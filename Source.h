#import "Cydia.h"

/* Source Class {{{ */
@interface Source : NSObject {
    CYString depiction_;
    CYString description_;
    CYString label_;
    CYString origin_;
    CYString support_;
	
    CYString uri_;
    CYString distribution_;
    CYString type_;
    CYString version_;
	
    NSString *host_;
    NSString *authority_;
	
    CYString defaultIcon_;
	
    NSDictionary *record_;
    BOOL trusted_;
}

- (Source *) initWithMetaIndex:(metaIndex *)index inPool:(apr_pool_t *)pool;

- (NSComparisonResult) compareByNameAndType:(Source *)source;

- (NSString *) depictionForPackage:(NSString *)package;
- (NSString *) supportForPackage:(NSString *)package;

- (NSDictionary *) record;
- (BOOL) trusted;

- (NSString *) uri;
- (NSString *) distribution;
- (NSString *) type;
- (NSString *) key;
- (NSString *) host;

- (NSString *) name;
- (NSString *) description;
- (NSString *) label;
- (NSString *) origin;
- (NSString *) version;

- (NSString *) defaultIcon;

@end
