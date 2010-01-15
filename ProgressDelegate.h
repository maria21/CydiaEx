#import "Cydia.h"

/* Delegate Helpers {{{ */
@interface NSObject(ProgressDelegate)

- (void) _setProgressErrorPackage:(NSArray *)args;
- (void) _setProgressErrorTitle:(NSArray *)args;
- (void) _setProgressError:(NSString *)error withTitle:(NSString *)title;

- (void) setProgressError:(NSString *)error forPackage:(NSString *)id;
@end
/* }}} */