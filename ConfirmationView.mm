#import "ConfirmationView.h"

@implementation ConfirmationView

- (void) dealloc {
    [changes_ release];
    if (issues_ != nil)
        [issues_ release];
    [sizes_ release];
    if (essential_ != nil)
        [essential_ release];
    [super dealloc];
}

- (void) cancel {
    [delegate_ cancel];
    [book_ popFromSuperviewAnimated:YES];
}

- (void) alertSheet:(UIActionSheet *)sheet buttonClicked:(int)button {
    NSString *context([sheet context]);
	
    if ([context isEqualToString:@"remove"]) {
        switch (button) {
            case 1:
                [self cancel];
                break;
            case 2:
                if (substrate_)
                    Finish_ = 2;
                [delegate_ confirm];
                break;
				_nodefault
        }
		
        [sheet dismiss];
    } else if ([context isEqualToString:@"unable"]) {
        [self cancel];
        [sheet dismiss];
    } else
        [super alertSheet:sheet buttonClicked:button];
}

- (void) webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)window forFrame:(WebFrame *)frame {
    [super webView:sender didClearWindowObject:window forFrame:frame];
    [window setValue:changes_ forKey:@"changes"];
    [window setValue:issues_ forKey:@"issues"];
    [window setValue:sizes_ forKey:@"sizes"];
}

- (id) initWithBook:(RVBook *)book database:(Database *)database {
    if ((self = [super initWithBook:book]) != nil) {
        database_ = database;
		
        NSMutableArray *installing = [NSMutableArray arrayWithCapacity:16];
        NSMutableArray *reinstalling = [NSMutableArray arrayWithCapacity:16];
        NSMutableArray *upgrading = [NSMutableArray arrayWithCapacity:16];
        NSMutableArray *downgrading = [NSMutableArray arrayWithCapacity:16];
        NSMutableArray *removing = [NSMutableArray arrayWithCapacity:16];
		
        bool remove(false);
		
        pkgDepCache::Policy *policy([database_ policy]);
		
        pkgCacheFile &cache([database_ cache]);
        NSArray *packages = [database_ packages];
        for (Package *package in packages) {
            pkgCache::PkgIterator iterator = [package iterator];
            pkgDepCache::StateCache &state(cache[iterator]);
			
            NSString *name([package name]);
			
            if (state.NewInstall())
                [installing addObject:name];
            else if (!state.Delete() && (state.iFlags & pkgDepCache::ReInstall) == pkgDepCache::ReInstall)
                [reinstalling addObject:name];
            else if (state.Upgrade())
                [upgrading addObject:name];
            else if (state.Downgrade())
                [downgrading addObject:name];
            else if (state.Delete()) {
                if ([package essential])
                    remove = true;
                [removing addObject:name];
            } else continue;
			
            substrate_ |= DepSubstrate(policy->GetCandidateVer(iterator));
            substrate_ |= DepSubstrate(iterator.CurrentVer());
        }
		
        if (!remove)
            essential_ = nil;
        else if (Advanced_) {
            NSString *parenthetical(UCLocalize("PARENTHETICAL"));
			
            essential_ = [[UIActionSheet alloc]
						  initWithTitle:UCLocalize("REMOVING_ESSENTIALS")
						  buttons:[NSArray arrayWithObjects:
								   [NSString stringWithFormat:parenthetical, UCLocalize("CANCEL_OPERATION"), UCLocalize("SAFE")],
								   [NSString stringWithFormat:parenthetical, UCLocalize("FORCE_REMOVAL"), UCLocalize("UNSAFE")],
								   nil]
						  defaultButtonIndex:0
						  delegate:self
						  context:@"remove"
						  ];
			
            [essential_ setDestructiveButtonIndex:1];
            [essential_ setBodyText:UCLocalize("REMOVING_ESSENTIALS_EX")];
        } else {
            essential_ = [[UIActionSheet alloc]
						  initWithTitle:UCLocalize("UNABLE_TO_COMPLY")
						  buttons:[NSArray arrayWithObjects:UCLocalize("OKAY"), nil]
						  defaultButtonIndex:0
						  delegate:self
						  context:@"unable"
						  ];
			
            [essential_ setBodyText:UCLocalize("UNABLE_TO_COMPLY_EX")];
        }
		
        changes_ = [[NSArray alloc] initWithObjects:
					installing,
					reinstalling,
					upgrading,
					downgrading,
					removing,
					nil];
		
        issues_ = [database_ issues];
        if (issues_ != nil)
            issues_ = [issues_ retain];
		
        sizes_ = [[NSArray alloc] initWithObjects:
				  SizeString([database_ fetcher].FetchNeeded()),
				  SizeString([database_ fetcher].PartialPresent()),
				  SizeString([database_ cache]->UsrSize()),
				  nil];
		
        [self loadURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"confirm" ofType:@"html"]]];
    } return self;
}

- (NSString *) backButtonTitle {
    return UCLocalize("CONFIRM");
}

- (NSString *) leftButtonTitle {
    return [NSString stringWithFormat:UCLocalize("SLASH_DELIMITED"), UCLocalize("CANCEL"), UCLocalize("QUEUE")];
}

- (id) rightButtonTitle {
    return issues_ != nil ? nil : [super rightButtonTitle];
}

- (id) _rightButtonTitle {
#if AlwaysReload || IgnoreInstall
    return [super _rightButtonTitle];
#else
    return UCLocalize("CONFIRM");
#endif
}

- (void) _leftButtonClicked {
    [self cancel];
}

#if !AlwaysReload
- (void) _rightButtonClicked {
#if IgnoreInstall
    return [super _rightButtonClicked];
#endif
    if (essential_ != nil)
        [essential_ popupAlertAnimated:YES];
    else {
        if (substrate_)
            Finish_ = 2;
        [delegate_ confirm];
    }
}
#endif

@end
/* }}} */

