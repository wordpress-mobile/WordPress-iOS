//
//  WordPressTest.m
//  WordPressTest
//
//  Created by Jorge Bernal on 2/1/12.
//  Copyright (c) 2012 Automattic. All rights reserved.
//

#import "WordPressTest.h"
#import "XMLRPCEventBasedParser.h"
#import "XMLRPCEncoder.h"
#import "NSString+XMLExtensions.h"

@implementation WordPressTest

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testXmlEntitiesDecoding
{
    XMLRPCEventBasedParser *parser = [[XMLRPCEventBasedParser alloc] initWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"entities" ofType:@"xml"]]];
    NSDictionary *response = [parser parse];
    NSString *decoded = [response objectForKey:@"description"];
    NSString *expected = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"entitiesDecoded" ofType:@"xml"] encoding:NSUTF8StringEncoding error:nil];
    STAssertEqualObjects(decoded, expected, nil);

    decoded = [NSString decodeXMLCharactersIn:@"&lt;td&gt;&amp;gt;&lt;/td&gt;&lt;td&gt;&amp;amp;#62;&lt;/td&gt;&lt;td&gt;&amp;amp;gt;&lt;/td&gt;"];
    expected = @"<td>&gt;</td><td>&amp;#62;</td><td>&amp;gt;</td>";
    STAssertEqualObjects(decoded, expected, nil);
}

- (void)testXmlEntitiesEncoding {
    XMLRPCEncoder *encoder = [[XMLRPCEncoder alloc] init];
    [encoder setMethod:@"fake.test" withParameters:[NSArray arrayWithObject:@"<b>&lt;b&gt;</b> tag &amp; &quot;other&quot; \"tags\""]];
    NSString *encoded = [encoder encode];
    NSString *expected = @"<?xml version=\"1.0\"?><methodCall><methodName>fake.test</methodName><params><param><value><string>&#60;b&#62;&#38;lt;b&#38;gt;&#60;/b&#62; tag &#38;amp; &#38;quot;other&#38;quot; \"tags\"</string></value></param></params></methodCall>";
    STAssertEqualObjects(encoded, expected, @"Failed encoding test. \nencoded:  %@\nexpected: %@", encoded, expected);
}

@end
