#import "Cydia.h"


/* Sections View {{{ */
@interface SectionsView : RVPage {
    _transient Database *database_;
    NSMutableArray *sections_;
    NSMutableArray *filtered_;
    UITransitionView *transition_;
    UITable *list_;
    UIView *accessory_;
    BOOL editing_;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database;
- (void) reloadData;
- (void) resetView;

@end
