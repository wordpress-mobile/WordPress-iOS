//
//  DTVersionTest.m
//  iCatalog
//
//  Created by Rene Pirringer on 20.07.11.
//  Copyright 2011 Cocoanetics. All rights reserved.
//

#import "DTVersionTest.h"
#import "DTVersion.h"

@implementation DTVersionTest

- (void)testCreate
{
	DTVersion *version = [DTVersion versionWithString:@"foobar"];
	XCTAssertNil(version, @"DTVersion object should not be create of an unsupported string");

	version = [DTVersion versionWithString:@"1.-1"];
	XCTAssertNil(version, @"DTVersion object should not be create of an unsupported string");

	//version = [DTVersion versionWithString:@"1.2.1.1"];
	//XCTAssertNil(version, @"DTVersion object should not be create of an unsupported string");

	
	version = [DTVersion versionWithString:@"1.2.3"];
	XCTAssertNotNil(version, @"DTVersion object should be create");
	XCTAssertEqual(1, (int)version.major, @"version.major is not the correct value %lu",(unsigned long)version.major);
	XCTAssertEqual(2, (int)version.minor, @"version.minor is not the correct value %lu", (unsigned long)version.minor);
	XCTAssertEqual(3, (int)version.maintenance, @"version.maintenance is not the correct value %lu", (unsigned long)version.maintenance);

	version = [DTVersion versionWithString:@"2.9999"];
	XCTAssertNotNil(version, @"DTVersion object should be create");
	XCTAssertEqual(2, (int)version.major, @"version.major is not the correct value %lu", (unsigned long)version.major);
	XCTAssertEqual(9999, (int)version.minor, @"version.minor is not the correct value %lu", (unsigned long)version.minor);
	XCTAssertEqual(0, (int)version.maintenance, @"version.maintenance is not the correct value %lu", (unsigned long)version.maintenance);

	version = [DTVersion versionWithString:@"1"];
	XCTAssertNotNil(version, @"DTVersion object should be create");
	XCTAssertEqual(1, (int)version.major, @"version.major is not the correct value %lu", (unsigned long)version.major);
	XCTAssertEqual(0, (int)version.minor, @"version.minor is not the correct value %lu", (unsigned long)version.minor);
	XCTAssertEqual(0, (int)version.maintenance, @"version.maintenance is not the correct value %lu", (unsigned long)version.maintenance);


	version = [DTVersion versionWithString:@"1.2.3.4"];
	XCTAssertNotNil(version, @"DTVersion object should be create");
	XCTAssertEqual(1, (int)version.major, @"version.major is not the correct value %lu", (unsigned long)version.major);
	XCTAssertEqual(2, (int)version.minor, @"version.minor is not the correct value %lu", (unsigned long)version.minor);
	XCTAssertEqual(3, (int)version.maintenance, @"version.maintenance is not the correct value %lu", (unsigned long)version.maintenance);
	XCTAssertEqual(4, (int)version.build, @"version.build is not the correct value %lu", (unsigned long)version.build);
}


