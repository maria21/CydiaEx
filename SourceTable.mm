#import "SourceTable.h"
#import "PackageTable.h"
#import "FilteredPackageTable.h"

@implementation SourceTable

- (void) _deallocConnection:(NSURLConnection *)connection {
    if (connection != nil) {
        [connection cancel];
        //[connection setDelegate:nil];
        [connection release];
    }
}

- (void) dealloc {
    [[list_ table] setDelegate:nil];
    [list_ setDataSource:nil];
	
    if (href_ != nil)
        [href_ release];
    if (hud_ != nil)
        [hud_ release];
    if (error_ != nil)
        [error_ release];
	
    //[self _deallocConnection:installer_];
    [self _deallocConnection:trivial_];
    [self _deallocConnection:trivial_gz_];
    [self _deallocConnection:trivial_bz2_];
    //[self _deallocConnection:automatic_];
	
    [sources_ release];
    [list_ release];
    [super dealloc];
}

- (int) numberOfSectionsInSectionList:(UISectionList *)list {
    return offset_ == 0 ? 1 : 2;
}

- (NSString *) sectionList:(UISectionList *)list titleForSection:(int)section {
    switch (section + (offset_ == 0 ? 1 : 0)) {
        case 0: return UCLocalize("ENTERED_BY_USER");
        case 1: return UCLocalize("INSTALLED_BY_PACKAGE");
			
			_nodefault
    }
}

- (int) sectionList:(UISectionList *)list rowForSection:(int)section {
    switch (section + (offset_ == 0 ? 1 : 0)) {
        case 0: return 0;
        case 1: return offset_;
			
			_nodefault
    }
}

- (int) numberOfRowsInTable:(UITable *)table {
    return [sources_ count];
}

- (float) table:(UITable *)table heightForRow:(int)row {
    Source *source = [sources_ objectAtIndex:row];
    return [source description] == nil ? 56 : 73;
}

- (UITableCell *) table:(UITable *)table cellForRow:(int)row column:(UITableColumn *)col {
    Source *source = [sources_ objectAtIndex:row];
    // XXX: weird warning, stupid selectors ;P
    return [[[SourceCell alloc] initWithSource:(id)source] autorelease];
}

- (BOOL) table:(UITable *)table showDisclosureForRow:(int)row {
    return YES;
}

- (BOOL) table:(UITable *)table canSelectRow:(int)row {
    return YES;
}

- (void) tableRowSelected:(NSNotification*)notification {
    UITable *table([list_ table]);
    int row([table selectedRow]);
    if (row == INT_MAX)
        return;
	
    Source *source = [sources_ objectAtIndex:row];
	
    PackageTable *packages = [[[FilteredPackageTable alloc]
							   initWithBook:book_
							   database:database_
							   title:[source label]
							   filter:@selector(isVisibleInSource:)
							   with:source
							   ] autorelease];
	
    [packages setDelegate:delegate_];
	
    [book_ pushPage:packages];
}

- (BOOL) table:(UITable *)table canDeleteRow:(int)row {
    Source *source = [sources_ objectAtIndex:row];
    return [source record] != nil;
}

- (void) table:(UITable *)table willSwipeToDeleteRow:(int)row {
    [[list_ table] setDeleteConfirmationRow:row];
}

- (void) table:(UITable *)table deleteRow:(int)row {
    Source *source = [sources_ objectAtIndex:row];
    [Sources_ removeObjectForKey:[source key]];
    [delegate_ syncData];
}

- (void) complete {
    [Sources_ setObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 @"deb", @"Type",
						 href_, @"URI",
						 @"./", @"Distribution",
						 nil] forKey:[NSString stringWithFormat:@"deb:%@:./", href_]];
	
    [delegate_ syncData];
}

- (NSString *) getWarning {
    NSString *href(href_);
    NSRange colon([href rangeOfString:@"://"]);
    if (colon.location != NSNotFound)
        href = [href substringFromIndex:(colon.location + 3)];
    href = [href stringByAddingPercentEscapes];
    href = [CydiaURL(@"api/repotag/") stringByAppendingString:href];
    href = [href stringByCachingURLWithCurrentCDN];
	
    NSURL *url([NSURL URLWithString:href]);
	
    NSStringEncoding encoding;
    NSError *error(nil);
	
    if (NSString *warning = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:&error])
        return [warning length] == 0 ? nil : warning;
    return nil;
}

