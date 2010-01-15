#import "CydiaBrowserView.h"


@implementation CydiaBrowserView

- (void) dealloc {
    [cydia_ release];
    [super dealloc];
}

- (void) webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)window forFrame:(WebFrame *)frame {
    [super webView:sender didClearWindowObject:window forFrame:frame];
    [window setValue:cydia_ forKey:@"cydia"];
}

- (void) _setMoreHeaders:(NSMutableURLRequest *)request {
    if (System_ != NULL)
        [request setValue:System_ forHTTPHeaderField:@"X-System"];
    if (Machine_ != NULL)
        [request setValue:[NSString stringWithUTF8String:Machine_] forHTTPHeaderField:@"X-Machine"];
    if (UniqueID_ != nil)
        [request setValue:UniqueID_ forHTTPHeaderField:@"X-Unique-ID"];
    if (Role_ != nil)
        [request setValue:Role_ forHTTPHeaderField:@"X-Role"];
}

- (NSURLRequest *) webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)source {
    NSMutableURLRequest *copy = [request mutableCopy];
    [self _setMoreHeaders:copy];
    return copy;
}

- (id) initWithBook:(RVBook *)book forWidth:(float)width {
    if ((self = [super initWithBook:book forWidth:width ofClass:[CydiaBrowserView class]]) != nil) {
        cydia_ = [[CydiaObject alloc] initWithDelegate:indirect_];
		
        WebView *webview([webview_ webView]);
		
        Package *package([[Database sharedInstance] packageWithName:@"cydia"]);
		
        NSString *application = package == nil ? @"Cydia" : [NSString
															 stringWithFormat:@"Cydia/%@",
															 [package installed]
															 ];
		
        if (Safari_ != nil)
            application = [NSString stringWithFormat:@"Safari/%@ %@", Safari_, application];
        if (Build_ != nil)
            application = [NSString stringWithFormat:@"Mobile/%@ %@", Build_, application];
        if (Product_ != nil)
            application = [NSString stringWithFormat:@"Version/%@ %@", Product_, application];
		
        [webview setApplicationNameForUserAgent:application];
    } return self;
}

@end

