#import "SectionCell.h"


@implementation SectionCell

- (void) clearSection {
    if (section_ != nil) {
        [section_ release];
        section_ = nil;
    }
	
    if (name_ != nil) {
        [name_ release];
        name_ = nil;
    }
	
    if (count_ != nil) {
        [count_ release];
        count_ = nil;
    }
}

- (void) dealloc {
    [self clearSection];
    [icon_ release];
    [switch_ release];
    [super dealloc];
}

- (id) init {
    if ((self = [super init]) != nil) {
        icon_ = [[UIImage applicationImageNamed:@"folder.png"] retain];
		
        switch_ = [[_UISwitchSlider alloc] initWithFrame:CGRectMake(218, 9, 60, 25)];
        [switch_ addTarget:self action:@selector(onSwitch:) forEvents:UIControlEventTouchUpInside];
    } return self;
}

- (void) onSwitch:(id)sender {
    NSMutableDictionary *metadata = [Sections_ objectForKey:section_];
    if (metadata == nil) {
        metadata = [NSMutableDictionary dictionaryWithCapacity:2];
        [Sections_ setObject:metadata forKey:section_];
    }
	
    Changed_ = true;
    [metadata setObject:[NSNumber numberWithBool:([switch_ value] == 0)] forKey:@"Hidden"];
}

- (void) setSection:(Section *)section editing:(BOOL)editing {
    if (editing != editing_) {
        if (editing_)
            [switch_ removeFromSuperview];
        else
            [self addSubview:switch_];
        editing_ = editing;
    }
	
    [self clearSection];
	
    if (section == nil) {
        name_ = [UCLocalize("ALL_PACKAGES") retain];
        count_ = nil;
    } else {
        section_ = [section localized];
        if (section_ != nil)
            section_ = [section_ retain];
        name_  = [(section_ == nil || [section_ length] == 0 ? UCLocalize("NO_SECTION") : section_) retain];
        count_ = [[NSString stringWithFormat:@"%d", [section count]] retain];
		
        if (editing_)
            [switch_ setValue:(isSectionVisible(section_) ? 1 : 0) animated:NO];
    }
}

- (void) drawContentInRect:(CGRect)rect selected:(BOOL)selected {
    [icon_ drawInRect:CGRectMake(8, 7, 32, 32)];
	
    if (selected)
        UISetColor(White_);
	
    if (!selected)
        UISetColor(Black_);
    [name_ drawAtPoint:CGPointMake(48, 9) forWidth:(editing_ ? 164 : 250) withFont:Font22Bold_ ellipsis:2];
	
    CGSize size = [count_ sizeWithFont:Font14_];
	
    UISetColor(White_);
    if (count_ != nil)
        [count_ drawAtPoint:CGPointMake(13 + (29 - size.width) / 2, 16) withFont:Font12Bold_];
	
    [super drawContentInRect:rect selected:selected];
}

@end
/* }}} */
