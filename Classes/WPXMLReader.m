//
//  WPXMLReader.m
//  WordPress
//
//  Created by JanakiRam on 22/01/09.
//

#import "WPXMLReader.h"

@implementation WPXMLReader

@synthesize hostUrl;

- (void)parseXMLData:(NSData *)data parseError:(NSError * *)error {
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
    [parser setDelegate:self];
    [parser parse];

    NSError *parseError = [parser parserError];

    if (parseError && error) {
        *error = parseError;
    }

    [parser release];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"link"]) {
        NSString *relAtt = [attributeDict valueForKey:@"rel"];

        if ([relAtt isEqualToString:@"EditURI"]) {
            hostUrl = [attributeDict valueForKey:@"href"];
        }
    }
}

-(void)dealloc {
	[hostUrl release];
	[super dealloc];
}

@end
