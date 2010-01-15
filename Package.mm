#import "Package.h"

@implementation Package

- (NSString *) description {
    return [NSString stringWithFormat:@"<Package:%@>", static_cast<NSString *>(name_)];
}

- (void) dealloc {
    if (source_ != nil)
        [source_ release];
    if (section$_ != nil)
        [section$_ release];
	
    if (latest_ != nil)
        [latest_ release];
	
    if (sponsor$_ != nil)
        [sponsor$_ release];
    if (author$_ != nil)
        [author$_ release];
    if (tags_ != nil)
        [tags_ release];
    if (role_ != nil)
        [role_ release];
	
    if (relationships_ != nil)
        [relationships_ release];
    if (metadata_ != nil)
        [metadata_ release];
	
    [super dealloc];
}

+ (NSString *) webScriptNameForSelector:(SEL)selector {
    if (selector == @selector(hasTag:))
        return @"hasTag";
    else
        return nil;
}

+ (BOOL) isSelectorExcludedFromWebScript:(SEL)selector {
    return [self webScriptNameForSelector:selector] == nil;
}

+ (NSArray *) _attributeKeys {
    return [NSArray arrayWithObjects:@"applications", @"author", @"depiction", @"longDescription", @"essential", @"homepage", @"icon", @"id", @"installed", @"latest", @"longSection", @"maintainer", @"mode", @"name", @"purposes", @"section", @"shortDescription", @"shortSection", @"simpleSection", @"size", @"source", @"sponsor", @"support", @"warnings", nil];
}

- (NSArray *) attributeKeys {
    return [[self class] _attributeKeys];
}

+ (BOOL) isKeyExcludedFromWebScript:(const char *)name {
    return ![[self _attributeKeys] containsObject:[NSString stringWithUTF8String:name]] && [super isKeyExcludedFromWebScript:name];
}

- (void) parse {
    if (parsed_)
        return;
    parsed_ = true;
    if (file_.end())
        return;
	
    _profile(Package$parse)
	pkgRecords::Parser *parser;
	
	_profile(Package$parse$Lookup)
	parser = &[database_ records]->Lookup(file_);
	_end
	
	CYString website;
	
	_profile(Package$parse$Find)
	struct {
		const char *name_;
		CYString *value_;
	} names[] = {
		{"icon", &icon_},
		{"depiction", &depiction_},
		{"homepage", &homepage_},
		{"website", &website},
		{"bugs", &bugs_},
		{"support", &support_},
		{"sponsor", &sponsor_},
		{"author", &author_},
	};
	
	for (size_t i(0); i != sizeof(names) / sizeof(names[0]); ++i) {
		const char *start, *end;
		
		if (parser->Find(names[i].name_, start, end)) {
			CYString &value(*names[i].value_);
			_profile(Package$parse$Value)
			value.set(pool_, start, end - start);
			_end
		}
	}
	_end
	
	_profile(Package$parse$Tagline)
	const char *start, *end;
	if (parser->ShortDesc(start, end)) {
		const char *stop(reinterpret_cast<const char *>(memchr(start, '\n', end - start)));
		if (stop == NULL)
			stop = end;
		while (stop != start && stop[-1] == '\r')
			--stop;
		tagline_.set(pool_, start, stop - start);
	}
	_end
	
	_profile(Package$parse$Retain)
	if (homepage_.empty())
		homepage_ = website;
	if (homepage_ == depiction_)
		homepage_.clear();
	_end
    _end
}

- (void) setVisible {
    visible_ = required_ && [self hasSupportingRole] && [self unfiltered];
}

