// TRANSIT ADMIN PATCH — not part of upstream FlutterFire.
//
// On Windows the Firebase C++ SDK completes futures and fires listeners on its
// own worker threads, and FlutterFire sends the results to Dart from there.
// Flutter's Windows engine only accepts platform-channel traffic on the
// platform (UI) thread and aborts the process otherwise (0xc0000409,
// FAST_FAIL_INVALID_ARG) — see flutter/flutter#134346 and
// firebase/flutterfire#18210 / #18226.
//
// PlatformThreadMessenger wraps the registrar's BinaryMessenger so that every
// outgoing message (EventChannel events) and every reply to a Dart call
// (Pigeon / MethodChannel results) is re-posted to the platform thread when it
// arrives from any other thread. The plugin code itself is unchanged apart
// from using this wrapper instead of `registrar->messenger()`.
//
// FLUTTERFIRE_DISPATCH_CLASS must be defined (to a unique wide string) before
// including this header, so each plugin DLL registers its own window class.

#pragma once

#include <flutter/binary_messenger.h>
#include <windows.h>

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#ifndef FLUTTERFIRE_DISPATCH_CLASS
#error "Define FLUTTERFIRE_DISPATCH_CLASS before including platform_thread_messenger.h"
#endif

extern "C" IMAGE_DOS_HEADER __ImageBase;

namespace flutterfire_threading {


class PlatformThreadDispatcher {
 public:
  static PlatformThreadDispatcher& Instance() {
    static PlatformThreadDispatcher instance;
    return instance;
  }

  // Must be called on the platform thread (plugin registration runs there).
  void Init() {
    if (hwnd_ != nullptr) return;
    thread_id_ = ::GetCurrentThreadId();
    HINSTANCE module = reinterpret_cast<HINSTANCE>(&__ImageBase);
    WNDCLASSW wc = {};
    wc.lpfnWndProc = &PlatformThreadDispatcher::WndProc;
    wc.hInstance = module;
    wc.lpszClassName = FLUTTERFIRE_DISPATCH_CLASS;
    ::RegisterClassW(&wc);  // Already registered on a re-init is fine.
    hwnd_ = ::CreateWindowExW(0, FLUTTERFIRE_DISPATCH_CLASS, L"", 0, 0, 0, 0,
                              0, HWND_MESSAGE, nullptr, module, nullptr);
  }

  bool OnPlatformThread() const {
    return thread_id_ == 0 || ::GetCurrentThreadId() == thread_id_;
  }

  // Runs [task] now when already on the platform thread, otherwise queues it
  // there (in order).
  void Run(std::function<void()> task) {
    if (hwnd_ == nullptr || OnPlatformThread()) {
      task();
      return;
    }
    auto* heap = new std::function<void()>(std::move(task));
    if (!::PostMessageW(hwnd_, kRunTask, 0, reinterpret_cast<LPARAM>(heap))) {
      delete heap;  // Window gone (shutting down) — drop the message.
    }
  }

 private:
  static constexpr UINT kRunTask = WM_APP + 0x3A7;

  static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wparam,
                                  LPARAM lparam) {
    if (msg == kRunTask) {
      std::unique_ptr<std::function<void()>> task(
          reinterpret_cast<std::function<void()>*>(lparam));
      if (task && *task) (*task)();
      return 0;
    }
    return ::DefWindowProcW(hwnd, msg, wparam, lparam);
  }

  HWND hwnd_ = nullptr;
  DWORD thread_id_ = 0;
};

class PlatformThreadMessenger : public flutter::BinaryMessenger {
 public:
  explicit PlatformThreadMessenger(flutter::BinaryMessenger* inner)
      : inner_(inner) {
    PlatformThreadDispatcher::Instance().Init();
  }

  void Send(const std::string& channel, const uint8_t* message,
            size_t message_size,
            flutter::BinaryReply reply = nullptr) const override {
    auto& dispatcher = PlatformThreadDispatcher::Instance();
    if (dispatcher.OnPlatformThread()) {
      inner_->Send(channel, message, message_size, std::move(reply));
      return;
    }
    std::vector<uint8_t> copy(message, message + message_size);
    flutter::BinaryMessenger* inner = inner_;
    dispatcher.Run([inner, channel, copy, reply]() {
      inner->Send(channel, copy.data(), copy.size(), reply);
    });
  }

  void SetMessageHandler(const std::string& channel,
                         flutter::BinaryMessageHandler handler) override {
    if (!handler) {
      inner_->SetMessageHandler(channel, nullptr);
      return;
    }
    inner_->SetMessageHandler(
        channel, [handler](const uint8_t* message, size_t message_size,
                           flutter::BinaryReply reply) {
          // The handler is invoked on the platform thread; its reply may be
          // called later from an SDK thread, so route that back.
          flutter::BinaryReply safe_reply = [reply](const uint8_t* data,
                                                    size_t size) {
            auto& dispatcher = PlatformThreadDispatcher::Instance();
            if (dispatcher.OnPlatformThread()) {
              reply(data, size);
              return;
            }
            std::vector<uint8_t> copy(data, data + size);
            dispatcher.Run(
                [reply, copy]() { reply(copy.data(), copy.size()); });
          };
          handler(message, message_size, std::move(safe_reply));
        });
  }

 private:
  flutter::BinaryMessenger* inner_;
};

}  // namespace flutterfire_threading
