#import "Cydia.h"


/* Status Delegation {{{ */
class Status :
    public pkgAcquireStatus
	{
	private:
		_transient NSObject<ProgressDelegate> *delegate_;
		
	public:
		Status() :
        delegate_(nil)
		{
		}
		
		void setDelegate(id delegate) {
			delegate_ = delegate;
		}
		
		NSObject<ProgressDelegate> *getDelegate() const {
			return delegate_;
		}
		
		virtual bool MediaChange(std::string media, std::string drive) {
			return false;
		}
		
		virtual void IMSHit(pkgAcquire::ItemDesc &item) {
		}
		
		virtual void Fetch(pkgAcquire::ItemDesc &item) {
			//NSString *name([NSString stringWithUTF8String:item.ShortDesc.c_str()]);
			[delegate_ setProgressTitle:[NSString stringWithFormat:UCLocalize("DOWNLOADING_"), [NSString stringWithUTF8String:item.ShortDesc.c_str()]]];
		}
		
		virtual void Done(pkgAcquire::ItemDesc &item) {
		}
		
		virtual void Fail(pkgAcquire::ItemDesc &item) {
			if (
				item.Owner->Status == pkgAcquire::Item::StatIdle ||
				item.Owner->Status == pkgAcquire::Item::StatDone
				)
				return;
			
			std::string &error(item.Owner->ErrorText);
			if (error.empty())
				return;
			
			NSString *description([NSString stringWithUTF8String:item.Description.c_str()]);
			NSArray *fields([description componentsSeparatedByString:@" "]);
			NSString *source([fields count] == 0 ? nil : [fields objectAtIndex:0]);
			
			[delegate_ performSelectorOnMainThread:@selector(_setProgressErrorPackage:)
										withObject:[NSArray arrayWithObjects:
													[NSString stringWithUTF8String:error.c_str()],
													source,
													nil]
									 waitUntilDone:YES
			 ];
		}
		
		virtual bool Pulse(pkgAcquire *Owner) {
			bool value = pkgAcquireStatus::Pulse(Owner);
			
			float percent(
						  double(CurrentBytes + CurrentItems) /
						  double(TotalBytes + TotalItems)
						  );
			
			[delegate_ setProgressPercent:percent];
			return [delegate_ isCancelling:CurrentBytes] ? false : value;
		}
		
		virtual void Start() {
			[delegate_ startProgress];
		}
		
		virtual void Stop() {
		}
	};
/* }}} */
