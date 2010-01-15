#import "AddSourceView.h"

@implementation AddSourceView

- (id) initWithBook:(RVBook *)book database:(Database *)database {
    if ((self = [super initWithBook:book]) != nil) {
        database_ = database;
    } return self;
}

@end
/* }}} */