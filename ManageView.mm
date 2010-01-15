#import "ManageView.h"

@implementation ManageView

- (NSString *) title {
    return UCLocalize("MANAGE");
}

- (void) _leftButtonClicked {
    [delegate_ askForSettings];
    [delegate_ updateData];
}

- (NSString *) leftButtonTitle {
    return UCLocalize("SETTINGS");
}

#if !AlwaysReload
- (id) _rightButtonTitle {
    return Queuing_ ? UCLocalize("QUEUE") : nil;
}

- (UINavigationButtonStyle) rightButtonStyle {
    return Queuing_ ? UINavigationButtonStyleHighlighted : UINavigationButtonStyleNormal;
}

- (void) _rightButtonClicked {
    [delegate_ queue];
}
#endif

- (bool) isLoading {
    return false;
}

@end
/* }}} */

