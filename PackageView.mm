#import "PackageView.h"


@implementation PackageView

- (void) dealloc {
    if (package_ != nil)
        [package_ release];
    if (name_ != nil)
        [name_ release];
    [buttons_ release];
    [super dealloc];
}

- (void) release {
    if ([self retainCount] == 1)
        [delegate_ setPackageView:self];
    [super release];
}

/* XXX: this is not safe at all... localization of /fail/ */
- (void) _clickButtonWithName:(NSString *)name {
    if ([name isEqualToString:UCLocalize("CLEAR")])
        [delegate_ clearPackage:package_];
    else if ([name isEqualToString:UCLocalize("INSTALL")])
        [delegate_ installPackage:package_];
    else if ([name isEqualToString:UCLocalize("REINSTALL")])
        [delegate_ installPackage:package_];
    else if ([name isEqualToString:UCLocalize("REMOVE")])
        [delegate_ removePackage:package_];
    else if ([name isEqualToString:UCLocalize("UPGRADE")])
        [delegate_ installPackage:package_];
    else _assert(false);
}

- (void) alertSheet:(UIActionSheet *)sheet buttonClicked:(int)button {
    NSString *context([sheet context]);
	
    if ([context isEqualToString:@"modify"]) {
        int count = [buttons_ count];
        _assert(count != 0);
        _assert(button <= count + 1);
		
        if (count != button - 1)
            [self _clickButtonWithName:[buttons_ objectAtIndex:(button - 1)]];
		
        [sheet dismiss];
    } else
        [super alertSheet:sheet buttonClicked:button];
}

- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    return [super webView:sender didFinishLoadForFrame:frame];
}

- (void) webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)window forFrame:(WebFrame *)frame {
    [super webView:sender didClearWindowObject:window forFrame:frame];
    [window setValue:package_ forKey:@"package"];
}

- (bool) _allowJavaScriptPanel {
    return commercial_;
}

#if !AlwaysReload
- (void) __rightButtonClicked {
    int count([buttons_ count]);
    if (count == 0)
        return;
	
    if (count == 1)
        [self _clickButtonWithName:[buttons_ objectAtIndex:0]];
    else {
        NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:(count + 1)];
        [buttons addObjectsFromArray:buttons_];
        [buttons addObject:UCLocalize("CANCEL")];
		
        [delegate_ slideUp:[[[UIActionSheet alloc]
							 initWithTitle:nil
							 buttons:buttons
							 defaultButtonIndex:([buttons count] - 1)
							 delegate:self
							 context:@"modify"
							 ] autorelease]];
    }
}

- (void) _rightButtonClicked {
    if (commercial_)
        [super _rightButtonClicked];
    else
        [self __rightButtonClicked];
}
#endif

- (id) _rightButtonTitle {
    int count = [buttons_ count];
    return count == 0 ? nil : count != 1 ? UCLocalize("MODIFY") : [buttons_ objectAtIndex:0];
}

- (NSString *) backButtonTitle {
    return @"Details";
}

- (id) initWithBook:(RVBook *)book database:(Database *)database {
    if ((self = [super initWithBook:book]) != nil) {
        database_ = database;
        buttons_ = [[NSMutableArray alloc] initWithCapacity:4];
        [self loadURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"package" ofType:@"html"]]];
    } return self;
}

- (void) setPackage:(Package *)package {
    if (package_ != nil) {
        [package_ autorelease];
        package_ = nil;
    }
	
    if (name_ != nil) {
        [name_ release];
        name_ = nil;
    }
	
    [buttons_ removeAllObjects];
	
    if (package != nil) {
        [package parse];
		
        package_ = [package retain];
        name_ = [[package id] retain];
        commercial_ = [package isCommercial];
		
        if ([package_ mode] != nil)
            [buttons_ addObject:UCLocalize("CLEAR")];
        if ([package_ source] == nil);
        else if ([package_ upgradableAndEssential:NO])
            [buttons_ addObject:UCLocalize("UPGRADE")];
        else if ([package_ uninstalled])
            [buttons_ addObject:UCLocalize("INSTALL")];
        else
            [buttons_ addObject:UCLocalize("REINSTALL")];
        if (![package_ uninstalled])
            [buttons_ addObject:UCLocalize("REMOVE")];
		
        if (special_ != NULL) {
            CGRect frame([webview_ frame]);
            frame.size.width = 320;
            frame.size.height = 0;
            [webview_ setFrame:frame];
			
            [scroller_ scrollPointVisibleAtTopLeft:CGPointZero];
			
            WebThreadLock();
            [[[webview_ webView] windowScriptObject] setValue:package_ forKey:@"package"];
			
            [self setButtonTitle:nil withStyle:nil toFunction:nil];
			
            [self setFinishHook:nil];
            [self setPopupHook:nil];
            WebThreadUnlock();
			
            //[self yieldToSelector:@selector(callFunction:) withObject:special_];
            [super callFunction:special_];
        }
    }
	
    [self reloadButtons];
}

- (bool) isLoading {
    return commercial_ ? [super isLoading] : false;
}

- (void) reloadData {
    [self setPackage:[database_ packageWithName:name_]];
}

@end
/* }}} */