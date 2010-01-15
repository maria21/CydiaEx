#import "Database.h"


/* Database Implementation {{{ */
@implementation Database

+ (Database *) sharedInstance {
    static Database *instance;
    if (instance == nil)
        instance = [[Database alloc] init];
    return instance;
}

- (unsigned) era {
    return era_;
}

- (void) dealloc {
    _assert(false);
    NSRecycleZone(zone_);
    // XXX: malloc_destroy_zone(zone_);
    apr_pool_destroy(pool_);
    [super dealloc];
}

- (void) _readCydia:(NSNumber *)fd { _pooled
    __gnu_cxx::stdio_filebuf<char> ib([fd intValue], std::ios::in);
    std::istream is(&ib);
    std::string line;
	
    static Pcre finish_r("^finish:([^:]*)$");
	
    while (std::getline(is, line)) {
        const char *data(line.c_str());
        size_t size = line.size();
        lprintf("C:%s\n", data);
		
        if (finish_r(data, size)) {
            NSString *finish = finish_r[1];
            int index = [Finishes_ indexOfObject:finish];
            if (index != INT_MAX && index > Finish_)
                Finish_ = index;
        }
    }
	
    _assume(false);
}

- (void) _readStatus:(NSNumber *)fd { _pooled
    __gnu_cxx::stdio_filebuf<char> ib([fd intValue], std::ios::in);
    std::istream is(&ib);
    std::string line;
	
    static Pcre conffile_r("^status: [^ ]* : conffile-prompt : (.*?) *$");
    static Pcre pmstatus_r("^([^:]*):([^:]*):([^:]*):(.*)$");
	
    while (std::getline(is, line)) {
        const char *data(line.c_str());
        size_t size(line.size());
        lprintf("S:%s\n", data);
		
        if (conffile_r(data, size)) {
            [delegate_ setConfigurationData:conffile_r[1]];
        } else if (strncmp(data, "status: ", 8) == 0) {
            NSString *string = [NSString stringWithUTF8String:(data + 8)];
            [delegate_ setProgressTitle:string];
        } else if (pmstatus_r(data, size)) {
            std::string type([pmstatus_r[1] UTF8String]);
            NSString *id = pmstatus_r[2];
			
            float percent([pmstatus_r[3] floatValue]);
            [delegate_ setProgressPercent:(percent / 100)];
			
            NSString *string = pmstatus_r[4];
			
            if (type == "pmerror")
                [delegate_ performSelectorOnMainThread:@selector(_setProgressErrorPackage:)
											withObject:[NSArray arrayWithObjects:string, id, nil]
										 waitUntilDone:YES
				 ];
            else if (type == "pmstatus") {
                [delegate_ setProgressTitle:string];
            } else if (type == "pmconffile")
                [delegate_ setConfigurationData:string];
            else
                lprintf("E:unknown pmstatus\n");
        } else
            lprintf("E:unknown status\n");
    }
	
    _assume(false);
}

- (void) _readOutput:(NSNumber *)fd { _pooled
    __gnu_cxx::stdio_filebuf<char> ib([fd intValue], std::ios::in);
    std::istream is(&ib);
    std::string line;
	
    while (std::getline(is, line)) {
        lprintf("O:%s\n", line.c_str());
        [delegate_ addProgressOutput:[NSString stringWithUTF8String:line.c_str()]];
    }
	
    _assume(false);
}

- (FILE *) input {
    return input_;
}

- (Package *) packageWithName:(NSString *)name {
	@synchronized ([Database class]) {
		if (static_cast<pkgDepCache *>(cache_) == NULL)
			return nil;
		pkgCache::PkgIterator iterator(cache_->FindPkg([name UTF8String]));
		return iterator.end() ? nil : [Package packageWithIterator:iterator withZone:NULL inPool:pool_ database:self];
	} }

