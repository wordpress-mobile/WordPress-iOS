#import <Foundation/Foundation.h>

@class XMLRPCEventBasedParserDelegate;

@interface XMLRPCEventBasedParser : NSObject<NSXMLParserDelegate> {
    NSXMLParser *myParser;
    XMLRPCEventBasedParserDelegate *myParserDelegate;
    BOOL isFault;
}

- (id)initWithData: (NSData *)data;

#pragma mark -

- (id)parse;

- (void)abortParsing;

#pragma mark -

- (NSError *)parserError;

#pragma mark -

- (BOOL)isFault;

@end
