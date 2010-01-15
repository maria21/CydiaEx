#import "Cydia.h"

/* Mime Addresses {{{ */
@interface Address : NSObject {
    NSString *name_;
    NSString *address_;
}

- (NSString *) name;
- (NSString *) address;

- (void) setAddress:(NSString *)address;

+ (Address *) addressWithString:(NSString *)string;
- (Address *) initWithString:(NSString *)string;
@end
