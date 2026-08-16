#import "NeoWCSettingsModels.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const NeoWCEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCCollapsedFeaturesKey;
FOUNDATION_EXPORT NSString *const NeoWCDisplayVersion;

FOUNDATION_EXPORT void NeoWCSettingsRegisterDefaults(void);
FOUNDATION_EXPORT void NeoWCSettingsRegenerateDailyStepTarget(NSUserDefaults *defaults);
FOUNDATION_EXPORT NSArray<NeoWCSettingSection *> *NeoWCSettingsBuildSections(NeoWCSettingsCategory category,
                                                                            NSSet<NSString *> *collapsedFeatureKeys);

NS_ASSUME_NONNULL_END
