#import "CYBook.h"


@implementation CYBook

- (void) dealloc {
    [overlay_ release];
    [indicator_ release];
    [prompt_ release];
    [progress_ release];
    [cancel_ release];
    [super dealloc];
}

- (NSString *) getTitleForPage:(RVPage *)page {
    return [super getTitleForPage:page];
}

- (BOOL) updating {
    return updating_;
}

- (void) update {
    [UIView beginAnimations:nil context:NULL];
	
    CGRect ovrframe = [overlay_ frame];
    ovrframe.origin.y = 0;
    [overlay_ setFrame:ovrframe];
	
    CGRect barframe = [navbar_ frame];
    barframe.origin.y += ovrframe.size.height;
    [navbar_ setFrame:barframe];
	
    CGRect trnframe = [transition_ frame];
    trnframe.origin.y += ovrframe.size.height;
    trnframe.size.height -= ovrframe.size.height;
    [transition_ setFrame:trnframe];
	
    [UIView endAnimations];
	
    [indicator_ startAnimation];
    [prompt_ setText:UCLocalize("UPDATING_DATABASE")];
    [progress_ setProgress:0];
	
    updating_ = true;
    [overlay_ addSubview:cancel_];
	
    [NSThread
	 detachNewThreadSelector:@selector(_update)
	 toTarget:self
	 withObject:nil
	 ];
}

- (void) alertSheet:(UIActionSheet *)sheet buttonClicked:(int)button {
    NSString *context([sheet context]);
	
    if ([context isEqualToString:@"refresh"])
        [sheet dismiss];
}

- (void) _update_ {
    updating_ = false;
	
    [indicator_ stopAnimation];
	
    [UIView beginAnimations:nil context:NULL];
	
    CGRect ovrframe = [overlay_ frame];
    ovrframe.origin.y = -ovrframe.size.height;
    [overlay_ setFrame:ovrframe];
	
    CGRect barframe = [navbar_ frame];
    barframe.origin.y -= ovrframe.size.height;
    [navbar_ setFrame:barframe];
	
    CGRect trnframe = [transition_ frame];
    trnframe.origin.y -= ovrframe.size.height;
    trnframe.size.height += ovrframe.size.height;
    [transition_ setFrame:trnframe];
	
    [UIView commitAnimations];
	
    [delegate_ performSelector:@selector(reloadData) withObject:nil afterDelay:0];
}

