#import "Cydia.h"

#import "SettingsView.h"
#import "ConfirmationView.h"
#import "SignatureView.h"
#import "ProgressView.h"

#import "SectionsView.h"
#import "PackageView.h"
#import "ChangesView.h"
#import "ManageView.h"
#import "SearchView.h"

#import "SourceTable.h"
#import "FileTable.h"
#import "InstalledView.h"
#import "AddSourceView.h"


@implementation Cydia

- (void) _loaded {
    if ([broken_ count] != 0) {
        int count = [broken_ count];
		
        UIActionSheet *sheet = [[[UIActionSheet alloc]
								 initWithTitle:(count == 1 ? UCLocalize("HALFINSTALLED_PACKAGE") : [NSString stringWithFormat:UCLocalize("HALFINSTALLED_PACKAGES"), count])
								 buttons:[NSArray arrayWithObjects:
										  UCLocalize("FORCIBLY_CLEAR"),
										  UCLocalize("TEMPORARY_IGNORE"),
										  nil]
								 defaultButtonIndex:0
								 delegate:self
								 context:@"fixhalf"
								 ] autorelease];
		
        [sheet setBodyText:UCLocalize("HALFINSTALLED_PACKAGE_EX")];
        [sheet popupAlertAnimated:YES];
    } else if (!Ignored_ && [essential_ count] != 0) {
        int count = [essential_ count];
		
        UIActionSheet *sheet = [[[UIActionSheet alloc]
								 initWithTitle:(count == 1 ? UCLocalize("ESSENTIAL_UPGRADE") : [NSString stringWithFormat:UCLocalize("ESSENTIAL_UPGRADES"), count])
								 buttons:[NSArray arrayWithObjects:
										  UCLocalize("UPGRADE_ESSENTIAL"),
										  UCLocalize("COMPLETE_UPGRADE"),
										  UCLocalize("TEMPORARY_IGNORE"),
										  nil]
								 defaultButtonIndex:0
								 delegate:self
								 context:@"upgrade"
								 ] autorelease];
		
        [sheet setBodyText:UCLocalize("ESSENTIAL_UPGRADE_EX")];
        [sheet popupAlertAnimated:YES];
    }
}

- (void) _saveConfig {
    if (Changed_) {
        _trace();
        NSString *error(nil);
        if (NSData *data = [NSPropertyListSerialization dataFromPropertyList:Metadata_ format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error]) {
            _trace();
            NSError *error(nil);
            if (![data writeToFile:@"/var/lib/cydia/metadata.plist" options:NSAtomicWrite error:&error])
                NSLog(@"failure to save metadata data: %@", error);
            _trace();
        } else {
            NSLog(@"failure to serialize metadata: %@", error);
            return;
        }
		
        Changed_ = false;
    }
}

- (void) _updateData {
    [self _saveConfig];
	
    /* XXX: this is just stupid */
    if (tag_ != 2 && sections_ != nil)
        [sections_ reloadData];
    if (tag_ != 3 && changes_ != nil)
        [changes_ reloadData];
    if (tag_ != 5 && search_ != nil)
        [search_ reloadData];
	
    [book_ reloadData];
}

