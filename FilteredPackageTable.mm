#import "FilteredPackageTable.h"


@implementation FilteredPackageTable

- (void) dealloc {
    if (object_ != nil)
        [object_ release];
    [super dealloc];
}

- (void) setObject:(id)object {
    if (object_ != nil)
        [object_ release];
    if (object == nil)
        object_ = nil;
    else
        object_ = [object retain];
}

- (bool) hasPackage:(Package *)package {
    _profile(FilteredPackageTable$hasPackage)
	return [package valid] && (*reinterpret_cast<bool (*)(id, SEL, id)>(imp_))(package, filter_, object_);
    _end
}

- (id) initWithBook:(RVBook *)book database:(Database *)database title:(NSString *)title filter:(SEL)filter with:(id)object {
    if ((self = [super initWithBook:book database:database title:title]) != nil) {
        filter_ = filter;
        object_ = object == nil ? nil : [object retain];
		
        /* XXX: this is an unsafe optimization of doomy hell */
        Method method(class_getInstanceMethod([Package class], filter));
        _assert(method != NULL);
        imp_ = method_getImplementation(method);
        _assert(imp_ != NULL);
		
        [self reloadData];
    } return self;
}

@end
/* }}} */