- (Database *) init {
    if ((self = [super init]) != nil) {
        policy_ = NULL;
        records_ = NULL;
        resolver_ = NULL;
        fetcher_ = NULL;
        lock_ = NULL;
		
        zone_ = NSCreateZone(1024 * 1024, 256 * 1024, NO);
        apr_pool_create(&pool_, NULL);
		
        packages_ = [[NSMutableArray alloc] init];
		
        int fds[2];
		
        _assert(pipe(fds) != -1);
        cydiafd_ = fds[1];
		
        _config->Set("APT::Keep-Fds::", cydiafd_);
        setenv("CYDIA", [[[[NSNumber numberWithInt:cydiafd_] stringValue] stringByAppendingString:@" 1"] UTF8String], _not(int));
		
        [NSThread
		 detachNewThreadSelector:@selector(_readCydia:)
		 toTarget:self
		 withObject:[[NSNumber numberWithInt:fds[0]] retain]
		 ];
		
        _assert(pipe(fds) != -1);
        statusfd_ = fds[1];
		
        [NSThread
		 detachNewThreadSelector:@selector(_readStatus:)
		 toTarget:self
		 withObject:[[NSNumber numberWithInt:fds[0]] retain]
		 ];
		
        _assert(pipe(fds) != -1);
        _assert(dup2(fds[0], 0) != -1);
        _assert(close(fds[0]) != -1);
		
        input_ = fdopen(fds[1], "a");
		
        _assert(pipe(fds) != -1);
        _assert(dup2(fds[1], 1) != -1);
        _assert(close(fds[1]) != -1);
		
        [NSThread
		 detachNewThreadSelector:@selector(_readOutput:)
		 toTarget:self
		 withObject:[[NSNumber numberWithInt:fds[0]] retain]
		 ];
    } return self;
}

- (pkgCacheFile &) cache {
    return cache_;
}

- (pkgDepCache::Policy *) policy {
    return policy_;
}

- (pkgRecords *) records {
    return records_;
}

- (pkgProblemResolver *) resolver {
    return resolver_;
}

- (pkgAcquire &) fetcher {
    return *fetcher_;
}

- (pkgSourceList &) list {
    return *list_;
}

- (NSArray *) packages {
    return packages_;
}

- (NSArray *) sources {
    NSMutableArray *sources([NSMutableArray arrayWithCapacity:sources_.size()]);
    for (SourceMap::const_iterator i(sources_.begin()); i != sources_.end(); ++i)
        [sources addObject:i->second];
    return sources;
}

- (NSArray *) issues {
    if (cache_->BrokenCount() == 0)
        return nil;
	
    NSMutableArray *issues([NSMutableArray arrayWithCapacity:4]);
	
    for (Package *package in packages_) {
        if (![package broken])
            continue;
        pkgCache::PkgIterator pkg([package iterator]);
		
        NSMutableArray *entry([NSMutableArray arrayWithCapacity:4]);
        [entry addObject:[package name]];
        [issues addObject:entry];
		
        pkgCache::VerIterator ver(cache_[pkg].InstVerIter(cache_));
        if (ver.end())
            continue;
		
        for (pkgCache::DepIterator dep(ver.DependsList()); !dep.end(); ) {
            pkgCache::DepIterator start;
            pkgCache::DepIterator end;
            dep.GlobOr(start, end); // ++dep
			
            if (!cache_->IsImportantDep(end))
                continue;
            if ((cache_[end] & pkgDepCache::DepGInstall) != 0)
                continue;
			
            NSMutableArray *failure([NSMutableArray arrayWithCapacity:4]);
            [entry addObject:failure];
            [failure addObject:[NSString stringWithUTF8String:start.DepType()]];
			
            NSString *name([NSString stringWithUTF8String:start.TargetPkg().Name()]);
            if (Package *package = [self packageWithName:name])
                name = [package name];
            [failure addObject:name];
			
            pkgCache::PkgIterator target(start.TargetPkg());
            if (target->ProvidesList != 0)
                [failure addObject:@"?"];
            else {
                pkgCache::VerIterator ver(cache_[target].InstVerIter(cache_));
                if (!ver.end())
                    [failure addObject:[NSString stringWithUTF8String:ver.VerStr()]];
                else if (!cache_[target].CandidateVerIter(cache_).end())
                    [failure addObject:@"-"];
                else if (target->ProvidesList == 0)
                    [failure addObject:@"!"];
                else
                    [failure addObject:@"%"];
            }
			
            _forever {
                if (start.TargetVer() != 0)
                    [failure addObject:[NSString stringWithFormat:@"%s %s", start.CompType(), start.TargetVer()]];
                if (start == end)
                    break;
                ++start;
            }
        }
    }
	
    return issues;
}

