//
//  CXMLNode_CreationExtensions.h
//  TouchCode
//
//  Created by Jonathan Wight on 04/01/08.
//  Copyright 2008 toxicsoftware.com. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "CXMLNode.h"

@class CXMLElement;

@interface CXMLNode (CXMLNode_CreationExtensions)

//- (id)initWithKind:(NSXMLNodeKind)kind;
//- (id)initWithKind:(NSXMLNodeKind)kind options:(NSUInteger)options; //primitive
+ (id)document;
+ (id)documentWithRootElement:(CXMLElement *)element;
+ (id)elementWithName:(NSString *)name;
+ (id)elementWithName:(NSString *)name URI:(NSString *)URI;
+ (id)elementWithName:(NSString *)name stringValue:(NSString *)string;
//+ (id)elementWithName:(NSString *)name children:(NSArray *)children attributes:(NSArray *)attributes;
//+ (id)attributeWithName:(NSString *)name stringValue:(NSString *)stringValue;
//+ (id)attributeWithName:(NSString *)name URI:(NSString *)URI stringValue:(NSString *)stringValue;
+ (id)namespaceWithName:(NSString *)name stringValue:(NSString *)stringValue;
+ (id)processingInstructionWithName:(NSString *)name stringValue:(NSString *)stringValue;
//+ (id)commentWithStringValue:(NSString *)stringValue;
//+ (id)textWithStringValue:(NSString *)stringValue;
//+ (id)DTDNodeWithXMLString:(NSString *)string;

- (void)setStringValue:(NSString *)inStringValue;

@end
