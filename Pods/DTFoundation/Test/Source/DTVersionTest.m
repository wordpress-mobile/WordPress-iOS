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
	STAssertNil(version, @"DTVersion object should not be create of an unsupported string");

	version = [DTVersion versionWithString:@"1.-1"];
	STAssertNil(version, @"DTVersion object should not be create of an unsupported string");

	//version = [DTVersion versionWithString:@"1.2.1.1"];
	//STAssertNil(version, @"DTVersion object should not be create of an unsupported string");

	
	version = [DTVersion versionWithString:@"1.2.3"];
	STAssertNotNil(version, @"DTVersion object should be create");
	STAssertEquals(1, (int)version.major, @"version.major is not the correct value %d", version.major);
	STAssertEquals(2, (int)version.minor, @"version.minor is not the correct value %d", version.minor);
	STAssertEquals(3, (int)version.maintenance, @"version.maintenance is not the correct value %d", version.maintenance);

	version = [DTVersion versionWithString:@"2.9999"];
	STAssertNotNil(version, @"DTVersion object should be create");
	STAssertEquals(2, (int)version.major, @"version.major is not the correct value %d", version.major);
	STAssertEquals(9999, (int)version.minor, @"version.minor is not the correct value %d", version.minor);
	STAssertEquals(0, (int)version.maintenance, @"version.maintenance is not the correct value %d", version.maintenance);

	version = [DTVersion versionWithString:@"1"];
	STAssertNotNil(version, @"DTVersion object should be create");
	STAssertEquals(1, (int)version.major, @"version.major is not the correct value %d", version.major);
	STAssertEquals(0, (int)version.minor, @"version.minor is not the correct value %d", version.minor);
	STAssertEquals(0, (int)version.maintenance, @"version.maintenance is not the correct value %d", version.maintenance);


	version = [DTVersion versionWithString:@"1.2.3.4"];
	STAssertNotNil(version, @"DTVersion object should be create");
	STAssertEquals(1, (int)version.major, @"version.major is not the correct value %d", version.major);
	STAssertEquals(2, (int)version.minor, @"version.minor is not the correct value %d", version.minor);
	STAssertEquals(3, (int)version.maintenance, @"version.maintenance is not the correct value %d", version.maintenance);
	STAssertEquals(4, (int)version.build, @"version.build is not the correct value %d", version.build);
}


- (void)testEquals
{
	DTVersion *first = [DTVersion versionWithString:@"1.2.3"];
	DTVersion *second = [DTVersion versionWithString:@"1.2.4"];
	
	STAssertFalse([first isEqualToVersion:second], @"first version is not equal to second, but should");
	STAssertFalse([first isEqual:second], @"first version is not equal to second, but should");

	second = [DTVersion versionWithString:@"1.2"];
	STAssertFalse([first isEqualToVersion:second], @"first version is equal to second, but should not");
	STAssertFalse([first isEqual:second], @"first version is equal to second, but should not");
	
	first = [DTVersion versionWithString:@"1.0.0"];
	second = [DTVersion versionWithString:@"1"];
	STAssertTrue([first isEqualToVersion:second], @"first version is not equal to second, but should");
	STAssertTrue([first isEqual:second], @"first version is not equal to second, but should");

	second = [DTVersion versionWithString:@"1.0"];
	STAssertTrue([first isEqualToVersion:second], @"first version is not equal to second, but should");
	STAssertTrue([first isEqual:second], @"first version is not equal to second, but should");

	
	STAssertTrue([first isEqualToString:@"1.0.0"], @"first version is not equal to second, but should");
	STAssertTrue([first isEqual:@"1.0.0"], @"first version is not equal to second, but should");
	STAssertTrue([first isEqualToString:@"1.0"], @"first version is not equal to second, but should");
	STAssertTrue([first isEqualToString:@"1"], @"first version is not equal to second, but should");
	STAssertTrue([first isEqual:@"1.0.0.0"], @"first version is not equal to second, but should");

	STAssertFalse([first isEqualToString:@"1.2"], @"first version is equal to second, but should not");
	STAssertFalse([first isEqualToString:@"1.1.1"], @"first version is equal to second, but should not");
	STAssertFalse([first isEqualToString:@"foobar"], @"first version is equal to second, but should not");
	STAssertFalse([first isEqualToString:@"0.0.0"], @"first version is equal to second, but should not");


	first = [DTVersion versionWithString:@"1.2.3.4"];
	second = [DTVersion versionWithString:@"1.2.3.4"];
	STAssertTrue([first isEqualToVersion:second], @"first version is not equal to second, but should");
}


- (void)testCompare
{
	DTVersion *first = [DTVersion versionWithString:@"1.2.3"];
	DTVersion *second = [DTVersion versionWithString:@"1.2.3"];

	STAssertEquals(NSOrderedSame, [first compare:second], @"should be the same");

	second = [DTVersion versionWithString:@"1.2.0"];
	STAssertEquals(NSOrderedDescending, [first compare:second], @"%@ should be larger then %@", first, second);

	second = [DTVersion versionWithString:@"1.2.4"];
	STAssertEquals(NSOrderedAscending, [first compare:second], @"%@ should be smaller then %@", first, second);

	second = [DTVersion versionWithString:@"0.9.9"];
	STAssertEquals(NSOrderedDescending, [first compare:second], @"%@ should be smaller then %@", first, second);


	second = [DTVersion versionWithString:@"0.9.9"];
	STAssertEquals(NSOrderedDescending, [first compare:nil], @"%@ should be smaller then %@", first, second);


	second = [DTVersion versionWithString:@"0.9.9.0"];
	STAssertEquals(NSOrderedDescending, [first compare:nil], @"%@ should be smaller then %@", first, second);
}

- (void)testLessThan
{
	DTVersion *first = [DTVersion versionWithString:@"1.0"];
	DTVersion *second = [DTVersion versionWithString:@"2.0"];

	STAssertTrue([first isLessThenVersion:second], @"first version is not less the second");
	STAssertFalse([second isLessThenVersion:first], @"second should not be less then first");

	STAssertTrue([second isGreaterThenVersion:first], @"second version is not greater then first");

	STAssertFalse([second isLessThenVersionString:@"2.0.0"], @"second should not be less then 2.0.0");
	STAssertFalse([second isLessThenVersionString:@"1.9.9"], @"second should not be less then 1.9.9");
	STAssertTrue([second isLessThenVersionString:@"2.0.1"], @"second should be less then 2.0.0");
}

- (void)testVersion
{
	DTVersion *first = [DTVersion versionWithString:@"8.00.047 build 010"];
	DTVersion *second = [DTVersion versionWithString:@"8.00.047"];

	STAssertEquals(NSOrderedSame, [first compare:second], @"should be the same");

	STAssertFalse([first isLessThenVersionString:@"8.00.047"], @"first version is not less than 8.00.047");

	second = [DTVersion versionWithString:@"8.00.047 build 010"];
	STAssertEquals(NSOrderedSame, [first compare:second], @"should be the same");
}

@end