- (void) _reloadData {
    UIView *block();
	
    static bool loaded(false);
    UIProgressHUD *hud([self addProgressHUD]);
    [hud setText:(loaded ? UCLocalize("RELOADING_DATA") : UCLocalize("LOADING_DATA"))];
	
    [database_ yieldToSelector:@selector(reloadData) withObject:nil];
    _trace();
	
    [self removeProgressHUD:hud];
	
    size_t changes(0);
	
    [essential_ removeAllObjects];
    [broken_ removeAllObjects];
	
    NSArray *packages([database_ packages]);
    for (Package *package in packages) {
        if ([package half])
            [broken_ addObject:package];
        if ([package upgradableAndEssential:NO]) {
            if ([package essential])
                [essential_ addObject:package];
            ++changes;
        }
    }
	
    if (changes != 0) {
        NSString *badge([[NSNumber numberWithInt:changes] stringValue]);
        [toolbar_ setBadgeValue:badge forButton:3];
        if ([toolbar_ respondsToSelector:@selector(setBadgeAnimated:forButton:)])
            [toolbar_ setBadgeAnimated:([essential_ count] != 0) forButton:3];
        if ([self respondsToSelector:@selector(setApplicationBadge:)])
            [self setApplicationBadge:badge];
        else
            [self setApplicationBadgeString:badge];
    } else {
        [toolbar_ setBadgeValue:nil forButton:3];
        if ([toolbar_ respondsToSelector:@selector(setBadgeAnimated:forButton:)])
            [toolbar_ setBadgeAnimated:NO forButton:3];
        if ([self respondsToSelector:@selector(removeApplicationBadge)])
            [self removeApplicationBadge];
        else // XXX: maybe use setApplicationBadgeString also?
            [self setApplicationIconBadgeNumber:0];
    }
	
    Queuing_ = false;
    [toolbar_ setBadgeValue:nil forButton:4];
	
    [self _updateData];
	
    if (loaded || ManualRefresh) loaded:
        [self _loaded];
    else {
        loaded = true;
		
        if (NSDate *update = [Metadata_ objectForKey:@"LastUpdate"]) {
            NSTimeInterval interval([update timeIntervalSinceNow]);
            if (interval <= 0 && interval > -(15*60))
                goto loaded;
        }
		
        [book_ update];
    }
}

- (void) updateData {
    [database_ setVisible];
    [self _updateData];
}

- (void) update_ {
    [database_ update];
}

- (void) syncData {
    FILE *file(fopen("/etc/apt/sources.list.d/cydia.list", "w"));
    _assert(file != NULL);
	
    for (NSString *key in [Sources_ allKeys]) {
        NSDictionary *source([Sources_ objectForKey:key]);
		
        fprintf(file, "%s %s %s\n",
				[[source objectForKey:@"Type"] UTF8String],
				[[source objectForKey:@"URI"] UTF8String],
				[[source objectForKey:@"Distribution"] UTF8String]
				);
    }
	
    fclose(file);
	
    [self _saveConfig];
	
    [progress_
	 detachNewThreadSelector:@selector(update_)
	 toTarget:self
	 withObject:nil
	 title:UCLocalize("UPDATING_SOURCES")
	 ];
}

- (void) reloadData {
    @synchronized (self) {
        if (confirm_ == nil)
            [self _reloadData];
    }
}

- (void) resolve {
    pkgProblemResolver *resolver = [database_ resolver];
	
    resolver->InstallProtect();
    if (!resolver->Resolve(true))
        _error->Discard();
}

- (void) popUpBook:(RVBook *)book {
    [underlay_ popSubview:book];
}

- (CGRect) popUpBounds {
    return [underlay_ bounds];
}

- (bool) perform {
    if (![database_ prepare])
        return false;
	
    confirm_ = [[RVBook alloc] initWithFrame:[self popUpBounds]];
    [confirm_ setDelegate:self];
	
    ConfirmationView *page([[[ConfirmationView alloc] initWithBook:confirm_ database:database_] autorelease]);
    [page setDelegate:self];
	
    [confirm_ setPage:page];
    [self popUpBook:confirm_];
	
    return true;
}

- (void) queue {
    @synchronized (self) {
        [self perform];
    }
}

- (void) clearPackage:(Package *)package {
    @synchronized (self) {
        [package clear];
        [self resolve];
        [self perform];
    }
}

- (void) installPackage:(Package *)package {
    @synchronized (self) {
        [package install];
        [self resolve];
        [self perform];
    }
}

- (void) removePackage:(Package *)package {
    @synchronized (self) {
        [package remove];
        [self resolve];
        [self perform];
    }
}

- (void) distUpgrade {
    @synchronized (self) {
        if (![database_ upgrade])
            return;
        [self perform];
    }
}

- (void) cancel {
    [self slideUp:[[[UIActionSheet alloc]
					initWithTitle:nil
					buttons:[NSArray arrayWithObjects:UCLocalize("CONTINUE_QUEUING"), UCLocalize("CANCEL_CLEAR"), nil]
					defaultButtonIndex:1
					delegate:self
					context:@"cancel"
					] autorelease]];
}

