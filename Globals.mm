#import "Cydia.h"
#import "HomeView.h"


/* Profiler {{{ */
struct timeval _ltv;
bool _itv;

TimeList times_;

class ProfileTime {
private:
    const char *name_;
    uint64_t total_;
    uint64_t count_;
	
public:
    ProfileTime(const char *name) :
	name_(name),
	total_(0)
    {
        times_.push_back(this);
    }
	
    void AddTime(uint64_t time) {
        total_ += time;
        ++count_;
    }
	
    void Print() {
        if (total_ != 0)
            std::cerr << std::setw(5) << count_ << ", " << std::setw(7) << total_ << " : " << name_ << std::endl;
        total_ = 0;
        count_ = 0;
    }
};

class ProfileTimer {
private:
    ProfileTime &time_;
    uint64_t start_;
	
public:
    ProfileTimer(ProfileTime &time) :
	time_(time),
	start_(_timestamp)
    {
    }
	
    ~ProfileTimer() {
        time_.AddTime(_timestamp - start_);
    }
};

/*
void PrintTimes() {
    for (TimeList::const_iterator i(times_.begin()); i != times_.end(); ++i)
        (*i)->Print();
    std::cerr << "========" << std::endl;
}*/

void NSLogPoint(const char *fix, const CGPoint &point) {
    NSLog(@"%s(%g,%g)", fix, point.x, point.y);
}