- (Package *) initWithVersion:(pkgCache::VerIterator)version withZone:(NSZone *)zone inPool:(apr_pool_t *)pool database:(Database *)database {
    if ((self = [super init]) != nil) {
		_profile(Package$initWithVersion)
		@synchronized (database) {
			era_ = [database era];
			pool_ = pool;
			
			version_ = version;
			iterator_ = version.ParentPkg();
			database_ = database;
			
			_profile(Package$initWithVersion$Latest)
            latest_ = (NSString *) StripVersion(version_.VerStr());
			_end
			
			pkgCache::VerIterator current;
			_profile(Package$initWithVersion$Versions)
            current = iterator_.CurrentVer();
            if (!current.end())
                installed_.set(pool_, StripVersion_(current.VerStr()));
			
            if (!version_.end())
                file_ = version_.FileList();
            else {
                pkgCache &cache([database_ cache]);
                file_ = pkgCache::VerFileIterator(cache, cache.VerFileP);
            }
			_end
			
			_profile(Package$initWithVersion$Name)
            id_.set(pool_, iterator_.Name());
            name_.set(pool, iterator_.Display());
			_end
			
			if (!file_.end()) {
				_profile(Package$initWithVersion$Source)
                source_ = [database_ getSource:file_.File()];
                if (source_ != nil)
                    [source_ retain];
                cached_ = true;
				_end
			}
			
			required_ = true;
			
			_profile(Package$initWithVersion$Tags)
            pkgCache::TagIterator tag(iterator_.TagList());
            if (!tag.end()) {
                tags_ = [[NSMutableArray alloc] initWithCapacity:8];
                do {
                    const char *name(tag.Name());
                    [tags_ addObject:(NSString *)CFCString(name)];
                    if (role_ == nil && strncmp(name, "role::", 6) == 0 /*&& strcmp(name, "role::leaper") != 0*/)
                        role_ = (NSString *) CFCString(name + 6);
                    if (required_ && strncmp(name, "require::", 9) == 0 && (
																			true
																			))
                        required_ = false;
                    ++tag;
                } while (!tag.end());
            }
			_end
			
			bool changed(false);
			NSString *key([id_ lowercaseString]);
			
			_profile(Package$initWithVersion$Metadata)
            metadata_ = [Packages_ objectForKey:key];
			
            if (metadata_ == nil) {
                firstSeen_ = now_;
				
                metadata_ = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
							  firstSeen_, @"FirstSeen",
							  latest_, @"LastVersion",
							  nil] mutableCopy];
				
                changed = true;
            } else {
                firstSeen_ = [metadata_ objectForKey:@"FirstSeen"];
                lastSeen_ = [metadata_ objectForKey:@"LastSeen"];
				
                if (NSNumber *subscribed = [metadata_ objectForKey:@"IsSubscribed"])
                    subscribed_ = [subscribed boolValue];
				
                NSString *version([metadata_ objectForKey:@"LastVersion"]);
				
                if (firstSeen_ == nil) {
                    firstSeen_ = lastSeen_ == nil ? now_ : lastSeen_;
                    [metadata_ setObject:firstSeen_ forKey:@"FirstSeen"];
                    changed = true;
                }
				
                if (version == nil) {
                    [metadata_ setObject:latest_ forKey:@"LastVersion"];
                    changed = true;
                } else {
					if (![version isEqualToString:latest_]) {
						[metadata_ setObject:latest_ forKey:@"LastVersion"];
						lastSeen_ = now_;
						[metadata_ setObject:lastSeen_ forKey:@"LastSeen"];
						changed = true;
					} }
            }
			
            metadata_ = [metadata_ retain];
			
            if (changed) {
                [Packages_ setObject:metadata_ forKey:key];
                Changed_ = true;
            }
			_end
			
			_profile(Package$initWithVersion$Section)
            section_.set(pool_, iterator_.Section());
			_end
			
			essential_ = ((iterator_->Flags & pkgCache::Flag::Essential) == 0 ? NO : YES) || [self hasTag:@"cydia::essential"];
			[self setVisible];
		} _end } return self;
}

+ (Package *) packageWithIterator:(pkgCache::PkgIterator)iterator withZone:(NSZone *)zone inPool:(apr_pool_t *)pool database:(Database *)database {
	@synchronized ([Database class]) {
		pkgCache::VerIterator version;
		
		_profile(Package$packageWithIterator$GetCandidateVer)
        version = [database policy]->GetCandidateVer(iterator);
		_end
		
		if (version.end())
			return nil;
		
		return [[[Package alloc]
				 initWithVersion:version
				 withZone:zone
				 inPool:pool
				 database:database
				 ] autorelease];
	} }

- (pkgCache::PkgIterator) iterator {
    return iterator_;
}