- (void) complete {
    @synchronized (self) {
        [self _reloadData];
		
        if (confirm_ != nil) {
            [confirm_ release];
            confirm_ = nil;
        }
    }
}

- (void) confirm {
    [overlay_ removeFromSuperview];
    reload_ = true;
	
    [progress_
	 detachNewThreadSelector:@selector(perform)
	 toTarget:database_
	 withObject:nil
	 title:UCLocalize("RUNNING")
	 ];
}

- (void) progressViewIsComplete:(ProgressView *)progress {
    if (confirm_ != nil) {
        [underlay_ addSubview:overlay_];
        [confirm_ popFromSuperviewAnimated:NO];
    }
	
    [self complete];
}

- (void) setPage:(RVPage *)page {
    [page resetViewAnimated:NO];
    [page setDelegate:self];
    [book_ setPage:page];
}

- (RVPage *) _pageForURL:(NSURL *)url withClass:(Class)_class {
    CydiaBrowserView *browser = [[[_class alloc] initWithBook:book_] autorelease];
    [browser loadURL:url];
    return browser;
}

- (SectionsView *) sectionsView {
    if (sections_ == nil)
        sections_ = [[SectionsView alloc] initWithBook:book_ database:database_];
    return sections_;
}

- (void) buttonBarItemTapped:(id)sender {
    unsigned tag = [sender tag];
    if (tag == tag_) {
        [book_ resetViewAnimated:YES];
        return;
    } else if (tag_ == 2)
        [[self sectionsView] resetView];
	
    switch (tag) {
        case 1: _setHomePage(self); break;
			
        case 2: [self setPage:[self sectionsView]]; break;
        case 3: [self setPage:changes_]; break;
        case 4: [self setPage:manage_]; break;
        case 5: [self setPage:search_]; break;
			
			_nodefault
    }
	
    tag_ = tag;
}

- (void) askForSettings {
    NSString *parenthetical(UCLocalize("PARENTHETICAL"));
	
    CYActionSheet *role([[[CYActionSheet alloc]
						  initWithTitle:UCLocalize("WHO_ARE_YOU")
						  buttons:[NSArray arrayWithObjects:
								   [NSString stringWithFormat:parenthetical, UCLocalize("USER"), UCLocalize("USER_EX")],
								   [NSString stringWithFormat:parenthetical, UCLocalize("HACKER"), UCLocalize("HACKER_EX")],
								   [NSString stringWithFormat:parenthetical, UCLocalize("DEVELOPER"), UCLocalize("DEVELOPER_EX")],
								   nil]
						  defaultButtonIndex:-1
						  ] autorelease]);
	
    [role setBodyText:UCLocalize("ROLE_EX")];
	
    int button([role yieldToPopupAlertAnimated:YES]);
	
    switch (button) {
        case 1: Role_ = @"User"; break;
        case 2: Role_ = @"Hacker"; break;
        case 3: Role_ = @"Developer"; break;
			
			_nodefault
    }
	
    Settings_ = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				 Role_, @"Role",
				 nil];
	
    [Metadata_ setObject:Settings_ forKey:@"Settings"];
	
    Changed_ = true;
	
    [role dismiss];
}

- (void) setPackageView:(PackageView *)view {
    WebThreadLock();
    [view setPackage:nil];
#if RecyclePackageViews
    if ([details_ count] < 3)
        [details_ addObject:view];
#endif
    WebThreadUnlock();
}

- (PackageView *) _packageView {
    return [[[PackageView alloc] initWithBook:book_ database:database_] autorelease];
}

- (PackageView *) packageView {
#if RecyclePackageViews
    PackageView *view;
    size_t count([details_ count]);
	
    if (count == 0) {
        view = [self _packageView];
	renew:
        [details_ addObject:[self _packageView]];
    } else {
        view = [[[details_ lastObject] retain] autorelease];
        [details_ removeLastObject];
        if (count == 1)
            goto renew;
    }
	
    return view;
#else
    return [self _packageView];
#endif
}