- (void) _endConnection:(NSURLConnection *)connection {
    NSURLConnection **field = NULL;
    if (connection == trivial_)
        field = &trivial_;
    else if (connection == trivial_bz2_)
        field = &trivial_bz2_;
    else if (connection == trivial_gz_)
        field = &trivial_gz_;
    _assert(field != NULL);
    [connection release];
    *field = nil;
	
    if (
        trivial_ == nil &&
        trivial_bz2_ == nil &&
        trivial_gz_ == nil
		) {
        bool defer(false);
		
        if (cydia_) {
            if (NSString *warning = [self yieldToSelector:@selector(getWarning)]) {
                defer = true;
				
                UIActionSheet *sheet = [[[UIActionSheet alloc]
										 initWithTitle:UCLocalize("SOURCE_WARNING")
										 buttons:[NSArray arrayWithObjects:UCLocalize("ADD_ANYWAY"), UCLocalize("CANCEL"), nil]
										 defaultButtonIndex:0
										 delegate:self
										 context:@"warning"
										 ] autorelease];
				
                [sheet setNumberOfRows:1];
				
                [sheet setBodyText:warning];
                [sheet popupAlertAnimated:YES];
            } else
                [self complete];
        } else if (error_ != nil) {
            UIActionSheet *sheet = [[[UIActionSheet alloc]
									 initWithTitle:UCLocalize("VERIFICATION_ERROR")
									 buttons:[NSArray arrayWithObjects:UCLocalize("OK"), nil]
									 defaultButtonIndex:0
									 delegate:self
									 context:@"urlerror"
									 ] autorelease];
			
            [sheet setBodyText:[error_ localizedDescription]];
            [sheet popupAlertAnimated:YES];
        } else {
            UIActionSheet *sheet = [[[UIActionSheet alloc]
									 initWithTitle:UCLocalize("NOT_REPOSITORY")
									 buttons:[NSArray arrayWithObjects:UCLocalize("OK"), nil]
									 defaultButtonIndex:0
									 delegate:self
									 context:@"trivial"
									 ] autorelease];
			
            [sheet setBodyText:UCLocalize("NOT_REPOSITORY_EX")];
            [sheet popupAlertAnimated:YES];
        }
		
        [delegate_ setStatusBarShowsProgress:NO];
        [delegate_ removeProgressHUD:hud_];
		
        [hud_ autorelease];
        hud_ = nil;
		
        if (!defer) {
            [href_ release];
            href_ = nil;
        }
		
        if (error_ != nil) {
            [error_ release];
            error_ = nil;
        }
    }
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    switch ([response statusCode]) {
        case 200:
            cydia_ = YES;
    }
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    lprintf("connection:\"%s\" didFailWithError:\"%s\"", [href_ UTF8String], [[error localizedDescription] UTF8String]);
    if (error_ != nil)
        error_ = [error retain];
    [self _endConnection:connection];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [self _endConnection:connection];
}

