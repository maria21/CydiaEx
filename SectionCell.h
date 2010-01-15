#import "Cydia.h"


@class Section;
/* Section Cell {{{ */
@interface SectionCell : UISimpleTableCell {
    NSString *section_;
    NSString *name_;
    NSString *count_;
    UIImage *icon_;
    _UISwitchSlider *switch_;
    BOOL editing_;
}

- (id) init;
- (void) setSection:(Section *)section editing:(BOOL)editing;

@end
