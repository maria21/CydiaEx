#import "SectionsView.h"

#import "PackageTable.h"
#import "FilteredPackageTable.h"

@implementation SectionsView

- (void) dealloc {
    [list_ setDataSource:nil];
    [list_ setDelegate:nil];
	
    [sections_ release];
    [filtered_ release];
    [transition_ release];
    [list_ release];
    [accessory_ release];
    [super dealloc];
}

- (int) numberOfRowsInTable:(UITable *)table {
    return editing_ ? [sections_ count] : [filtered_ count] + 1;
}

- (float) table:(UITable *)table heightForRow:(int)row {
    return 45;
}

- (UITableCell *) table:(UITable *)table cellForRow:(int)row column:(UITableColumn *)col reusing:(UITableCell *)reusing {
    if (reusing == nil)
        reusing = [[[SectionCell alloc] init] autorelease];
    [(SectionCell *)reusing setSection:(editing_ ?
										[sections_ objectAtIndex:row] :
										(row == 0 ? nil : [filtered_ objectAtIndex:(row - 1)])
										) editing:editing_];
    return reusing;
}

- (BOOL) table:(UITable *)table showDisclosureForRow:(int)row {
    return !editing_;
}

- (BOOL) table:(UITable *)table canSelectRow:(int)row {
    return !editing_;
}

- (void) tableRowSelected:(NSNotification *)notification {
    int row = [[notification object] selectedRow];
    if (row == INT_MAX)
        return;
	
    Section *section;
    NSString *name;
    NSString *title;
	
    if (row == 0) {
        section = nil;
        name = nil;
        title = UCLocalize("ALL_PACKAGES");
    } else {
        section = [filtered_ objectAtIndex:(row - 1)];
        name = [section name];
		
        if (name != nil) {
            name = [NSString stringWithString:name];
            title = [[NSBundle mainBundle] localizedStringForKey:Simplify(name) value:nil table:@"Sections"];
        } else {
            name = @"";
            title = UCLocalize("NO_SECTION");
        }
    }
	
    PackageTable *table = [[[FilteredPackageTable alloc]
							initWithBook:book_
							database:database_
							title:title
							filter:@selector(isVisibleInSection:)
							with:name
							] autorelease];
	
    [table setDelegate:delegate_];
	
    [book_ pushPage:table];
}

- (id) initWithBook:(RVBook *)book database:(Database *)database {
    if ((self = [super initWithBook:book]) != nil) {
        database_ = database;
		
        sections_ = [[NSMutableArray arrayWithCapacity:16] retain];
        filtered_ = [[NSMutableArray arrayWithCapacity:16] retain];
		
        transition_ = [[UITransitionView alloc] initWithFrame:[self bounds]];
        [self addSubview:transition_];
		
        list_ = [[UITable alloc] initWithFrame:[transition_ bounds]];
        [transition_ transition:0 toView:list_];
		
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
		
        [self reloadData];
		
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [list_ setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    } return self;
}

- (void) reloadData {
    NSArray *packages = [database_ packages];
	
    [sections_ removeAllObjects];
    [filtered_ removeAllObjects];
	
#if 0
    typedef __gnu_cxx::hash_map<NSString *, Section *, NSStringMapHash, NSStringMapEqual> SectionMap;
    SectionMap sections;
    sections.resize(64);
#else
    NSMutableDictionary *sections([NSMutableDictionary dictionaryWithCapacity:32]);
#endif
	
    _trace();
    for (Package *package in packages) {
        NSString *name([package section]);
        NSString *key(name == nil ? @"" : name);
		
#if 0
        Section **section;
		
        _profile(SectionsView$reloadData$Section)
		section = &sections[key];
		if (*section == nil) {
			_profile(SectionsView$reloadData$Section$Allocate)
			*section = [[[Section alloc] initWithName:name localize:YES] autorelease];
			_end
		}
        _end
		
        [*section addToCount];
		
        _profile(SectionsView$reloadData$Filter)
		if (![package valid] || ![package visible])
			continue;
        _end
		
        [*section addToRow];
#else
        Section *section;
		
        _profile(SectionsView$reloadData$Section)
		section = [sections objectForKey:key];
		if (section == nil) {
			_profile(SectionsView$reloadData$Section$Allocate)
			section = [[[Section alloc] initWithName:name localize:YES] autorelease];
			[sections setObject:section forKey:key];
			_end
		}
        _end
		
        [section addToCount];
		
        _profile(SectionsView$reloadData$Filter)
		if (![package valid] || ![package visible])
			continue;
        _end
		
        [section addToRow];
#endif
    }
    _trace();
	
#if 0
    for (SectionMap::const_iterator i(sections.begin()), e(sections.end()); i != e; ++i)
        [sections_ addObject:i->second];
#else
    [sections_ addObjectsFromArray:[sections allValues]];
#endif
	
    [sections_ sortUsingSelector:@selector(compareByLocalized:)];
	
    for (Section *section in sections_) {
        size_t count([section row]);
        if (count == 0)
            continue;
		
        section = [[[Section alloc] initWithName:[section name] localized:[section localized]] autorelease];
        [section setCount:count];
        [filtered_ addObject:section];
    }
	
    [list_ reloadData];
    _trace();
}

- (void) resetView {
    if (editing_)
        [self _rightButtonClicked];
}

- (void) resetViewAnimated:(BOOL)animated {
    [list_ resetViewAnimated:animated];
}

- (void) _rightButtonClicked {
    if ((editing_ = !editing_))
        [list_ reloadData];
    else
        [delegate_ updateData];
    [book_ reloadTitleForPage:self];
    [book_ reloadButtonsForPage:self];
}

- (NSString *) title {
    return editing_ ? UCLocalize("SECTION_VISIBILITY") : UCLocalize("SECTIONS");
}

- (NSString *) backButtonTitle {
    return UCLocalize("SECTIONS");
}

- (id) rightButtonTitle {
    return [sections_ count] == 0 ? nil : editing_ ? UCLocalize("DONE") : UCLocalize("EDIT");
}

- (UINavigationButtonStyle) rightButtonStyle {
    return editing_ ? UINavigationButtonStyleHighlighted : UINavigationButtonStyleNormal;
}

- (UIView *) accessoryView {
    return accessory_;
}

@end
/* }}} */
