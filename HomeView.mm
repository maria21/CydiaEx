#import "HomeView.h"

@implementation HomeView

- (void) alertSheet:(UIActionSheet *)sheet buttonClicked:(int)button {
    NSString *context([sheet context]);
	
    if ([context isEqualToString:@"about"])
        [sheet dismiss];
    else
        [super alertSheet:sheet buttonClicked:button];
}

- (void) _setMoreHeaders:(NSMutableURLRequest *)request {
    [super _setMoreHeaders:request];
    if (ChipID_ != nil)
        [request setValue:ChipID_ forHTTPHeaderField:@"X-Chip-ID"];
}

- (void) _leftButtonClicked {
    UIActionSheet *sheet = [[[UIActionSheet alloc]
							 initWithTitle:UCLocalize("ABOUT_CYDIA")
							 buttons:[NSArray arrayWithObjects:UCLocalize("CLOSE"), nil]
							 defaultButtonIndex:0
							 delegate:self
							 context:@"about"
							 ] autorelease];
	
    [sheet setBodyText:
	 @"Copyright (C) 2008-2009\n"
	 "Jay Freeman (saurik)\n"
	 "saurik@saurik.com\n"
	 "http://www.saurik.com/\n"
	 "\n"
	 "The Okori Group\n"
	 "http://www.theokorigroup.com/\n"
	 "\n"
	 "College of Creative Studies,\n"
	 "University of California,\n"
	 "Santa Barbara\n"
	 "http://www.ccs.ucsb.edu/"
	 ];
	
    [sheet popupAlertAnimated:YES];
}

- (NSString *) leftButtonTitle {
    return UCLocalize("ABOUT");
}

@end
/* }}} */
