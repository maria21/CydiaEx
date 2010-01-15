#import "Cydia.h"

/* Add Source View {{{ */
@interface AddSourceView : RVPage {
    _transient Database *database_;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database;

@end