void NSLogRect(const char *fix, const CGRect &rect) {
    NSLog(@"%s(%g,%g)+(%g,%g)", fix, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

NSString *CydiaURL(NSString *path) {
    char page[25];
    page[0] = 'h'; page[1] = 't'; page[2] = 't'; page[3] = 'p'; page[4] = ':';
    page[5] = '/'; page[6] = '/'; page[7] = 'c'; page[8] = 'y'; page[9] = 'd';
    page[10] = 'i'; page[11] = 'a'; page[12] = '.'; page[13] = 's'; page[14] = 'a';
    page[15] = 'u'; page[16] = 'r'; page[17] = 'i'; page[18] = 'k'; page[19] = '.';
    page[20] = 'c'; page[21] = 'o'; page[22] = 'm'; page[23] = '/'; page[24] = '\0';
    return [[NSString stringWithUTF8String:page] stringByAppendingString:path];
}



@implementation NSObject (Cydia)

- (void) doNothing {
}

- (void) _yieldToContext:(NSMutableArray *)context { _pooled
    SEL selector(reinterpret_cast<SEL>([[context objectAtIndex:0] pointerValue]));
    id object([[context objectAtIndex:1] nonretainedObjectValue]);
    volatile bool &stopped(*reinterpret_cast<bool *>([[context objectAtIndex:2] pointerValue]));
	
    /* XXX: deal with exceptions */
    id value([self performSelector:selector withObject:object]);
	
    NSMethodSignature *signature([self methodSignatureForSelector:selector]);
    [context removeAllObjects];
    if ([signature methodReturnLength] != 0 && value != nil)
        [context addObject:value];
	
    stopped = true;
	
    [self
	 performSelectorOnMainThread:@selector(doNothing)
	 withObject:nil
	 waitUntilDone:NO
	 ];
}

- (id) yieldToSelector:(SEL)selector withObject:(id)object {
    /*return [self performSelector:selector withObject:object];*/
	
    volatile bool stopped(false);
	
    NSMutableArray *context([NSMutableArray arrayWithObjects:
							 [NSValue valueWithPointer:selector],
							 [NSValue valueWithNonretainedObject:object],
							 [NSValue valueWithPointer:const_cast<bool *>(&stopped)],
							 nil]);
	
    NSThread *thread([[[NSThread alloc]
					   initWithTarget:self
					   selector:@selector(_yieldToContext:)
					   object:context
					   ] autorelease]);
	
    [thread start];
	
    NSRunLoop *loop([NSRunLoop currentRunLoop]);
    NSDate *future([NSDate distantFuture]);
	
    while (!stopped && [loop runMode:NSDefaultRunLoopMode beforeDate:future]);
	
    return [context count] == 0 ? nil : [context objectAtIndex:0];
}

- (id) yieldToSelector:(SEL)selector {
    return [self yieldToSelector:selector withObject:nil];
}

@end
/* }}} */

/* NSForcedOrderingSearch doesn't work on the iPhone */
const NSStringCompareOptions MatchCompareOptions_ = NSLiteralSearch | NSCaseInsensitiveSearch;
const NSStringCompareOptions LaxCompareOptions_ = NSNumericSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch | NSCaseInsensitiveSearch;
const CFStringCompareFlags LaxCompareFlags_ = kCFCompareCaseInsensitive | kCFCompareNonliteral | kCFCompareLocalized | kCFCompareNumerically | kCFCompareWidthInsensitive | kCFCompareForcedOrdering;

@implementation NSMutableArray (Cydia)

- (void) addInfoDictionary:(NSDictionary *)info {
    [self addObject:info];
}

@end

@implementation NSMutableDictionary (Cydia)

- (void) addInfoDictionary:(NSDictionary *)info {
    [self setObject:info forKey:[info objectForKey:@"CFBundleIdentifier"]];
}

@end
/* }}} */



@implementation PopTransitionView

- (void) transitionViewDidComplete:(UITransitionView *)view fromView:(UIView *)from toView:(UIView *)to {
    if (from != nil && to == nil)
        [self removeFromSuperview];
}

@end

@implementation UIView (PopUpView)

- (void) popFromSuperviewAnimated:(BOOL)animated {
    [[self superview] transition:(animated ? UITransitionPushFromTop : UITransitionNone) toView:nil];
}

- (void) popSubview:(UIView *)view {
    UITransitionView *transition([[[PopTransitionView alloc] initWithFrame:[self bounds]] autorelease]);
    [transition setDelegate:transition];
    [self addSubview:transition];
	
    UIView *blank = [[[UIView alloc] initWithFrame:[transition bounds]] autorelease];
    [transition transition:UITransitionNone toView:blank];
    [transition transition:UITransitionPushFromBottom toView:view];
}

@end
/* }}} */




void RadixSort_(NSMutableArray *self, size_t count, struct RadixItem_ *swap) {
    struct RadixItem_ *lhs(swap), *rhs(swap + count);
	
    static const size_t width = 32;
    static const size_t bits = 11;
    static const size_t slots = 1 << bits;
    static const size_t passes = (width + (bits - 1)) / bits;
	
    size_t *hist(new size_t[slots]);
	
    for (size_t pass(0); pass != passes; ++pass) {
        memset(hist, 0, sizeof(size_t) * slots);
		
        for (size_t i(0); i != count; ++i) {
            uint32_t key(lhs[i].key);
            key >>= pass * bits;
            key &= _not(uint32_t) >> width - bits;
            ++hist[key];
        }
		
        size_t offset(0);
        for (size_t i(0); i != slots; ++i) {
            size_t local(offset);
            offset += hist[i];
            hist[i] = local;
        }
		
        for (size_t i(0); i != count; ++i) {
            uint32_t key(lhs[i].key);
            key >>= pass * bits;
            key &= _not(uint32_t) >> width - bits;
            rhs[hist[key]++] = lhs[i];
        }
		
        RadixItem_ *tmp(lhs);
        lhs = rhs;
        rhs = tmp;
    }
	
    delete [] hist;
	
    NSMutableArray *values([NSMutableArray arrayWithCapacity:count]);
    for (size_t i(0); i != count; ++i)
        [values addObject:[self objectAtIndex:lhs[i].index]];
    [self setArray:values];
	
    delete [] swap;
}

@implementation NSMutableArray (Radix)

- (void) radixSortUsingSelector:(SEL)selector withObject:(id)object {
    size_t count([self count]);
    if (count == 0)
        return;
	
#if 0
    NSInvocation *invocation([NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"L12@0:4@8"]]);
    [invocation setSelector:selector];
    [invocation setArgument:&object atIndex:2];
#else
    /* XXX: this is an unsafe optimization of doomy hell */
    Method method(class_getInstanceMethod([[self objectAtIndex:0] class], selector));
    _assert(method != NULL);
    uint32_t (*imp)(id, SEL, id) = reinterpret_cast<uint32_t (*)(id, SEL, id)>(method_getImplementation(method));
    _assert(imp != NULL);
#endif
	
    struct RadixItem_ *swap(new RadixItem_[count * 2]);
	
    for (size_t i(0); i != count; ++i) {
        RadixItem_ &item(swap[i]);
        item.index = i;
		
        id object([self objectAtIndex:i]);
		
#if 0
        [invocation setTarget:object];
        [invocation invoke];
        [invocation getReturnValue:&item.key];
#else
        item.key = imp(object, selector, object);
#endif
    }
	
    RadixSort_(self, count, swap);
}

- (void) radixSortUsingFunction:(SKRadixFunction)function withContext:(void *)argument {
    size_t count([self count]);
    struct RadixItem_ *swap(new RadixItem_[count * 2]);
	
    for (size_t i(0); i != count; ++i) {
        RadixItem_ &item(swap[i]);
        item.index = i;
		
        id object([self objectAtIndex:i]);
        item.key = function(object, argument);
    }
	
    RadixSort_(self, count, swap);
}

@end
/* }}} */


uint32_t PackageChangesRadix(Package *self, void *) {
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

_finline static void Stifle(uint8_t &value) {
}

uint32_t PackagePrefixRadix(Package *self, void *context) {
    size_t offset(reinterpret_cast<size_t>(context));
    CYString &name([self cyname]);
	
    size_t size(name.size());
    if (size == 0)
        return 0;
    char *text(name.data());
	
    size_t zeros;
    if (!isdigit(text[0]))
        zeros = 0;
    else {
        size_t digits(1);
        while (size != digits && isdigit(text[digits]))
            if (++digits == 4)
                break;
        zeros = 4 - digits;
    }
	
    uint8_t data[4];
	
    // 0.607997
	
    if (offset == 0 && zeros != 0) {
        memset(data, '0', zeros);
        memcpy(data + zeros, text, 4 - zeros);
    } else {
        /* XXX: there's some danger here if you request a non-zero offset < 4 and it gets zero padded */
        if (size <= offset - zeros)
            return 0;
		
        text += offset - zeros;
        size -= offset - zeros;
		
        if (size >= 4)
            memcpy(data, text, 4);
        else {
            memcpy(data, text, size);
            memset(data + size, 0, 4 - size);
        }
		
        for (size_t i(0); i != 4; ++i)
            if (isalpha(data[i]))
                data[i] &= 0xdf;
    }
	
    if (offset == 0)
        data[0] = (data[0] & 0x3f) | "\x80\x00\xc0\x40"[data[0] >> 6];
	
    /* XXX: ntohl may be more honest */
    return OSSwapInt32(*reinterpret_cast<uint32_t *>(data));
}

CYString &(*PackageName)(Package *self, SEL sel);

CFComparisonResult PackageNameCompare(Package *lhs, Package *rhs, void *arg) {
    _profile(PackageNameCompare)
	CYString &lhi(PackageName(lhs, @selector(cyname)));
	CYString &rhi(PackageName(rhs, @selector(cyname)));
	CFStringRef lhn(lhi), rhn(rhi);
	
	if (lhn == NULL)
		return rhn == NULL ? NSOrderedSame : NSOrderedAscending;
	else if (rhn == NULL)
		return NSOrderedDescending;
	
	_profile(PackageNameCompare$NumbersLast)
	if (!lhi.empty() && !rhi.empty()) {
		UniChar lhc(CFStringGetCharacterAtIndex(lhn, 0));
		UniChar rhc(CFStringGetCharacterAtIndex(rhn, 0));
		bool lha(CFUniCharIsMemberOf(lhc, kCFUniCharLetterCharacterSet));
		if (lha != CFUniCharIsMemberOf(rhc, kCFUniCharLetterCharacterSet))
			return lha ? NSOrderedAscending : NSOrderedDescending;
	}
	_end
	
	CFIndex length = CFStringGetLength(lhn);
	
	_profile(PackageNameCompare$Compare)
	return CFStringCompareWithOptionsAndLocale(lhn, rhn, CFRangeMake(0, length), LaxCompareFlags_, Locale_);
	_end
    _end
}

CFComparisonResult PackageNameCompare_(Package **lhs, Package **rhs, void *context) {
    return PackageNameCompare(*lhs, *rhs, context);
}





/* Insertion Sort {{{ */

CFIndex SKBSearch_(const void *element, CFIndex elementSize, const void *list, CFIndex count, CFComparatorFunction comparator, void *context) {
    const char *ptr = (const char *)list;
    while (0 < count) {
        CFIndex half = count / 2;
        const char *probe = ptr + elementSize * half;
        CFComparisonResult cr = comparator(element, probe, context);
		if (0 == cr) return (probe - (const char *)list) / elementSize;
        ptr = (cr < 0) ? ptr : probe + elementSize;
        count = (cr < 0) ? half : (half + (count & 1) - 1);
    }
    return (ptr - (const char *)list) / elementSize;
}

CFIndex CFBSearch_(const void *element, CFIndex elementSize, const void *list, CFIndex count, CFComparatorFunction comparator, void *context) {
    const char *ptr = (const char *)list;
    while (0 < count) {
        CFIndex half = count / 2;
        const char *probe = ptr + elementSize * half;
        CFComparisonResult cr = comparator(element, probe, context);
		if (0 == cr) return (probe - (const char *)list) / elementSize;
        ptr = (cr < 0) ? ptr : probe + elementSize;
        count = (cr < 0) ? half : (half + (count & 1) - 1);
    }
    return (ptr - (const char *)list) / elementSize;
}

void CFArrayInsertionSortValues(CFMutableArrayRef array, CFRange range, CFComparatorFunction comparator, void *context) {
    if (range.length == 0)
        return;
    const void **values(new const void *[range.length]);
    CFArrayGetValues(array, range, values);
	
#if HistogramInsertionSort
    uint32_t total(0), *offsets(new uint32_t[range.length]);
#endif
	
    for (CFIndex index(1); index != range.length; ++index) {
        const void *value(values[index]);
        //CFIndex correct(SKBSearch_(&value, sizeof(const void *), values, index, comparator, context));
        CFIndex correct(index);
        while (comparator(value, values[correct - 1], context) == kCFCompareLessThan)
            if (--correct == 0)
                break;
        if (correct != index) {
            size_t offset(index - correct);
#if HistogramInsertionSort
            total += offset;
            ++offsets[offset];
            if (offset > 10)
                NSLog(@"Heavy Insertion Displacement: %u = %@", offset, value);
#endif
            memmove(values + correct + 1, values + correct, sizeof(const void *) * offset);
            values[correct] = value;
        }
    }
	
    CFArrayReplaceValues(array, range, values, range.length);
    delete [] values;
	
#if HistogramInsertionSort
    for (CFIndex index(0); index != range.length; ++index)
        if (offsets[index] != 0)
            NSLog(@"Insertion Displacement [%u]: %u", index, offsets[index]);
    NSLog(@"Average Insertion Displacement: %f", double(total) / range.length);
    delete [] offsets;
#endif
}

/* }}} */

/* Apple Bug Fixes {{{ */
@implementation UIWebDocumentView (Cydia)

- (void) _setScrollerOffset:(CGPoint)offset {
    UIScroller *scroller([self _scroller]);
	
    CGSize size([scroller contentSize]);
    CGSize bounds([scroller bounds].size);
	
    CGPoint max;
    max.x = size.width - bounds.width;
    max.y = size.height - bounds.height;
	
    // wtf Apple?!
    if (max.x < 0)
        max.x = 0;
    if (max.y < 0)
        max.y = 0;
	
    offset.x = offset.x < 0 ? 0 : offset.x > max.x ? max.x : offset.x;
    offset.y = offset.y < 0 ? 0 : offset.y > max.y ? max.y : offset.y;
	
    [scroller setOffset:offset];
}

@end
/* }}} */

NSUInteger DOMNodeList$countByEnumeratingWithState$objects$count$(DOMNodeList *self, SEL sel, NSFastEnumerationState *state, id *objects, NSUInteger count) {
    size_t length([self length] - state->state);
    if (length <= 0)
        return 0;
    else if (length > count)
        length = count;
		for (size_t i(0); i != length; ++i)
			objects[i] = [self item:state->state++];
			state->itemsPtr = objects;
			state->mutationsPtr = (unsigned long *) self;
			return length;
}



@implementation NSString (Cydia)

+ (NSString *) stringWithUTF8BytesNoCopy:(const char *)bytes length:(int)length {
    return [[[NSString alloc] initWithBytesNoCopy:const_cast<char *>(bytes) length:length encoding:NSUTF8StringEncoding freeWhenDone:NO] autorelease];
}

+ (NSString *) stringWithUTF8Bytes:(const char *)bytes length:(int)length withZone:(NSZone *)zone inPool:(apr_pool_t *)pool {
    char *data(reinterpret_cast<char *>(apr_palloc(pool, length)));
    memcpy(data, bytes, length);
    return [[[NSString allocWithZone:zone] initWithBytesNoCopy:data length:length encoding:NSUTF8StringEncoding freeWhenDone:NO] autorelease];
}

+ (NSString *) stringWithUTF8Bytes:(const char *)bytes length:(int)length {
    return [[[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding] autorelease];
}

- (NSComparisonResult) compareByPath:(NSString *)other {
    NSString *prefix = [self commonPrefixWithString:other options:0];
    size_t length = [prefix length];
	
    NSRange lrange = NSMakeRange(length, [self length] - length);
    NSRange rrange = NSMakeRange(length, [other length] - length);
	
    lrange = [self rangeOfString:@"/" options:0 range:lrange];
    rrange = [other rangeOfString:@"/" options:0 range:rrange];
	
    NSComparisonResult value;
	
    if (lrange.location == NSNotFound && rrange.location == NSNotFound)
        value = NSOrderedSame;
    else if (lrange.location == NSNotFound)
        value = NSOrderedAscending;
    else if (rrange.location == NSNotFound)
        value = NSOrderedDescending;
    else
        value = NSOrderedSame;
	
    NSString *lpath = lrange.location == NSNotFound ? [self substringFromIndex:length] :
	[self substringWithRange:NSMakeRange(length, lrange.location - length)];
    NSString *rpath = rrange.location == NSNotFound ? [other substringFromIndex:length] :
	[other substringWithRange:NSMakeRange(length, rrange.location - length)];
	
    NSComparisonResult result = [lpath compare:rpath];
    return result == NSOrderedSame ? value : result;
}

- (NSString *) stringByCachingURLWithCurrentCDN {
    return [self
			stringByReplacingOccurrencesOfString:@"://"
			withString:@"://ne.edgecastcdn.net/8003A4/"
			options:0
			/* XXX: this is somewhat inaccurate */
			range:NSMakeRange(0, 10)
			];
}

- (NSString *) stringByAddingPercentEscapesIncludingReserved {
    return [(id)CFURLCreateStringByAddingPercentEscapes(
														kCFAllocatorDefault, 
														(CFStringRef) self,
														NULL,
														CFSTR(";/?:@&=+$,"),
														kCFStringEncodingUTF8
														) autorelease];
}

@end
/* }}} */

/* C++ NSString Algorithm Adapters {{{ */
extern "C" {
    CF_EXPORT CFHashCode CFStringHashNSString(CFStringRef str);
}



struct NSStringMapHash :
std::unary_function<NSString *, size_t>
{
    _finline size_t operator ()(NSString *value) const {
        return CFStringHashNSString((CFStringRef) value);
    }
};

struct NSStringMapLess :
std::binary_function<NSString *, NSString *, bool>
{
    _finline bool operator ()(NSString *lhs, NSString *rhs) const {
        return [lhs compare:rhs] == NSOrderedAscending;
    }
};

struct NSStringMapEqual :
std::binary_function<NSString *, NSString *, bool>
{
    _finline bool operator ()(NSString *lhs, NSString *rhs) const {
        return CFStringCompare((CFStringRef) lhs, (CFStringRef) rhs, 0) == kCFCompareEqualTo;
        //CFEqual((CFTypeRef) lhs, (CFTypeRef) rhs);
        //[lhs isEqualToString:rhs];
    }
};
/* }}} */



/* Random Global Variables {{{ */
const int PulseInterval_ = 50000;
const int ButtonBarHeight_ = 48;
const float KeyboardTime_ = 0.3f;

int Finish_;
NSArray *Finishes_;

bool Queuing_;

CGColor Blue_;
CGColor Blueish_;
CGColor Black_;
CGColor Off_;
CGColor White_;
CGColor Gray_;
CGColor Green_;
CGColor Purple_;
CGColor Purplish_;

UIColor *InstallingColor_;
UIColor *RemovingColor_;

NSString *App_;
NSString *Home_;

BOOL Advanced_;
BOOL Ignored_;

UIFont *Font12_;
UIFont *Font12Bold_;
UIFont *Font14_;
UIFont *Font18Bold_;
UIFont *Font22Bold_;

const char *Machine_ = NULL;
const NSString *System_ = NULL;
const NSString *SerialNumber_ = nil;
const NSString *ChipID_ = nil;
const NSString *UniqueID_ = nil;
const NSString *Build_ = nil;
const NSString *Product_ = nil;
const NSString *Safari_ = nil;

CFLocaleRef Locale_;
NSArray *Languages_;
CGColorSpaceRef space_;

bool reload_;

NSDictionary *SectionMap_;
NSMutableDictionary *Metadata_;
_transient NSMutableDictionary *Settings_;
_transient NSString *Role_;
_transient NSMutableDictionary *Packages_;
_transient NSMutableDictionary *Sections_;
_transient NSMutableDictionary *Sources_;
bool Changed_;
NSDate *now_;

#if RecycleWebViews
NSMutableArray *Documents_;
#endif
/* }}} */


/* Display Helpers {{{ */
inline float Interpolate(float begin, float end, float fraction) {
    return (end - begin) * fraction + begin;
}

/* XXX: localize this! */
NSString *SizeString(double size) {
    bool negative = size < 0;
    if (negative)
        size = -size;
	
    unsigned power = 0;
    while (size > 1024) {
        size /= 1024;
        ++power;
    }
	
    static const char *powers_[] = {"B", "kB", "MB", "GB"};
	
    return [NSString stringWithFormat:@"%s%.1f %s", (negative ? "-" : ""), size, powers_[power]];
}

CFStringRef CFCString(const char *value) {
    return CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, reinterpret_cast<const uint8_t *>(value), strlen(value), kCFStringEncodingUTF8, NO, kCFAllocatorNull);
}

const char *StripVersion_(const char *version) {
    const char *colon(strchr(version, ':'));
    if (colon != NULL)
        version = colon + 1;
    return version;
}

CFStringRef StripVersion(const char *version) {
    const char *colon(strchr(version, ':'));
    if (colon != NULL)
        version = colon + 1;
    return CFStringCreateWithBytes(kCFAllocatorDefault, reinterpret_cast<const uint8_t *>(version), strlen(version), kCFStringEncodingUTF8, NO);
    // XXX: performance
    return CFCString(version);
}

NSString *LocalizeSection(NSString *section) {
    static Pcre title_r("^(.*?) \\((.*)\\)$");
    if (title_r(section)) {
        NSString *parent(title_r[1]);
        NSString *child(title_r[2]);
		
        return [NSString stringWithFormat:UCLocalize("PARENTHETICAL"),
				LocalizeSection(parent),
				LocalizeSection(child)
				];
    }
	
    return [[NSBundle mainBundle] localizedStringForKey:section value:nil table:@"Sections"];
}

NSString *Simplify(NSString *title) {
    const char *data = [title UTF8String];
    size_t size = [title length];
	
    static Pcre square_r("^\\[(.*)\\]$");
    if (square_r(data, size))
        return Simplify(square_r[1]);
	
    static Pcre paren_r("^\\((.*)\\)$");
    if (paren_r(data, size))
        return Simplify(paren_r[1]);
	
    static Pcre title_r("^(.*?) \\((.*)\\)$");
    if (title_r(data, size))
        return Simplify(title_r[1]);
	
    return title;
}
/* }}} */

NSString *GetLastUpdate() {
    NSDate *update = [Metadata_ objectForKey:@"LastUpdate"];
	
    if (update == nil)
        return UCLocalize("NEVER_OR_UNKNOWN");
	
    CFDateFormatterRef formatter = CFDateFormatterCreate(NULL, Locale_, kCFDateFormatterMediumStyle, kCFDateFormatterMediumStyle);
    CFStringRef formatted = CFDateFormatterCreateStringWithDate(NULL, formatter, (CFDateRef) update);
	
    CFRelease(formatter);
	
    return [(NSString *) formatted autorelease];
}

bool isSectionVisible(NSString *section) {
    NSDictionary *metadata([Sections_ objectForKey:section]);
    NSNumber *hidden(metadata == nil ? nil : [metadata objectForKey:@"Hidden"]);
    return hidden == nil || ![hidden boolValue];
}



NSString *Colon_;
NSString *Error_;
NSString *Warning_;


/* Confirmation View {{{ */
bool DepSubstrate(const pkgCache::VerIterator &iterator) {
    if (!iterator.end())
        for (pkgCache::DepIterator dep(iterator.DependsList()); !dep.end(); ++dep) {
            if (dep->Type != pkgCache::Dep::Depends && dep->Type != pkgCache::Dep::PreDepends)
                continue;
            pkgCache::PkgIterator package(dep.TargetPkg());
            if (package.end())
                continue;
            if (strcmp(package.Name(), "mobilesubstrate") == 0)
                return true;
        }
	
    return false;
}


void _setHomePage(Cydia *self) {
    [self setPage:[self _pageForURL:[NSURL URLWithString:CydiaURL(@"")] withClass:[HomeView class]]];
}







