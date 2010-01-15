#import "Cydia.h"


/* Package Cell {{{ */
@interface ContentView : UIView {
    _transient id delegate_;
}

@end


@interface PackageCell : UITableViewCell {
    UIImage *icon_;
    NSString *name_;
    NSString *description_;
    bool commercial_;
    NSString *source_;
    UIImage *badge_;
    Package *package_;
    UIColor *color_;
    ContentView *content_;
    BOOL faded_;
    float fade_;
    UIImage *placard_;
}

- (PackageCell *) init;
- (void) setPackage:(Package *)package;

+ (int) heightForPackage:(Package *)package;
- (void) drawContentRect:(CGRect)rect;

@end
