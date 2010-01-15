#import "Cydia.h"

/* Changes View {{{ */
@interface ChangesView : RVPage {
    _transient Database *database_;
    NSMutableArray *packages_;
    NSMutableArray *sections_;
    UITableView *list_;
    unsigned upgrades_;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database;
- (void) reloadData;

@end
