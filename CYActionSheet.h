#import "Cydia.h"

@interface CYActionSheet : UIActionSheet {
    unsigned button_;
}

- (int) yieldToPopupAlertAnimated:(BOOL)animated;
@end