- (bool) popErrorWithTitle:(NSString *)title {
    bool fatal(false);
    std::string message;
	
    while (!_error->empty()) {
        std::string error;
        bool warning(!_error->PopMessage(error));
        if (!warning)
            fatal = true;
        for (;;) {
            size_t size(error.size());
            if (size == 0 || error[size - 1] != '\n')
                break;
            error.resize(size - 1);
        }
        lprintf("%c:[%s]\n", warning ? 'W' : 'E', error.c_str());
		
        if (!message.empty())
            message += "\n\n";
        message += error;
    }
	
    if (fatal && !message.empty())
        [delegate_ _setProgressError:[NSString stringWithUTF8String:message.c_str()] withTitle:[NSString stringWithFormat:Colon_, fatal ? Error_ : Warning_, title]];
	
    return fatal;
}

- (bool) popErrorWithTitle:(NSString *)title forOperation:(bool)success {
    return [self popErrorWithTitle:title] || !success;
}

- (void) reloadData { _pooled
	@synchronized ([Database class]) {
		@synchronized (self) {
			++era_;
		}
		
		[packages_ removeAllObjects];
		sources_.clear();
		
		_error->Discard();
		
		delete list_;
		list_ = NULL;
		manager_ = NULL;
		delete lock_;
		lock_ = NULL;
		delete fetcher_;
		fetcher_ = NULL;
		delete resolver_;
		resolver_ = NULL;
		delete records_;
		records_ = NULL;
		delete policy_;
		policy_ = NULL;
		
		if (now_ != nil) {
			[now_ release];
			now_ = nil;
		}
		
		cache_.Close();
		
		apr_pool_clear(pool_);
		NSRecycleZone(zone_);
		
		int chk(creat("/tmp/cydia.chk", 0644));
		if (chk != -1)
			close(chk);
		
		NSString *title(UCLocalize("DATABASE"));
		
		_trace();
		if (!cache_.Open(progress_, true)) { pop:
			std::string error;
			bool warning(!_error->PopMessage(error));
			lprintf("cache_.Open():[%s]\n", error.c_str());
			
			if (error == "dpkg was interrupted, you must manually run 'dpkg --configure -a' to correct the problem. ")
				[delegate_ repairWithSelector:@selector(configure)];
			else if (error == "The package lists or status file could not be parsed or opened.")
				[delegate_ repairWithSelector:@selector(update)];
			// else if (error == "Could not open lock file /var/lib/dpkg/lock - open (13 Permission denied)")
			// else if (error == "Could not get lock /var/lib/dpkg/lock - open (35 Resource temporarily unavailable)")
			// else if (error == "The list of sources could not be read.")
			else
				[delegate_ _setProgressError:[NSString stringWithUTF8String:error.c_str()] withTitle:[NSString stringWithFormat:Colon_, warning ? Warning_ : Error_, title]];
			
			if (warning)
				goto pop;
			_error->Discard();
			return;
		}
		_trace();
		
		unlink("/tmp/cydia.chk");
		
		now_ = [[NSDate date] retain];
		
		policy_ = new pkgDepCache::Policy();
		records_ = new pkgRecords(cache_);
		resolver_ = new pkgProblemResolver(cache_);
		fetcher_ = new pkgAcquire(&status_);
		lock_ = NULL;
		
		list_ = new pkgSourceList();
		if ([self popErrorWithTitle:title forOperation:list_->ReadMainList()])
			return;
		
		if (cache_->DelCount() != 0 || cache_->InstCount() != 0) {
			[delegate_ _setProgressError:@"COUNTS_NONZERO_EX" withTitle:title];
			return;
		}
		
		if ([self popErrorWithTitle:title forOperation:pkgApplyStatus(cache_)])
			return;
		
		if (cache_->BrokenCount() != 0) {
			if ([self popErrorWithTitle:title forOperation:pkgFixBroken(cache_)])
				return;
			
			if (cache_->BrokenCount() != 0) {
				[delegate_ _setProgressError:@"STILL_BROKEN_EX" withTitle:title];
				return;
			}
			
			if ([self popErrorWithTitle:title forOperation:pkgMinimizeUpgrade(cache_)])
				return;
		}
		
		_trace();
		
		for (pkgSourceList::const_iterator source = list_->begin(); source != list_->end(); ++source) {
			std::vector<pkgIndexFile *> *indices = (*source)->GetIndexFiles();
			for (std::vector<pkgIndexFile *>::const_iterator index = indices->begin(); index != indices->end(); ++index)
				// XXX: this could be more intelligent
				if (dynamic_cast<debPackagesIndex *>(*index) != NULL) {
					pkgCache::PkgFileIterator cached((*index)->FindInCache(cache_));
					if (!cached.end())
						sources_[cached->ID] = [[[Source alloc] initWithMetaIndex:*source inPool:pool_] autorelease];
				}
		}
		
		_trace();
		
		{
			/*std::vector<Package *> packages;
			 packages.reserve(std::max(10000U, [packages_ count] + 1000));
			 [packages_ release];
			 packages_ = nil;*/
			
			_trace();
			
			for (pkgCache::PkgIterator iterator = cache_->PkgBegin(); !iterator.end(); ++iterator)
				if (Package *package = [Package packageWithIterator:iterator withZone:zone_ inPool:pool_ database:self])
					//packages.push_back(package);
					[packages_ addObject:package];
			
			_trace();
			
			/*if (packages.empty())
			 packages_ = [[NSArray alloc] init];
			 else
			 packages_ = [[NSArray alloc] initWithObjects:&packages.front() count:packages.size()];
			 _trace();*/
			
			[packages_ radixSortUsingFunction:reinterpret_cast<SKRadixFunction>(&PackagePrefixRadix) withContext:reinterpret_cast<void *>(16)];
			[packages_ radixSortUsingFunction:reinterpret_cast<SKRadixFunction>(&PackagePrefixRadix) withContext:reinterpret_cast<void *>(4)];
			[packages_ radixSortUsingFunction:reinterpret_cast<SKRadixFunction>(&PackagePrefixRadix) withContext:reinterpret_cast<void *>(0)];
			
			/*_trace();
			 PrintTimes();
			 _trace();*/
			
			_trace();
			
			/*if (!packages.empty())
			 CFQSortArray(&packages.front(), packages.size(), sizeof(packages.front()), reinterpret_cast<CFComparatorFunction>(&PackageNameCompare_), NULL);*/
			//std::sort(packages.begin(), packages.end(), PackageNameOrdering());
			
			//CFArraySortValues((CFMutableArrayRef) packages_, CFRangeMake(0, [packages_ count]), reinterpret_cast<CFComparatorFunction>(&PackageNameCompare), NULL);
			
			CFArrayInsertionSortValues((CFMutableArrayRef) packages_, CFRangeMake(0, [packages_ count]), reinterpret_cast<CFComparatorFunction>(&PackageNameCompare), NULL);
			
			//[packages_ sortUsingFunction:reinterpret_cast<NSComparisonResult (*)(id, id, void *)>(&PackageNameCompare) context:NULL];
			
			_trace();
		}
	} }

