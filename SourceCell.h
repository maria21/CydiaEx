#import "Cydia.h"

/* Source Cell {{{ */
@interface SourceCell : UITableCell {
    UIImage *icon_;
    NSString *origin_;
    NSString *description_;
    NSString *label_;
}

- (void) dealloc;

- (SourceCell *) initWithSource:(Source *)source;

@end