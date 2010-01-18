#import "PackageCell.h"

@implementation ContentView

- (id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame]) != nil) {
    } return self;
}

- (void) setDelegate:(id)delegate {
    delegate_ = delegate;
}

- (void) drawRect:(CGRect)rect {
    [super drawRect:rect];
    [delegate_ drawContentRect:rect];
}

@end

@implementation PackageCell

- (void) clearPackage {
    if (icon_ != nil) {
        [icon_ release];
        icon_ = nil;
    }
	
    if (name_ != nil) {
        [name_ release];
        name_ = nil;
    }
	
    if (description_ != nil) {
        [description_ release];
        description_ = nil;
    }
	
    if (source_ != nil) {
        [source_ release];
        source_ = nil;
    }
	
    if (badge_ != nil) {
        [badge_ release];
        badge_ = nil;
    }
	
    if (placard_ != nil) {
        [placard_ release];
        placard_ = nil;
    }
	
    [package_ release];
    package_ = nil;
}

- (void) dealloc {
    [self clearPackage];
    [content_ release];
    [color_ release];
    [super dealloc];
}

- (float) fade {
    return faded_ ? [self selectionPercent] : fade_;
}

- (PackageCell *) init {
    CGRect frame(CGRectMake(0, 0, 320, 74));
    if ((self = [super initWithFrame:frame reuseIdentifier:@"Package"]) != nil) {
        UIView *content([self contentView]);
        CGRect bounds([content bounds]);
        content_ = [[ContentView alloc] initWithFrame:bounds];
        [content_ setDelegate:self];
        [content_ setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        [content_ setOpaque:YES];
        [content addSubview:content_];
        if ([self respondsToSelector:@selector(selectionPercent)])
            faded_ = YES;
    } return self;
}

- (void) _setBackgroundColor {
    UIColor *color;
    if (NSString *mode = [package_ mode]) {
        bool remove([mode isEqualToString:@"REMOVE"] || [mode isEqualToString:@"PURGE"]);
        color = remove ? RemovingColor_ : InstallingColor_;
    } else
        color = [UIColor whiteColor];
	
    [content_ setBackgroundColor:color];
    [self setNeedsDisplay];
}

- (void) setPackage:(Package *)package {
    [self clearPackage];
    [package parse];
	
    Source *source = [package source];
	
    icon_ = [[package icon] retain];
    name_ = [[package name] retain];
    description_ = [[package shortDescription] retain];
    commercial_ = [package isCommercial];
	
    package_ = [package retain];
	
    NSString *label = nil;
    bool trusted = false;
	
    if (source != nil) {
        label = [source label];
        trusted = [source trusted];
    } else if ([[package id] isEqualToString:@"firmware"])
        label = UCLocalize("APPLE");
    else
        label = [NSString stringWithFormat:UCLocalize("SLASH_DELIMITED"), UCLocalize("UNKNOWN"), UCLocalize("LOCAL")];
	
    NSString *from(label);
	
    NSString *section = [package simpleSection];
    if (section != nil && ![section isEqualToString:label]) {
        section = [[NSBundle mainBundle] localizedStringForKey:section value:nil table:@"Sections"];
        from = [NSString stringWithFormat:UCLocalize("PARENTHETICAL"), from, section];
    }
	
    from = [NSString stringWithFormat:UCLocalize("FROM"), from];
    source_ = [from retain];
	
    if (NSString *purpose = [package primaryPurpose])
        if ((badge_ = [UIImage imageAtPath:[NSString stringWithFormat:@"%@/Purposes/%@.png", App_, purpose]]) != nil)
            badge_ = [badge_ retain];
	
    if ([package installed] != nil)
        if ((placard_ = [UIImage imageAtPath:[NSString stringWithFormat:@"%@/installed.png", App_]]) != nil)
            placard_ = [placard_ retain];
	
    [self _setBackgroundColor];
    [content_ setNeedsDisplay];
}

- (void) drawContentRect:(CGRect)rect {
    bool selected([self isSelected]);
	
#if 0
    CGContextRef context(UIGraphicsGetCurrentContext());
    [([[self selectedBackgroundView] superview] != nil ? [UIColor clearColor] : [self backgroundColor]) set];
    CGContextFillRect(context, rect);
#endif
	
    if (icon_ != nil) {
        CGRect rect;
        rect.size = [icon_ size];
		
        rect.size.width /= 2;
        rect.size.height /= 2;
		
        rect.origin.x = 25 - rect.size.width / 2;
        rect.origin.y = 25 - rect.size.height / 2;
		
        [icon_ drawInRect:rect];
    }
	
    if (badge_ != nil) {
        CGSize size = [badge_ size];
		
        [badge_ drawAtPoint:CGPointMake(
										36 - size.width / 2,
										36 - size.height / 2
										)];
    }
	
    if (selected)
        UISetColor(White_);
	
    if (!selected)
        UISetColor(commercial_ ? Purple_ : Black_);
    [name_ drawAtPoint:CGPointMake(48, 8) forWidth:(placard_ == nil ? 240 : 214) withFont:Font18Bold_ ellipsis:2];
    [source_ drawAtPoint:CGPointMake(48, 29) forWidth:225 withFont:Font12_ ellipsis:2];
	
    if (!selected)
        UISetColor(commercial_ ? Purplish_ : Gray_);
    [description_ drawAtPoint:CGPointMake(12, 46) forWidth:274 withFont:Font14_ ellipsis:2];
	
    if (placard_ != nil)
        [placard_ drawAtPoint:CGPointMake(268, 9)];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)fade {
    //[self _setBackgroundColor];
    [super setSelected:selected animated:fade];
    [content_ setNeedsDisplay];
}

+ (int) heightForPackage:(Package *)package {
    return 73;
}

@end
/* }}} */
