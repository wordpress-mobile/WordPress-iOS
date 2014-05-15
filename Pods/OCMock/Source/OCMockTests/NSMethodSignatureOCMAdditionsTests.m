//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "NSMethodSignature+OCMAdditions.h"
#import "NSMethodSignatureOCMAdditionsTests.h"

#if TARGET_OS_IPHONE
#define NSPoint CGPoint
#define NSSize  CGSize
#define NSRect  CGRect
#endif

@implementation NSMethodSignatureOCMAdditionsTests

- (void)testDeterminesThatSpecialReturnIsNotNeededForNonStruct
{
    const char *types = "i";
   	NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:types];
    STAssertFalse([sig usesSpecialStructureReturn], @"Should have determined no need for special (stret) return.");
}

- (void)testDeterminesThatSpecialReturnIsNeededForLargeStruct
{
    // This type should(!) require special returns for all architectures
    const char *types = "{CATransform3D=ffffffffffffffff}";
   	NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:types];
    STAssertTrue([sig usesSpecialStructureReturn], @"Should have determined need for special (stret) return.");
}

- (void)testArchDependentSpecialReturns
{
#define ASSERT_ENC(expected, enctype) do {\
   BOOL useSpecial = expected; \
   STAssertNoThrow(useSpecial = [[NSMethodSignature signatureWithObjCTypes:enctype] usesSpecialStructureReturn], \
                  @"NSMethodSignature failed for type '%s'", enctype); \
   STAssertEquals((int)useSpecial, (int)expected,\
                  @"Special (stret) return incorrect for type '%s'", enctype); \
 } while (0)
#define ASSERT_TYPE(expected, type) ASSERT_ENC(expected, @encode(type))
    
#if __x86_64__
    ASSERT_TYPE(YES,NSRect);
    ASSERT_TYPE(NO, NSPoint);
    ASSERT_TYPE(NO, NSRange);
    ASSERT_ENC(NO, "{foo=ffff}");
    ASSERT_ENC(YES,"{foo=fffff}");
    ASSERT_ENC(YES,"{foo=D}");
    ASSERT_ENC(NO, "{foo=t}");
    ASSERT_ENC(YES,"{foo=TT}");
    ASSERT_TYPE(NO, __int128_t);
    ASSERT_TYPE(NO, long double);
    ASSERT_ENC(YES,"{nlist_64=(?=I)CCSQ}16@0:8");
#endif
#if __i386__
    ASSERT_TYPE(YES,NSRect);
    ASSERT_TYPE(NO, NSPoint);
    ASSERT_TYPE(NO, NSRange);
    ASSERT_TYPE(NO, long double);
    ASSERT_ENC(NO, "{foo=ff}");
    ASSERT_ENC(YES,"{foo=fff}");
    ASSERT_ENC(NO, "{foo=c}");
    ASSERT_ENC(NO, "{foo=cc}");
    ASSERT_ENC(YES,"{foo=ccc}");
    ASSERT_ENC(NO, "{foo=cccc}");
    ASSERT_ENC(YES,"{foo=cccccc}");
    ASSERT_ENC(NO, "{foo=cccccccc}");
    ASSERT_ENC(YES,"{foo=D}");
#endif
#if __arm__
    ASSERT_TYPE(YES, NSRect);
    ASSERT_TYPE(YES, NSPoint);
    ASSERT_TYPE(YES, NSRange);
    ASSERT_ENC(NO, "{foo=f}");
    ASSERT_ENC(YES,"{foo=ff}");
    ASSERT_ENC(NO, "{foo=c}");
    ASSERT_ENC(NO, "{foo=cc}");
    ASSERT_ENC(NO, "{foo=ccc}");
    ASSERT_ENC(NO, "{foo=cccc}");
    ASSERT_ENC(YES,"{foo=ccccc}");
#endif
}

- (void)testNSMethodSignatureDebugDescriptionWorksTheWayWeExpectIt
{
	const char *types = "{CATransform3D=ffffffffffffffff}";
	NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:types];
	NSString *debugDescription = [sig debugDescription];
	NSRange stretYESRange = [debugDescription rangeOfString:@"is special struct return? YES"];
	NSRange stretNORange = [debugDescription rangeOfString:@"is special struct return? NO"];
	STAssertTrue(stretYESRange.length > 0 || stretNORange.length > 0, @"NSMethodSignature debugDescription has changed; need to change OCPartialMockObject impl");
}


@end