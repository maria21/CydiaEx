#import "Cydia.h"

/* File Table {{{ */
@interface FileTable : RVPage {
    _transient Database *database_;
    Package *package_;
    NSString *name_;
    NSMutableArray *files_;
    UITableView *list_;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database;
- (void) setPackage:(Package *)package;

@end
