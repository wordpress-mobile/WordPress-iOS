//
//  NSDictionaryDTErrorTest.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 10/18/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSDictionaryDTErrorTest.h"
#import "NSDictionary+DTError.h"

/**
 Tests for NSDictionary+DTError Category
 */
@implementation NSDictionaryDTErrorTest

/**
 Tests to get an NSDictionary out of invalid Plist data
 Has to return an NSError object
 */
- (void)testDictionaryWithContentsOfInvalidPlistData
{
    // get invalid Plist data
    NSString *invalidPlistDataString = @"/usdifusadfuiosdufisudfousdfmsa,s.,-,./&(/&(/=)(=)(=()";
    NSData *plistData = [invalidPlistDataString dataUsingEncoding:NSUTF8StringEncoding];
    
    // do conversion to NSDictionary
    NSError *error = nil;
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfData:plistData error:&error];
    
    // do checks
    XCTAssertNil(dictionary, @"Dictionary has content but should be nil");
    XCTAssertNotNil(error, @"No error occured with invalid Plist data");
}

/**
 Test to get an NSDictionary out of a valid Plist data
 No NSerror has to be returned
 */
- (void)testArrayWithValidPlist
{
    // get Plist data from file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *finalPath = [testBundle pathForResource:@"DictionarySample" ofType:@"plist"];
    NSData *plistData = [NSData dataWithContentsOfFile:finalPath];
    
    // do conversion to NSDictionary
    NSError *error = nil;
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfData:plistData error:&error];
    
    // do checks
    XCTAssertNil(error, @"Error occured during parsing of valid Plist data");
    XCTAssertTrue(4 == [[dictionary allValues] count], @"Wrong count of objects in dictionary");
}

@end
