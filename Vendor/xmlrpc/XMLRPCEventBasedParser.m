#import "XMLRPCEventBasedParser.h"
#import "XMLRPCEventBasedParserDelegate.h"

@implementation XMLRPCEventBasedParser

- (id)initWithData: (NSData *)data {
    if (!data) {
        return nil;
    }
    
    if (self = [self init]) {
        myParser = [[NSXMLParser alloc] initWithData: data];
        myParserDelegate = nil;
        isFault = NO;
    }
    
    return self;
}

#pragma mark -

- (id)parse {
    [myParser setDelegate: self];
    
    [myParser parse];
    
    if ([myParser parserError]) {
        return nil;
    }
    
    return [myParserDelegate elementValue];
}

- (void)abortParsing {
    [myParser abortParsing];
}

#pragma mark -

- (NSError *)parserError {
    return [myParser parserError];
}

#pragma mark -

- (BOOL)isFault {
    return isFault;
}

#pragma mark -

- (void)dealloc {
    [myParser release];
    [myParserDelegate release];
    
    [super dealloc];
}

@end

#pragma mark -

@implementation XMLRPCEventBasedParser (NSXMLParserDelegate)

- (void)parser: (NSXMLParser *)parser didStartElement: (NSString *)element namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qualifiedName attributes: (NSDictionary *)attributes {
    if ([element isEqualToString: @"fault"]) {
        isFault = YES;
    } else if ([element isEqualToString: @"value"]) {
        myParserDelegate = [[XMLRPCEventBasedParserDelegate alloc] initWithParent: nil];
        
        [myParser setDelegate: myParserDelegate];
    }
}

- (void)parser: (NSXMLParser *)parser parseErrorOccurred: (NSError *)parseError {
    [self abortParsing];
}

@end