- (void) configure {
    NSString *dpkg = [NSString stringWithFormat:@"dpkg --configure -a --status-fd %u", statusfd_];
    system([dpkg UTF8String]);
}

- (bool) clean {
    // XXX: I don't remember this condition
    if (lock_ != NULL)
        return false;
	
    FileFd Lock;
    Lock.Fd(GetLock(_config->FindDir("Dir::Cache::Archives") + "lock"));
	
    NSString *title(UCLocalize("CLEAN_ARCHIVES"));
	
    if ([self popErrorWithTitle:title])
        return false;
	
    pkgAcquire fetcher;
    fetcher.Clean(_config->FindDir("Dir::Cache::Archives"));
	
    class LogCleaner :
	public pkgArchiveCleaner
    {
	protected:
        virtual void Erase(const char *File, std::string Pkg, std::string Ver, struct stat &St) {
            unlink(File);
        }
    } cleaner;
	
    if ([self popErrorWithTitle:title forOperation:cleaner.Go(_config->FindDir("Dir::Cache::Archives") + "partial/", cache_)])
        return false;
	
    return true;
}

- (bool) prepare {
    fetcher_->Shutdown();
	
    pkgRecords records(cache_);
	
    lock_ = new FileFd();
    lock_->Fd(GetLock(_config->FindDir("Dir::Cache::Archives") + "lock"));
	
    NSString *title(UCLocalize("PREPARE_ARCHIVES"));
	
    if ([self popErrorWithTitle:title])
        return false;
	
    pkgSourceList list;
    if ([self popErrorWithTitle:title forOperation:list.ReadMainList()])
        return false;
	
    manager_ = (_system->CreatePM(cache_));
    if ([self popErrorWithTitle:title forOperation:manager_->GetArchives(fetcher_, &list, &records)])
        return false;
	
    return true;
}

