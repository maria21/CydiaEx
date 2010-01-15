#import "Cydia.h"
#import "CydiaBrowserView.h"

/* Package View {{{ */
@interface PackageView : CydiaBrowserView {
    _transient Database *database_;
    Package *package_;
    NSString *name_;
    bool commercial_;
    NSMutableArray *buttons_;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database;
- (void) setPackage:(Package *)package;

@end