- (void) alertSheet:(UIActionSheet *)sheet buttonClicked:(int)button {
    NSString *context([sheet context]);
	
    if ([context isEqualToString:@"missing"])
        [sheet dismiss];
    else if ([context isEqualToString:@"cancel"]) {
        bool clear;
		
        switch (button) {
            case 1:
                clear = false;
				break;
				
            case 2:
                clear = true;
				break;
				
				_nodefault
        }
		
        [sheet dismiss];
		
        @synchronized (self) {
            if (clear)
                [self _reloadData];
            else {
                Queuing_ = true;
                [toolbar_ setBadgeValue:UCLocalize("Q_D") forButton:4];
                [book_ reloadData];
            }
			
            if (confirm_ != nil) {
                [confirm_ release];
                confirm_ = nil;
            }
        }
    } else if ([context isEqualToString:@"fixhalf"]) {
        switch (button) {
            case 1:
                @synchronized (self) {
                    for (Package *broken in broken_) {
                        [broken remove];
						
                        NSString *id = [broken id];
                        unlink([[NSString stringWithFormat:@"/var/lib/dpkg/info/%@.prerm", id] UTF8String]);
                        unlink([[NSString stringWithFormat:@"/var/lib/dpkg/info/%@.postrm", id] UTF8String]);
                        unlink([[NSString stringWithFormat:@"/var/lib/dpkg/info/%@.preinst", id] UTF8String]);
                        unlink([[NSString stringWithFormat:@"/var/lib/dpkg/info/%@.postinst", id] UTF8String]);
                    }
					
                    [self resolve];
                    [self perform];
                }
				break;
				
            case 2:
                [broken_ removeAllObjects];
                [self _loaded];
				break;
				
				_nodefault
        }
		
        [sheet dismiss];
    } else if ([context isEqualToString:@"upgrade"]) {
        switch (button) {
            case 1:
                @synchronized (self) {
                    for (Package *essential in essential_)
                        [essential install];
					
                    [self resolve];
                    [self perform];
                }
				break;
				
            case 2:
                [self distUpgrade];
				break;
				
            case 3:
                Ignored_ = YES;
				break;
				
				_nodefault
        }
		
        [sheet dismiss];
    }
}

- (void) system:(NSString *)command { _pooled
    system([command UTF8String]);
}

- (void) applicationWillSuspend {
    [database_ clean];
    [super applicationWillSuspend];
}

- (void) applicationSuspend:(__GSEvent *)event {
    if (hud_ == nil && ![progress_ isRunning])
        [super applicationSuspend:event];
}

- (void) _animateSuspension:(BOOL)arg0 duration:(double)arg1 startTime:(double)arg2 scale:(float)arg3 {
    if (hud_ == nil)
        [super _animateSuspension:arg0 duration:arg1 startTime:arg2 scale:arg3];
}

- (void) _setSuspended:(BOOL)value {
    if (hud_ == nil)
        [super _setSuspended:value];
}

- (UIProgressHUD *) addProgressHUD {
    UIProgressHUD *hud([[[UIProgressHUD alloc] initWithWindow:window_] autorelease]);
    [window_ setUserInteractionEnabled:NO];
    [hud show:YES];
    [progress_ addSubview:hud];
    return hud;
}

- (void) removeProgressHUD:(UIProgressHUD *)hud {
    [hud show:NO];
    [hud removeFromSuperview];
    [window_ setUserInteractionEnabled:YES];
}

- (RVPage *) pageForPackage:(NSString *)name {
    if (Package *package = [database_ packageWithName:name]) {
        PackageView *view([self packageView]);
        [view setPackage:package];
        return view;
    } else {
        NSURL *url([NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"unknown" ofType:@"html"]]);
        url = [NSURL URLWithString:[[url absoluteString] stringByAppendingString:[NSString stringWithFormat:@"?%@", name]]];
        return [self _pageForURL:url withClass:[CydiaBrowserView class]];
    }
}

