#import "SourceCell.h"

@implementation SourceCell

- (void) dealloc {
    [icon_ release];
    [origin_ release];
    [description_ release];
    [label_ release];
    [super dealloc];
}

- (SourceCell *) initWithSource:(Source *)source {
    if ((self = [super init]) != nil) {
        if (icon_ == nil)
            icon_ = [UIImage applicationImageNamed:[NSString stringWithFormat:@"Sources/%@.png", [source host]]];
        if (icon_ == nil)
            icon_ = [UIImage applicationImageNamed:@"unknown.png"];
        icon_ = [icon_ retain];
		
        origin_ = [[source name] retain];
        label_ = [[source uri] retain];
        description_ = [[source description] retain];
    } return self;
}

- (void) drawContentInRect:(CGRect)rect selected:(BOOL)selected {
    if (icon_ != nil)
        [icon_ drawInRect:CGRectMake(10, 10, 30, 30)];
	
    if (selected)
        UISetColor(White_);
	
    if (!selected)
        UISetColor(Black_);
    [origin_ drawAtPoint:CGPointMake(48, 8) forWidth:240 withFont:Font18Bold_ ellipsis:2];
	
    if (!selected)
        UISetColor(Blue_);
    [label_ drawAtPoint:CGPointMake(58, 29) forWidth:225 withFont:Font12_ ellipsis:2];
	
    if (!selected)
        UISetColor(Gray_);
    [description_ drawAtPoint:CGPointMake(12, 46) forWidth:280 withFont:Font14_ ellipsis:2];
	
    [super drawContentInRect:rect selected:selected];
}

@end
/* }}} */
