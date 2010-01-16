#import "SourceCell.h"

@implementation SourceCell

- (void) dealloc {
    [icon_ release];
    [origin_ release];
    [description_ release];
    [label_ release];
	
	[iconView_ release];
	[originLabel_ release];
	[descriptionLabel_ release];
	[labelLabel_ release];
	
    [super dealloc];
}

- (void) setSource:(Source *)source {
	[icon_ release];
    [origin_ release];
    [description_ release];
    [label_ release];
	
	[iconView_ release];
	[originLabel_ release];
	[descriptionLabel_ release];
	[labelLabel_ release];
	
	if (icon_ == nil)
		icon_ = [UIImage applicationImageNamed:[NSString stringWithFormat:@"Sources/%@.png", [source host]]];
	if (icon_ == nil)
		icon_ = [UIImage applicationImageNamed:@"unknown.png"];
	icon_ = [icon_ retain];
	
	origin_ = [[source name] retain];
	label_ = [[source uri] retain];
	description_ = [[source description] retain];	
	
	iconView_ = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 30, 30)];
	[iconView_ setImage:icon_];
	
	originLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(48, 8, 240, [origin_ sizeWithFont:Font18Bold_].height)];
	[originLabel_ setText:origin_];
	[originLabel_ setFont:Font18Bold_];
	[originLabel_ setTextColor:[UIColor colorWithCGColor:(CGColorRef) Black_]];
	
	labelLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(48, 29, 240, [label_ sizeWithFont:Font12_].height)];
	[labelLabel_ setText:label_];
	[labelLabel_ setFont:Font12_];
	[labelLabel_ setTextColor:[UIColor colorWithCGColor:(CGColorRef) Blue_]];
	
	descriptionLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(12, 46, 280, [description_ sizeWithFont:Font14_].height)];
	[descriptionLabel_ setText:description_];
	[descriptionLabel_ setFont:Font14_];
	[descriptionLabel_ setTextColor:[UIColor colorWithCGColor:(CGColorRef) Gray_]];
	
	[self addSubview:iconView_];
	[self addSubview:originLabel_];
	[self addSubview:descriptionLabel_];
	[self addSubview:labelLabel_];
}

- (SourceCell *) initWithSource:(Source *)source {
    if ((self = [super init]) != nil) {
        [self setSource:source];
    } return self;
}

@end
/* }}} */
