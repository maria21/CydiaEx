#import "SettingsView.h"


@implementation SettingsView

- (void) dealloc {
    [table_ setDataSource:nil];
	
    [name_ release];
    if (package_ != nil)
        [package_ release];
    [table_ release];
    [subscribedSwitch_ release];
    [ignoredSwitch_ release];
    [subscribedCell_ release];
    [ignoredCell_ release];
    [super dealloc];
}

- (int) numberOfGroupsInPreferencesTable:(UIPreferencesTable *)table {
    if (package_ == nil)
        return 0;
	
    return 2;
}

- (NSString *) preferencesTable:(UIPreferencesTable *)table titleForGroup:(int)group {
    if (package_ == nil)
        return nil;
	
    switch (group) {
        case 0: return nil;
        case 1: return nil;
			
			_nodefault
    }
	
    return nil;
}

- (BOOL) preferencesTable:(UIPreferencesTable *)table isLabelGroup:(int)group {
    if (package_ == nil)
        return NO;
	
    switch (group) {
        case 0: return NO;
        case 1: return YES;
			
			_nodefault
    }
	
    return NO;
}

- (int) preferencesTable:(UIPreferencesTable *)table numberOfRowsInGroup:(int)group {
    if (package_ == nil)
        return 0;
	
    switch (group) {
        case 0: return 1;
        case 1: return 1;
			
			_nodefault
    }
	
    return 0;
}

- (void) onSomething:(UIPreferencesControlTableCell *)cell withKey:(NSString *)key {
    if (package_ == nil)
        return;
	
    _UISwitchSlider *slider([cell control]);
    BOOL value([slider value] != 0);
    NSMutableDictionary *metadata([package_ metadata]);
	
    BOOL before;
    if (NSNumber *number = [metadata objectForKey:key])
        before = [number boolValue];
    else
        before = NO;
	
    if (value != before) {
        [metadata setObject:[NSNumber numberWithBool:value] forKey:key];
        Changed_ = true;
        [delegate_ updateData];
    }
}

- (void) onSubscribed:(UIPreferencesControlTableCell *)cell {
    [self onSomething:cell withKey:@"IsSubscribed"];
}

- (void) onIgnored:(UIPreferencesControlTableCell *)cell {
    [self onSomething:cell withKey:@"IsIgnored"];
}

- (id) preferencesTable:(UIPreferencesTable *)table cellForRow:(int)row inGroup:(int)group {
    if (package_ == nil)
        return nil;
	
    switch (group) {
        case 0: switch (row) {
            case 0:
                return subscribedCell_;
            case 1:
                return ignoredCell_;
				_nodefault
        } break;
			
        case 1: switch (row) {
            case 0: {
                UIPreferencesControlTableCell *cell([[[UIPreferencesControlTableCell alloc] init] autorelease]);
                [cell setShowSelection:NO];
                [cell setTitle:UCLocalize("SHOW_ALL_CHANGES_EX")];
                return cell;
            }
				
				_nodefault
        } break;
			
			_nodefault
    }
	
    return nil;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database package:(NSString *)package {
    if ((self = [super initWithBook:book])) {
        database_ = database;
        name_ = [package retain];
		
        table_ = [[UIPreferencesTable alloc] initWithFrame:[self bounds]];
        [self addSubview:table_];
		
        subscribedSwitch_ = [[_UISwitchSlider alloc] initWithFrame:CGRectMake(200, 10, 50, 20)];
        [subscribedSwitch_ addTarget:self action:@selector(onSubscribed:) forEvents:UIControlEventTouchUpInside];
		
        ignoredSwitch_ = [[_UISwitchSlider alloc] initWithFrame:CGRectMake(200, 10, 50, 20)];
        [ignoredSwitch_ addTarget:self action:@selector(onIgnored:) forEvents:UIControlEventTouchUpInside];
		
        subscribedCell_ = [[UIPreferencesControlTableCell alloc] init];
        [subscribedCell_ setShowSelection:NO];
        [subscribedCell_ setTitle:UCLocalize("SHOW_ALL_CHANGES")];
        [subscribedCell_ setControl:subscribedSwitch_];
		
        ignoredCell_ = [[UIPreferencesControlTableCell alloc] init];
        [ignoredCell_ setShowSelection:NO];
        [ignoredCell_ setTitle:UCLocalize("IGNORE_UPGRADES")];
        [ignoredCell_ setControl:ignoredSwitch_];
		
        [table_ setDataSource:self];
        [self reloadData];
    } return self;
}

- (void) resetViewAnimated:(BOOL)animated {
    [table_ resetViewAnimated:animated];
}

- (void) reloadData {
    if (package_ != nil)
        [package_ autorelease];
    package_ = [database_ packageWithName:name_];
    if (package_ != nil) {
        [package_ retain];
        [subscribedSwitch_ setValue:([package_ subscribed] ? 1 : 0) animated:NO];
        [ignoredSwitch_ setValue:([package_ ignored] ? 1 : 0) animated:NO];
    }
	
    [table_ reloadData];
}

- (NSString *) title {
    return UCLocalize("SETTINGS");
}

@end
/* }}} */
