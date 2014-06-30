//
//  WPXMLRPCEncoderTest.m
//  WPXMLRPCTest
//
//  Created by Jorge Bernal on 2/25/13.
//
//

#import "WPXMLRPCEncoder.h"
#import "WPXMLRPCEncoderTest.h"

@implementation WPXMLRPCEncoderTest

- (void)testRequestEncoder {
    WPXMLRPCEncoder *encoder = [[WPXMLRPCEncoder alloc] initWithMethod:@"wp.getUsersBlogs" andParameters:@[@"username", @"password"]];
    NSString *testCase = [[self unitTestBundle] pathForResource:@"RequestTestCase" ofType:@"xml"];
    NSString *testCaseData = [[NSString alloc] initWithContentsOfFile:testCase encoding:NSUTF8StringEncoding error:nil];
    NSString *parsedResult = [[NSString alloc] initWithData:[encoder body] encoding:NSUTF8StringEncoding];
    STAssertEqualObjects(parsedResult, testCaseData, nil);
}

- (void)testResponseEncoder {
    
}

#pragma mark - 

- (NSBundle *)unitTestBundle {
    return [NSBundle bundleForClass:[WPXMLRPCEncoderTest class]];
}

@end
