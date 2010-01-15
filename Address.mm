

#import "Address.h"



@implementation Address

- (void) dealloc {
    [name_ release];
    if (address_ != nil)
        [address_ release];
    [super dealloc];
}

- (NSString *) name {
    return name_;
}

- (NSString *) address {
    return address_;
}

- (void) setAddress:(NSString *)address {
    if (address_ != nil)
        [address_ autorelease];
    if (address == nil)
        address_ = nil;
    else
        address_ = [address retain];
}

+ (Address *) addressWithString:(NSString *)string {
    return [[[Address alloc] initWithString:string] autorelease];
}

+ (NSArray *) _attributeKeys {
    return [NSArray arrayWithObjects:@"address", @"name", nil];
}

- (NSArray *) attributeKeys {
    return [[self class] _attributeKeys];
}

+ (BOOL) isKeyExcludedFromWebScript:(const char *)name {
    return ![[self _attributeKeys] containsObject:[NSString stringWithUTF8String:name]] && [super isKeyExcludedFromWebScript:name];
}

- (Address *) initWithString:(NSString *)string {
    if ((self = [super init]) != nil) {
        const char *data = [string UTF8String];
        size_t size = [string length];
		
        static Pcre address_r("^\"?(.*)\"? <([^>]*)>$");
		
        if (address_r(data, size)) {
            name_ = [address_r[1] retain];
            address_ = [address_r[2] retain];
        } else {
            name_ = [string retain];
            address_ = nil;
        }
    } return self;
}

@end
/* }}} */

