/*
 *  Copyright (c) 2013-2014 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import <XCTest/XCTest.h>
#import "NSMethodSignature+OCMAdditions.h"

#if TARGET_OS_IPHONE
#define NSPoint CGPoint
#define NSSize  CGSize
#define NSRect  CGRect
#endif

@interface NSMethodSignatureOCMAdditionsTests : XCTestCase

@end

@implementation NSMethodSignatureOCMAdditionsTests

- (void)testDeterminesThatSpecialReturnIsNotNeededForNonStruct
{
    const char *types = "i";
   	NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:types];
    XCTAssertFalse([sig usesSpecialStructureReturn], @"Should have determined no need for special (stret) return.");
}

- (void)testDeterminesThatSpecialReturnIsNeededForLargeStruct
{
    // This type should(!) require special returns for all architectures
    const char *types = "{CATransform3D=ffffffffffffffff}";
   	NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:types];
    XCTAssertTrue([sig usesSpecialStructureReturn], @"Should have determined need for special (stret) return.");
}

- (void)testArchDependentSpecialReturns
{
#define ASSERT_ENC(expected, enctype) do {\
   BOOL useSpecial = expected; \
   XCTAssertNoThrow(useSpecial = [[NSMethodSignature signatureWithObjCTypes:enctype] usesSpecialStructureReturn], \
                  @"NSMethodSignature failed for type '%s'", enctype); \
   XCTAssertEqual((int)useSpecial, (int)expected,\
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
	XCTAssertTrue(stretYESRange.length > 0 || stretNORange.length > 0, @"NSMethodSignature debugDescription has changed; need to change OCPartialMockObject impl");
}


@end
