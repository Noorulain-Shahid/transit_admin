#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter_windows.h>
#include <windows.h>

#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // One instance only. A second copy shares the first one's Firebase local
  // cache (Firestore persistence / auth storage), cannot lock it, and the
  // Firebase C++ SDK aborts with an unhandled C++ exception (0xE06D7363).
  // Opening the app again just brings the running window to the front.
  HANDLE single_instance =
      ::CreateMutexW(nullptr, TRUE, L"Local\\TransitAdminSingleInstance");
  if (single_instance != nullptr &&
      ::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing =
        ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Transit Admin");
    if (existing != nullptr) {
      if (::IsIconic(existing)) ::ShowWindow(existing, SW_RESTORE);
      ::SetForegroundWindow(existing);
    }
    ::CloseHandle(single_instance);
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  // Open at 1366x800 (logical pixels), shrunk to fit a smaller screen's work
  // area and centred on it. Win32Window::Create scales these by the
  // monitor's DPI, so the work area is converted to logical pixels first.
  POINT cursor{0, 0};
  ::GetCursorPos(&cursor);
  HMONITOR monitor = ::MonitorFromPoint(cursor, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO monitor_info{};
  monitor_info.cbSize = sizeof(monitor_info);
  ::GetMonitorInfo(monitor, &monitor_info);
  const double scale = FlutterDesktopGetDpiForMonitor(monitor) / 96.0;
  const RECT work = monitor_info.rcWork;
  const int work_width =
      static_cast<int>((work.right - work.left) / scale);
  const int work_height =
      static_cast<int>((work.bottom - work.top) / scale);
  const int width = (std::min)(1366, (std::max)(800, work_width - 40));
  const int height = (std::min)(800, (std::max)(600, work_height - 40));
  const int left = static_cast<int>(work.left / scale) +
                   (std::max)(0, (work_width - width) / 2);
  const int top = static_cast<int>(work.top / scale) +
                  (std::max)(0, (work_height - height) / 2);
  Win32Window::Point origin(left, top);
  Win32Window::Size size(width, height);
  if (!window.Create(L"Transit Admin", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
