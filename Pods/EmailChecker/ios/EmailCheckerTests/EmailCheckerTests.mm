//
//  EmailCheckerTests.m
//  EmailCheckerTests
//
//  Created by Maxime Biais on 12/11/2013.
//  Copyright (c) 2013 Automattic. All rights reserved.
//

#import <XCTest/XCTest.h>
#include "EmailDomainSpellChecker.h"

@interface EmailCheckerTests : XCTestCase

@end

@implementation EmailCheckerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    EmailDomainSpellChecker *edsc = new EmailDomainSpellChecker();
    std::string toTest;

    // Not modified tests
    toTest = "hello@mop.com";
    XCTAssert(edsc->suggestDomainCorrection(toTest).compare(toTest) == 0, @"%s must not be corrected", toTest.c_str());

    toTest = "hello@gmail.com";
    XCTAssert(edsc->suggestDomainCorrection(toTest).compare(toTest) == 0, @"%s must not be corrected", toTest.c_str());
    
    toTest = "hello";
    XCTAssert(edsc->suggestDomainCorrection(toTest).compare(toTest) == 0, @"%s must not be corrected", toTest.c_str());

    toTest = "hello@";
    XCTAssert(edsc->suggestDomainCorrection(toTest).compare(toTest) == 0, @"%s must not be corrected", toTest.c_str());
    
    toTest = "@";
    XCTAssert(edsc->suggestDomainCorrection(toTest).compare(toTest) == 0, @"%s must not be corrected", toTest.c_str());

    toTest = "";
    XCTAssert(edsc->suggestDomainCorrection(toTest).compare(toTest) == 0, @"%s must not be corrected", toTest.c_str());
    
    toTest = "@hello";
    XCTAssert(edsc->suggestDomainCorrection(toTest).compare(toTest) == 0, @"%s must not be corrected", toTest.c_str());

    toTest = "@hello.com";
    XCTAssert(edsc->suggestDomainCorrection(toTest).compare(toTest) == 0, @"%s must not be corrected", toTest.c_str());

    toTest = "kikoo@gmail.com";
    XCTAssert(edsc->suggestDomainCorrection(toTest).compare(toTest) == 0, @"%s must not be corrected", toTest.c_str());

    toTest = "kikoo@azdoij.cm";
    XCTAssert(edsc->suggestDomainCorrection("kikoo@azdoij.cm").compare(toTest) == 0, @"%s must not be corrected", toTest.c_str());
    
    // Expected suggestions
    XCTAssert(edsc->suggestDomainCorrection("hello@gmial.com").compare("hello@gmail.com") == 0);
    XCTAssert(edsc->suggestDomainCorrection("hello@gmai.com").compare("hello@gmail.com") == 0);
    XCTAssert(edsc->suggestDomainCorrection("hello@yohoo.com").compare("hello@yahoo.com") == 0);
    XCTAssert(edsc->suggestDomainCorrection("hello@yhoo.com").compare("hello@yahoo.com") == 0);
    XCTAssert(edsc->suggestDomainCorrection("hello@ayhoo.com").compare("hello@yahoo.com") == 0);
    XCTAssert(edsc->suggestDomainCorrection("hello@yhoo.com").compare("hello@yahoo.com") == 0);
    XCTAssert(edsc->suggestDomainCorrection("hello@outloo.com").compare("hello@outlook.com") == 0);
    XCTAssert(edsc->suggestDomainCorrection("hello@comcats.com").compare("hello@comcast.com") == 0);
    

    // private tests
    /*
    NSLog(@"TEST: %s", edsc->suggest("gmail.com").c_str());
    NSLog(@"TEST: %s", edsc->suggest("gamail.com").c_str());
    NSLog(@"TEST: %s", edsc->suggest("gmial.com").c_str());
    NSLog(@"TEST: %s", edsc->suggest("gmaiil.cm").c_str());
    */
}

@end
