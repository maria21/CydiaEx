#import "FileTable.h"

@implementation FileTable

- (void) dealloc {
    if (package_ != nil)
        [package_ release];
    if (name_ != nil)
        [name_ release];
    [files_ release];
    [list_ release];
    [super dealloc];
}

- (int) tableView:(UITableView *)tableView numberOfRowsInSection:(int)section {
    return files_ == nil ? 0 : [files_ count];
}

- (float) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 24;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseIdentifier] autorelease];
        UIFont *font = [UIFont systemFontOfSize:16];
        [cell setFont:font];
    }
    [cell setText:[files_ objectAtIndex:indexPath.row]];
	[cell setSelectionStyle:0 /*UITableViewCellSelectionStyleNone*/];
    return cell;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database {
    if ((self = [super initWithBook:book]) != nil) {
        database_ = database;
		
        files_ = [[NSMutableArray arrayWithCapacity:32] retain];
		
        list_ = [[UITableView alloc] initWithFrame:[self bounds]];
        [self addSubview:list_];
				
        [list_ setDataSource:self];
        [list_ setDelegate:self];
    } return self;
}

- (void) setPackage:(Package *)package {
    if (package_ != nil) {
        [package_ autorelease];
        package_ = nil;
    }
	
    if (name_ != nil) {
        [name_ release];
        name_ = nil;
    }
	
    [files_ removeAllObjects];
	
    if (package != nil) {
        package_ = [package retain];
        name_ = [[package id] retain];
		
        if (NSArray *files = [package files])
            [files_ addObjectsFromArray:files];
		
        if ([files_ count] != 0) {
            if ([[files_ objectAtIndex:0] isEqualToString:@"/."])
                [files_ removeObjectAtIndex:0];
            [files_ sortUsingSelector:@selector(compareByPath:)];
			
            NSMutableArray *stack = [NSMutableArray arrayWithCapacity:8];
            [stack addObject:@"/"];
			
            for (int i(0), e([files_ count]); i != e; ++i) {
                NSString *file = [files_ objectAtIndex:i];
                while (![file hasPrefix:[stack lastObject]])
                    [stack removeLastObject];
                NSString *directory = [stack lastObject];
                [stack addObject:[file stringByAppendingString:@"/"]];
                [files_ replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@"%*s%@",
														   ([stack count] - 2) * 3, "",
														   [file substringFromIndex:[directory length]]
														   ]];
            }
        }
    }
	
    [list_ reloadData];
}

- (void) resetViewAnimated:(BOOL)animated {
    [list_ resetViewAnimated:animated];
}

- (void) reloadData {
    [self setPackage:[database_ packageWithName:name_]];
    [self reloadButtons];
}

- (NSString *) title {
    return UCLocalize("INSTALLED_FILES");
}

- (NSString *) backButtonTitle {
    return UCLocalize("FILES");
}

@end
/* }}} */
