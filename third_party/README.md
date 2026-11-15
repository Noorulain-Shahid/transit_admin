# Patched FlutterFire plugins (Transit Admin, Windows)

`pubspec.yaml` overrides `cloud_firestore` (6.3.0) and `firebase_auth` (6.4.0)
with these local copies. Only their `windows/` C++ code differs from pub.dev;
Android, iOS, macOS and web behave exactly as upstream.

## Why

1. **Every Firestore query crashed the Windows app (0xc0000409).**
   `cloud_firestore` 6.3.0 ships Windows C++ generated before
   `cloud_firestore_platform_interface` 7.2.0 added `PigeonPipelineResult`
   (137) and `PigeonPipelineSnapshot` (138) to the Pigeon codec. Dart therefore
   sends query parameters as type 139 while the C++ read 139 as
   `PigeonSnapshotMetadata` and aborted. Fix: `cloud_firestore/windows/messages.g.cpp`
   ids shifted to match Dart (QueryParameters 139, QuerySnapshot 140,
   SnapshotMetadata 141, TransactionCommand 142).

2. **Firebase SDK threads (flutter/flutter#134346, flutterfire#18210/#18226).**
   The Firebase C++ SDK completes futures and fires listeners on worker threads;
   Flutter's Windows engine aborts on platform-channel traffic off the platform
   thread. `windows/platform_thread_messenger.h` wraps the registrar's
   messenger so every event and every reply is posted to the platform thread.

## Upgrading

Before bumping either package, check whether upstream fixed both issues. If
not, copy the new version here again and re-apply the two changes (search for
`TRANSIT ADMIN PATCH`). Delete the overrides once upstream is fixed.
