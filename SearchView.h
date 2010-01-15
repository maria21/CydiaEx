#import "Cydia.h"

@class FilteredPackageTable;
@interface SearchView : RVPage {
    UIView *accessory_;
    UISearchField *field_;
    FilteredPackageTable *table_;
    UIView *dimmed_;
    bool reload_;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database;
- (void) reloadData;

@end