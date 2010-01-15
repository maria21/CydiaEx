/* Cydia - iPhone UIKit Front-End for Debian APT
 * Copyright (C) 2008-2009  Jay Freeman (saurik)
 */

/* Modified BSD License {{{ */
/*
 *        Redistribution and use in source and binary
 * forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the
 *    above copyright notice, this list of conditions
 *    and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the
 *    above copyright notice, this list of conditions
 *    and the following disclaimer in the documentation
 *    and/or other materials provided with the
 *    distribution.
 * 3. The name of the author may not be used to endorse
 *    or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/* }}} */

// XXX: wtf/FastMalloc.h... wtf?
#define USE_SYSTEM_MALLOC 1

/* #include Directives {{{ */
#import "UICaboodle/UCPlatform.h"
#import "UICaboodle/UCLocalize.h"

#include <objc/objc.h>
#include <objc/runtime.h>

#include <CoreGraphics/CoreGraphics.h>
#include <GraphicsServices/GraphicsServices.h>
#include <Foundation/Foundation.h>

#if 0
#define DEPLOYMENT_TARGET_MACOSX 1
#define CF_BUILDING_CF 1
#include <CoreFoundation/CFInternal.h>
#endif

#include <CoreFoundation/CFPriv.h>
#include <CoreFoundation/CFUniChar.h>

#import <UIKit/UIKit.h>

#include <WebCore/WebCoreThread.h>
#import <WebKit/WebDefaultUIKitDelegate.h>

#include <algorithm>
#include <iomanip>
#include <sstream>
#include <string>

#include <ext/stdio_filebuf.h>

#include <apt-pkg/acquire.h>
#include <apt-pkg/acquire-item.h>
#include <apt-pkg/algorithms.h>
#include <apt-pkg/cachefile.h>
#include <apt-pkg/clean.h>
#include <apt-pkg/configuration.h>
#include <apt-pkg/debindexfile.h>
#include <apt-pkg/debmetaindex.h>
#include <apt-pkg/error.h>
#include <apt-pkg/init.h>
#include <apt-pkg/mmap.h>
#include <apt-pkg/pkgrecords.h>
#include <apt-pkg/sha1.h>
#include <apt-pkg/sourcelist.h>
#include <apt-pkg/sptr.h>
#include <apt-pkg/strutl.h>
#include <apt-pkg/tagfile.h>

#include <apr-1/apr_pools.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <sys/param.h>
#include <sys/mount.h>

#include <notify.h>
#include <dlfcn.h>

extern "C" {
#include <mach-o/nlist.h>
}

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <errno.h>
#include <pcre.h>

#include <ext/hash_map>

#import "UICaboodle/BrowserView.h"
#import "UICaboodle/ResetView.h"

#import "substrate.h"
/* }}} */


/* C++ NSString Wrapper Cache {{{ */
class CYString {
private:
    char *data_;
    size_t size_;
    CFStringRef cache_;
	
    _finline void clear_() {
        if (cache_ != NULL) {
            CFRelease(cache_);
            cache_ = NULL;
        }
    }
	
public:
    _finline bool empty() const {
        return size_ == 0;
    }
	
    _finline size_t size() const {
        return size_;
    }
	
    _finline char *data() const {
        return data_;
    }
	
    _finline void clear() {
        size_ = 0;
        clear_();
    }
	
    _finline CYString() :
	data_(0),
	size_(0),
	cache_(NULL)
    {
    }
	
    _finline ~CYString() {
        clear_();
    }
	
    void operator =(const CYString &rhs) {
        data_ = rhs.data_;
        size_ = rhs.size_;
		
        if (rhs.cache_ == nil)
            cache_ = NULL;
        else
            cache_ = reinterpret_cast<CFStringRef>(CFRetain(rhs.cache_));
    }
	
    void set(apr_pool_t *pool, const char *data, size_t size) {
        if (size == 0)
            clear();
        else {
            clear_();
			
            char *temp(reinterpret_cast<char *>(apr_palloc(pool, size + 1)));
            memcpy(temp, data, size);
            temp[size] = '\0';
            data_ = temp;
            size_ = size;
        }
    }
	
    _finline void set(apr_pool_t *pool, const char *data) {
        set(pool, data, data == NULL ? 0 : strlen(data));
    }
	
    _finline void set(apr_pool_t *pool, const std::string &rhs) {
        set(pool, rhs.data(), rhs.size());
    }
	
    bool operator ==(const CYString &rhs) const {
        return size_ == rhs.size_ && memcmp(data_, rhs.data_, size_) == 0;
    }
	
