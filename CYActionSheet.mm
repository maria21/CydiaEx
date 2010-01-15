
#import "CYActionSheet.h"

@implementation CYActionSheet

- (id) initWithTitle:(NSString *)title buttons:(NSArray *)buttons defaultButtonIndex:(int)index {
    if ((self = [super initWithTitle:title buttons:buttons defaultButtonIndex:index delegate:self context:nil]) != nil) {
    } return self;
}

- (void) alertSheet:(UIActionSheet *)sheet buttonClicked:(int)button {
    button_ = button;
}

- (int) yieldToPopupAlertAnimated:(BOOL)animated {
    button_ = 0;
    [self popupAlertAnimated:animated];
    NSRunLoop *loop([NSRunLoop currentRunLoop]);
    NSDate *future([NSDate distantFuture]);
    while (button_ == 0 && [loop runMode:NSDefaultRunLoopMode beforeDate:future]);
    return button_;
}

@end
