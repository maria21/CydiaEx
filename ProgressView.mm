#import "ProgressView.h"
#import "Database.h"

@implementation ProgressView

- (void) dealloc {
    [transition_ setDelegate:nil];
    [navbar_ setDelegate:nil];
	
    [view_ release];
    if (background_ != nil)
        [background_ release];
    [transition_ release];
    [overlay_ release];
    [navbar_ release];
    [progress_ release];
    [output_ release];
    [activity_ release];
    [status_ release];
    [close_ release];
    [header_ release];
    if (title_ != nil)
        [title_ release];
    [super dealloc];
}

- (id) initWithFrame:(struct CGRect)frame database:(Database *)database delegate:(id)delegate {
    if ((self = [super initWithFrame:frame]) != nil) {
        database_ = database;
        delegate_ = delegate;
		
        transition_ = [[UITransitionView alloc] initWithFrame:[self bounds]];
        [transition_ setDelegate:self];
		
        overlay_ = [[UIView alloc] initWithFrame:[transition_ bounds]];
		
        background_ = [[UIView alloc] initWithFrame:[self bounds]];
        [background_ setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];
        [self addSubview:background_];
		
        [self addSubview:transition_];
		
        BOOL showNavbar = NO;
		
        CGSize navsize = [UINavigationBar defaultSize];
        CGRect navrect = {{0, 0}, navsize};
		
        navbar_ = [[UINavigationBar alloc] initWithFrame:navrect];
        if (showNavbar)
            [overlay_ addSubview:navbar_];
		
        [navbar_ setBarStyle:UIBarStyleBlackTranslucent];
        [navbar_ setDelegate:self];
		
        UINavigationItem *navitem = [[[UINavigationItem alloc] initWithTitle:nil] autorelease];
        [navbar_ pushNavigationItem:navitem];
		
        CGRect bounds = [overlay_ bounds];
        CGSize prgsize = [UIProgressBar defaultSize];
		
        CGRect prgrect = {{
            (bounds.size.width - prgsize.width) / 2,
            (showNavbar ? navrect.size.height + 105 : 105)
        }, prgsize};
		
        progress_ = [[UIProgressView alloc] initWithFrame:prgrect];
        [progress_ setProgressViewStyle:1];
		
        status_ = [[UITextLabel alloc] initWithFrame:CGRectMake(
																10,
																(showNavbar ? navrect.size.height + 75 : 75),
																bounds.size.width - 20,
																24
																)];
		
        [status_ setColor:[UIColor whiteColor]];
        [status_ setBackgroundColor:[UIColor clearColor]];
		
        [status_ setCentersHorizontally:YES];
        //[status_ setFont:font];
		
        header_ = [[UITextLabel alloc] initWithFrame:CGRectMake(
																10,
																(showNavbar ? navrect.size.height + 25 : 25),
																bounds.size.width - 20,
																35
																)];
		
        [header_ setFont:[UIFont boldSystemFontOfSize:30.0f]];
        [header_ setColor:[UIColor whiteColor]];
        [header_ setBackgroundColor:[UIColor clearColor]];
        [header_ setShadowColor:[UIColor blackColor]];
		[header_ setShadowOffset:CGSizeMake(0.0f, 2.0f)];
		
        [header_ setCentersHorizontally:YES];
		
        [overlay_ addSubview:header_];
		
        output_ = [[UITextView alloc] initWithFrame:CGRectMake(
															   10,
															   (showNavbar ? navrect.size.height + 116 : 116),
															   bounds.size.width - 20,
															   bounds.size.height - (showNavbar ? navrect.size.height : 0) - 116 - 60
															   )];
		
        //[output_ setTextFont:@"Courier New"];
        [output_ setFont:[[output_ font] fontWithSize:12]];
		
        [output_ setTextColor:[UIColor whiteColor]];
        [output_ setBackgroundColor:[UIColor clearColor]];
		
        [output_ setMarginTop:0];
        [output_ setAllowsRubberBanding:YES];
        [output_ setEditable:NO];
		
        [overlay_ addSubview:output_];
		
        activity_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:0];
        [activity_ setFrame:CGRectMake((bounds.size.width / 2) - (37 / 2), bounds.size.height - 70, 37, 37)];
        [activity_ startAnimating];
		
        [overlay_ addSubview:activity_];
		
        close_ = [[UIPushButton alloc] initWithFrame:CGRectMake(
																10,
																bounds.size.height - prgsize.height - 50,
																bounds.size.width - 20,
																32 + prgsize.height
																)];
		
        [close_ setAutosizesToFit:NO];
        [close_ setDrawsShadow:YES];
        [close_ setStretchBackground:YES];
        [close_ setEnabled:YES];
		
        UIFont *bold = [UIFont boldSystemFontOfSize:22];
        [close_ setTitleFont:bold];
		
        [close_ addTarget:self action:@selector(closeButtonPushed) forEvents:UIControlEventTouchUpInside];
        [close_ setBackground:[UIImage applicationImageNamed:@"green-up.png"] forState:0];
        [close_ setBackground:[UIImage applicationImageNamed:@"green-dn.png"] forState:1];
    } return self;
}

