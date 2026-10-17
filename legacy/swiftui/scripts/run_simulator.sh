#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
meetme_simulator_id="${1:-$(xcrun simctl list devices available --json | python3 -c 'import json,sys; devices=json.load(sys.stdin)["devices"]; print(next((d["udid"] for values in devices.values() for d in values if d["name"] == "MeetMe iPhone 17"), ""))')}"
if [[ -z "$meetme_simulator_id" ]]; then
  meetme_simulator_id=$(xcrun simctl create 'MeetMe iPhone 17' com.apple.CoreSimulator.SimDeviceType.iPhone-17 com.apple.CoreSimulator.SimRuntime.iOS-26-0)
fi
xcrun simctl boot "$meetme_simulator_id" 2>/dev/null || true
xcrun simctl bootstatus "$meetme_simulator_id" -b
xcodebuild -project MeetMe.xcodeproj -scheme MeetMe -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
xcrun simctl install "$meetme_simulator_id" build/DerivedData/Build/Products/Debug-iphonesimulator/MeetMe.app
xcrun simctl launch "$meetme_simulator_id" dev.meetme.localdemo
print "Meetme is running on $meetme_simulator_id. Open Simulator to interact."