- (void)testEquals
{
	DTVersion *first = [DTVersion versionWithString:@"1.2.3"];
	DTVersion *second = [DTVersion versionWithString:@"1.2.4"];
	
	XCTAssertFalse([first isEqualToVersion:second], @"first version is not equal to second, but should");
	XCTAssertFalse([first isEqual:second], @"first version is not equal to second, but should");

	second = [DTVersion versionWithString:@"1.2"];
	XCTAssertFalse([first isEqualToVersion:second], @"first version is equal to second, but should not");
	XCTAssertFalse([first isEqual:second], @"first version is equal to second, but should not");
	
	first = [DTVersion versionWithString:@"1.0.0"];
	second = [DTVersion versionWithString:@"1"];
	XCTAssertTrue([first isEqualToVersion:second], @"first version is not equal to second, but should");
	XCTAssertTrue([first isEqual:second], @"first version is not equal to second, but should");

	second = [DTVersion versionWithString:@"1.0"];
	XCTAssertTrue([first isEqualToVersion:second], @"first version is not equal to second, but should");
	XCTAssertTrue([first isEqual:second], @"first version is not equal to second, but should");

	
	XCTAssertTrue([first isEqualToString:@"1.0.0"], @"first version is not equal to second, but should");
	XCTAssertTrue([first isEqual:@"1.0.0"], @"first version is not equal to second, but should");
	XCTAssertTrue([first isEqualToString:@"1.0"], @"first version is not equal to second, but should");
	XCTAssertTrue([first isEqualToString:@"1"], @"first version is not equal to second, but should");
	XCTAssertTrue([first isEqual:@"1.0.0.0"], @"first version is not equal to second, but should");

	XCTAssertFalse([first isEqualToString:@"1.2"], @"first version is equal to second, but should not");
	XCTAssertFalse([first isEqualToString:@"1.1.1"], @"first version is equal to second, but should not");
	XCTAssertFalse([first isEqualToString:@"foobar"], @"first version is equal to second, but should not");
	XCTAssertFalse([first isEqualToString:@"0.0.0"], @"first version is equal to second, but should not");


	first = [DTVersion versionWithString:@"1.2.3.4"];
	second = [DTVersion versionWithString:@"1.2.3.4"];
	XCTAssertTrue([first isEqualToVersion:second], @"first version is not equal to second, but should");
}


- (void)testCompare
{
	DTVersion *first = [DTVersion versionWithString:@"1.2.3"];
	DTVersion *second = [DTVersion versionWithString:@"1.2.3"];

	XCTAssertEqual(NSOrderedSame, [first compare:second], @"should be the same");

	second = [DTVersion versionWithString:@"1.2.0"];
	XCTAssertEqual(NSOrderedDescending, [first compare:second], @"%@ should be larger then %@", first, second);

	second = [DTVersion versionWithString:@"1.2.4"];
	XCTAssertEqual(NSOrderedAscending, [first compare:second], @"%@ should be smaller then %@", first, second);

	second = [DTVersion versionWithString:@"0.9.9"];
	XCTAssertEqual(NSOrderedDescending, [first compare:second], @"%@ should be smaller then %@", first, second);


	second = [DTVersion versionWithString:@"0.9.9"];
	XCTAssertEqual(NSOrderedDescending, [first compare:nil], @"%@ should be smaller then %@", first, second);


	second = [DTVersion versionWithString:@"0.9.9.0"];
	XCTAssertEqual(NSOrderedDescending, [first compare:nil], @"%@ should be smaller then %@", first, second);
}

- (void)testLessThan
{
	DTVersion *first = [DTVersion versionWithString:@"1.0"];
	DTVersion *second = [DTVersion versionWithString:@"2.0"];

	XCTAssertTrue([first isLessThenVersion:second], @"first version is not less the second");
	XCTAssertFalse([second isLessThenVersion:first], @"second should not be less then first");

	XCTAssertTrue([second isGreaterThenVersion:first], @"second version is not greater then first");

	XCTAssertFalse([second isLessThenVersionString:@"2.0.0"], @"second should not be less then 2.0.0");
	XCTAssertFalse([second isLessThenVersionString:@"1.9.9"], @"second should not be less then 1.9.9");
	XCTAssertTrue([second isLessThenVersionString:@"2.0.1"], @"second should be less then 2.0.0");
}

- (void)testVersion
{
	DTVersion *first = [DTVersion versionWithString:@"8.00.047 build 010"];
	DTVersion *second = [DTVersion versionWithString:@"8.00.047"];

	XCTAssertEqual(NSOrderedSame, [first compare:second], @"should be the same");

	XCTAssertFalse([first isLessThenVersionString:@"8.00.047"], @"first version is not less than 8.00.047");

	second = [DTVersion versionWithString:@"8.00.047 build 010"];
	XCTAssertEqual(NSOrderedSame, [first compare:second], @"should be the same");
}

@end
