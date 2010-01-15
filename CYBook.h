#import "Cydia.h"


/* Cydia Book {{{ */
@interface CYBook : RVBook <
ProgressDelegate
> {
    _transient Database *database_;
    UINavigationBar *overlay_;
    UINavigationBar *underlay_;
    UIProgressIndicator *indicator_;
    UITextLabel *prompt_;
    UIProgressBar *progress_;
    UINavigationButton *cancel_;
    bool updating_;
}

- (id) initWithFrame:(CGRect)frame database:(Database *)database;
- (void) update;
- (BOOL) updating;

@end