- (NSString *) section {
    if (section$_ == nil) {
        if (section_.empty())
            return nil;
		
        std::replace(section_.data(), section_.data() + section_.size(), ' ', '_');
        NSString *name(section_);
		
	lookup:
        if (NSDictionary *value = [SectionMap_ objectForKey:name])
            if (NSString *rename = [value objectForKey:@"Rename"]) {
                name = rename;
                goto lookup;
            }
		
        section$_ = [[name stringByReplacingCharacter:'_' withCharacter:' '] retain];
    } return section$_;
}

- (NSString *) simpleSection {
    if (NSString *section = [self section])
        return Simplify(section);
    else
        return nil;
}

- (NSString *) longSection {
    return LocalizeSection([self section]);
}

- (NSString *) shortSection {
    return [[NSBundle mainBundle] localizedStringForKey:[self simpleSection] value:nil table:@"Sections"];
}

- (NSString *) uri {
    return nil;
#if 0
    pkgIndexFile *index;
    pkgCache::PkgFileIterator file(file_.File());
    if (![database_ list].FindIndex(file, index))
        return nil;
    return [NSString stringWithUTF8String:iterator_->Path];
    //return [NSString stringWithUTF8String:file.Site()];
    //return [NSString stringWithUTF8String:index->ArchiveURI(file.FileName()).c_str()];
#endif
}

- (Address *) maintainer {
    if (file_.end())
        return nil;
    pkgRecords::Parser *parser = &[database_ records]->Lookup(file_);
    const std::string &maintainer(parser->Maintainer());
    return maintainer.empty() ? nil : [Address addressWithString:[NSString stringWithUTF8String:maintainer.c_str()]];
}

- (size_t) size {
    return version_.end() ? 0 : version_->InstalledSize;
}

- (NSString *) longDescription {
    if (file_.end())
        return nil;
    pkgRecords::Parser *parser = &[database_ records]->Lookup(file_);
    NSString *description([NSString stringWithUTF8String:parser->LongDesc().c_str()]);
	
    NSArray *lines = [description componentsSeparatedByString:@"\n"];
    NSMutableArray *trimmed = [NSMutableArray arrayWithCapacity:([lines count] - 1)];
    if ([lines count] < 2)
        return nil;
	
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    for (size_t i(1), e([lines count]); i != e; ++i) {
        NSString *trim = [[lines objectAtIndex:i] stringByTrimmingCharactersInSet:whitespace];
        [trimmed addObject:trim];
    }
	
    return [trimmed componentsJoinedByString:@"\n"];
}

- (NSString *) shortDescription {
    return tagline_;
}

- (unichar) index {
    _profile(Package$index)
	CFStringRef name((CFStringRef) [self name]);
	if (CFStringGetLength(name) == 0)
		return '#';
	UniChar character(CFStringGetCharacterAtIndex(name, 0));
	if (!CFUniCharIsMemberOf(character, kCFUniCharLetterCharacterSet))
		return '#';
	return toupper(character);
    _end
}

- (NSMutableDictionary *) metadata {
    return metadata_;
}

- (NSDate *) seen {
    if (subscribed_ && lastSeen_ != nil)
        return lastSeen_;
    return firstSeen_;
}

- (BOOL) subscribed {
    return subscribed_;
}

- (BOOL) ignored {
    NSDictionary *metadata([self metadata]);
    if (NSNumber *ignored = [metadata objectForKey:@"IsIgnored"])
        return [ignored boolValue];
    else
        return false;
}

- (NSString *) latest {
    return latest_;
}

- (NSString *) installed {
    return installed_;
}

- (BOOL) uninstalled {
    return installed_.empty();
}

- (BOOL) valid {
    return !version_.end();
}

- (BOOL) upgradableAndEssential:(BOOL)essential {
    _profile(Package$upgradableAndEssential)
	pkgCache::VerIterator current(iterator_.CurrentVer());
	if (current.end())
		return essential && essential_ && visible_;
	else
		return !version_.end() && version_ != current;// && (!essential || ![database_ cache][iterator_].Keep());
    _end
}

- (BOOL) essential {
    return essential_;
}

- (BOOL) broken {
    return [database_ cache][iterator_].InstBroken();
}

