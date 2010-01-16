#import "Cydia.h"

/* Source Table {{{ */
@interface SourceTable : RVPage {
    _transient Database *database_;
    UITableView *list_;
    NSMutableArray *sources_;
    UIActionSheet *alert_;
    int offset_;
	
    NSString *href_;
    UIProgressHUD *hud_;
    NSError *error_;
	
    //NSURLConnection *installer_;
    NSURLConnection *trivial_;
    NSURLConnection *trivial_bz2_;
    NSURLConnection *trivial_gz_;
    //NSURLConnection *automatic_;
	
    BOOL cydia_;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database;

@end