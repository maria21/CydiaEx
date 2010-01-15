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

- (int) numberOfRowsInTable:(UITable *)table {
    return files_ == nil ? 0 : [files_ count];
}

- (float) table:(UITable *)table heightForRow:(int)row {
    return 24;
}

- (UITableCell *) table:(UITable *)table cellForRow:(int)row column:(UITableColumn *)col reusing:(UITableCell *)reusing {
    if (reusing == nil) {
        reusing = [[[UIImageAndTextTableCell alloc] init] autorelease];
        UIFont *font = [UIFont systemFontOfSize:16];
        [[(UIImageAndTextTableCell *)reusing titleTextLabel] setFont:font];
    }
    [(UIImageAndTextTableCell *)reusing setTitle:[files_ objectAtIndex:row]];
    return reusing;
}

- (BOOL) table:(UITable *)table canSelectRow:(int)row {
    return NO;
}

- (id) initWithBook:(RVBook *)book database:(Database *)database {
    if ((self = [super initWithBook:book]) != nil) {
        database_ = database;
		
        files_ = [[NSMutableArray arrayWithCapacity:32] retain];
		
        list_ = [[UITable alloc] initWithFrame:[self bounds]];
        [self addSubview:list_];
		
        UITableColumn *column = [[[UITableColumn alloc]
								  initWithTitle:UCLocalize("NAME")
								  identifier:@"name"
								  width:[self frame].size.width
								  ] autorelease];
		
        [list_ setDataSource:self];
        [list_ setSeparatorStyle:1];
        [list_ addTableColumn:column];
        [list_ setDelegate:self];
        [list_ setReusesTableCells:YES];
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