- (void) setContentView:(UIView *)view {
    view_ = [view retain];
}

- (void) resetView {
    [transition_ transition:6 toView:view_];
}

- (void) alertSheet:(UIActionSheet *)sheet buttonClicked:(int)button {
    NSString *context([sheet context]);
	
    if ([context isEqualToString:@"conffile"]) {
        FILE *input = [database_ input];
		
        switch (button) {
            case 1:
                fprintf(input, "N\n");
                fflush(input);
                break;
            case 2:
                fprintf(input, "Y\n");
                fflush(input);
                break;
				_nodefault
        }
		
        [sheet dismiss];
    }
}

- (void) closeButtonPushed {
    running_ = NO;
	
	switch (Finish_) {
		case 1: [delegate_ terminateWithSuccess]; break;
		default: [self resetView]; break;
	}
}

- (void) _retachThread {
    UINavigationItem *item([navbar_ topItem]);
	
    [database_ popErrorWithTitle:title_];
    [delegate_ progressViewIsComplete:self];
	
    if (Finish_ < 4) {
        FileFd file;
        if (!file.Open(NotifyConfig_, FileFd::ReadOnly))
            _error->Discard();
        else {
            MMap mmap(file, MMap::ReadOnly);
            SHA1Summation sha1;
            sha1.Add(reinterpret_cast<uint8_t *>(mmap.Data()), mmap.Size());
            if (!(notifyconf_ == sha1.Result()))
                Finish_ = 4;
        }
    }
	
    if (Finish_ < 3) {
        FileFd file;
        if (!file.Open(SpringBoard_, FileFd::ReadOnly))
            _error->Discard();
        else {
            MMap mmap(file, MMap::ReadOnly);
            SHA1Summation sha1;
            sha1.Add(reinterpret_cast<uint8_t *>(mmap.Data()), mmap.Size());
            if (!(springlist_ == sha1.Result()))
                Finish_ = 3;
        }
    }
	
	[item setTitle:UCLocalize("COMPLETE")];
    [header_ setText:UCLocalize("COMPLETE")];
	
    switch (Finish_) {
        case 1: [close_ setTitle:UCLocalize("CLOSE_CYDIA")]; break;
		default: [close_ setTitle:UCLocalize("RETURN_TO_CYDIA")]; break;
    }
	
	[overlay_ addSubview:close_];
    [activity_ removeFromSuperview];
	
	if (Finish_ > 1) {
		NSString *text;
		switch (Finish_) {
			case 2: text = UCLocalize("RESTART_SPRINGBOARD"); break;
			case 3: text = UCLocalize("RELOAD_SPRINGBOARD"); break;
			case 4: text = UCLocalize("REBOOT_DEVICE"); break;
		}
		
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cydia" message:text delegate:nil cancelButtonTitle:nil otherButtonTitles:UCLocalize("OKAY"), nil];
		[alertView show];
		[alertView autorelease];
	}
	
#define ListCache_ "/User/Library/Caches/com.apple.mobile.installation.plist"
#define IconCache_ "/User/Library/Caches/com.apple.springboard-imagecache-icons.plist"
	
    unlink(IconCache_);
	
    if (NSMutableDictionary *cache = [[NSMutableDictionary alloc] initWithContentsOfFile:@ListCache_]) {
        [cache autorelease];
		
        NSFileManager *manager([NSFileManager defaultManager]);
        NSError *error(nil);
		
        id system([cache objectForKey:@"System"]);
        if (system == nil)
            goto error;
		
        struct stat info;
        if (stat(ListCache_, &info) == -1)
            goto error;
		
        [system removeAllObjects];
		
        if (NSArray *apps = [manager contentsOfDirectoryAtPath:@"/Applications" error:&error]) {
            for (NSString *app in apps)
                if ([app hasSuffix:@".app"]) {
                    NSString *path = [@"/Applications" stringByAppendingPathComponent:app];
                    NSString *plist = [path stringByAppendingPathComponent:@"Info.plist"];
                    if (NSMutableDictionary *info = [[NSMutableDictionary alloc] initWithContentsOfFile:plist]) {
                        [info autorelease];
                        if ([info objectForKey:@"CFBundleIdentifier"] != nil) {
                            [info setObject:path forKey:@"Path"];
                            [info setObject:@"System" forKey:@"ApplicationType"];
                            [system addInfoDictionary:info];
                        }
                    }
                }
        } else goto error;
		
        [cache writeToFile:@ListCache_ atomically:YES];
		
        if (chown(ListCache_, info.st_uid, info.st_gid) == -1)
            goto error;
        if (chmod(ListCache_, 644/*info.st_mode*/) == -1)
            goto error;
		
        if (false) error:
            lprintf("%s\n", error == nil ? strerror(errno) : [[error localizedDescription] UTF8String]);
    }
	
    notify_post("com.apple.mobile.application_installed");
	
    [delegate_ setStatusBarShowsProgress:NO];
}