- (NSURLConnection *) _requestHRef:(NSString *)href method:(NSString *)method {
    NSMutableURLRequest *request = [NSMutableURLRequest
									requestWithURL:[NSURL URLWithString:href]
									cachePolicy:NSURLRequestUseProtocolCachePolicy
									timeoutInterval:20.0
									];
	
    [request setHTTPMethod:method];
	
    if (Machine_ != NULL)
        [request setValue:[NSString stringWithUTF8String:Machine_] forHTTPHeaderField:@"X-Machine"];
    if (UniqueID_ != nil)
        [request setValue:UniqueID_ forHTTPHeaderField:@"X-Unique-ID"];
	
    if (Role_ != nil)
        [request setValue:Role_ forHTTPHeaderField:@"X-Role"];
	
    return [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
}

- (void) alertSheet:(UIActionSheet *)sheet buttonClicked:(int)button {
    NSString *context([sheet context]);
	
    if ([context isEqualToString:@"source"]) {
        switch (button) {
            case 1: {
                NSString *href = [[sheet textField] text];
				
                //installer_ = [[self _requestHRef:href method:@"GET"] retain];
				
                if (![href hasSuffix:@"/"])
                    href_ = [href stringByAppendingString:@"/"];
                else
                    href_ = href;
                href_ = [href_ retain];
				
                trivial_ = [[self _requestHRef:[href_ stringByAppendingString:@"Packages"] method:@"HEAD"] retain];
                trivial_bz2_ = [[self _requestHRef:[href_ stringByAppendingString:@"Packages.bz2"] method:@"HEAD"] retain];
                trivial_gz_ = [[self _requestHRef:[href_ stringByAppendingString:@"Packages.gz"] method:@"HEAD"] retain];
                //trivial_bz2_ = [[self _requestHRef:[href stringByAppendingString:@"dists/Release"] method:@"HEAD"] retain];
				
                cydia_ = false;
				
                hud_ = [[delegate_ addProgressHUD] retain];
                [hud_ setText:UCLocalize("VERIFYING_URL")];
            } break;
				
            case 2:
				break;
				
				_nodefault
        }
		
        [sheet dismiss];
    } else if ([context isEqualToString:@"trivial"])
        [sheet dismiss];
    else if ([context isEqualToString:@"urlerror"])
        [sheet dismiss];
    else if ([context isEqualToString:@"warning"]) {
        switch (button) {
            case 1:
                [self complete];
				break;
				
            case 2:
				break;
				
				_nodefault
        }
		
        [href_ release];
        href_ = nil;
		
        [sheet dismiss];
    }
}

- (id) initWithBook:(RVBook *)book database:(Database *)database {
    if ((self = [super initWithBook:book]) != nil) {
        database_ = database;
        sources_ = [[NSMutableArray arrayWithCapacity:16] retain];
		
        //list_ = [[UITable alloc] initWithFrame:[self bounds]];
        list_ = [[UISectionList alloc] initWithFrame:[self bounds] showSectionIndex:NO];
        [list_ setShouldHideHeaderInShortLists:NO];
		
        [self addSubview:list_];
        [list_ setDataSource:self];
		
        UITableColumn *column = [[UITableColumn alloc]
								 initWithTitle:UCLocalize("NAME")
								 identifier:@"name"
								 width:[self frame].size.width
								 ];
		
        UITable *table = [list_ table];
        [table setSeparatorStyle:1];
        [table addTableColumn:column];
        [table setDelegate:self];
		
        [self reloadData];
		
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [list_ setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    } return self;
}

- (void) reloadData {
    pkgSourceList list;
    if (!list.ReadMainList())
        return;
	
    [sources_ removeAllObjects];
    [sources_ addObjectsFromArray:[database_ sources]];
    _trace();
    [sources_ sortUsingSelector:@selector(compareByNameAndType:)];
    _trace();
	
    int count([sources_ count]);
    for (offset_ = 0; offset_ != count; ++offset_) {
        Source *source = [sources_ objectAtIndex:offset_];
        if ([source record] == nil)
            break;
    }
	
    [list_ reloadData];
}

- (void) resetViewAnimated:(BOOL)animated {
    [list_ resetViewAnimated:animated];
}

- (void) _leftButtonClicked {
    /*[book_ pushPage:[[[AddSourceView alloc]
	 initWithBook:book_
	 database:database_
	 ] autorelease]];*/
	
    UIActionSheet *sheet = [[[UIActionSheet alloc]
							 initWithTitle:UCLocalize("ENTER_APT_URL")
							 buttons:[NSArray arrayWithObjects:UCLocalize("ADD_SOURCE"), UCLocalize("CANCEL"), nil]
							 defaultButtonIndex:0
							 delegate:self
							 context:@"source"
							 ] autorelease];
	
    [sheet setNumberOfRows:1];
	
    [sheet addTextFieldWithValue:@"http://" label:@""];
	
    UITextInputTraits *traits = [[sheet textField] textInputTraits];
    [traits setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [traits setAutocorrectionType:UITextAutocorrectionTypeNo];
    [traits setKeyboardType:UIKeyboardTypeURL];
    // XXX: UIReturnKeyDone
    [traits setReturnKeyType:UIReturnKeyNext];
	
    [sheet popupAlertAnimated:YES];
}

- (void) _rightButtonClicked {
    UITable *table = [list_ table];
    BOOL editing = [table isRowDeletionEnabled];
    [table enableRowDeletion:!editing animated:YES];
    [book_ reloadButtonsForPage:self];
}

- (NSString *) title {
    return UCLocalize("SOURCES");
}

- (NSString *) leftButtonTitle {
    return [[list_ table] isRowDeletionEnabled] ? UCLocalize("ADD") : nil;
}

- (id) rightButtonTitle {
    return [[list_ table] isRowDeletionEnabled] ? UCLocalize("DONE") : UCLocalize("EDIT");
}

- (UINavigationButtonStyle) rightButtonStyle {
    return [[list_ table] isRowDeletionEnabled] ? UINavigationButtonStyleHighlighted : UINavigationButtonStyleNormal;
}

@end
/* }}} */
