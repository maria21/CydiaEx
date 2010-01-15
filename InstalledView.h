#import "Cydia.h"

@class FilteredPackageTable;
/* Installed View {{{ */
@interface InstalledView : RVPage {
    _transient Database *database_;
    FilteredPackageTable *packages_;
    BOOL expert_;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database;

@end
