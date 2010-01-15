#import "Cydia.h"


/* Progress View {{{ */
@interface ProgressView : UIView <
ConfigurationDelegate,
ProgressDelegate
> {
    _transient Database *database_;
    UIView *view_;
    UIView *background_;
    UITransitionView *transition_;
    UIView *overlay_;
    UINavigationBar *navbar_;
    UIProgressBar *progress_;
    UITextView *output_;
    UITextLabel *status_;
    UITextLabel *header_;
    UIPushButton *close_;
    UIActivityIndicatorView *activity_;
    id delegate_;
    BOOL running_;
    SHA1SumValue springlist_;
    SHA1SumValue notifyconf_;
    NSString *title_;
}

- (id) initWithFrame:(struct CGRect)frame database:(Database *)database delegate:(id)delegate;
- (void) setContentView:(UIView *)view;
- (void) resetView;

- (void) _retachThread;
- (void) _detachNewThreadData:(ProgressData *)data;
- (void) detachNewThreadSelector:(SEL)selector toTarget:(id)target withObject:(id)object title:(NSString *)title;

- (BOOL) isRunning;

@end
