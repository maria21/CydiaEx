#import "Cydia.h"
#import "PackageTable.h"

@class RVBook, Package;
/* Filtered Package Table {{{ */
@interface FilteredPackageTable : PackageTable {
    SEL filter_;
    IMP imp_;
    id object_;
}

- (void) setObject:(id)object;

- (id) initWithBook:(RVBook *)book database:(Database *)database title:(NSString *)title filter:(SEL)filter with:(id)object;

@end
