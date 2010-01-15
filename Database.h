#import "Cydia.h"


/* Database Interface {{{ */
typedef std::map< unsigned long, _H<Source> > SourceMap;

@interface Database : NSObject {
    NSZone *zone_;
    apr_pool_t *pool_;
	
    unsigned era_;
	
    pkgCacheFile cache_;
    pkgDepCache::Policy *policy_;
    pkgRecords *records_;
    pkgProblemResolver *resolver_;
    pkgAcquire *fetcher_;
    FileFd *lock_;
    SPtr<pkgPackageManager> manager_;
    pkgSourceList *list_;
	
    SourceMap sources_;
    NSMutableArray *packages_;
	
    _transient NSObject<ConfigurationDelegate, ProgressDelegate> *delegate_;
    Status status_;
    Progress progress_;
	
    int cydiafd_;
    int statusfd_;
    FILE *input_;
}

+ (Database *) sharedInstance;
- (unsigned) era;

- (void) _readCydia:(NSNumber *)fd;
- (void) _readStatus:(NSNumber *)fd;
- (void) _readOutput:(NSNumber *)fd;

- (FILE *) input;

- (Package *) packageWithName:(NSString *)name;

- (pkgCacheFile &) cache;
- (pkgDepCache::Policy *) policy;
- (pkgRecords *) records;
- (pkgProblemResolver *) resolver;
- (pkgAcquire &) fetcher;
- (pkgSourceList &) list;
- (NSArray *) packages;
- (NSArray *) sources;
- (void) reloadData;

- (void) configure;
- (bool) prepare;
- (void) perform;
- (bool) upgrade;
- (void) update;

- (void) setVisible;

- (void) updateWithStatus:(Status &)status;

- (void) setDelegate:(id)delegate;
- (Source *) getSource:(pkgCache::PkgFileIterator)file;
@end
/* }}} */
