#import "Cydia.h"


/* Relationship Class {{{ */
@interface Relationship : NSObject {
    NSString *type_;
    NSString *id_;
}

- (NSString *) type;
- (NSString *) id;
- (NSString *) name;

@end
