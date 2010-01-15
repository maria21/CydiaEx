#import "Cydia.h"

/* Web Scripting {{{ */
@interface CydiaObject : NSObject {
    id indirect_;
}

- (id) initWithDelegate:(IndirectDelegate *)indirect;
@end
