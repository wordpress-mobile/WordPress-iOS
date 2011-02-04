//
//  CXMLElement_CreationExtensions.m
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

#import "CXMLElement_CreationExtensions.h"

@implementation CXMLElement (CXMLElement_CreationExtensions)

- (void)addChild:(CXMLNode *)inNode
{
NSAssert(inNode->_node->doc == NULL, @"Cannot addChild with a node that already is part of a document. Copy it first!");
NSAssert(self->_node != NULL, @"_node should not be null");
NSAssert(inNode->_node != NULL, @"_node should not be null");
xmlAddChild(self->_node, inNode->_node);
}

- (void)addNamespace:(CXMLNode *)inNamespace
{
xmlSetNs(self->_node, (xmlNsPtr)inNamespace->_node);
}

- (void)setStringValue:(NSString *)inStringValue
{
NSAssert(inStringValue != NULL, @"CXMLElement setStringValue should not be null");
xmlNodePtr theContentNode = xmlNewText((const xmlChar *)[inStringValue UTF8String]);
NSAssert(self->_node != NULL, @"_node should not be null");
xmlAddChild(self->_node, theContentNode);
}

@end
