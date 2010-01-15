@class Cydia;
#import "Globals.h"

#import "Protocols.h"
#import "CydiaObject.h"
#import "CYActionSheet.h"
#import "CYBook.h"
#import "CydiaURLProtocol.h"
#import "ProgressData.h"
#import "Progress.h"
#import "Status.h"
#import "ProgressDelegate.h"

#import "Address.h"
#import "Database.h"
#import "Source.h"
#import "Package.h"
#import "Relationship.h"
#import "Section.h"

#import "CydiaBrowserView.h"

#import "SourceCell.h"
#import "PackageCell.h"
#import "SectionCell.h"


@class ProgressView, SectionsView, ChangesView, ManageView, SearchView, CYBook;
@interface Cydia : UIApplication <
ConfirmationViewDelegate,
ProgressViewDelegate,
SearchViewDelegate,
CydiaDelegate
> {
    UIWindow *window_;
	
    UIView *underlay_;
    UIView *overlay_;
    CYBook *book_;
    UIToolbar *toolbar_;
	
    RVBook *confirm_;
	
    NSMutableArray *essential_;
    NSMutableArray *broken_;
	
    Database *database_;
    ProgressView *progress_;
	
    unsigned tag_;
	
    UIKeyboard *keyboard_;
    UIProgressHUD *hud_;
	
    SectionsView *sections_;
    ChangesView *changes_;
    ManageView *manage_;
    SearchView *search_;
	
#if RecyclePackageViews
    NSMutableArray *details_;
#endif
}

- (RVPage *) _pageForURL:(NSURL *)url withClass:(Class)_class;
- (void) setPage:(RVPage *)page;

@end