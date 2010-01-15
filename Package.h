#import "Cydia.h"

@class Address;
/* Package Class {{{ */
@interface Package : NSObject {
    unsigned era_;
    apr_pool_t *pool_;
	
    pkgCache::VerIterator version_;
    pkgCache::PkgIterator iterator_;
    _transient Database *database_;
    pkgCache::VerFileIterator file_;
	
    Source *source_;
    bool cached_;
    bool parsed_;
	
    CYString section_;
    NSString *section$_;
    bool essential_;
    bool required_;
    bool visible_;
	
    NSString *latest_;
    CYString installed_;
	
    CYString id_;
    CYString name_;
    CYString tagline_;
    CYString icon_;
    CYString depiction_;
    CYString homepage_;
	
    CYString sponsor_;
    Address *sponsor$_;
	
    CYString author_;
    Address *author$_;
	
    CYString bugs_;
    CYString support_;
    NSMutableArray *tags_;
    NSString *role_;
	
    NSArray *relationships_;
	
    NSMutableDictionary *metadata_;
    _transient NSDate *firstSeen_;
    _transient NSDate *lastSeen_;
    bool subscribed_;
}

- (Package *) initWithVersion:(pkgCache::VerIterator)version withZone:(NSZone *)zone inPool:(apr_pool_t *)pool database:(Database *)database;
+ (Package *) packageWithIterator:(pkgCache::PkgIterator)iterator withZone:(NSZone *)zone inPool:(apr_pool_t *)pool database:(Database *)database;

- (pkgCache::PkgIterator) iterator;
- (void) parse;

- (NSString *) section;
- (NSString *) simpleSection;

- (NSString *) longSection;
- (NSString *) shortSection;

- (NSString *) uri;

- (Address *) maintainer;
- (size_t) size;
- (NSString *) longDescription;
- (NSString *) shortDescription;
- (unichar) index;

- (NSMutableDictionary *) metadata;
- (NSDate *) seen;
- (BOOL) subscribed;
- (BOOL) ignored;

- (NSString *) latest;
- (NSString *) installed;
- (BOOL) uninstalled;

- (BOOL) valid;
- (BOOL) upgradableAndEssential:(BOOL)essential;
- (BOOL) essential;
- (BOOL) broken;
- (BOOL) unfiltered;
- (BOOL) visible;

- (BOOL) half;
- (BOOL) halfConfigured;
- (BOOL) halfInstalled;
- (BOOL) hasMode;
- (NSString *) mode;

- (void) setVisible;

- (NSString *) id;
- (NSString *) name;
- (UIImage *) icon;
- (NSString *) homepage;
- (NSString *) depiction;
- (Address *) author;

- (NSString *) support;

- (NSArray *) files;
- (NSArray *) relationships;
- (NSArray *) warnings;
- (NSArray *) applications;

- (Source *) source;
- (NSString *) role;

- (BOOL) matches:(NSString *)text;

- (bool) hasSupportingRole;
- (BOOL) hasTag:(NSString *)tag;
- (NSString *) primaryPurpose;
- (NSArray *) purposes;
- (bool) isCommercial;

- (CYString &) cyname;

- (uint32_t) compareBySection:(NSArray *)sections;

- (uint32_t) compareForChanges;

- (void) install;
- (void) remove;

- (bool) isUnfilteredAndSearchedForBy:(NSString *)search;
- (bool) isInstalledAndVisible:(NSNumber *)number;
- (bool) isVisibleInSection:(NSString *)section;
- (bool) isVisibleInSource:(Source *)source;

@end
