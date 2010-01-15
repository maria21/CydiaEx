#import "InstalledView.h"


@implementation InstalledView

- (void) dealloc {
    [packages_ release];
    [super dealloc];
}

- (id) initWithBook:(RVBook *)book database:(Database *)database {
    if ((self = [super initWithBook:book]) != nil) {
        database_ = database;
		
        packages_ = [[FilteredPackageTable alloc]
					 initWithBook:book
					 database:database
					 title:nil
					 filter:@selector(isInstalledAndVisible:)
					 with:[NSNumber numberWithBool:YES]
					 ];
		
        [self addSubview:packages_];
		
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [packages_ setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    } return self;
}

- (void) resetViewAnimated:(BOOL)animated {
    [packages_ resetViewAnimated:animated];
}

- (void) reloadData {
    [packages_ reloadData];
}

- (void) _rightButtonClicked {
    [packages_ setObject:[NSNumber numberWithBool:expert_]];
    [packages_ reloadData];
    expert_ = !expert_;
    [book_ reloadButtonsForPage:self];
}

- (NSString *) title {
    return UCLocalize("INSTALLED");
}

- (NSString *) backButtonTitle {
    return UCLocalize("PACKAGES");
}

- (id) rightButtonTitle {
    return Role_ != nil && [Role_ isEqualToString:@"Developer"] ? nil : expert_ ? UCLocalize("EXPERT") : UCLocalize("SIMPLE");
}

- (UINavigationButtonStyle) rightButtonStyle {
    return expert_ ? UINavigationButtonStyleHighlighted : UINavigationButtonStyleNormal;
}

- (void) setDelegate:(id)delegate {
    [super setDelegate:delegate];
    [packages_ setDelegate:delegate];
}

@end
/* }}} */
