//
//  DTVersionTest.h
//  iCatalog
//
//  Created by Rene Pirringer on 20.07.11.
//  Copyright 2011 Cocoanetics. All rights reserved.
//

//  Logic unit tests contain unit test code that is designed to be linked into an independent test executable.
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

#import <SenTestingKit/SenTestingKit.h>

@interface DTVersionTest : SenTestCase

- (void)testCreate; 
- (void)testEquals;
- (void)testCompare;
- (void)testLessThan;

@end
