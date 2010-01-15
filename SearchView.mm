#import "SearchView.h"
#import "PackageTable.h"
#import "FilteredPackageTable.h"

@implementation SearchView

- (void) dealloc {
    [field_ setDelegate:nil];
	
    [accessory_ release];
    [field_ release];
    [table_ release];
    [dimmed_ release];
    [super dealloc];
}

- (void) _showKeyboard:(BOOL)show {
    CGSize keysize = [UIKeyboard defaultSize];
    CGRect keydown = [book_ pageBounds];
    CGRect keyup = keydown;
    keyup.size.height -= keysize.height - ButtonBarHeight_;
	
    float delay = KeyboardTime_ * ButtonBarHeight_ / keysize.height;
	
    UIFrameAnimation *animation = [[[UIFrameAnimation alloc] initWithTarget:[table_ list]] autorelease];
    [animation setSignificantRectFields:8];
	
    if (show) {
        [animation setStartFrame:keydown];
        [animation setEndFrame:keyup];
    } else {
        [animation setStartFrame:keyup];
        [animation setEndFrame:keydown];
    }
	
    UIAnimator *animator = [UIAnimator sharedAnimator];
	
    [animator
	 addAnimations:[NSArray arrayWithObjects:animation, nil]
	 withDuration:(KeyboardTime_ - delay)
	 start:!show
	 ];
	
    if (show)
        [animator performSelector:@selector(startAnimation:) withObject:animation afterDelay:delay];
	
    [delegate_ showKeyboard:show];
}

- (void) textFieldDidBecomeFirstResponder:(UITextField *)field {
    [self _showKeyboard:YES];
}

- (void) textFieldDidResignFirstResponder:(UITextField *)field {
    [self _showKeyboard:NO];
}

- (void) keyboardInputChanged:(UIFieldEditor *)editor {
    if (reload_) {
        NSString *text([field_ text]);
        [field_ setClearButtonStyle:(text == nil || [text length] == 0 ? 0 : 2)];
        [self reloadData];
        reload_ = false;
    }
}

- (void) textFieldClearButtonPressed:(UITextField *)field {
    reload_ = true;
}

- (void) keyboardInputShouldDelete:(id)input {
    reload_ = true;
}

- (BOOL) keyboardInput:(id)input shouldInsertText:(NSString *)text isMarkedText:(int)marked {
    if ([text length] != 1 || [text characterAtIndex:0] != '\n') {
        reload_ = true;
        return YES;
    } else {
        [field_ resignFirstResponder];
        return NO;
    }
}

- (id) initWithBook:(RVBook *)book database:(Database *)database {
    if ((self = [super initWithBook:book]) != nil) {
        CGRect pageBounds = [book_ pageBounds];
		
        dimmed_ = [[UIView alloc] initWithFrame:pageBounds];
        CGColor dimmed(space_, 0, 0, 0, 0.5);
        [dimmed_ setBackgroundColor:[UIColor colorWithCGColor:dimmed]];
		
        table_ = [[FilteredPackageTable alloc]
				  initWithBook:book
				  database:database
				  title:nil
				  filter:@selector(isUnfilteredAndSearchedForBy:)
				  with:nil
				  ];
		
        [table_ setShouldHideHeaderInShortLists:NO];
        [self addSubview:table_];
		
        CGRect cnfrect = {{7, 38}, {17, 18}};
		
        CGRect area;
		
        area.origin.x = 10;
        area.origin.y = 1;
		
        area.size.width = [self bounds].size.width - area.origin.x * 2;
        area.size.height = [UISearchField defaultHeight];
		
        field_ = [[UISearchField alloc] initWithFrame:area];
		
        UIFont *font = [UIFont systemFontOfSize:16];
        [field_ setFont:font];
		
        [field_ setPlaceholder:UCLocalize("SEARCH_EX")];
        [field_ setDelegate:self];
		
        [field_ setPaddingTop:5];
		
        UITextInputTraits *traits([field_ textInputTraits]);
        [traits setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [traits setAutocorrectionType:UITextAutocorrectionTypeNo];
        [traits setReturnKeyType:UIReturnKeySearch];
		
        CGRect accrect = {{0, 6}, {6 + cnfrect.size.width + 6 + area.size.width + 6, area.size.height}};
		
        accessory_ = [[UIView alloc] initWithFrame:accrect];
        [accessory_ addSubview:field_];
		
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [table_ setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    } return self;
}

- (void) resetViewAnimated:(BOOL)animated {
    [table_ resetViewAnimated:animated];
}

- (void) _reloadData {
}

- (void) reloadData {
    [table_ setObject:[field_ text]];
    _profile(SearchView$reloadData)
	[table_ reloadData];
    _end
    PrintTimes();
    [table_ resetCursor];
}

- (UIView *) accessoryView {
    return accessory_;
}

- (NSString *) title {
    return nil;
}

- (NSString *) backButtonTitle {
    return UCLocalize("SEARCH");
}

- (void) setDelegate:(id)delegate {
    [table_ setDelegate:delegate];
    [super setDelegate:delegate];
}

@end
/* }}} */
