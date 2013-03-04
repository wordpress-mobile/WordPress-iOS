// WPXMLRPCDecoderDelegate.m
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

#import "WPXMLRPCDecoderDelegate.h"
#import "WPBase64Utils.h"

@interface WPXMLRPCDecoderDelegate (WPXMLRPCEventBasedParserDelegatePrivate)

- (BOOL)isDictionaryElementType:(WPXMLRPCElementType)elementType;

#pragma mark -

- (void)addElementValueToParent;

#pragma mark -

- (NSDate *)parseDateString:(NSString *)dateString withFormat:(NSString *)format;

#pragma mark -

- (NSNumber *)parseInteger:(NSString *)value;

- (NSNumber *)parseDouble:(NSString *)value;

- (NSNumber *)parseBoolean:(NSString *)value;

- (NSString *)parseString:(NSString *)value;

- (NSDate *)parseDate:(NSString *)value;

- (NSData *)parseData:(NSString *)value;

@end

#pragma mark -

@implementation WPXMLRPCDecoderDelegate

- (id)initWithParent:(WPXMLRPCDecoderDelegate *)parent {
    self = [super init];
    if (self) {
        myParent = parent;
        myChildren = [[NSMutableArray alloc] initWithCapacity:1];
        myElementType = WPXMLRPCElementTypeString;
        myElementKey = nil;
        myElementValue = [[NSMutableString alloc] init];
    }
    
    return self;
}

#pragma mark -

- (void)setParent:(WPXMLRPCDecoderDelegate *)parent {
    
    
    myParent = parent;
}

- (WPXMLRPCDecoderDelegate *)parent {
    return myParent;
}

#pragma mark -

- (void)setElementType:(WPXMLRPCElementType)elementType {
    myElementType = elementType;
}

- (WPXMLRPCElementType)elementType {
    return myElementType;
}

#pragma mark -

- (void)setElementKey:(NSString *)elementKey {
    
    
    myElementKey = elementKey;
}

- (NSString *)elementKey {
    return myElementKey;
}

#pragma mark -

- (void)setElementValue:(id)elementValue {
    
    
    myElementValue = elementValue;
}

- (id)elementValue {
    return myElementValue;
}

#pragma mark -


@end

#pragma mark -

