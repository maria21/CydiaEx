#import "Cydia.h"

/* Delegate Prototypes {{{ */
@class Package;
@class Source;

@protocol ProgressDelegate
- (void) setProgressError:(NSString *)error withTitle:(NSString *)id;
- (void) setProgressTitle:(NSString *)title;
- (void) setProgressPercent:(float)percent;
- (void) startProgress;
- (void) addProgressOutput:(NSString *)output;
- (bool) isCancelling:(size_t)received;
@end

@protocol ConfigurationDelegate
- (void) repairWithSelector:(SEL)selector;
- (void) setConfigurationData:(NSString *)data;
@end

@class PackageView;

@protocol CydiaDelegate
- (void) setPackageView:(PackageView *)view;
- (void) clearPackage:(Package *)package;
- (void) installPackage:(Package *)package;
- (void) removePackage:(Package *)package;
- (void) slideUp:(UIActionSheet *)alert;
- (void) distUpgrade;
- (void) updateData;
- (void) syncData;
- (void) askForSettings;
- (UIProgressHUD *) addProgressHUD;
- (void) removeProgressHUD:(UIProgressHUD *)hud;
- (RVPage *) pageForPackage:(NSString *)name;
- (PackageView *) packageView;
@end
/* }}} */

@class ProgressView;
@protocol ProgressViewDelegate
- (void) progressViewIsComplete:(ProgressView *)sender;
@end

/* Search View {{{ */
@protocol SearchViewDelegate
- (void) showKeyboard:(BOOL)show;
@end

@protocol ConfirmationViewDelegate
- (void) cancel;
- (void) confirm;
- (void) queue;
@end

