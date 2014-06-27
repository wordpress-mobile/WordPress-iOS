//
//  NSObject_SafeExpectationsTest_OSX.m
//  NSObject+SafeExpectationsTest_OSX
//
//  Created by Jorge Bernal on 2/6/13.
//
//

#import "NSObject_SafeExpectationsTest.h"
#import "NSObject+SafeExpectations.h"

@implementation NSObject_SafeExpectationsTest_OSX

- (void)setUp
{
    [super setUp];

    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.

    // Fixes weird bug where Xcode would complain that tests didn't finish
    // because they actually finished too fast
    NSLog(@"done");

    [super tearDown];
}

- (void)testDictionary
{
    NSDictionary *dict = @{
                           @"string": @"test string",
                           @"numString": @"123",
                           @"doubleString": @"123.456789012345",
                           @"num": @123,
                           @"array": @[@1,@2,@3],
                           @"dict": @{@"test1": @100, @"test2": @200}
                           };

    STAssertNil([dict stringForKey:@"undefined"], nil);

    // stringForKey:
    STAssertNotNil([dict stringForKey:@"string"], nil);
    STAssertNotNil([dict stringForKey:@"numString"], nil);
    STAssertNotNil([dict stringForKey:@"num"], nil);
    STAssertNil([dict stringForKey:@"array"], nil);
    STAssertNil([dict stringForKey:@"dict"], nil);

    STAssertEqualObjects([dict stringForKey:@"string"], @"test string", nil);
    STAssertEqualObjects([dict stringForKey:@"numString"], @"123", nil);
    STAssertEqualObjects([dict stringForKey:@"num"], @"123", nil);

    // numberForKey:
    STAssertNil([dict numberForKey:@"string"], nil);
    STAssertNotNil([dict numberForKey:@"numString"], nil);
    STAssertNotNil([dict numberForKey:@"doubleString"], nil);
    STAssertNotNil([dict numberForKey:@"num"], nil);
    STAssertNil([dict numberForKey:@"array"], nil);
    STAssertNil([dict numberForKey:@"dict"], nil);

    STAssertEqualObjects([dict numberForKey:@"numString"], @123, nil);
    STAssertEqualObjects([dict numberForKey:@"doubleString"], @123.456789012345, nil);
    STAssertEqualObjects([dict numberForKey:@"num"], @123, nil);

    // arrayForKey:
    STAssertNil([dict arrayForKey:@"string"], nil);
    STAssertNil([dict arrayForKey:@"numString"], nil);
    STAssertNil([dict arrayForKey:@"doubleString"], nil);
    STAssertNil([dict arrayForKey:@"num"], nil);
    STAssertNotNil([dict arrayForKey:@"array"], nil);
    STAssertNil([dict arrayForKey:@"dict"], nil);
    STAssertEquals([[dict arrayForKey:@"array"] count], (NSUInteger)3, nil);

    // dictionaryForKey:
    STAssertNil([dict dictionaryForKey:@"string"], nil);
    STAssertNil([dict dictionaryForKey:@"numString"], nil);
    STAssertNil([dict dictionaryForKey:@"doubleString"], nil);
    STAssertNil([dict dictionaryForKey:@"num"], nil);
    STAssertNil([dict dictionaryForKey:@"array"], nil);
    STAssertNotNil([dict dictionaryForKey:@"dict"], nil);
    STAssertEquals([[dict dictionaryForKey:@"dict"] count], (NSUInteger)2, nil);
}

