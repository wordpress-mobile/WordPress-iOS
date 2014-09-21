/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "MPTweakInline.h"
#import "MPTweak.h"
#import "MPTweakStore.h"

#import <libkern/OSAtomic.h>
#import <mach-o/getsect.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

static MPTweak *_MPTweakCreateWithEntry(NSString *name, mp_tweak_entry *entry)
{
    NSString *encoding = [NSString stringWithFormat:@"%s", *entry->encoding];
    MPTweak *tweak = [[MPTweak alloc] initWithName:name andEncoding:encoding];

  if (strcmp(*entry->encoding, @encode(BOOL)) == 0) {
    tweak.defaultValue = @(*(BOOL *)entry->value);
  } else if (strcmp(*entry->encoding, @encode(float)) == 0) {
    tweak.defaultValue = [NSNumber numberWithFloat:*(float *)entry->value];
    if (entry->min != NULL && entry->max != NULL) {
      tweak.minimumValue = [NSNumber numberWithFloat:*(float *)entry->min];
      tweak.maximumValue = [NSNumber numberWithFloat:*(float *)entry->max];
    }
  } else if (strcmp(*entry->encoding, @encode(double)) == 0) {
    tweak.defaultValue = [NSNumber numberWithDouble:*(double *)entry->value];
    if (entry->min != NULL && entry->max != NULL) {
      tweak.minimumValue = [NSNumber numberWithDouble:*(double *)entry->min];
      tweak.maximumValue = [NSNumber numberWithDouble:*(double *)entry->max];
    }
  } else if (strcmp(*entry->encoding, @encode(short)) == 0) {
      tweak.defaultValue = [NSNumber numberWithShort:*(short *)entry->value];
      if (entry->min != NULL && entry->max != NULL) {
          tweak.minimumValue = [NSNumber numberWithShort:*(short *)entry->min];
          tweak.maximumValue = [NSNumber numberWithShort:*(short *)entry->max];
      }
  } else if (strcmp(*entry->encoding, @encode(unsigned short)) == 0) {
      tweak.defaultValue = [NSNumber numberWithUnsignedShort:*(unsigned short int *)entry->value];
      if (entry->min != NULL && entry->max != NULL) {
          tweak.minimumValue = [NSNumber numberWithUnsignedShort:*(unsigned short *)entry->min];
          tweak.maximumValue = [NSNumber numberWithUnsignedShort:*(unsigned short *)entry->max];
      }
  } else if (strcmp(*entry->encoding, @encode(int)) == 0) {
    tweak.defaultValue = [NSNumber numberWithInt:*(int *)entry->value];
    if (entry->min != NULL && entry->max != NULL) {
      tweak.minimumValue = [NSNumber numberWithInt:*(int *)entry->min];
      tweak.maximumValue = [NSNumber numberWithInt:*(int *)entry->max];
    }
  } else if (strcmp(*entry->encoding, @encode(uint)) == 0) {
    tweak.defaultValue = [NSNumber numberWithUnsignedInt:*(uint *)entry->value];
    if (entry->min != NULL && entry->max != NULL) {
      tweak.minimumValue = [NSNumber numberWithUnsignedInt:*(uint *)entry->min];
      tweak.maximumValue = [NSNumber numberWithUnsignedInt:*(uint *)entry->max];
    }
  } else if (strcmp(*entry->encoding, @encode(long)) == 0) {
      tweak.defaultValue = [NSNumber numberWithLong:*(long *)entry->value];
      if (entry->min != NULL && entry->max != NULL) {
          tweak.minimumValue = [NSNumber numberWithLong:*(long *)entry->min];
          tweak.maximumValue = [NSNumber numberWithLong:*(long *)entry->max];
      }
  } else if (strcmp(*entry->encoding, @encode(unsigned long)) == 0) {
      tweak.defaultValue = [NSNumber numberWithUnsignedLong:*(unsigned long *)entry->value];
      if (entry->min != NULL && entry->max != NULL) {
          tweak.minimumValue = [NSNumber numberWithUnsignedLong:*(unsigned long *)entry->min];
          tweak.maximumValue = [NSNumber numberWithUnsignedLong:*(unsigned long *)entry->max];
      }
  } else if (strcmp(*entry->encoding, @encode(long long)) == 0) {
      tweak.defaultValue = [NSNumber numberWithLongLong:*(long long *)entry->value];
      if (entry->min != NULL && entry->max != NULL) {
          tweak.minimumValue = [NSNumber numberWithLongLong:*(long long *)entry->min];
          tweak.maximumValue = [NSNumber numberWithLongLong:*(long long *)entry->max];
      }
  } else if (strcmp(*entry->encoding, @encode(unsigned long long)) == 0) {
      tweak.defaultValue = [NSNumber numberWithUnsignedLongLong:*(unsigned long long *)entry->value];
      if (entry->min != NULL && entry->max != NULL) {
          tweak.minimumValue = [NSNumber numberWithUnsignedLongLong:*(unsigned long long *)entry->min];
          tweak.maximumValue = [NSNumber numberWithUnsignedLongLong:*(unsigned long long *)entry->max];
      }
  } else if (*entry->encoding[0] == '[') {
    // Assume it's a C string.
    tweak.defaultValue = [NSString stringWithUTF8String:entry->value];
  } else if (strcmp(*entry->encoding, @encode(id)) == 0) {
    tweak.defaultValue = *((__unsafe_unretained id *)entry->value);
  } else {
    NSCAssert(NO, @"Unknown encoding %s for tweak %@. Value was %p.", *entry->encoding, *entry->name, entry->value);
    tweak = nil;
  }

  return tweak;
}

@interface _MPTweakInlineLoader : NSObject

@end

@implementation _MPTweakInlineLoader

+ (void)load
{
  static uint32_t _tweaksLoaded = 0;
  if (OSAtomicTestAndSetBarrier(1, &_tweaksLoaded)) {
    return;
  }

#ifdef __LP64__
  typedef uint64_t mp_tweak_value;
  typedef struct section_64 mp_tweak_section;
#define mp_tweak_getsectbynamefromheader getsectbynamefromheader_64
#else
  typedef uint32_t mp_tweak_value;
  typedef struct section mp_tweak_section;
#define mp_tweak_getsectbynamefromheader getsectbynamefromheader
#endif

  MPTweakStore *store = [MPTweakStore sharedInstance];

  Dl_info info;
  dladdr((void *)&_MPTweakCreateWithEntry, &info);

  const mp_tweak_value mach_header = (mp_tweak_value)info.dli_fbase;
  const mp_tweak_section *section = mp_tweak_getsectbynamefromheader((void *)mach_header, MPTweakSegmentName, MPTweakSectionName);

  if (section == NULL) {
    return;
  }

  for (mp_tweak_value addr = section->offset; addr < section->offset + section->size; addr += sizeof(mp_tweak_entry)) {
    mp_tweak_entry *entry = (mp_tweak_entry *)(mach_header + addr);

    NSString *name = [NSString stringWithString:*entry->name];
    if ([store tweakWithName:name] == nil) {
      MPTweak *tweak = _MPTweakCreateWithEntry(name, entry);
      if (tweak != nil) {
        [store addTweak:tweak];
      }
    }
  }
}

@end