- (BOOL) unfiltered {
    NSString *section([self section]);
    return section == nil || isSectionVisible(section);
}

- (BOOL) visible {
    return visible_;
}

- (BOOL) half {
    unsigned char current(iterator_->CurrentState);
    return current == pkgCache::State::HalfConfigured || current == pkgCache::State::HalfInstalled;
}

- (BOOL) halfConfigured {
    return iterator_->CurrentState == pkgCache::State::HalfConfigured;
}

- (BOOL) halfInstalled {
    return iterator_->CurrentState == pkgCache::State::HalfInstalled;
}

- (BOOL) hasMode {
    pkgDepCache::StateCache &state([database_ cache][iterator_]);
    return state.Mode != pkgDepCache::ModeKeep;
}

- (NSString *) mode {
    pkgDepCache::StateCache &state([database_ cache][iterator_]);
	
    switch (state.Mode) {
        case pkgDepCache::ModeDelete:
            if ((state.iFlags & pkgDepCache::Purge) != 0)
                return @"PURGE";
            else
                return @"REMOVE";
        case pkgDepCache::ModeKeep:
            if ((state.iFlags & pkgDepCache::ReInstall) != 0)
                return @"REINSTALL";
            /*else if ((state.iFlags & pkgDepCache::AutoKept) != 0)
			 return nil;*/
            else
                return nil;
        case pkgDepCache::ModeInstall:
            /*if ((state.iFlags & pkgDepCache::ReInstall) != 0)
			 return @"REINSTALL";
			 else*/ switch (state.Status) {
				 case -1:
					 return @"DOWNGRADE";
				 case 0:
					 return @"INSTALL";
				 case 1:
					 return @"UPGRADE";
				 case 2:
					 return @"NEW_INSTALL";
					 _nodefault
			 }
			_nodefault
    }
}

- (NSString *) id {
    return id_;
}

- (NSString *) name {
    return name_.empty() ? id_ : name_;
}

- (UIImage *) icon {
    NSString *section = [self simpleSection];
	
    UIImage *icon(nil);
    if (!icon_.empty())
        if ([icon_ hasPrefix:@"file:///"])
            icon = [UIImage imageAtPath:[icon_ substringFromIndex:7]];
    if (icon == nil) if (section != nil)
        icon = [UIImage imageAtPath:[NSString stringWithFormat:@"%@/Sections/%@.png", App_, section]];
    if (icon == nil) if (source_ != nil) if (NSString *dicon = [source_ defaultIcon])
        if ([dicon hasPrefix:@"file:///"])
            icon = [UIImage imageAtPath:[dicon substringFromIndex:7]];
    if (icon == nil)
        icon = [UIImage applicationImageNamed:@"unknown.png"];
    return icon;
}

- (NSString *) homepage {
    return homepage_;
}

- (NSString *) depiction {
    return !depiction_.empty() ? depiction_ : [[self source] depictionForPackage:id_];
}

- (Address *) sponsor {
    if (sponsor$_ == nil) {
        if (sponsor_.empty())
            return nil;
        sponsor$_ = [[Address addressWithString:sponsor_] retain];
    } return sponsor$_;
}

- (Address *) author {
    if (author$_ == nil) {
        if (author_.empty())
            return nil;
        author$_ = [[Address addressWithString:author_] retain];
    } return author$_;
}

- (NSString *) support {
    return !bugs_.empty() ? bugs_ : [[self source] supportForPackage:id_];
}

- (NSArray *) files {
    NSString *path = [NSString stringWithFormat:@"/var/lib/dpkg/info/%@.list", static_cast<NSString *>(id_)];
    NSMutableArray *files = [NSMutableArray arrayWithCapacity:128];
	
    std::ifstream fin;
    fin.open([path UTF8String]);
    if (!fin.is_open())
        return nil;
	
    std::string line;
    while (std::getline(fin, line))
        [files addObject:[NSString stringWithUTF8String:line.c_str()]];
	
    return files;
}

- (NSArray *) relationships {
    return relationships_;
}