- (void) _detachNewThreadData:(ProgressData *)data { _pooled
    [[data target] performSelector:[data selector] withObject:[data object]];
    [data release];
	
    [self performSelectorOnMainThread:@selector(_retachThread) withObject:nil waitUntilDone:YES];
}

- (void) detachNewThreadSelector:(SEL)selector toTarget:(id)target withObject:(id)object title:(NSString *)title {
    if (title_ != nil)
        [title_ release];
    if (title == nil)
        title_ = nil;
    else
        title_ = [title retain];
	
    UINavigationItem *item([navbar_ topItem]);
    [item setTitle:title_];
    [header_ setText:title_];
	
    [status_ setText:nil];
    [output_ setText:@""];
    [progress_ setProgress:0];
	
    [close_ removeFromSuperview];
    [overlay_ addSubview:progress_];
    [overlay_ addSubview:status_];
	
    [delegate_ setStatusBarShowsProgress:YES];
    running_ = YES;
	
    {
        FileFd file;
        if (!file.Open(NotifyConfig_, FileFd::ReadOnly))
            _error->Discard();
        else {
            MMap mmap(file, MMap::ReadOnly);
            SHA1Summation sha1;
            sha1.Add(reinterpret_cast<uint8_t *>(mmap.Data()), mmap.Size());
            notifyconf_ = sha1.Result();
        }
    }
	
    {
        FileFd file;
        if (!file.Open(SpringBoard_, FileFd::ReadOnly))
            _error->Discard();
        else {
            MMap mmap(file, MMap::ReadOnly);
            SHA1Summation sha1;
            sha1.Add(reinterpret_cast<uint8_t *>(mmap.Data()), mmap.Size());
            springlist_ = sha1.Result();
        }
    }
	
    [transition_ transition:6 toView:overlay_];
	
    [NSThread
	 detachNewThreadSelector:@selector(_detachNewThreadData:)
	 toTarget:self
	 withObject:[[ProgressData alloc]
				 initWithSelector:selector
				 target:target
				 object:object
				 ]
	 ];
}

- (void) repairWithSelector:(SEL)selector {
    [self
	 detachNewThreadSelector:selector
	 toTarget:database_
	 withObject:nil
	 title:UCLocalize("REPAIRING")
	 ];
}

- (void) setConfigurationData:(NSString *)data {
    [self
	 performSelectorOnMainThread:@selector(_setConfigurationData:)
	 withObject:data
	 waitUntilDone:YES
	 ];
}

- (void) setProgressError:(NSString *)error withTitle:(NSString *)title {
    CYActionSheet *sheet([[[CYActionSheet alloc]
						   initWithTitle:title
						   buttons:[NSArray arrayWithObjects:UCLocalize("OKAY"), nil]
						   defaultButtonIndex:0
						   ] autorelease]);
	
    [sheet setBodyText:error];
    [sheet yieldToPopupAlertAnimated:YES];
    [sheet dismiss];
}

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
    return false;
}

- (void) _setConfigurationData:(NSString *)data {
    static Pcre conffile_r("^'(.*)' '(.*)' ([01]) ([01])$");
	
    if (!conffile_r(data)) {
        lprintf("E:invalid conffile\n");
        return;
    }
	
    NSString *ofile = conffile_r[1];
    //NSString *nfile = conffile_r[2];
	
    UIActionSheet *sheet = [[[UIActionSheet alloc]
							 initWithTitle:UCLocalize("CONFIGURATION_UPGRADE")
							 buttons:[NSArray arrayWithObjects:
									  UCLocalize("KEEP_OLD_COPY"),
									  UCLocalize("ACCEPT_NEW_COPY"),
									  // XXX: UCLocalize("SEE_WHAT_CHANGED"),
									  nil]
							 defaultButtonIndex:0
							 delegate:self
							 context:@"conffile"
							 ] autorelease];
	
    [sheet setBodyText:[NSString stringWithFormat:@"%@\n\n%@", UCLocalize("CONFIGURATION_UPGRADE_EX"), ofile]];
    [sheet popupAlertAnimated:YES];
}

- (void) _setProgressTitle:(NSString *)title {
    NSMutableArray *words([[title componentsSeparatedByString:@" "] mutableCopy]);
    for (size_t i(0), e([words count]); i != e; ++i) {
        NSString *word([words objectAtIndex:i]);
        if (Package *package = [database_ packageWithName:word])
            [words replaceObjectAtIndex:i withObject:[package name]];
    }
	
    [status_ setText:[words componentsJoinedByString:@" "]];
}

- (void) _setProgressPercent:(NSNumber *)percent {
    [progress_ setProgress:[percent floatValue]];
}

- (void) _addProgressOutput:(NSString *)output {
    [output_ setText:[NSString stringWithFormat:@"%@\n%@", [output_ text], output]];
    CGSize size = [output_ contentSize];
    CGRect rect = {{0, size.height}, {size.width, 0}};
    [output_ scrollRectToVisible:rect animated:YES];
}

- (BOOL) isRunning {
    return running_;
}

@end
/* }}} */
