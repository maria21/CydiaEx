#import "PackageTable.h"


@implementation PackageTable

- (void) dealloc {
    [list_ setDataSource:nil];
	
    [title_ release];
    [packages_ release];
    [sections_ release];
    [list_ release];
    [index_ release];
    [indices_ release];
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
    Package *package([packages_ objectAtIndex:([section row] + row)]);
    return package;
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
    package = [database_ packageWithName:[package id]];
    PackageView *view([delegate_ packageView]);
    [view setPackage:package];
    [view setDelegate:delegate_];
    [book_ pushPage:view];
    return path;
}

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [packages_ count] > 20 ? index_ : nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database title:(NSString *)title {
    if ((self = [super initWithBook:book]) != nil) {
        database_ = database;
        title_ = [title retain];
		
        index_ = [[NSMutableArray alloc] initWithCapacity:32];
        indices_ = [[NSMutableDictionary alloc] initWithCapacity:32];
		
        packages_ = [[NSMutableArray arrayWithCapacity:16] retain];
        sections_ = [[NSMutableArray arrayWithCapacity:16] retain];
		
        list_ = [[UITableView alloc] initWithFrame:[self bounds] style:UITableViewStylePlain];
        [list_ setDataSource:self];
        [list_ setDelegate:self];
		
        [self addSubview:list_];
		
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [list_ setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    } return self;
}

- (void) setDelegate:(id)delegate {
    delegate_ = delegate;
}

- (bool) hasPackage:(Package *)package {
    return true;
}

- (void) reloadData {
    NSArray *packages = [database_ packages];
	
    [packages_ removeAllObjects];
    [sections_ removeAllObjects];
	
    _profile(PackageTable$reloadData$Filter)
	for (Package *package in packages)
		if ([self hasPackage:package])
			[packages_ addObject:package];
    _end
	
    [index_ removeAllObjects];
    [indices_ removeAllObjects];
	
    Section *section = nil;
	
    _profile(PackageTable$reloadData$Section)
	for (size_t offset(0), end([packages_ count]); offset != end; ++offset) {
		Package *package;
		unichar index;
		
		_profile(PackageTable$reloadData$Section$Package)
		package = [packages_ objectAtIndex:offset];
		index = [package index];
		_end
		
		if (section == nil || [section index] != index) {
			_profile(PackageTable$reloadData$Section$Allocate)
			section = [[[Section alloc] initWithIndex:index row:offset] autorelease];
			_end
			
			[index_ addObject:[section name]];
			//[indices_ setObject:[NSNumber numberForInt:[sections_ count]] forKey:index];
			
			_profile(PackageTable$reloadData$Section$Add)
			[sections_ addObject:section];
			_end
		}
		
		[section addToCount];
	}
    _end
	
    _profile(PackageTable$reloadData$List)
	[list_ reloadData];
    _end
}

- (NSString *) title {
    return title_;
}

- (void) resetViewAnimated:(BOOL)animated {
    [list_ resetViewAnimated:animated];
}

- (void) resetCursor {
    [list_ scrollRectToVisible:CGRectMake(0, 0, 0, 0) animated:NO];
}

- (UITableView *) list {
    return list_;
}

- (void) setShouldHideHeaderInShortLists:(BOOL)hide {
    //XXX:[list_ setShouldHideHeaderInShortLists:hide];
}

@end
/* }}} */
