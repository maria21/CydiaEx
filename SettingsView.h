#import "Cydia.h"


/* Settings View {{{ */
@interface SettingsView : RVPage {
    _transient Database *database_;
    NSString *name_;
    Package *package_;
    UIPreferencesTable *table_;
    _UISwitchSlider *subscribedSwitch_;
    _UISwitchSlider *ignoredSwitch_;
    UIPreferencesControlTableCell *subscribedCell_;
    UIPreferencesControlTableCell *ignoredCell_;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database package:(NSString *)package;

@end