- (void)testDictionaryKeyPath
{
    NSDictionary *dict = @{@"level1": @{
                                   @"level2": @{
                                           @"string": @"test string",
                                           @"numString": @"123",
                                           @"doubleString": @"123.456789012345",
                                           @"num": @123,
                                           @"array": @[@1,@2,@3],
                                           @"dict": @{@"test1": @100, @"test2": @200}
                                           },
                                   @"string": @"test string",
                                   @"doubleString": @"123.456789012345",
                                   @"numString": @"123",
                                   @"num": @123,
                                   @"array": @[@1,@2,@3],
                                   @"dict": @{@"test1": @100, @"test2": @200}
                                   },
                           @"string": @"test string",
                           @"doubleString": @"123.456789012345",
                           @"numString": @"123",
                           @"num": @123,
                           @"array": @[@1,@2,@3],
                           @"dict": @{@"test1": @100, @"test2": @200}
                           };

    STAssertNotNil([dict objectForKeyPath:@"level1"], nil);
    STAssertNotNil([dict objectForKeyPath:@"level1.level2"], nil);
    STAssertNotNil([dict objectForKeyPath:@"level1.level2.string"], nil);
    STAssertNil([dict objectForKeyPath:@"level1.level2.level3"], nil);
    STAssertNil([dict objectForKeyPath:@"level1.level2.string.missing"], nil);

    // stringForKeyPath:
    STAssertNotNil([dict stringForKeyPath:@"level1.string"], nil);
    STAssertNotNil([dict stringForKeyPath:@"level1.numString"], nil);
    STAssertNotNil([dict stringForKeyPath:@"level1.num"], nil);
    STAssertNil([dict stringForKeyPath:@"level1.array"], nil);
    STAssertNil([dict stringForKeyPath:@"level1.dict"], nil);

    STAssertEqualObjects([dict stringForKeyPath:@"level1.string"], @"test string", nil);
    STAssertEqualObjects([dict stringForKeyPath:@"level1.numString"], @"123", nil);
    STAssertEqualObjects([dict stringForKeyPath:@"level1.num"], @"123", nil);

    // numberForKeyPath:
    STAssertNil([dict numberForKeyPath:@"level1.string"], nil);
    STAssertNotNil([dict numberForKeyPath:@"level1.numString"], nil);
    STAssertNotNil([dict numberForKeyPath:@"level1.doubleString"], nil);
    STAssertNotNil([dict numberForKeyPath:@"level1.num"], nil);
    STAssertNil([dict numberForKeyPath:@"level1.array"], nil);
    STAssertNil([dict numberForKeyPath:@"level1.dict"], nil);

    STAssertEqualObjects([dict numberForKeyPath:@"level1.numString"], @123, nil);
    STAssertEqualObjects([dict numberForKeyPath:@"level1.doubleString"], @123.456789012345, nil);
    STAssertEqualObjects([dict numberForKeyPath:@"level1.num"], @123, nil);

    // arrayForKeyPath:
    STAssertNil([dict arrayForKeyPath:@"level1.string"], nil);
    STAssertNil([dict arrayForKeyPath:@"level1.numString"], nil);
    STAssertNil([dict arrayForKeyPath:@"level1.doubleString"], nil);
    STAssertNil([dict arrayForKeyPath:@"level1.num"], nil);
    STAssertNotNil([dict arrayForKeyPath:@"level1.array"], nil);
    STAssertNil([dict arrayForKeyPath:@"level1.dict"], nil);
    STAssertEquals([[dict arrayForKeyPath:@"level1.array"] count], (NSUInteger)3, nil);

    // dictionaryForKeyPath:
    STAssertNil([dict dictionaryForKeyPath:@"level1.string"], nil);
    STAssertNil([dict dictionaryForKeyPath:@"level1.numString"], nil);
    STAssertNil([dict dictionaryForKeyPath:@"level1.doubleString"], nil);
    STAssertNil([dict dictionaryForKeyPath:@"level1.num"], nil);
    STAssertNil([dict dictionaryForKeyPath:@"level1.array"], nil);
    STAssertNotNil([dict dictionaryForKeyPath:@"level1.dict"], nil);
    STAssertEquals([[dict dictionaryForKeyPath:@"level1.dict"] count], (NSUInteger)2, nil);
}

@end
