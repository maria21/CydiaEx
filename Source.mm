#import "Source.h"

@implementation Source

- (void) _clear {
    uri_.clear();
    distribution_.clear();
    type_.clear();
	
    description_.clear();
    label_.clear();
    origin_.clear();
    depiction_.clear();
    support_.clear();
    version_.clear();
    defaultIcon_.clear();
	
    if (record_ != nil) {
        [record_ release];
        record_ = nil;
    }
	
    if (host_ != nil) {
        [host_ release];
        host_ = nil;
    }
	
    if (authority_ != nil) {
        [authority_ release];
        authority_ = nil;
    }
}

- (void) dealloc {
    [self _clear];
    [super dealloc];
}

+ (NSArray *) _attributeKeys {
    return [NSArray arrayWithObjects:@"description", @"distribution", @"host", @"key", @"label", @"name", @"origin", @"trusted", @"type", @"uri", @"version", nil];
}

- (NSArray *) attributeKeys {
    return [[self class] _attributeKeys];
}

+ (BOOL) isKeyExcludedFromWebScript:(const char *)name {
    return ![[self _attributeKeys] containsObject:[NSString stringWithUTF8String:name]] && [super isKeyExcludedFromWebScript:name];
}

- (void) setMetaIndex:(metaIndex *)index inPool:(apr_pool_t *)pool {
    [self _clear];
	
    trusted_ = index->IsTrusted();
	
    uri_.set(pool, index->GetURI());
    distribution_.set(pool, index->GetDist());
    type_.set(pool, index->GetType());
	
    debReleaseIndex *dindex(dynamic_cast<debReleaseIndex *>(index));
    if (dindex != NULL) {
        FileFd fd;
        if (!fd.Open(dindex->MetaIndexFile("Release"), FileFd::ReadOnly))
            _error->Discard();
        else {
            pkgTagFile tags(&fd);
			
            pkgTagSection section;
            tags.Step(section);
			
            struct {
                const char *name_;
                CYString *value_;
            } names[] = {
                {"default-icon", &defaultIcon_},
                {"depiction", &depiction_},
                {"description", &description_},
                {"label", &label_},
                {"origin", &origin_},
                {"support", &support_},
                {"version", &version_},
            };
			
            for (size_t i(0); i != sizeof(names) / sizeof(names[0]); ++i) {
                const char *start, *end;
				
                if (section.Find(names[i].name_, start, end)) {
                    CYString &value(*names[i].value_);
                    value.set(pool, start, end - start);
                }
            }
        }
    }
	
    record_ = [Sources_ objectForKey:[self key]];
    if (record_ != nil)
        record_ = [record_ retain];
	
    NSURL *url([NSURL URLWithString:uri_]);
	
    host_ = [url host];
    if (host_ != nil)
        host_ = [[host_ lowercaseString] retain];
	
    if (host_ != nil)
        authority_ = host_;
    else
        authority_ = [url path];
	
    if (authority_ != nil)
        authority_ = [authority_ retain];
}

- (Source *) initWithMetaIndex:(metaIndex *)index inPool:(apr_pool_t *)pool {
    if ((self = [super init]) != nil) {
        [self setMetaIndex:index inPool:pool];
    } return self;
}

- (NSComparisonResult) compareByNameAndType:(Source *)source {
    NSDictionary *lhr = [self record];
    NSDictionary *rhr = [source record];
	
    if (lhr != rhr)
        return lhr == nil ? NSOrderedDescending : NSOrderedAscending;
	
    NSString *lhs = [self name];
    NSString *rhs = [source name];
	
    if ([lhs length] != 0 && [rhs length] != 0) {
        unichar lhc = [lhs characterAtIndex:0];
        unichar rhc = [rhs characterAtIndex:0];
		
        if (isalpha(lhc) && !isalpha(rhc))
            return NSOrderedAscending;
        else if (!isalpha(lhc) && isalpha(rhc))
            return NSOrderedDescending;
    }
	
    return [lhs compare:rhs options:LaxCompareOptions_];
}

- (NSString *) depictionForPackage:(NSString *)package {
    return depiction_.empty() ? nil : [depiction_ stringByReplacingOccurrencesOfString:@"*" withString:package];
}

- (NSString *) supportForPackage:(NSString *)package {
    return support_.empty() ? nil : [support_ stringByReplacingOccurrencesOfString:@"*" withString:package];
}

- (NSDictionary *) record {
    return record_;
}

- (BOOL) trusted {
    return trusted_;
}

- (NSString *) uri {
    return uri_;
}

- (NSString *) distribution {
    return distribution_;
}

- (NSString *) type {
    return type_;
}

- (NSString *) key {
    return [NSString stringWithFormat:@"%@:%@:%@", (NSString *) type_, (NSString *) uri_, (NSString *) distribution_];
}

- (NSString *) host {
    return host_;
}

- (NSString *) name {
    return origin_.empty() ? authority_ : origin_;
}

- (NSString *) description {
    return description_;
}

- (NSString *) label {
    return label_.empty() ? authority_ : label_;
}

- (NSString *) origin {
    return origin_;
}

- (NSString *) version {
    return version_;
}

- (NSString *) defaultIcon {
    return defaultIcon_;
}

@end
/* }}} */
