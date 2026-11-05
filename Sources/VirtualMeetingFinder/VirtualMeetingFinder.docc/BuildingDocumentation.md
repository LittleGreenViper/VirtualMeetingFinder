# Build the App and Documentation

Build an app documentation archive that includes its internal implementation symbols.

## Overview

Open `VirtualMeetingFinder.xcodeproj` or `VirtualMeetingFinder.xcworkspace` in
Xcode and allow its Swift packages to resolve. Select **We Are Never Alone** and
an iOS simulator destination. Build normally to check compilation, or choose
**Product > Build Documentation** to open the catalog in Xcode's documentation viewer.

The app target sets `DOCC_MINIMUM_ACCESS_LEVEL` to `internal` in Debug, Release,
and Screenshots. Most app controllers are internal, so a public-only symbol graph
would omit the implementation that contributors need. Keep their access levels
unchanged when adding documentation.

### Command-line build

From the repository root, with the intended Xcode selected:

```sh
xcodebuild docbuild \
  -project VirtualMeetingFinder.xcodeproj \
  -scheme 'We Are Never Alone' \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/VMFDocumentation \
  CODE_SIGNING_ALLOWED=NO
```

The app archive is written to:

```text
/tmp/VMFDocumentation/Build/Products/Debug-iphonesimulator/We Are Never Alone.doccarchive
```

Open that archive in Xcode to browse the catalog. Package documentation archives
are produced alongside it. When checking diagnostics, distinguish this app's
source and catalog from warnings in package checkouts.

### Keeping the catalog useful

Start with the module overview and the contributor guides. Its Topics groups
link the lifecycle, screens, shared controls, and share-sheet activities. Type
pages expose their documented members through DocC's generated navigation.
Update these groups when adding a new major type.

Use DocC symbol links for app declarations and article links for guides. Document
parameter names as they appear inside Swift declarations. Describe time indexes,
weekday indexes, and HHMM values explicitly. Keep source comments aligned with
the current popover and search model. Retain upstream copyright and license
notices when editing reused files.

Existing generated documentation under `docs/` is a separate, older output. A
local DocC build does not publish or replace that website.

### Screenshot builds

Use **We Are Never Alone (For Screenshots)** only for simulator screenshots. The
Screenshots configuration exposes recognized meeting-app controls and Recovrr
controls for presentation even when the apps are unavailable. It does not install
those apps. The scheme disables archiving, and the build guard rejects archive
or install actions with that configuration. Use regular Debug or Release builds
when checking real app availability and accessibility behavior.
