#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const NeoWCPluginShortcutsEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCPluginShortcutLoggingKey;
FOUNDATION_EXPORT NSString *const NeoWCPluginShortcutFloatingDebugKey;
FOUNDATION_EXPORT NSString *const NeoWCPluginShortcutDebugCenterKey;
FOUNDATION_EXPORT NSString *const NeoWCPluginShortcutRevokeRecordsKey;
FOUNDATION_EXPORT NSString *const NeoWCPluginShortcutCustomPageKey;
FOUNDATION_EXPORT NSString *const NeoWCPluginShortcutCustomTitleKey;
FOUNDATION_EXPORT NSString *const NeoWCPluginShortcutCustomClassKey;

/// Registers the enabled shortcuts with WCPluginsMgr. Registration is idempotent per process.
FOUNDATION_EXPORT void NeoWCRegisterPluginShortcuts(id manager);
FOUNDATION_EXPORT void NeoWCRegisterPluginShortcutsIfAvailable(void);