- (void) perform {
    NSString *title(UCLocalize("PERFORM_SELECTIONS"));
	
    NSMutableArray *before = [NSMutableArray arrayWithCapacity:16]; {
        pkgSourceList list;
        if ([self popErrorWithTitle:title forOperation:list.ReadMainList()])
            return;
        for (pkgSourceList::const_iterator source = list.begin(); source != list.end(); ++source)
            [before addObject:[NSString stringWithUTF8String:(*source)->GetURI().c_str()]];
    }
	
    if (fetcher_->Run(PulseInterval_) != pkgAcquire::Continue) {
        _trace();
        return;
    }
	
    bool failed = false;
    for (pkgAcquire::ItemIterator item = fetcher_->ItemsBegin(); item != fetcher_->ItemsEnd(); item++) {
        if ((*item)->Status == pkgAcquire::Item::StatDone && (*item)->Complete)
            continue;
        if ((*item)->Status == pkgAcquire::Item::StatIdle)
            continue;
		
        std::string uri = (*item)->DescURI();
        std::string error = (*item)->ErrorText;
		
        lprintf("pAf:%s:%s\n", uri.c_str(), error.c_str());
        failed = true;
		
        [delegate_ performSelectorOnMainThread:@selector(_setProgressErrorPackage:)
									withObject:[NSArray arrayWithObjects:
												[NSString stringWithUTF8String:error.c_str()],
												nil]
								 waitUntilDone:YES
		 ];
    }
	
    if (failed) {
        _trace();
        return;
    }
	
    _system->UnLock();
    pkgPackageManager::OrderResult result = manager_->DoInstall(statusfd_);
	
    if (_error->PendingError()) {
        _trace();
        return;
    }
	
    if (result == pkgPackageManager::Failed) {
        _trace();
        return;
    }
	
    if (result != pkgPackageManager::Completed) {
        _trace();
        return;
    }
	
    NSMutableArray *after = [NSMutableArray arrayWithCapacity:16]; {
        pkgSourceList list;
        if ([self popErrorWithTitle:title forOperation:list.ReadMainList()])
            return;
        for (pkgSourceList::const_iterator source = list.begin(); source != list.end(); ++source)
            [after addObject:[NSString stringWithUTF8String:(*source)->GetURI().c_str()]];
    }
	
    if (![before isEqualToArray:after])
        [self update];
}

- (bool) upgrade {
    NSString *title(UCLocalize("UPGRADE"));
    if ([self popErrorWithTitle:title forOperation:pkgDistUpgrade(cache_)])
        return false;
    return true;
}

- (void) update {
    [self updateWithStatus:status_];
}

- (void) setVisible {
    for (Package *package in packages_)
        [package setVisible];
}

- (void) updateWithStatus:(Status &)status {
    _transient NSObject<ProgressDelegate> *delegate(status.getDelegate());
    NSString *title(UCLocalize("REFRESHING_DATA"));
	
    pkgSourceList list;
    if (!list.ReadMainList())
        [delegate _setProgressError:@"Unable to read source list." withTitle:title];
	
    FileFd lock;
    lock.Fd(GetLock(_config->FindDir("Dir::State::Lists") + "lock"));
    if ([self popErrorWithTitle:title])
        return;
	
    if ([self popErrorWithTitle:title forOperation:ListUpdate(status, list, PulseInterval_)])
	/* XXX: ignore this because users suck and don't understand why refreshing is important: return */;
	
    [Metadata_ setObject:[NSDate date] forKey:@"LastUpdate"];
    Changed_ = true;
}

- (void) setDelegate:(id)delegate {
    delegate_ = delegate;
    status_.setDelegate(delegate);
    progress_.setDelegate(delegate);
}

- (Source *) getSource:(pkgCache::PkgFileIterator)file {
    SourceMap::const_iterator i(sources_.find(file->ID));
    return i == sources_.end() ? nil : i->second;
}

@end
/* }}} */
