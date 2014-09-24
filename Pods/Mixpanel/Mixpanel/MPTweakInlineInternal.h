/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "MPTweak.h"
#import "MPTweakStore.h"
#import "_MPTweakBindObserver.h"

#ifdef __cplusplus
extern "C" {
#endif

#define MPTweakSegmentName "__DATA"
#define MPTweakSectionName "MPTweak"

typedef __unsafe_unretained NSString *MPTweakLiteralString;

typedef struct {
  MPTweakLiteralString *name;
  void *value;
  void *min;
  void *max;
  char **encoding;
} mp_tweak_entry;

#if __has_feature(objc_arc)
#define _MPTweakRelease(x)
#else
#define _MPTweakRelease(x) [x release]
#endif

#define __MPTweakConcat_(X, Y) X ## Y
#define __MPTweakConcat(X, Y) __MPTweakConcat_(X, Y)

#define __MPTweakIndex(_1, _2, _3, value, ...) value
#define __MPTweakIndexCount(...) __MPTweakIndex(__VA_ARGS__, 3, 2, 1)

#define __MPTweakHasRange1(__withoutRange, __withRange, ...) __withoutRange
#define __MPTweakHasRange2(__withoutRange, __withRange, ...) __MPTweakInvalidNumberOfArgumentsPassed
#define __MPTweakHasRange3(__withoutRange, __withRange, ...) __withRange
#define _MPTweakHasRange(__withoutRange, __withRange, ...) __MPTweakConcat(__MPTweakHasRange, __MPTweakIndexCount(__VA_ARGS__))(__withoutRange, __withRange)

#define _MPTweakInlineWithoutRange(name_, default_) \
  _MPTweakInlineWithRangeInternal(name_, default_, NO, NULL, NO, NULL)
#define _MPTweakInlineWithRange(name_, default_, min_, max_) \
  _MPTweakInlineWithRangeInternal(name_, default_, YES, min_, YES, max_)
#define _MPTweakInlineWithRangeInternal(name_, default_, hasmin_, min_, hasmax_, max_) \
((^{ \
  /* store the tweak data in the binary at compile time. */ \
  __attribute__((used)) static MPTweakLiteralString name__ = name_; \
  __attribute__((used)) static __typeof__(default_) default__ = default_; \
  __attribute__((used)) static __typeof__(min_) min__ = min_; \
  __attribute__((used)) static __typeof__(max_) max__ = max_; \
  __attribute__((used)) static char *encoding__ = (char *)@encode(__typeof__(default_)); \
  __attribute__((used)) __attribute__((section (MPTweakSegmentName "," MPTweakSectionName))) static mp_tweak_entry entry = \
    {&name__, &default__, hasmin_ ? &min__ : NULL, hasmax_ ? &max__ : NULL, &encoding__ }; \
\
  /* find the registered tweak with the given name. */ \
  return [[MPTweakStore sharedInstance] tweakWithName:[NSString stringWithString:*entry.name]]; \
})())
#define _MPTweakInline(name_, ...) _MPTweakHasRange(_MPTweakInlineWithoutRange, _MPTweakInlineWithRange, __VA_ARGS__)(name_, __VA_ARGS__)

#define _MPTweakValueInternal(tweak_, name_, default_, hasmin_, min_, hasmax_, max_) \
((^{ \
  /* returns a correctly typed version of the current tweak value */ \
  _Pragma("clang diagnostic push") \
  _Pragma("clang diagnostic ignored \"-Wc11-extensions\"") \
  MPTweakValue currentValue = tweak_.currentValue ?: tweak_.defaultValue; \
  return _Generic(default_, \
    float: [currentValue floatValue], \
    const float: [currentValue floatValue], \
    double: [currentValue doubleValue], \
    const double: [currentValue doubleValue], \
    short: [currentValue shortValue], \
    const short: [currentValue shortValue], \
    unsigned short: [currentValue unsignedShortValue], \
    const unsigned short: [currentValue unsignedShortValue], \
    int: [currentValue intValue], \
    const int: [currentValue intValue], \
    unsigned int: [currentValue unsignedIntValue], \
    const unsigned int: [currentValue unsignedIntValue], \
    long long: [currentValue longLongValue], \
    const long long: [currentValue longLongValue], \
    unsigned long long: [currentValue unsignedLongLongValue], \
    const unsigned long long: [currentValue unsignedLongLongValue], \
    BOOL: [currentValue boolValue], \
    const BOOL: [currentValue boolValue], \
    id: currentValue, \
    const id: currentValue, \
    /* assume char * as the default. */ \
    /* constant strings are typed as char[N] */ \
    /* and we can't enumerate all of those. */ \
    /* luckily, we only need one fallback */ \
    default: [currentValue UTF8String] \
  ); \
  _Pragma("clang diagnostic pop") \
})())

#define _MPTweakValueWithoutRange(name_, default_) _MPTweakValueWithRangeInternal(name_, default_, NO, NULL, NO, NULL)
#define _MPTweakValueWithRange(name_, default_, min_, max_) _MPTweakValueWithRangeInternal(name_, default_, YES, min_, YES, max_)
#define _MPTweakValueWithRangeInternal(name_, default_, hasmin_, min_, hasmax_, max_) \
((^{ \
  MPTweak *tweak = _MPTweakInlineWithRangeInternal(name_, default_, hasmin_, min_, hasmax_, max_); \
  return _MPTweakValueInternal(tweak, name_, default_, hasmin_, min_, hasmax_, max_); \
})())
#define _MPTweakValue(name_, ...) _MPTweakHasRange(_MPTweakValueWithoutRange, _MPTweakValueWithRange, __VA_ARGS__)(name_, __VA_ARGS__)

#define _MPTweakBindWithoutRange(object_, property_, name_, default_) \
  _MPTweakBindWithRangeInternal(object_, property_, name_, default_, NO, NULL, NO, NULL)
#define _MPTweakBindWithRange(object_, property_, name_, default_, min_, max_) \
  _MPTweakBindWithRangeInternal(object_, property_, name_, default_, YES, min_, YES, max_)
#define _MPTweakBindWithRangeInternal(object_, property_, name_, default_, hasmin_, min_, hasmax_, max_) \
((^{ \
  MPTweak *tweak = _MPTweakInlineWithRangeInternal(name_, default_, hasmin_, min_, hasmax_, max_); \
  object_.property_ = _MPTweakValueInternal(tweak, name_, default_, hasmin_, min_, hasmax_, max_); \
\
  _MPTweakBindObserver *observer__ = [[_MPTweakBindObserver alloc] initWithTweak:tweak block:^(id object__) { \
    __typeof__(object_) object___ = object__; \
    object___.property_ = _MPTweakValueInternal(tweak, name_, default_, hasmin_, min_, hasmax_, max_); \
  }]; \
  [observer__ attachToObject:object_]; \
})())
#define _MPTweakBind(object_, property_, name_, ...) _MPTweakHasRange(_MPTweakBindWithoutRange, _MPTweakBindWithRange, __VA_ARGS__)(object_, property_, name_, __VA_ARGS__)

#ifdef __cplusplus
}
#endif

