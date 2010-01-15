#import "SignatureView.h"

@implementation SignatureView

- (void) dealloc {
    [package_ release];
    [super dealloc];
}

- (void) webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)window forFrame:(WebFrame *)frame {
    // XXX: dude!
    [super webView:sender didClearWindowObject:window forFrame:frame];
}

- (id) initWithBook:(RVBook *)book database:(Database *)database package:(NSString *)package {
    if ((self = [super initWithBook:book]) != nil) {
        database_ = database;
        package_ = [package retain];
        [self reloadData];
    } return self;
}

- (void) resetViewAnimated:(BOOL)animated {
}

- (void) reloadData {
    [self loadURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"signature" ofType:@"html"]]];
}

@end
/* }}} */
