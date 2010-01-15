#import "Cydia.h"
#import "CydiaBrowserView.h"

/* Signature View {{{ */
@interface SignatureView : CydiaBrowserView {
    _transient Database *database_;
    NSString *package_;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database package:(NSString *)package;

@end
