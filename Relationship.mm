#import "Relationship.h"
@implementation Relationship

- (void) dealloc {
    [type_ release];
    [id_ release];
    [super dealloc];
}

- (NSString *) type {
    return type_;
}

- (NSString *) id {
    return id_;
}

- (NSString *) name {
    _assert(false);
    return nil;
}

@end