- (RVPage *) pageForURL:(NSURL *)url hasTag:(int *)tag {
    if (tag != NULL)
        tag = 0;
	
    NSString *href([url absoluteString]);
    if ([href hasPrefix:@"apptapp://package/"])
        return [self pageForPackage:[href substringFromIndex:18]];
	
    NSString *scheme([[url scheme] lowercaseString]);
    if (![scheme isEqualToString:@"cydia"])
        return nil;
    NSString *path([url absoluteString]);
    if ([path length] < 8)
        return nil;
    path = [path substringFromIndex:8];
    if (![path hasPrefix:@"/"])
        path = [@"/" stringByAppendingString:path];
	
    if ([path isEqualToString:@"/add-source"])
        return [[[AddSourceView alloc] initWithBook:book_ database:database_] autorelease];
    else if ([path isEqualToString:@"/storage"])
        return [self _pageForURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"storage" ofType:@"html"]] withClass:[CydiaBrowserView class]];
    else if ([path isEqualToString:@"/sources"])
        return [[[SourceTable alloc] initWithBook:book_ database:database_] autorelease];
    else if ([path isEqualToString:@"/packages"])
        return [[[InstalledView alloc] initWithBook:book_ database:database_] autorelease];
    else if ([path hasPrefix:@"/url/"])
        return [self _pageForURL:[NSURL URLWithString:[path substringFromIndex:5]] withClass:[CydiaBrowserView class]];
    else if ([path hasPrefix:@"/launch/"])
        [self launchApplicationWithIdentifier:[path substringFromIndex:8] suspended:NO];
    else if ([path hasPrefix:@"/package-settings/"])
        return [[[SettingsView alloc] initWithBook:book_ database:database_ package:[path substringFromIndex:18]] autorelease];
    else if ([path hasPrefix:@"/package-signature/"])
        return [[[SignatureView alloc] initWithBook:book_ database:database_ package:[path substringFromIndex:19]] autorelease];
    else if ([path hasPrefix:@"/package/"])
        return [self pageForPackage:[path substringFromIndex:9]];
    else if ([path hasPrefix:@"/files/"]) {
        NSString *name = [path substringFromIndex:7];
		
        if (Package *package = [database_ packageWithName:name]) {
            FileTable *files = [[[FileTable alloc] initWithBook:book_ database:database_] autorelease];
            [files setPackage:package];
            return files;
        }
    }
	
    return nil;
}

- (void) applicationOpenURL:(NSURL *)url {
    [super applicationOpenURL:url];
    int tag;
    if (RVPage *page = [self pageForURL:url hasTag:&tag]) {
        [self setPage:page];
        [toolbar_ showSelectionForButton:tag];
        tag_ = tag;
    }
}