- (id) initWithFrame:(CGRect)frame database:(Database *)database {
    if ((self = [super initWithFrame:frame]) != nil) {
        database_ = database;
		
        CGRect ovrrect([navbar_ bounds]);
        ovrrect.size.height = [UINavigationBar defaultSize].height;
        ovrrect.origin.y = -ovrrect.size.height;
		
        overlay_ = [[UINavigationBar alloc] initWithFrame:ovrrect];
        [self addSubview:overlay_];
		
        ovrrect.origin.y = frame.size.height;
        underlay_ = [[UINavigationBar alloc] initWithFrame:ovrrect];
        [underlay_ setTintColor:[UIColor colorWithRed:0.23 green:0.23 blue:0.23 alpha:1]];
        [self addSubview:underlay_];
		
        [overlay_ setBarStyle:1];
        [underlay_ setBarStyle:1];
		
        int barstyle([overlay_ _barStyle:NO]);
        bool ugly(barstyle == 0);
		
        UIProgressIndicatorStyle style = ugly ?
		UIProgressIndicatorStyleMediumBrown :
		UIProgressIndicatorStyleMediumWhite;
		
        CGSize indsize([UIProgressIndicator defaultSizeForStyle:style]);
        unsigned indoffset = (ovrrect.size.height - indsize.height) / 2;
        CGRect indrect = {{indoffset, indoffset}, indsize};
		
        indicator_ = [[UIProgressIndicator alloc] initWithFrame:indrect];
        [indicator_ setStyle:style];
        [overlay_ addSubview:indicator_];
		
        CGSize prmsize = {215, indsize.height + 4};
		
        CGRect prmrect = {{
            indoffset * 2 + indsize.width,
            unsigned(ovrrect.size.height - prmsize.height) / 2 - 1
        }, prmsize};
		
        UIFont *font([UIFont systemFontOfSize:15]);
		
        prompt_ = [[UITextLabel alloc] initWithFrame:prmrect];
		
        [prompt_ setColor:[UIColor colorWithCGColor:(ugly ? Blueish_ : Off_)]];
        [prompt_ setBackgroundColor:[UIColor clearColor]];
        [prompt_ setFont:font];
		
        [overlay_ addSubview:prompt_];
		
        CGSize prgsize = {75, 100};
		
        CGRect prgrect = {{
            ovrrect.size.width - prgsize.width - 10,
            (ovrrect.size.height - prgsize.height) / 2
        } , prgsize};
		
        progress_ = [[UIProgressBar alloc] initWithFrame:prgrect];
        [progress_ setStyle:0];
        [overlay_ addSubview:progress_];
		
        cancel_ = [[UINavigationButton alloc] initWithTitle:UCLocalize("CANCEL") style:UINavigationButtonStyleHighlighted];
        [cancel_ addTarget:self action:@selector(_onCancel) forControlEvents:UIControlEventTouchUpInside];
		
        CGRect frame = [cancel_ frame];
        frame.origin.x = ovrrect.size.width - frame.size.width - 5;
        frame.origin.y = (ovrrect.size.height - frame.size.height) / 2;
        [cancel_ setFrame:frame];
		
        [cancel_ setBarStyle:barstyle];
    } return self;
}

- (void) _onCancel {
    updating_ = false;
    [cancel_ removeFromSuperview];
}

- (void) _update { _pooled
    Status status;
    status.setDelegate(self);
    [database_ updateWithStatus:status];
	
    [self
	 performSelectorOnMainThread:@selector(_update_)
	 withObject:nil
	 waitUntilDone:NO
	 ];
}

- (void) setProgressError:(NSString *)error withTitle:(NSString *)title {
    [prompt_ setText:[NSString stringWithFormat:UCLocalize("COLON_DELIMITED"), UCLocalize("ERROR"), error]];
}

/*
 UIActionSheet *sheet = [[[UIActionSheet alloc]
 initWithTitle:[NSString stringWithFormat:UCLocalize("COLON_DELIMITED"), UCLocalize("ERROR"), UCLocalize("REFRESH")]
 buttons:[NSArray arrayWithObjects:
 UCLocalize("OK"),
 nil]
 defaultButtonIndex:0
 delegate:self
 context:@"refresh"
 ] autorelease];
 
 [sheet setBodyText:error];
 [sheet popupAlertAnimated:YES];
 
 [self reloadButtons];
 */

- (void) setProgressTitle:(NSString *)title {
    [self
	 performSelectorOnMainThread:@selector(_setProgressTitle:)
	 withObject:title
	 waitUntilDone:YES
	 ];
}

- (void) setProgressPercent:(float)percent {
    [self
	 performSelectorOnMainThread:@selector(_setProgressPercent:)
	 withObject:[NSNumber numberWithFloat:percent]
	 waitUntilDone:YES
	 ];
}

- (void) startProgress {
}

- (void) addProgressOutput:(NSString *)output {
    [self
	 performSelectorOnMainThread:@selector(_addProgressOutput:)
	 withObject:output
	 waitUntilDone:YES
	 ];
}

- (bool) isCancelling:(size_t)received {
    return !updating_;
}

- (void) _setProgressTitle:(NSString *)title {
    [prompt_ setText:title];
}

- (void) _setProgressPercent:(NSNumber *)percent {
    [progress_ setProgress:[percent floatValue]];
}

- (void) _addProgressOutput:(NSString *)output {
}

@end
/* }}} */
