#import "CydiaObject.h"


@implementation CydiaObject

- (void) dealloc {
    [indirect_ release];
    [super dealloc];
}

- (id) initWithDelegate:(IndirectDelegate *)indirect {
    if ((self = [super init]) != nil) {
        indirect_ = [indirect retain];
    } return self;
}

+ (NSArray *) _attributeKeys {
    return [NSArray arrayWithObjects:@"device", @"firewire", @"imei", @"mac", @"serial", nil];
}

- (NSArray *) attributeKeys {
    return [[self class] _attributeKeys];
}

+ (BOOL) isKeyExcludedFromWebScript:(const char *)name {
    return ![[self _attributeKeys] containsObject:[NSString stringWithUTF8String:name]] && [super isKeyExcludedFromWebScript:name];
}

- (NSString *) device {
    return [[UIDevice currentDevice] uniqueIdentifier];
}

#if 0 // XXX: implement!
- (NSString *) mac {
    if (![indirect_ promptForSensitive:@"Mac Address"])
        return nil;
}

- (NSString *) serial {
    if (![indirect_ promptForSensitive:@"Serial #"])
        return nil;
}

- (NSString *) firewire {
    if (![indirect_ promptForSensitive:@"Firewire GUID"])
        return nil;
}

- (NSString *) imei {
    if (![indirect_ promptForSensitive:@"IMEI"])
        return nil;
}
#endif

+ (NSString *) webScriptNameForSelector:(SEL)selector {
    if (selector == @selector(close))
        return @"close";
    else if (selector == @selector(getInstalledPackages))
        return @"getInstalledPackages";
    else if (selector == @selector(getPackageById:))
        return @"getPackageById";
    else if (selector == @selector(setAutoPopup:))
        return @"setAutoPopup";
    else if (selector == @selector(setButtonImage:withStyle:toFunction:))
        return @"setButtonImage";
    else if (selector == @selector(setButtonTitle:withStyle:toFunction:))
        return @"setButtonTitle";
    else if (selector == @selector(setFinishHook:))
        return @"setFinishHook";
    else if (selector == @selector(setPopupHook:))
        return @"setPopupHook";
    else if (selector == @selector(setSpecial:))
        return @"setSpecial";
    else if (selector == @selector(setViewportWidth:))
        return @"setViewportWidth";
    else if (selector == @selector(supports:))
        return @"supports";
    else if (selector == @selector(stringWithFormat:arguments:))
        return @"format";
    else if (selector == @selector(localizedStringForKey:value:table:))
        return @"localize";
    else if (selector == @selector(du:))
        return @"du";
    else if (selector == @selector(statfs:))
        return @"statfs";
    else
        return nil;
}

+ (BOOL) isSelectorExcludedFromWebScript:(SEL)selector {
    return [self webScriptNameForSelector:selector] == nil;
}

- (BOOL) supports:(NSString *)feature {
    return [feature isEqualToString:@"window.open"];
}

- (NSArray *) getInstalledPackages {
    NSArray *packages([[Database sharedInstance] packages]);
    NSMutableArray *installed([NSMutableArray arrayWithCapacity:[packages count]]);
    for (Package *package in installed)
        if ([package installed] != nil)
            [installed addObject:package];
    return installed;
}

- (Package *) getPackageById:(NSString *)id {
    Package *package([[Database sharedInstance] packageWithName:id]);
    [package parse];
    return package;
}

- (NSArray *) statfs:(NSString *)path {
    struct statfs stat;
	
    if (path == nil || statfs([path UTF8String], &stat) == -1)
        return nil;
	
    return [NSArray arrayWithObjects:
			[NSNumber numberWithUnsignedLong:stat.f_bsize],
			[NSNumber numberWithUnsignedLong:stat.f_blocks],
			[NSNumber numberWithUnsignedLong:stat.f_bfree],
			nil];
}

- (NSNumber *) du:(NSString *)path {
    NSNumber *value(nil);
	
    int fds[2];
    _assert(pipe(fds) != -1);
	
    pid_t pid(ExecFork());
    if (pid == 0) {
        _assert(dup2(fds[1], 1) != -1);
        _assert(close(fds[0]) != -1);
        _assert(close(fds[1]) != -1);
        /* XXX: this should probably not use du */
        execl("/usr/libexec/cydia/du", "du", "-s", [path UTF8String], NULL);
        exit(1);
        _assert(false);
    }
	
    _assert(close(fds[1]) != -1);
	
    if (FILE *du = fdopen(fds[0], "r")) {
        char line[1024];
        while (fgets(line, sizeof(line), du) != NULL) {
            size_t length(strlen(line));
            while (length != 0 && line[length - 1] == '\n')
                line[--length] = '\0';
            if (char *tab = strchr(line, '\t')) {
                *tab = '\0';
                value = [NSNumber numberWithUnsignedLong:strtoul(line, NULL, 0)];
            }
        }
		
        fclose(du);
    } else _assert(close(fds[0]));
	
    int status;
wait:
    if (waitpid(pid, &status, 0) == -1)
        if (errno == EINTR)
            goto wait;
        else _assert(false);
	
    return value;
}

- (void) close {
    [indirect_ close];
}

- (void) setAutoPopup:(BOOL)popup {
    [indirect_ setAutoPopup:popup];
}

- (void) setButtonImage:(NSString *)button withStyle:(NSString *)style toFunction:(id)function {
    [indirect_ setButtonImage:button withStyle:style toFunction:function];
}

- (void) setButtonTitle:(NSString *)button withStyle:(NSString *)style toFunction:(id)function {
    [indirect_ setButtonTitle:button withStyle:style toFunction:function];
}

- (void) setSpecial:(id)function {
    [indirect_ setSpecial:function];
}

- (void) setFinishHook:(id)function {
    [indirect_ setFinishHook:function];
}

- (void) setPopupHook:(id)function {
    [indirect_ setPopupHook:function];
}

- (void) setViewportWidth:(float)width {
    [indirect_ setViewportWidth:width];
}

- (NSString *) stringWithFormat:(NSString *)format arguments:(WebScriptObject *)arguments {
    //NSLog(@"SWF:\"%@\" A:%@", format, [arguments description]);
    unsigned count([arguments count]);
    id values[count];
    for (unsigned i(0); i != count; ++i)
        values[i] = [arguments objectAtIndex:i];
    return [[[NSString alloc] initWithFormat:format arguments:reinterpret_cast<va_list>(values)] autorelease];
}

- (NSString *) localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)table {
    if (reinterpret_cast<id>(value) == [WebUndefined undefined])
        value = nil;
    if (reinterpret_cast<id>(table) == [WebUndefined undefined])
        table = nil;
    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:table];
}

@end
/* }}} */
