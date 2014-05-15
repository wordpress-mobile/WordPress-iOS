//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMArg.h"
#import "OCMArgTests.h"

#if TARGET_OS_IPHONE
#define NSRect CGRect
#define NSZeroRect CGRectZero
#define NSMakeRect CGRectMake
#define valueWithRect valueWithCGRect
#endif


@implementation OCMArgTests

- (void)testValueMacroCreatesCorrectValueObjects
{
    NSRange range = NSMakeRange(5, 5);
    STAssertEqualObjects(OCMOCK_VALUE(range), [NSValue valueWithRange:range], nil);
#if defined(__GNUC__) && !defined(__STRICT_ANSI__)
    /* Should work with constant values and some expressions */
    STAssertEqualObjects(OCMOCK_VALUE(YES), @YES, nil);
    STAssertEqualObjects(OCMOCK_VALUE(42), @42, nil);
    STAssertEqualObjects(OCMOCK_VALUE(NSZeroRect), [NSValue valueWithRect:NSZeroRect], nil);
    STAssertEqualObjects(OCMOCK_VALUE([@"0123456789" rangeOfString:@"56789"]), [NSValue valueWithRange:range], nil);
#endif
}

@end