# NeoWC

NeoWC is a native UIKit WeChat enhancement tweak. Version `0.1.6` adds Moments reminders and comment protection, improves quick replies and media-to-voice actions, and reorganizes settings around user-facing features.

The settings page groups features into Chat, Moments, Interface Disable, Interface Optimization, Common Enhancements, and Plugin Settings. Category expansion state is remembered locally. NeoWC uses a transparent, single-stroke monogram that combines the letter N with a conversation tail; `Assets/NeoWCIcon.svg` is the matching scalable design source.

## Logs and development tools

Plugin Settings contains a bounded in-memory runtime log viewer and configuration import/export. Runtime inspection and developer tooling live in the separate WCDebug plugin and are not included in NeoWC.

## Entry

When `WCPluginsMgr` is available, NeoWC registers:

- Title: `NeoWC`
- Version: `0.1.6`
- Controller: `NeoWCSettingsViewController`

## Build

The GitHub Actions workflow builds both rootful and rootless `.deb` packages for `arm64` and `arm64e`. You can also build locally with Theos:

```sh
make clean package FINALPACKAGE=1
make clean package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```