- (NSArray *) warnings {
    NSMutableArray *warnings([NSMutableArray arrayWithCapacity:4]);
    const char *name(iterator_.Name());
	
    size_t length(strlen(name));
    if (length < 2) invalid:
        [warnings addObject:UCLocalize("ILLEGAL_PACKAGE_IDENTIFIER")];
    else for (size_t i(0); i != length; ++i)
        if (
            /* XXX: technically this is not allowed */
            (name[i] < 'A' || name[i] > 'Z') &&
            (name[i] < 'a' || name[i] > 'z') &&
            (name[i] < '0' || name[i] > '9') &&
            (i == 0 || name[i] != '+' && name[i] != '-' && name[i] != '.')
			) goto invalid;
	
    if (strcmp(name, "cydia") != 0) {
        bool cydia = false;
        bool user = false;
        bool _private = false;
        bool stash = false;
		
        bool repository = [[self section] isEqualToString:@"Repositories"];
		
        if (NSArray *files = [self files])
            for (NSString *file in files)
                if (!cydia && [file isEqualToString:@"/Applications/Cydia.app"])
                    cydia = true;
                else if (!user && [file isEqualToString:@"/User"])
                    user = true;
                else if (!_private && [file isEqualToString:@"/private"])
                    _private = true;
                else if (!stash && [file isEqualToString:@"/var/stash"])
                    stash = true;
		
        /* XXX: this is not sensitive enough. only some folders are valid. */
        if (cydia && !repository)
            [warnings addObject:[NSString stringWithFormat:UCLocalize("FILES_INSTALLED_TO"), @"Cydia.app"]];
        if (user)
            [warnings addObject:[NSString stringWithFormat:UCLocalize("FILES_INSTALLED_TO"), @"/User"]];
        if (_private)
            [warnings addObject:[NSString stringWithFormat:UCLocalize("FILES_INSTALLED_TO"), @"/private"]];
        if (stash)
            [warnings addObject:[NSString stringWithFormat:UCLocalize("FILES_INSTALLED_TO"), @"/var/stash"]];
    }
	
    return [warnings count] == 0 ? nil : warnings;
}

- (NSArray *) applications {
    NSString *me([[NSBundle mainBundle] bundleIdentifier]);
	
    NSMutableArray *applications([NSMutableArray arrayWithCapacity:2]);
	
    static Pcre application_r("^/Applications/(.*)\\.app/Info.plist$");
    if (NSArray *files = [self files])
        for (NSString *file in files)
            if (application_r(file)) {
                NSDictionary *info([NSDictionary dictionaryWithContentsOfFile:file]);
                NSString *id([info objectForKey:@"CFBundleIdentifier"]);
                if ([id isEqualToString:me])
                    continue;
				
                NSString *display([info objectForKey:@"CFBundleDisplayName"]);
                if (display == nil)
                    display = application_r[1];
				
                NSString *bundle([file stringByDeletingLastPathComponent]);
                NSString *icon([info objectForKey:@"CFBundleIconFile"]);
                if (icon == nil || [icon length] == 0)
                    icon = @"icon.png";
                NSURL *url([NSURL fileURLWithPath:[bundle stringByAppendingPathComponent:icon]]);
				
                NSMutableArray *application([NSMutableArray arrayWithCapacity:2]);
                [applications addObject:application];
				
                [application addObject:id];
                [application addObject:display];
                [application addObject:url];
            }
	
    return [applications count] == 0 ? nil : applications;
}

- (Source *) source {
    if (!cached_) {
        @synchronized (database_) {
            if ([database_ era] != era_ || file_.end())
                source_ = nil;
            else {
                source_ = [database_ getSource:file_.File()];
                if (source_ != nil)
                    [source_ retain];
            }
			
            cached_ = true;
        }
    }
	
    return source_;
}

- (NSString *) role {
    return role_;
}

- (BOOL) matches:(NSString *)text {
    if (text == nil)
        return NO;
	
    NSRange range;
	
    range = [[self id] rangeOfString:text options:MatchCompareOptions_];
    if (range.location != NSNotFound)
        return YES;
	
    range = [[self name] rangeOfString:text options:MatchCompareOptions_];
    if (range.location != NSNotFound)
        return YES;
	
    range = [[self shortDescription] rangeOfString:text options:MatchCompareOptions_];
    if (range.location != NSNotFound)
        return YES;
	
    return NO;
}

