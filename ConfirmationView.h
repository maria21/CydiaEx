#import "Cydia.h"
#import "CydiaBrowserView.h"

@interface ConfirmationView : CydiaBrowserView {
    _transient Database *database_;
    UIActionSheet *essential_;
    NSArray *changes_;
    NSArray *issues_;
    NSArray *sizes_;
    BOOL substrate_;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database;

@end
