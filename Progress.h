#import "Cydia.h"

/* Progress Delegation {{{ */
class Progress :
    public OpProgress
	{
	private:
		_transient id<ProgressDelegate> delegate_;
		float percent_;
		
	protected:
		virtual void Update() {
			/*if (abs(Percent - percent_) > 2)
			 //NSLog(@"%s:%s:%f", Op.c_str(), SubOp.c_str(), Percent);
			 percent_ = Percent;
			 }*/
			
			/*[delegate_ setProgressTitle:[NSString stringWithUTF8String:Op.c_str()]];
			 [delegate_ setProgressPercent:(Percent / 100)];*/
		}
		
	public:
		Progress() :
        delegate_(nil),
        percent_(0)
		{
		}
		
		void setDelegate(id delegate) {
			delegate_ = delegate;
		}
		
		id getDelegate() const {
			return delegate_;
		}
		
		virtual void Done() {
			//NSLog(@"DONE");
			//[delegate_ setProgressPercent:1];
		}
	};
/* }}} */