- (void) applicationDidFinishLaunching:(id)unused {
    [BrowserView _initialize];
	
    [NSURLProtocol registerClass:[CydiaURLProtocol class]];
	
    Font12_ = [[UIFont systemFontOfSize:12] retain];
    Font12Bold_ = [[UIFont boldSystemFontOfSize:12] retain];
    Font14_ = [[UIFont systemFontOfSize:14] retain];
    Font18Bold_ = [[UIFont boldSystemFontOfSize:18] retain];
    Font22Bold_ = [[UIFont boldSystemFontOfSize:22] retain];
	
    tag_ = 1;
	
    essential_ = [[NSMutableArray alloc] initWithCapacity:4];
    broken_ = [[NSMutableArray alloc] initWithCapacity:4];
	
    window_ = [[UIWindow alloc] initWithContentRect:[UIHardware fullScreenApplicationContentRect]];
    [window_ orderFront:self];
    [window_ makeKey:self];
    [window_ setHidden:NO];
	
    database_ = [Database sharedInstance];
	
    progress_ = [[ProgressView alloc] initWithFrame:[window_ bounds] database:database_ delegate:self];
    [database_ setDelegate:progress_];
    [window_ setContentView:progress_];
	
    underlay_ = [[UIView alloc] initWithFrame:[progress_ bounds]];
    [progress_ setContentView:underlay_];
	
    [progress_ resetView];
	
    if (
        readlink("/Applications", NULL, 0) == -1 && errno == EINVAL ||
        readlink("/Library/Ringtones", NULL, 0) == -1 && errno == EINVAL ||
        readlink("/Library/Wallpaper", NULL, 0) == -1 && errno == EINVAL ||
        //readlink("/usr/bin", NULL, 0) == -1 && errno == EINVAL ||
        readlink("/usr/include", NULL, 0) == -1 && errno == EINVAL ||
        readlink("/usr/lib/pam", NULL, 0) == -1 && errno == EINVAL ||
        readlink("/usr/libexec", NULL, 0) == -1 && errno == EINVAL ||
        readlink("/usr/share", NULL, 0) == -1 && errno == EINVAL ||
        //readlink("/var/lib", NULL, 0) == -1 && errno == EINVAL ||
        false
		) {
        [self setIdleTimerDisabled:YES];
		
        hud_ = [self addProgressHUD];
        [hud_ setText:@"Reorganizing\n\nWill Automatically\nClose When Done"];
        [self setStatusBarShowsProgress:YES];
		
        [self yieldToSelector:@selector(system:) withObject:@"/usr/libexec/cydia/free.sh"];
		
        [self setStatusBarShowsProgress:NO];
        [self removeProgressHUD:hud_];
        hud_ = nil;
		
        if (ExecFork() == 0) {
            execlp("launchctl", "launchctl", "stop", "com.apple.SpringBoard", NULL);
            perror("launchctl stop");
        }
		
        return;
    }
	
    if (Role_ == nil)
        [self askForSettings];
	
    _trace();
    overlay_ = [[UIView alloc] initWithFrame:[underlay_ bounds]];
	
    CGRect screenrect = [UIHardware fullScreenApplicationContentRect];
    book_ = [[CYBook alloc] initWithFrame:CGRectMake(
													 0, 0, screenrect.size.width, screenrect.size.height - 48
													 ) database:database_];
	
    [book_ setDelegate:self];
	
    [overlay_ addSubview:book_];
	
    NSArray *buttonitems = [NSArray arrayWithObjects:
							[NSDictionary dictionaryWithObjectsAndKeys:
							 @"buttonBarItemTapped:", kUIButtonBarButtonAction,
							 @"home-up.png", kUIButtonBarButtonInfo,
							 @"home-dn.png", kUIButtonBarButtonSelectedInfo,
							 [NSNumber numberWithInt:1], kUIButtonBarButtonTag,
							 self, kUIButtonBarButtonTarget,
							 @"Cydia", kUIButtonBarButtonTitle,
							 @"0", kUIButtonBarButtonType,
							 nil],
							
							[NSDictionary dictionaryWithObjectsAndKeys:
							 @"buttonBarItemTapped:", kUIButtonBarButtonAction,
							 @"install-up.png", kUIButtonBarButtonInfo,
							 @"install-dn.png", kUIButtonBarButtonSelectedInfo,
							 [NSNumber numberWithInt:2], kUIButtonBarButtonTag,
							 self, kUIButtonBarButtonTarget,
							 UCLocalize("SECTIONS"), kUIButtonBarButtonTitle,
							 @"0", kUIButtonBarButtonType,
							 nil],
							
							[NSDictionary dictionaryWithObjectsAndKeys:
							 @"buttonBarItemTapped:", kUIButtonBarButtonAction,
							 @"changes-up.png", kUIButtonBarButtonInfo,
							 @"changes-dn.png", kUIButtonBarButtonSelectedInfo,
							 [NSNumber numberWithInt:3], kUIButtonBarButtonTag,
							 self, kUIButtonBarButtonTarget,
							 UCLocalize("CHANGES"), kUIButtonBarButtonTitle,
							 @"0", kUIButtonBarButtonType,
							 nil],
							
							[NSDictionary dictionaryWithObjectsAndKeys:
							 @"buttonBarItemTapped:", kUIButtonBarButtonAction,
							 @"manage-up.png", kUIButtonBarButtonInfo,
							 @"manage-dn.png", kUIButtonBarButtonSelectedInfo,
							 [NSNumber numberWithInt:4], kUIButtonBarButtonTag,
							 self, kUIButtonBarButtonTarget,
							 UCLocalize("MANAGE"), kUIButtonBarButtonTitle,
							 @"0", kUIButtonBarButtonType,
							 nil],
							
							[NSDictionary dictionaryWithObjectsAndKeys:
							 @"buttonBarItemTapped:", kUIButtonBarButtonAction,
							 @"search-up.png", kUIButtonBarButtonInfo,
							 @"search-dn.png", kUIButtonBarButtonSelectedInfo,
							 [NSNumber numberWithInt:5], kUIButtonBarButtonTag,
							 self, kUIButtonBarButtonTarget,
							 UCLocalize("SEARCH"), kUIButtonBarButtonTitle,
							 @"0", kUIButtonBarButtonType,
							 nil],
							nil];
	
    toolbar_ = [[UIToolbar alloc]
				initInView:overlay_
				withFrame:CGRectMake(
									 0, screenrect.size.height - ButtonBarHeight_,
									 screenrect.size.width, ButtonBarHeight_
									 )
				withItemList:buttonitems
				];
	
    [toolbar_ setDelegate:self];
    [toolbar_ setBarStyle:1];
    [toolbar_ setButtonBarTrackingMode:2];
	
    int buttons[5] = {1, 2, 3, 4, 5};
    [toolbar_ registerButtonGroup:0 withButtons:buttons withCount:5];
    [toolbar_ showButtonGroup:0 withDuration:0];
	
    for (int i = 0; i != 5; ++i)
        [[toolbar_ viewWithTag:(i + 1)] setFrame:CGRectMake(
															i * 64 + 2, 1, 60, ButtonBarHeight_
															)];
	
    [toolbar_ showSelectionForButton:1];
    [overlay_ addSubview:toolbar_];
	
    [UIKeyboard initImplementationNow];
    CGSize keysize = [UIKeyboard defaultSize];
    CGRect keyrect = {{0, [overlay_ bounds].size.height}, keysize};
    keyboard_ = [[UIKeyboard alloc] initWithFrame:keyrect];
    [overlay_ addSubview:keyboard_];
	
    [underlay_ addSubview:overlay_];
	
    [self reloadData];
	
    [self sectionsView];
    changes_ = [[ChangesView alloc] initWithBook:book_ database:database_];
    search_ = [[SearchView alloc] initWithBook:book_ database:database_];
	
    manage_ = (ManageView *) [[self
							   _pageForURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"manage" ofType:@"html"]]
							   withClass:[ManageView class]
							   ] retain];
	
