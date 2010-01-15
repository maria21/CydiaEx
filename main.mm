#import "Cydia.h"

/*IMP alloc_;
 id Alloc_(id self, SEL selector) {
 id object = alloc_(self, selector);
 lprintf("[%s]A-%p\n", self->isa->name, object);
 return object;
 }*/

/*IMP dealloc_;
 id Dealloc_(id self, SEL selector) {
 id object = dealloc_(self, selector);
 lprintf("[%s]D-%p\n", self->isa->name, object);
 return object;
 }*/

Class $WebDefaultUIKitDelegate;

MSHook(void, UIWebDocumentView$_setUIKitDelegate$, UIWebDocumentView *self, SEL _cmd, id delegate) {
    if (delegate == nil && $WebDefaultUIKitDelegate != nil)
        delegate = [$WebDefaultUIKitDelegate sharedUIKitDelegate];
    return _UIWebDocumentView$_setUIKitDelegate$(self, _cmd, delegate);
}



int main(int argc, char *argv[]) { _pooled
    _trace();
	
    PackageName = reinterpret_cast<CYString &(*)(Package *, SEL)>(method_getImplementation(class_getInstanceMethod([Package class], @selector(cyname))));
	
    /* Library Hacks {{{ */
    class_addMethod(objc_getClass("DOMNodeList"), @selector(countByEnumeratingWithState:objects:count:), (IMP) &DOMNodeList$countByEnumeratingWithState$objects$count$, "I20@0:4^{NSFastEnumerationState}8^@12I16");
	
    $WebDefaultUIKitDelegate = objc_getClass("WebDefaultUIKitDelegate");
    Method UIWebDocumentView$_setUIKitDelegate$(class_getInstanceMethod([WebView class], @selector(_setUIKitDelegate:)));
    if (UIWebDocumentView$_setUIKitDelegate$ != NULL) {
        _UIWebDocumentView$_setUIKitDelegate$ = reinterpret_cast<void (*)(UIWebDocumentView *, SEL, id)>(method_getImplementation(UIWebDocumentView$_setUIKitDelegate$));
        method_setImplementation(UIWebDocumentView$_setUIKitDelegate$, reinterpret_cast<IMP>(&$UIWebDocumentView$_setUIKitDelegate$));
    }
    /* }}} */
    /* Set Locale {{{ */
    Locale_ = CFLocaleCopyCurrent();
    Languages_ = [NSLocale preferredLanguages];
    //CFStringRef locale(CFLocaleGetIdentifier(Locale_));
    //NSLog(@"%@", [Languages_ description]);
	
    const char *lang;
    if (Languages_ == nil || [Languages_ count] == 0)
        // XXX: consider just setting to C and then falling through?
        lang = NULL;
    else {
        lang = [[Languages_ objectAtIndex:0] UTF8String];
        setenv("LANG", lang, true);
    }
	
    //std::setlocale(LC_ALL, lang);
    NSLog(@"Setting Language: %s", lang);
    /* }}} */
	
    apr_app_initialize(&argc, const_cast<const char * const **>(&argv), NULL);
	
    /* Parse Arguments {{{ */
    bool substrate(false);
	
    if (argc != 0) {
        char **args(argv);
        int arge(1);
		
        for (int argi(1); argi != argc; ++argi)
            if (strcmp(argv[argi], "--") == 0) {
                arge = argi;
                argv[argi] = argv[0];
                argv += argi;
                argc -= argi;
                break;
            }
		
        for (int argi(1); argi != arge; ++argi)
            if (strcmp(args[argi], "--substrate") == 0)
                substrate = true;
            else
                fprintf(stderr, "unknown argument: %s\n", args[argi]);
    }
    /* }}} */
	
    App_ = [[NSBundle mainBundle] bundlePath];
    Home_ = NSHomeDirectory();
    Advanced_ = YES;
	
    setuid(0);
    setgid(0);
	
    /*Method alloc = class_getClassMethod([NSObject class], @selector(alloc));
	 alloc_ = alloc->method_imp;
	 alloc->method_imp = (IMP) &Alloc_;*/
	
    /*Method dealloc = class_getClassMethod([NSObject class], @selector(dealloc));
	 dealloc_ = dealloc->method_imp;
	 dealloc->method_imp = (IMP) &Dealloc_;*/
	
    /* System Information {{{ */
    size_t size;
	
    int maxproc;
    size = sizeof(maxproc);
    if (sysctlbyname("kern.maxproc", &maxproc, &size, NULL, 0) == -1)
        perror("sysctlbyname(\"kern.maxproc\", ?)");
    else if (maxproc < 64) {
        maxproc = 64;
        if (sysctlbyname("kern.maxproc", NULL, NULL, &maxproc, sizeof(maxproc)) == -1)
            perror("sysctlbyname(\"kern.maxproc\", #)");
    }
	
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    char *osversion = new char[size];
    if (sysctlbyname("kern.osversion", osversion, &size, NULL, 0) == -1)
        perror("sysctlbyname(\"kern.osversion\", ?)");
    else
        System_ = [NSString stringWithUTF8String:osversion];
	
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = new char[size];
    if (sysctlbyname("hw.machine", machine, &size, NULL, 0) == -1)
        perror("sysctlbyname(\"hw.machine\", ?)");
    else
        Machine_ = machine;
	
    if (CFMutableDictionaryRef dict = IOServiceMatching("IOPlatformExpertDevice")) {
        if (io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, dict)) {
            if (CFTypeRef serial = IORegistryEntryCreateCFProperty(service, CFSTR(kIOPlatformSerialNumberKey), kCFAllocatorDefault, 0)) {
                SerialNumber_ = [NSString stringWithString:(NSString *)serial];
                CFRelease(serial);
            }
			
            if (CFTypeRef ecid = IORegistryEntrySearchCFProperty(service, kIODeviceTreePlane, CFSTR("unique-chip-id"), kCFAllocatorDefault, kIORegistryIterateRecursively)) {
                NSData *data((NSData *) ecid);
                size_t length([data length]);
                uint8_t bytes[length];
                [data getBytes:bytes];
                char string[length * 2 + 1];
                for (size_t i(0); i != length; ++i)
                    sprintf(string + i * 2, "%.2X", bytes[length - i - 1]);
                ChipID_ = [NSString stringWithUTF8String:string];
                CFRelease(ecid);
            }
			
            IOObjectRelease(service);
        }
    }
	
    UniqueID_ = [[UIDevice currentDevice] uniqueIdentifier];
	
    if (NSDictionary *system = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"])
        Build_ = [system objectForKey:@"ProductBuildVersion"];
    if (NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:@"/Applications/MobileSafari.app/Info.plist"]) {
        Product_ = [info objectForKey:@"SafariProductVersion"];
        Safari_ = [info objectForKey:@"CFBundleVersion"];
    }
    /* }}} */
    /* Load Database {{{ */
    _trace();
    Metadata_ = [[[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/lib/cydia/metadata.plist"] autorelease];
    _trace();
    SectionMap_ = [[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sections" ofType:@"plist"]] autorelease];
    _trace();
	
    if (Metadata_ == NULL)
        Metadata_ = [NSMutableDictionary dictionaryWithCapacity:2];
    else {
        Settings_ = [Metadata_ objectForKey:@"Settings"];
		
        Packages_ = [Metadata_ objectForKey:@"Packages"];
        Sections_ = [Metadata_ objectForKey:@"Sections"];
        Sources_ = [Metadata_ objectForKey:@"Sources"];
    }
	
    if (Settings_ != nil)
        Role_ = [Settings_ objectForKey:@"Role"];
	
    if (Packages_ == nil) {
        Packages_ = [[[NSMutableDictionary alloc] initWithCapacity:128] autorelease];
        [Metadata_ setObject:Packages_ forKey:@"Packages"];
    }
	
    if (Sections_ == nil) {
        Sections_ = [[[NSMutableDictionary alloc] initWithCapacity:32] autorelease];
        [Metadata_ setObject:Sections_ forKey:@"Sections"];
    }
	
    if (Sources_ == nil) {
        Sources_ = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
        [Metadata_ setObject:Sources_ forKey:@"Sources"];
    }
    /* }}} */
	
#if RecycleWebViews
    Documents_ = [[[NSMutableArray alloc] initWithCapacity:4] autorelease];
#endif
	
    Finishes_ = [NSArray arrayWithObjects:@"return", @"reopen", @"restart", @"reload", @"reboot", nil];
	
    if (substrate && access("/Applications/WinterBoard.app/WinterBoard.dylib", F_OK) == 0)
        dlopen("/Applications/WinterBoard.app/WinterBoard.dylib", RTLD_LAZY | RTLD_GLOBAL);
    /*if (substrate && access("/Library/MobileSubstrate/MobileSubstrate.dylib", F_OK) == 0)
	 dlopen("/Library/MobileSubstrate/MobileSubstrate.dylib", RTLD_LAZY | RTLD_GLOBAL);*/
	
    if (access("/tmp/.cydia.fw", F_OK) == 0) {
        unlink("/tmp/.cydia.fw");
        goto firmware;
    } else if (access("/User", F_OK) != 0) {
	firmware:
        _trace();
        system("/usr/libexec/cydia/firmware.sh");
        _trace();
    }
	
    _assert([[NSFileManager defaultManager]
			 createDirectoryAtPath:@"/var/cache/apt/archives/partial"
			 withIntermediateDirectories:YES
			 attributes:nil
			 error:NULL
			 ]);
	
    if (access("/tmp/cydia.chk", F_OK) == 0) {
        if (unlink("/var/cache/apt/pkgcache.bin") == -1)
            _assert(errno == ENOENT);
        if (unlink("/var/cache/apt/srcpkgcache.bin") == -1)
            _assert(errno == ENOENT);
    }
	
    /* APT Initialization {{{ */
    _assert(pkgInitConfig(*_config));
    _assert(pkgInitSystem(*_config, _system));
	
    if (lang != NULL)
        _config->Set("APT::Acquire::Translation", lang);
    _config->Set("Acquire::http::Timeout", 15);
    _config->Set("Acquire::http::MaxParallel", 3);
    /* }}} */
    /* Color Choices {{{ */
    space_ = CGColorSpaceCreateDeviceRGB();
	
    Blue_.Set(space_, 0.2, 0.2, 1.0, 1.0);
    Blueish_.Set(space_, 0x19/255.f, 0x32/255.f, 0x50/255.f, 1.0);
    Black_.Set(space_, 0.0, 0.0, 0.0, 1.0);
    Off_.Set(space_, 0.9, 0.9, 0.9, 1.0);
    White_.Set(space_, 1.0, 1.0, 1.0, 1.0);
    Gray_.Set(space_, 0.4, 0.4, 0.4, 1.0);
    Green_.Set(space_, 0.0, 0.5, 0.0, 1.0);
    Purple_.Set(space_, 0.0, 0.0, 0.7, 1.0);
    Purplish_.Set(space_, 0.4, 0.4, 0.8, 1.0);
	
    InstallingColor_ = [UIColor colorWithRed:0.88f green:1.00f blue:0.88f alpha:1.00f];
    RemovingColor_ = [UIColor colorWithRed:1.00f green:0.88f blue:0.88f alpha:1.00f];
    /* }}}*/
    /* UIKit Configuration {{{ */
    void (*$GSFontSetUseLegacyFontMetrics)(BOOL)(reinterpret_cast<void (*)(BOOL)>(dlsym(RTLD_DEFAULT, "GSFontSetUseLegacyFontMetrics")));
    if ($GSFontSetUseLegacyFontMetrics != NULL)
        $GSFontSetUseLegacyFontMetrics(YES);
	
    UIKeyboardDisableAutomaticAppearance();
    /* }}} */
	
    Colon_ = UCLocalize("COLON_DELIMITED");
    Error_ = UCLocalize("ERROR");
    Warning_ = UCLocalize("WARNING");
	
    _trace();
    int value = UIApplicationMain(argc, argv, @"Cydia", @"Cydia");
	
    CGColorSpaceRelease(space_);
    CFRelease(Locale_);
	
    return value;
}