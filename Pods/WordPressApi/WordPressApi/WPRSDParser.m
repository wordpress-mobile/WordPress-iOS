//
//  WPRSDParser.m
//  WordPress
//
//  Created by Jorge Bernal on 10/18/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPRSDParser.h"

@implementation WPRSDParser {
    NSXMLParser *_parser;
    NSString *_endpoint;
    NSError *_error;
}

- (id)initWithXmlString:(NSString *)string {
    self = [super init];
    if (self) {
        _parser = [[NSXMLParser alloc] initWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
        [_parser setDelegate:self];
    }
    return self;
}

- (NSString *)parsedEndpointWithError:(NSError **)error {
    [_parser parse];
    if (error) *error = _error;
    return _endpoint;
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"api"]) {
        NSString *apiName = attributeDict[@"name"];
        if (apiName && [apiName isEqualToString:@"WordPress"]) {
            _endpoint = attributeDict[@"apiLink"];
            if (_endpoint) {
                [_parser abortParsing];
            }
        }
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    _error = parseError;
}

@end
