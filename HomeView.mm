#import "HomeView.h"

@implementation HomeView

- (void) _setMoreHeaders:(NSMutableURLRequest *)request {
    [super _setMoreHeaders:request];
    if (ChipID_ != nil)
        [request setValue:ChipID_ forHTTPHeaderField:@"X-Chip-ID"];
}

- (void) _leftButtonClicked {
    UIAlertView *alert = [[[UIAlertView alloc] init] autorelease];
	[alert setTitle:UCLocalize("ABOUT_CYDIA")];
	[alert addButtonWithTitle:UCLocalize("CLOSE")];
	[alert setCancelButtonIndex:0];
    [alert setMessage:
	 @"Copyright \u00A9 2008-2010\n"
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
	
    [alert show];
}

- (NSString *) leftButtonTitle {
    return UCLocalize("ABOUT");
}

@end
/* }}} */