#if RecyclePackageViews
    details_ = [[NSMutableArray alloc] initWithCapacity:4];
    [details_ addObject:[self _packageView]];
    [details_ addObject:[self _packageView]];
#endif
	
    PrintTimes();
	
    _setHomePage(self);
}

- (void) applicationWillTerminate:(UIApplication *)application {
    switch (Finish_) {
        case 2:
            system("launchctl stop com.apple.SpringBoard");
			break;
			
        case 3:
            system("launchctl unload "SpringBoard_"; launchctl load "SpringBoard_);
			break;
			
        case 4:
            system("reboot");
			break;
    }	
}

- (void) showKeyboard:(BOOL)show {
    CGSize keysize([UIKeyboard defaultSize]);
    CGRect keydown = {{0, [overlay_ bounds].size.height}, keysize};
    CGRect keyup(keydown);
    keyup.origin.y -= keysize.height;
	
    UIFrameAnimation *animation([[[UIFrameAnimation alloc] initWithTarget:keyboard_] autorelease]);
    [animation setSignificantRectFields:2];
	
    if (show) {
        [animation setStartFrame:keydown];
        [animation setEndFrame:keyup];
        [keyboard_ activate];
    } else {
        [animation setStartFrame:keyup];
        [animation setEndFrame:keydown];
        [keyboard_ deactivate];
    }
	
    [[UIAnimator sharedAnimator]
	 addAnimations:[NSArray arrayWithObjects:animation, nil]
	 withDuration:KeyboardTime_
	 start:YES
	 ];
}

- (void) slideUp:(UIActionSheet *)alert {
    [alert presentSheetInView:overlay_];
}

@end
