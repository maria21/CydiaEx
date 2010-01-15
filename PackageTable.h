#import "Cydia.h"



/* Package Table {{{ */
@interface PackageTable : RVPage {
    _transient Database *database_;
    NSString *title_;
    NSMutableArray *packages_;
    NSMutableArray *sections_;
    UITableView *list_;
    NSMutableArray *index_;
    NSMutableDictionary *indices_;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database title:(NSString *)title;

- (void) setDelegate:(id)delegate;

- (void) reloadData;
- (void) resetCursor;

- (UITableView *) list;

- (void) setShouldHideHeaderInShortLists:(BOOL)hide;

@end
