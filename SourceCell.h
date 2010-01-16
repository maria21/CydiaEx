#import "Cydia.h"

/* Source Cell {{{ */
@interface SourceCell : UITableViewCell {
    UIImage *icon_;
	UIImageView *iconView_;
    NSString *origin_;
    NSString *description_;
    NSString *label_;
	UILabel *originLabel_;
	UILabel *descriptionLabel_;
	UILabel *labelLabel_;
}

- (void) dealloc;

- (SourceCell *) initWithSource:(Source *)source;
- (void) setSource:(Source *)source;

@end