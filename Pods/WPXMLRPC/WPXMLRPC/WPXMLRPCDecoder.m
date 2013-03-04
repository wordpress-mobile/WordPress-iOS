// WPXMLRPCDecoder.m
//
// Copyright (c) 2013 WordPress - http://wordpress.org/
// Based on Eric Czarny's xmlrpc library - https://github.com/eczarny/xmlrpc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "WPXMLRPCDecoder.h"
#import "WPXMLRPCDecoderDelegate.h"
#import "WPXMLRPCDataCleaner.h"

NSString *const WPXMLRPCFaultErrorDomain = @"WPXMLRPCFaultError";

@interface WPXMLRPCDecoder () <NSXMLParserDelegate>
@end

@implementation WPXMLRPCDecoder {
    NSXMLParser *_parser;
    WPXMLRPCDecoderDelegate *_delegate;
    BOOL _isFault;
    NSData *_body;
    id _object;
    NSMutableString *_methodName;
}

- (id)initWithData:(NSData *)data {
    if (!data) {
        return nil;
    }
    
    if (self = [self init]) {
        _body = data;
        _parser = [[NSXMLParser alloc] initWithData:data];
        _delegate = nil;
        _isFault = NO;
        [self parse];
    }
    
    return self;
}

#pragma mark -

- (void)parse {
    [_parser setDelegate:self];
    
    [_parser parse];

    if ([_parser parserError]) {
        WPXMLRPCDataCleaner *cleaner = [[WPXMLRPCDataCleaner alloc] initWithData:_body];
        _body = [cleaner cleanData];
        _parser = [[NSXMLParser alloc] initWithData:_body];
        [_parser setDelegate:self];
        [_parser parse];
    }

    if ([_parser parserError])
        return;

    if (_methodName) {
        _object = @{@"methodName": _methodName, @"params": [_delegate elementValue]};
    } else {
        _object = [_delegate elementValue];
    }
}

- (void)abortParsing {
    [_parser abortParsing];
}

#pragma mark -

- (BOOL)isFault {
    return _isFault;
}

- (NSInteger)faultCode {
    if ([self isFault]) {
        return [[_object objectForKey: @"faultCode"] integerValue];
    }

    return 0;
}

- (NSString *)faultString {
    if ([self isFault]) {
        return [_object objectForKey: @"faultString"];
    }

    return nil;
}

- (NSError *)error {
    if ([_parser parserError]) {
        return [_parser parserError];
    }

    if ([self isFault]) {
        return [NSError errorWithDomain:WPXMLRPCFaultErrorDomain code:[self faultCode] userInfo:@{NSLocalizedDescriptionKey: [self faultString]}];
    }

    return nil;
}

#pragma mark -

- (id)object {
    return _object;
}

@end

#pragma mark -

@implementation WPXMLRPCDecoder (NSXMLParserDelegate)

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)element namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributes {
    if ([element isEqualToString:@"fault"]) {
        _isFault = YES;
    } else if ([element isEqualToString:@"value"]) {
        _delegate = [[WPXMLRPCDecoderDelegate alloc] initWithParent:nil];
        
        [_parser setDelegate:_delegate];
    } else if ([element isEqualToString:@"methodName"]) {
        _methodName = [NSMutableString string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"methodName"]) {
        _delegate = [[WPXMLRPCDecoderDelegate alloc] initWithParent:nil];

        [_parser setDelegate:_delegate];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [_methodName appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    [self abortParsing];
}

@end
