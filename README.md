# WCAtlas

WCAtlas is a native UIKit WeChat enhancement tweak. Version `0.1.7` includes native chat navigation, Moments enhancements, a reusable message library, automations, call recording, and call-audio tools.

The settings page groups features into Chat, Moments, Interface Disable, Interface Optimization, Common Enhancements, and Plugin Settings. Category expansion state is remembered locally. `Assets/WCAtlas-Icon-1024.png` is the release artwork.

## Logs and development tools

Plugin Settings contains a bounded in-memory runtime log viewer and WCAtlas-only configuration import/export. Runtime inspection and developer tooling live in the separate WCDebug plugin and are not included in WCAtlas.

WCAtlas registers its settings controller and optional quick switches through the external `WCPluginsMgr` API when available. The built-in plugin manager page is disabled by default; enabling it adds the WCAtlas-owned management entry inside WeChat.

## Entry

When `WCPluginsMgr` is available, WCAtlas registers:

- Title: `WCAtlas`
- Version: `0.1.7`
- Controller: `WCAtlasSettingsViewController`

## Build

The GitHub Actions workflow builds both rootful and rootless `.deb` packages for `arm64` and `arm64e`. You can also build locally with Theos:

```sh
make clean package FINALPACKAGE=1
make clean package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```