@implementation WPXMLRPCDecoderDelegate (NSXMLParserDelegate)

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)element namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributes {
    if ([element isEqualToString:@"value"] || [element isEqualToString:@"member"] || [element isEqualToString:@"name"]) {
        WPXMLRPCDecoderDelegate *parserDelegate = [[WPXMLRPCDecoderDelegate alloc] initWithParent:self];
        
        if ([element isEqualToString:@"member"]) {
            [parserDelegate setElementType:WPXMLRPCElementTypeMember];
        } else if ([element isEqualToString:@"name"]) {
            [parserDelegate setElementType:WPXMLRPCElementTypeName];
        }
        
        [myChildren addObject:parserDelegate];
        
        [parser setDelegate:parserDelegate];
        
        
        return;
    }
    
    if ([element isEqualToString:@"array"] || [element isEqualToString:@"params"]) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        
        [self setElementValue:array];
        
        
        [self setElementType:WPXMLRPCElementTypeArray];
    } else if ([element isEqualToString:@"struct"]) {
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
        
        [self setElementValue:dictionary];
        
        
        [self setElementType:WPXMLRPCElementTypeDictionary];
    } else if ([element isEqualToString:@"int"] || [element isEqualToString:@"i4"]) {
        [self setElementType:WPXMLRPCElementTypeInteger];
    } else if ([element isEqualToString:@"double"]) {
        [self setElementType:WPXMLRPCElementTypeDouble];
    } else if ([element isEqualToString:@"boolean"]) {
        [self setElementType:WPXMLRPCElementTypeBoolean];
    } else if ([element isEqualToString:@"string"]) {
        [self setElementType:WPXMLRPCElementTypeString];
    } else if ([element isEqualToString:@"dateTime.iso8601"]) {
        [self setElementType:WPXMLRPCElementTypeDate];
    } else if ([element isEqualToString:@"base64"]) {
        [self setElementType:WPXMLRPCElementTypeData];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)element namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName {
    if ([element isEqualToString:@"value"] || [element isEqualToString:@"member"] || [element isEqualToString:@"name"]) {
        NSString *elementValue = nil;
        
        if ((myElementType != WPXMLRPCElementTypeArray) && ![self isDictionaryElementType:myElementType]) {
            elementValue = [self parseString:myElementValue];
            
            
            myElementValue = nil;
        }
        
        switch (myElementType) {
            case WPXMLRPCElementTypeInteger:
                myElementValue = [self parseInteger:elementValue];
                
                
                break;
            case WPXMLRPCElementTypeDouble:
                myElementValue = [self parseDouble:elementValue];
                
                
                break;
            case WPXMLRPCElementTypeBoolean:
                myElementValue = [self parseBoolean:elementValue];
                
                
                break;
            case WPXMLRPCElementTypeString:
            case WPXMLRPCElementTypeName:
                myElementValue = elementValue;
                
                
                break;
            case WPXMLRPCElementTypeDate:
                myElementValue = [self parseDate:elementValue];
                
                
                break;
            case WPXMLRPCElementTypeData:
                myElementValue = [self parseData:elementValue];
                
                
                break;
            default:
                break;
        }
        
        if (myParent && myElementValue) {
            [self addElementValueToParent];
        }
        
        [parser setDelegate:myParent];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if ((myElementType == WPXMLRPCElementTypeArray) || [self isDictionaryElementType:myElementType]) {
        return;
    }
    
    if (!myElementValue) {
        myElementValue = [[NSMutableString alloc] initWithString:string];
    } else {
        [myElementValue appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    [parser abortParsing];
}

@end

#pragma mark -

@implementation WPXMLRPCDecoderDelegate (WPXMLRPCEventBasedParserDelegatePrivate)

- (BOOL)isDictionaryElementType:(WPXMLRPCElementType)elementType {
    if ((myElementType == WPXMLRPCElementTypeDictionary) || (myElementType == WPXMLRPCElementTypeMember)) {
        return YES;
    }
    
    return NO;
}

#pragma mark -

- (void)addElementValueToParent {
    id parentElementValue = [myParent elementValue];
    
    switch ([myParent elementType]) {
        case WPXMLRPCElementTypeArray:
            [parentElementValue addObject:myElementValue];
            
            break;
        case WPXMLRPCElementTypeDictionary:
            if ([myElementValue isEqual:[NSNull null]]) {
                [parentElementValue removeObjectForKey:myElementKey];
            } else {
                [parentElementValue setObject:myElementValue forKey:myElementKey];
            }
            
            break;
        case WPXMLRPCElementTypeMember:
            if (myElementType == WPXMLRPCElementTypeName) {
                [myParent setElementKey:myElementValue];
            } else {
                [myParent setElementValue:myElementValue];
            }
            
            break;
        default:
            break;
    }
}

#pragma mark -

- (NSDate *)parseDateString:(NSString *)dateString withFormat:(NSString *)format {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate *result = nil;
    
    [dateFormatter setDateFormat:format];
    
    result = [dateFormatter dateFromString:dateString];
    
    
    return result;
}

#pragma mark -

- (NSNumber *)parseInteger:(NSString *)value {
    return [NSNumber numberWithInteger:[value integerValue]];
}

- (NSNumber *)parseDouble:(NSString *)value {
    return [NSNumber numberWithDouble:[value doubleValue]];
}

- (NSNumber *)parseBoolean:(NSString *)value {
    if ([value isEqualToString:@"1"]) {
        return [NSNumber numberWithBool:YES];
    }
    
    return [NSNumber numberWithBool:NO];
}

- (NSString *)parseString:(NSString *)value {
    return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSDate *)parseDate:(NSString *)value {
    NSDate *result = nil;
    
    result = [self parseDateString:value withFormat:@"yyyyMMdd'T'HH:mm:ss"];
    
    if (!result) {
        result = [self parseDateString:value withFormat:@"yyyy'-'MM'-'dd'T'HH:mm:ss"];
    }
    
    if (!result) {
        result = (NSDate *)[NSNull null];
    }

    return result;
}

- (NSData *)parseData:(NSString *)value {
    return [WPBase64Utils decodeString:value];
}

@end
