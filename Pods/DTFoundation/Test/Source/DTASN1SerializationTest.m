//
//  DTASN1SerializationTest.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 3/9/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTASN1SerializationTest.h"

#import "DTASN1Serialization.h"
#import "DTBase64Coding.h"
#import "DTASN1BitString.h"

@implementation DTASN1SerializationTest

- (void)testDeserialization
{
	NSString *string = @"MBaAFDxB4o8ICKlMJYmNbcU40PyFjGIX";
	NSData *data = [DTBase64Coding dataByDecodingString:string];
	
	id object = [DTASN1Serialization objectWithData:data];
	
	STAssertNotNil(object, @"Should be able to decode as array");
	STAssertTrue([object isKindOfClass:[NSArray class]], @"Decoded object should be an array");
}

- (void)testBitString
{
	NSString *string = @"AwIFoA==";
	NSData *data = [DTBase64Coding dataByDecodingString:string];

	DTASN1BitString *bitString = [DTASN1Serialization objectWithData:data];
	
	NSString *asString = [bitString stringWithBits];
	STAssertTrue([@"101" isEqualToString:asString], @"Result should be 101");
}

- (void)testUTF8String
{
	NSString *string = @"DApTb21lLVN0YXRl";
	NSData *data = [DTBase64Coding dataByDecodingString:string];
    
	NSString *decodedString = [DTASN1Serialization objectWithData:data];
	
	STAssertTrue([@"Some-State" isEqualToString:decodedString], @"Result is not 'Some-State'");
}

// a sequence with no contents should still be returned as array
- (void)testDecodingEmptySequence
{
	NSString *string = @"MAA=";
	NSData *data = [DTBase64Coding dataByDecodingString:string];
	
	id object = [DTASN1Serialization objectWithData:data];
	
	STAssertNotNil(object, @"Should be able to decode as array");
	STAssertTrue([object isKindOfClass:[NSArray class]], @"Decoded object should be an array");
}

- (void)testCertificateDecoding
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"SelfSigned" ofType:@"der"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    id object = [DTASN1Serialization objectWithData:data];
    
	STAssertNotNil(object, @"Should be able to decode certificate");
    
    STAssertTrue([object isKindOfClass:[NSArray class]], @"Certficate should be decoded as NSArray");
    STAssertEquals([object count], (NSUInteger)3, @"Certificate should have 3 sections");
}

@end
