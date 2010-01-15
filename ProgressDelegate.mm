#import "ProgressDelegate.h"

/* Delegate Helpers {{{ */
@implementation NSObject(ProgressDelegate)

- (void) _setProgressErrorPackage:(NSArray *)args {
    [self performSelector:@selector(setProgressError:forPackage:)
			   withObject:[args objectAtIndex:0]
			   withObject:([args count] == 1 ? nil : [args objectAtIndex:1])
	 ];
}

- (void) _setProgressErrorTitle:(NSArray *)args {
    [self performSelector:@selector(setProgressError:withTitle:)
			   withObject:[args objectAtIndex:0]
			   withObject:([args count] == 1 ? nil : [args objectAtIndex:1])
	 ];
}

- (void) _setProgressError:(NSString *)error withTitle:(NSString *)title {
    [self performSelectorOnMainThread:@selector(_setProgressErrorTitle:)
						   withObject:[NSArray arrayWithObjects:error, title, nil]
						waitUntilDone:YES
	 ];
}

- (void) setProgressError:(NSString *)error forPackage:(NSString *)id {
    Package *package = id == nil ? nil : [[Database sharedInstance] packageWithName:id];
    // XXX: holy typecast batman!
    [(id<ProgressDelegate>)self setProgressError:error withTitle:(package == nil ? id : [package name])];
}

@end
/* }}} */