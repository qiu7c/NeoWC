# NeoWC

NeoWC is a native UIKit settings shell for a WeChat tweak. The current `0.1.0` milestone focuses on the plugin entry and UI; feature switches persist their state but do not yet change WeChat behavior.

The settings page groups features into collapsible message, privacy, appearance, and laboratory categories. Category expansion state is remembered locally. NeoWC uses a transparent, single-stroke monogram that combines the letter N with a conversation tail; `Assets/NeoWCIcon.svg` is the matching scalable design source.

## Entry

When `WCPluginsMgr` is available, NeoWC registers:

- Title: `NeoWC`
- Version: `0.1.0`
- Controller: `NeoWCSettingsViewController`

## Build

The GitHub Actions workflow builds both rootful and rootless `.deb` packages for `arm64` and `arm64e`. You can also build locally with Theos:

```sh
make clean package FINALPACKAGE=1
make clean package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```
