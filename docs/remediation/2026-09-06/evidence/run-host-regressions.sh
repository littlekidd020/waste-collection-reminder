#!/bin/bash
# Actual-model host checks. UIKit and notification delivery are not exercised here.
set -euo pipefail
REPO="$(cd -- "$(dirname -- "$0")/../../../.." && pwd)"
WORK="$(mktemp -d /tmp/bindaynz-host-regressions.XXXXXX)"
XCODE="$(xcode-select -p)"
PLATFORM="$XCODE/Platforms/MacOSX.platform/Developer"
cd "$REPO"
export BINDAYNZ_HOST_WORK="$WORK"
python3 - <<'PY'
import os, plistlib, uuid
from pathlib import Path
work = Path(os.environ['BINDAYNZ_HOST_WORK'])
notification = Path('BinDayNZ/Services/NotificationService.swift').read_text()
start = notification.index('    static func plan(')
end = notification.index('\n    func rescheduleUpcoming', start)
(work / 'NotificationPlan.swift').write_text(
    notification[:notification.index('final class NotificationService')] +
    'final class NotificationService {\n' + notification[start:end] + '\n}\n')
video = Path('BinDayNZ/Views/Info/YouTubePlayerView.swift').read_text()
start = video.index('    static func request(')
end = video.index('\n    final class Coordinator', start)
(work / 'YouTubeRequest.swift').write_text(
    'import Foundation\nstruct YouTubePlayerView {\n' + video[start:end] + '\n}\n')
contents = work / 'HostRegression.app/Contents'
(contents / 'MacOS').mkdir(parents=True)
with (contents / 'Info.plist').open('wb') as target:
    plistlib.dump({'CFBundleExecutable': 'HostRegression', 'CFBundleName': 'HostRegression',
                  'CFBundleIdentifier': 'com.bindaynz.regressionhost.' + uuid.uuid4().hex,
                  'CFBundlePackageType': 'APPL', 'CFBundleVersion': '1'}, target)
(work / 'main.swift').write_text('''import XCTest
let status: Int32 = MainActor.assumeIsolated {
    guard let identifier = Bundle.main.bundleIdentifier,
          identifier.hasPrefix("com.bindaynz.regressionhost.") else {
        fatalError("Host checks require their isolated preferences domain")
    }
    defer { UserDefaults.standard.removePersistentDomain(forName: identifier) }
    print("Isolated host bundle: \\(identifier)")
    let suite = XCTestSuite(name: "BinDayNZ host regressions")
    suite.addTest(ManualScheduleTests.defaultTestSuite)
    suite.addTest(SchedulePersistenceAndReminderTests.defaultTestSuite)
    suite.addTest(CalendarSafetyTests.defaultTestSuite)
    suite.addTest(WidgetSnapshotTests.defaultTestSuite)
    suite.addTest(VideoSourceTests.defaultTestSuite)
    suite.addTest(IconographyTests.defaultTestSuite)
    suite.run()
    guard let run = suite.testRun else { fatalError("No test result") }
    print("REGRESSION RESULT: \\(run.executionCount) executed, \\(run.failureCount) failures, \\(run.skipCount) skipped")
    return run.failureCount == 0 && run.executionCount == 30 && run.skipCount == 2 ? 0 : 1
}
exit(status)
''')
PY

SOURCES=(
  BinDayNZ/Models/BinType.swift BinDayNZ/Models/CollectionSchedule.swift
  BinDayNZ/Models/CollectionZone.swift BinDayNZ/Models/UpcomingCollection.swift
  BinDayNZ/Models/Council.swift BinDayNZ/Models/UserProfile.swift
  BinDayNZ/Services/ScheduleEngine.swift BinDayNZ/Services/CalendarService.swift
  BinDayNZ/Services/DataService.swift BinDayNZ/Services/LanguageManager.swift
)
TESTS=(
  BinDayNZTests/ManualScheduleTests.swift BinDayNZTests/ChangeAddressMapTests.swift
  BinDayNZTests/CalendarSafetyTests.swift BinDayNZTests/WidgetSnapshotTests.swift
  BinDayNZTests/VideoSourceTests.swift BinDayNZTests/IconographyTests.swift
)
date -u
swiftc --version
shasum -a 256 "${SOURCES[@]}" "${TESTS[@]}" BinDayNZ/Services/NotificationService.swift BinDayNZ/Views/Info/YouTubePlayerView.swift
set -x
swiftc -emit-library -emit-module -module-name BinDayNZ -enable-testing \
  -module-cache-path "$WORK/modules" -emit-module-path "$WORK/BinDayNZ.swiftmodule" \
  -o "$WORK/libBinDayNZ.dylib" "${SOURCES[@]}" "$WORK/NotificationPlan.swift" "$WORK/YouTubeRequest.swift"
swiftc -F "$PLATFORM/Library/Frameworks" -I "$PLATFORM/usr/lib" -L "$PLATFORM/usr/lib" \
  -I "$WORK" -L "$WORK" -lBinDayNZ -Xlinker -rpath -Xlinker "$WORK" \
  -Xlinker -rpath -Xlinker "$PLATFORM/Library/Frameworks" \
  -Xlinker -rpath -Xlinker "$PLATFORM/usr/lib" \
  -module-cache-path "$WORK/modules" "${TESTS[@]}" "$WORK/main.swift" \
  -o "$WORK/HostRegression.app/Contents/MacOS/HostRegression"
DYLD_FRAMEWORK_PATH="$PLATFORM/Library/PrivateFrameworks" "$WORK/HostRegression.app/Contents/MacOS/HostRegression"