    operator CFStringRef() {
        if (cache_ == NULL) {
            if (size_ == 0)
                return nil;
            cache_ = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, reinterpret_cast<uint8_t *>(data_), size_, kCFStringEncodingUTF8, NO, kCFAllocatorNull);
        } return cache_;
    }
	
    _finline operator id() {
        return (NSString *) static_cast<CFStringRef>(*this);
    }
};
/* }}} */


#define _timestamp ({ \
struct timeval tv; \
gettimeofday(&tv, NULL); \
tv.tv_sec * 1000000 + tv.tv_usec; \
})

typedef std::vector<class ProfileTime *> TimeList;

void PrintTimes();

#define _profile(name) { \
static ProfileTime name(#name); \
ProfileTimer _ ## name(name);

#define _end }
/* }}} */

#define _pooled _H<NSAutoreleasePool> _pool([[NSAutoreleasePool alloc] init], true);

void NSLogPoint(const char *fix, const CGPoint &point);
void NSLogRect(const char *fix, const CGRect &rect);
NSString *CydiaURL(NSString *path);

/* [NSObject yieldToSelector:(withObject:)] {{{*/
@interface NSObject (Cydia)
- (id) yieldToSelector:(SEL)selector withObject:(id)object;
- (id) yieldToSelector:(SEL)selector;
@end

/* Information Dictionaries {{{ */
@interface NSMutableArray (Cydia)
- (void) addInfoDictionary:(NSDictionary *)info;
@end

@interface NSMutableDictionary (Cydia)
- (void) addInfoDictionary:(NSDictionary *)info;
@end

/* Pop Transitions {{{ */
@interface PopTransitionView : UITransitionView {
}

@end

#define lprintf(args...) fprintf(stderr, args)

#define ForRelease 1
#define TraceLogging (1 && !ForRelease)
#define HistogramInsertionSort (0 && !ForRelease)
#define ProfileTimes (0 && !ForRelease)
#define ForSaurik (1 && !ForRelease)
#define LogBrowser (0 && !ForRelease)
#define TrackResize (0 && !ForRelease)
#define ManualRefresh (1 && !ForRelease)
#define ShowInternals (0 && !ForRelease)
#define IgnoreInstall (0 && !ForRelease)
#define RecycleWebViews 0
#define RecyclePackageViews (1 && ForRelease)
#define AlwaysReload (1 && !ForRelease)

#if !TraceLogging
#undef _trace
#define _trace(args...)
#endif

#if !ProfileTimes
#undef _profile
#define _profile(name) {
#undef _end
#define _end }
#define PrintTimes() do {} while (false)
#endif

/* Radix Sort {{{ */
typedef uint32_t (*SKRadixFunction)(id, void *);

@interface NSMutableArray (Radix)
- (void) radixSortUsingSelector:(SEL)selector withObject:(id)object;
- (void) radixSortUsingFunction:(SKRadixFunction)function withContext:(void *)argument;
@end

struct RadixItem_ {
    size_t index;
    uint32_t key;
};

void RadixSort_(NSMutableArray *self, size_t count, struct RadixItem_ *swap);

@class Package;
CFComparisonResult PackageNameCompare_(Package **lhs, Package **rhs, void *context);
CFComparisonResult PackageNameCompare(Package *lhs, Package *rhs, void *arg);

uint32_t PackagePrefixRadix(Package *self, void *context);
uint32_t PackageChangesRadix(Package *self, void *);

struct PackageNameOrdering :
std::binary_function<Package *, Package *, bool>
{
    _finline bool operator ()(Package *lhs, Package *rhs) const {
        return PackageNameCompare(lhs, rhs, NULL) == NSOrderedAscending;
    }
};

void CFArrayInsertionSortValues(CFMutableArrayRef array, CFRange range, CFComparatorFunction comparator, void *context);
extern const NSStringCompareOptions MatchCompareOptions_;
extern const NSStringCompareOptions LaxCompareOptions_;
extern const CFStringCompareFlags LaxCompareFlags_;

@interface NSString (UIKit)
- (NSString *) stringByAddingPercentEscapes;
@end

/* Cydia NSString Additions {{{ */
@interface NSString (Cydia)
+ (NSString *) stringWithUTF8BytesNoCopy:(const char *)bytes length:(int)length;
+ (NSString *) stringWithUTF8Bytes:(const char *)bytes length:(int)length withZone:(NSZone *)zone inPool:(apr_pool_t *)pool;
+ (NSString *) stringWithUTF8Bytes:(const char *)bytes length:(int)length;
- (NSComparisonResult) compareByPath:(NSString *)other;
- (NSString *) stringByCachingURLWithCurrentCDN;
- (NSString *) stringByAddingPercentEscapesIncludingReserved;
@end

/* Perl-Compatible RegEx {{{ */
class Pcre {
private:
    pcre *code_;
    pcre_extra *study_;
    int capture_;
    int *matches_;
    const char *data_;
	
public:
    Pcre(const char *regex) :
	study_(NULL)
    {
        const char *error;
        int offset;
        code_ = pcre_compile(regex, 0, &error, &offset, NULL);
		
        if (code_ == NULL) {
            lprintf("%d:%s\n", offset, error);
            _assert(false);
        }
		
        pcre_fullinfo(code_, study_, PCRE_INFO_CAPTURECOUNT, &capture_);
        matches_ = new int[(capture_ + 1) * 3];
    }
	
    ~Pcre() {
        pcre_free(code_);
        delete matches_;
    }
	
    NSString *operator [](size_t match) {
        return [NSString stringWithUTF8Bytes:(data_ + matches_[match * 2]) length:(matches_[match * 2 + 1] - matches_[match * 2])];
    }
	
    bool operator ()(NSString *data) {
        // XXX: length is for characters, not for bytes
        return operator ()([data UTF8String], [data length]);
    }
	
    bool operator ()(const char *data, size_t size) {
        data_ = data;
        return pcre_exec(code_, study_, data, size, 0, 0, matches_, (capture_ + 1) * 3) >= 0;
    }
};
/* }}} */


/* CoreGraphics Primitives {{{ */
class CGColor {
private:
    CGColorRef color_;
	
public:
    CGColor() :
	color_(NULL)
    {
    }
	
    CGColor(CGColorSpaceRef space, float red, float green, float blue, float alpha) :
	color_(NULL)
    {
        Set(space, red, green, blue, alpha);
    }
	
    void Clear() {
        if (color_ != NULL)
            CGColorRelease(color_);
    }
	
    ~CGColor() {
        Clear();
    }
	
    void Set(CGColorSpaceRef space, float red, float green, float blue, float alpha) {
        Clear();
        float color[] = {red, green, blue, alpha};
        color_ = CGColorCreate(space, color);
    }
	
    operator CGColorRef() {
        return color_;
    }
};
/* }}} */




/* Random Global Variables {{{ */
extern const int PulseInterval_;
extern const int ButtonBarHeight_;
extern const float KeyboardTime_;

extern int Finish_;
extern NSArray *Finishes_;

#define SpringBoard_ "/System/Library/LaunchDaemons/com.apple.SpringBoard.plist"
#define NotifyConfig_ "/etc/notify.conf"

extern bool Queuing_;

extern CGColor Blue_;
extern CGColor Blueish_;
extern CGColor Black_;
extern CGColor Off_;
extern CGColor White_;
extern CGColor Gray_;
extern CGColor Green_;
extern CGColor Purple_;
extern CGColor Purplish_;

extern UIColor *InstallingColor_;
extern UIColor *RemovingColor_;

extern NSString *App_;
extern NSString *Home_;

extern BOOL Advanced_;
extern BOOL Ignored_;

extern UIFont *Font12_;
extern UIFont *Font12Bold_;
extern UIFont *Font14_;
extern UIFont *Font18Bold_;
extern UIFont *Font22Bold_;

extern const char *Machine_;
extern const NSString *System_;
extern const NSString *SerialNumber_;
extern const NSString *ChipID_;
extern const NSString *UniqueID_;
extern const NSString *Build_;
extern const NSString *Product_;
extern const NSString *Safari_;
extern CYString &(*PackageName)(Package *self, SEL sel);

extern CFLocaleRef Locale_;
extern NSArray *Languages_;
extern CGColorSpaceRef space_;

extern bool reload_;

extern NSDictionary *SectionMap_;
extern NSMutableDictionary *Metadata_;
extern _transient NSMutableDictionary *Settings_;
extern _transient NSString *Role_;
extern _transient NSMutableDictionary *Packages_;
extern _transient NSMutableDictionary *Sections_;
extern _transient NSMutableDictionary *Sources_;
extern bool Changed_;
extern NSDate *now_;

#if RecycleWebViews
extern NSMutableArray *Documents_;
#endif
/* }}} */

NSUInteger DOMNodeList$countByEnumeratingWithState$objects$count$(DOMNodeList *self, SEL sel, NSFastEnumerationState *state, id *objects, NSUInteger count);


inline float Interpolate(float begin, float end, float fraction);
NSString *SizeString(double size);
CFStringRef CFCString(const char *value);
const char *StripVersion_(const char *version);
CFStringRef StripVersion(const char *version);
NSString *LocalizeSection(NSString *section);
NSString *Simplify(NSString *title);
NSString *GetLastUpdate();
bool isSectionVisible(NSString *section);

#import "Protocols.h"


extern NSString *Colon_;
extern NSString *Error_;
extern NSString *Warning_;

bool DepSubstrate(const pkgCache::VerIterator &iterator);

void _setHomePage(Cydia *self);

