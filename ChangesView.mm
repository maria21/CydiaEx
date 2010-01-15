#import "ChangesView.h"

@implementation ChangesView

- (void) dealloc {
    [list_ setDelegate:nil];
    [list_ setDataSource:nil];
	
    [packages_ release];
    [sections_ release];
    [list_ release];
    [super dealloc];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)list {
    NSInteger count([sections_ count]);
    return count == 0 ? 1 : count;
}

- (NSString *) tableView:(UITableView *)list titleForHeaderInSection:(NSInteger)section {
    if ([sections_ count] == 0)
        return nil;
    return [[sections_ objectAtIndex:section] name];
}

- (NSInteger) tableView:(UITableView *)list numberOfRowsInSection:(NSInteger)section {
    if ([sections_ count] == 0)
        return 0;
    return [[sections_ objectAtIndex:section] count];
}

- (Package *) packageAtIndexPath:(NSIndexPath *)path {
    Section *section([sections_ objectAtIndex:[path section]]);
    NSInteger row([path row]);
    return [packages_ objectAtIndex:([section row] + row)];
}

- (UITableViewCell *) tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
    PackageCell *cell([table dequeueReusableCellWithIdentifier:@"Package"]);
    if (cell == nil)
        cell = [[[PackageCell alloc] init] autorelease];
    [cell setPackage:[self packageAtIndexPath:path]];
    return cell;
}

- (CGFloat) tableView:(UITableView *)table heightForRowAtIndexPath:(NSIndexPath *)path {
    return 73;
    return [PackageCell heightForPackage:[self packageAtIndexPath:path]];
}

- (NSIndexPath *) tableView:(UITableView *)table willSelectRowAtIndexPath:(NSIndexPath *)path {
    Package *package([self packageAtIndexPath:path]);
    PackageView *view([delegate_ packageView]);
    [view setDelegate:delegate_];
    [view setPackage:package];
    [book_ pushPage:view];
    return path;
}

- (void) _leftButtonClicked {
    [(CYBook *)book_ update];
    [self reloadButtons];
}

- (void) _rightButtonClicked {
    [delegate_ distUpgrade];
}

- (id) initWithBook:(RVBook *)book database:(Database *)database {
    if ((self = [super initWithBook:book]) != nil) {
        database_ = database;
		
        packages_ = [[NSMutableArray arrayWithCapacity:16] retain];
        sections_ = [[NSMutableArray arrayWithCapacity:16] retain];
		
        list_ = [[UITableView alloc] initWithFrame:[self bounds] style:UITableViewStylePlain];
        [self addSubview:list_];
		
        //XXX:[list_ setShouldHideHeaderInShortLists:NO];
        [list_ setDataSource:self];
        [list_ setDelegate:self];
        //[list_ setSectionListStyle:1];
		
        [self reloadData];
		
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [list_ setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    } return self;
}

- (void) reloadData {
    NSArray *packages = [database_ packages];
	
    [packages_ removeAllObjects];
    [sections_ removeAllObjects];
	
    _trace();
    for (Package *package in packages)
        if (
            [package uninstalled] && [package valid] && [package visible] ||
            [package upgradableAndEssential:YES]
			)
            [packages_ addObject:package];
	
    _trace();
    [packages_ radixSortUsingFunction:reinterpret_cast<SKRadixFunction>(&PackageChangesRadix) withContext:NULL];
    _trace();
	
    Section *upgradable = [[[Section alloc] initWithName:UCLocalize("AVAILABLE_UPGRADES") localize:NO] autorelease];
    Section *ignored = [[[Section alloc] initWithName:UCLocalize("IGNORED_UPGRADES") localize:NO] autorelease];
    Section *section = nil;
    NSDate *last = nil;
	
    upgrades_ = 0;
    bool unseens = false;
	
    CFDateFormatterRef formatter(CFDateFormatterCreate(NULL, Locale_, kCFDateFormatterMediumStyle, kCFDateFormatterMediumStyle));
	
    for (size_t offset = 0, count = [packages_ count]; offset != count; ++offset) {
        Package *package = [packages_ objectAtIndex:offset];
		
        BOOL uae = [package upgradableAndEssential:YES];
		
        if (!uae) {
            unseens = true;
            NSDate *seen;
			
            _profile(ChangesView$reloadData$Remember)
			seen = [package seen];
            _end
			
            if (section == nil || last != seen && (seen == nil || [seen compare:last] != NSOrderedSame)) {
                last = seen;
				
                NSString *name;
                if (seen == nil)
                    name = UCLocalize("UNKNOWN");
                else {
                    name = (NSString *) CFDateFormatterCreateStringWithDate(NULL, formatter, (CFDateRef) seen);
                    [name autorelease];
                }
				
                _profile(ChangesView$reloadData$Allocate)
				name = [NSString stringWithFormat:UCLocalize("NEW_AT"), name];
				section = [[[Section alloc] initWithName:name row:offset localize:NO] autorelease];
				[sections_ addObject:section];
                _end
            }
			
            [section addToCount];
        } else if ([package ignored])
            [ignored addToCount];
        else {
            ++upgrades_;
            [upgradable addToCount];
        }
    }
    _trace();
	
    CFRelease(formatter);
	
    if (unseens) {
        Section *last = [sections_ lastObject];
        size_t count = [last count];
        [packages_ removeObjectsInRange:NSMakeRange([packages_ count] - count, count)];
        [sections_ removeLastObject];
    }
	
    if ([ignored count] != 0)
        [sections_ insertObject:ignored atIndex:0];
    if (upgrades_ != 0)
        [sections_ insertObject:upgradable atIndex:0];
	
    [list_ reloadData];
    [self reloadButtons];
}

- (void) resetViewAnimated:(BOOL)animated {
    [list_ resetViewAnimated:animated];
}

- (NSString *) leftButtonTitle {
    return [(CYBook *)book_ updating] ? nil : UCLocalize("REFRESH");
}

- (id) rightButtonTitle {
    return upgrades_ == 0 ? nil : [NSString stringWithFormat:UCLocalize("PARENTHETICAL"), UCLocalize("UPGRADE"), [NSString stringWithFormat:@"%u", upgrades_]];
}

- (NSString *) title {
    return UCLocalize("CHANGES");
}

@end
/* }}} */