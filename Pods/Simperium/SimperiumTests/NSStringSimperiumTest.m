//
//  NSStringSimperiumTest.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 4/8/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+Simperium.h"

@interface NSStringSimperiumTest : XCTestCase

@end

@implementation NSStringSimperiumTest

- (void)testSeparatingComponentsOnStringWithMissingSeparator
{
    NSString *sample = @"One Two Three Four Five Six Seven Eight Nine Ten";
    
    NSArray *result = [sample sp_componentsSeparatedByString:@":" limit:NSIntegerMax];

    XCTAssert(result.count == 1, @"Issue while splitting");
    XCTAssert([[result firstObject] isEqualToString:sample], @"Issue while splitting");
}

- (void)testSeparatingComponentsOnStringWithValidSeparator
{
    NSString *sample    = @"One:Two:Three:Four:Five:Six:Seven:Eight:Nine:Ten";
    NSArray *control    = [sample componentsSeparatedByString:@":"];
    
    for (NSInteger limit = 0; ++limit <= control.count; ) {
        NSArray *result = [sample sp_componentsSeparatedByString:@":" limit:limit];
        
        XCTAssert(result.count == limit, @"Issue while splitting");
        
        // Test [0, n-1] components
        for (NSInteger j = -1; ++j < result.count - 1; ) {
            XCTAssert([result[j] isEqual:control[j]], @"Issue while splitting");
        }
        
        // Test the last component
        NSInteger lastItem  = result.count - 1;
        NSRange subarray    = NSMakeRange(lastItem, control.count - lastItem);
        NSString *joined    = [[control subarrayWithRange:subarray] componentsJoinedByString:@":"];
        
        XCTAssert([[result lastObject] isEqual:joined], @"Issue while splitting last component");
    }
}

@end