- (bool) hasSupportingRole {
    if (role_ == nil)
        return true;
    if ([role_ isEqualToString:@"enduser"])
        return true;
    if ([Role_ isEqualToString:@"User"])
        return false;
    if ([role_ isEqualToString:@"hacker"])
        return true;
    if ([Role_ isEqualToString:@"Hacker"])
        return false;
    if ([role_ isEqualToString:@"developer"])
        return true;
    if ([Role_ isEqualToString:@"Developer"])
        return false;
    _assert(false);
}

- (BOOL) hasTag:(NSString *)tag {
    return tags_ == nil ? NO : [tags_ containsObject:tag];
}

- (NSString *) primaryPurpose {
    for (NSString *tag in tags_)
        if ([tag hasPrefix:@"purpose::"])
            return [tag substringFromIndex:9];
    return nil;
}

- (NSArray *) purposes {
    NSMutableArray *purposes([NSMutableArray arrayWithCapacity:2]);
    for (NSString *tag in tags_)
        if ([tag hasPrefix:@"purpose::"])
            [purposes addObject:[tag substringFromIndex:9]];
    return [purposes count] == 0 ? nil : purposes;
}

- (bool) isCommercial {
    return [self hasTag:@"cydia::commercial"];
}

- (CYString &) cyname {
    return name_.empty() ? id_ : name_;
}

- (uint32_t) compareBySection:(NSArray *)sections {
    NSString *section([self section]);
    for (size_t i(0), e([sections count]); i != e; ++i) {
        if ([section isEqualToString:[[sections objectAtIndex:i] name]])
            return i;
    }
	
    return _not(uint32_t);
}

- (uint32_t) compareForChanges {
    union {
        uint32_t key;
		
        struct {
            uint32_t timestamp : 30;
            uint32_t ignored : 1;
            uint32_t upgradable : 1;
        } bits;
    } value;
	
    bool upgradable([self upgradableAndEssential:YES]);
    value.bits.upgradable = upgradable ? 1 : 0;
	
    if (upgradable) {
        value.bits.timestamp = 0;
        value.bits.ignored = [self ignored] ? 0 : 1;
        value.bits.upgradable = 1;
    } else {
        value.bits.timestamp = static_cast<uint32_t>([[self seen] timeIntervalSince1970]) >> 2;
        value.bits.ignored = 0;
        value.bits.upgradable = 0;
    }
	
    return _not(uint32_t) - value.key;
}

- (void) clear {
    pkgProblemResolver *resolver = [database_ resolver];
    resolver->Clear(iterator_);
    resolver->Protect(iterator_);
}

- (void) install {
    pkgProblemResolver *resolver = [database_ resolver];
    resolver->Clear(iterator_);
    resolver->Protect(iterator_);
    pkgCacheFile &cache([database_ cache]);
    cache->MarkInstall(iterator_, false);
    pkgDepCache::StateCache &state((*cache)[iterator_]);
    if (!state.Install())
        cache->SetReInstall(iterator_, true);
}

- (void) remove {
    pkgProblemResolver *resolver = [database_ resolver];
    resolver->Clear(iterator_);
    resolver->Protect(iterator_);
    resolver->Remove(iterator_);
    [database_ cache]->MarkDelete(iterator_, true);
}

- (bool) isUnfilteredAndSearchedForBy:(NSString *)search {
    _profile(Package$isUnfilteredAndSearchedForBy)
	bool value(true);
	
	_profile(Package$isUnfilteredAndSearchedForBy$Unfiltered)
	value &= [self unfiltered];
	_end
	
	_profile(Package$isUnfilteredAndSearchedForBy$Match)
	value &= [self matches:search];
	_end
	
	return value;
    _end
}

- (bool) isInstalledAndVisible:(NSNumber *)number {
    return (![number boolValue] || [self visible]) && ![self uninstalled];
}

- (bool) isVisibleInSection:(NSString *)name {
    NSString *section = [self section];
	
    return
	[self visible] && (
					   name == nil ||
					   section == nil && [name length] == 0 ||
					   [name isEqualToString:section]
					   );
}

- (bool) isVisibleInSource:(Source *)source {
    return [self source] == source && [self visible];
}

@end
/* }}} */
