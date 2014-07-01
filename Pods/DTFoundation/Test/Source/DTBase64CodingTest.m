//
//  DTBase64CodingTest.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 04.03.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTBase64CodingTest.h"
#import "DTBase64Coding.h"
#import "NSString+DTPaths.h"

@implementation DTBase64CodingTest

- (void)testEncoding
{
    NSString *inString = @"This is a test of the encoding.";
    NSData *inData = [inString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *encodedString = [DTBase64Coding stringByEncodingData:inData];
    
    NSString *expectedOutput = @"VGhpcyBpcyBhIHRlc3Qgb2YgdGhlIGVuY29kaW5nLg==";
    
    XCTAssertTrue([expectedOutput isEqualToString:encodedString], @"Expected output and encoded string don't match");
}

- (void)testDecoding
{
    NSString *string = @"R0lGODlhDwAPAKECAAAAzMzM/////\n\nwAAACwAAAAADwAPAAACIISPeQHsrZ5ModrLlN48CXF8m2iQ3YmmKqVlRtW4ML\nwWACH+H09wdGltaXplZCBieSBVbGVhZCBTbWFydFNhdmVyIQAAOw==";
    
    NSData *data = [DTBase64Coding dataByDecodingString:string];
    
    XCTAssertEqual([data length], (NSUInteger)106, @"Decoded result should be 106 Bytes");
    
    UIImage *image = [UIImage imageWithData:data];
    
    XCTAssertNotNil(image, @"Should be a valid image");
    
    NSString *path = [[NSString documentsPath] stringByAppendingPathComponent:@"TestImage.png"];
    
    NSData *outdata = UIImagePNGRepresentation(image);
    
    [outdata writeToFile:path atomically:NO];
}

@end
