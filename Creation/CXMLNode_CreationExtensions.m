//
//  CXMLNode_CreationExtensions.m
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

#import "CXMLNode_CreationExtensions.h"

#import "CXMLDocument.h"
#import "CXMLElement.h"
#import "CXMLNode_PrivateExtensions.h"
#import "CXMLDocument_PrivateExtensions.h"
#import "CXMLNamespaceNode.h"

@implementation CXMLNode (CXMLNode_CreationExtensions)

+ (id)document;
{
xmlDocPtr theDocumentNode = xmlNewDoc((const xmlChar *)"1.0");
NSAssert(theDocumentNode != NULL, @"xmlNewDoc failed");
CXMLDocument *theDocument = [[[CXMLDocument alloc] initWithLibXMLNode:(xmlNodePtr)theDocumentNode freeOnDealloc:NO] autorelease];
return(theDocument);
}

+ (id)documentWithRootElement:(CXMLElement *)element;
{
xmlDocPtr theDocumentNode = xmlNewDoc((const xmlChar *)"1.0");
NSAssert(theDocumentNode != NULL, @"xmlNewDoc failed");
xmlDocSetRootElement(theDocumentNode, element.node);
CXMLDocument *theDocument = [[[CXMLDocument alloc] initWithLibXMLNode:(xmlNodePtr)theDocumentNode freeOnDealloc:NO] autorelease];
[theDocument.nodePool addObject:element];
return(theDocument);
}

+ (id)elementWithName:(NSString *)name
{
xmlNodePtr theElementNode = xmlNewNode(NULL, (const xmlChar *)[name UTF8String]);
CXMLElement *theElement = [[[CXMLElement alloc] initWithLibXMLNode:(xmlNodePtr)theElementNode freeOnDealloc:NO] autorelease];
return(theElement);
}

+ (id)elementWithName:(NSString *)name URI:(NSString *)URI
{
xmlNodePtr theElementNode = xmlNewNode(NULL, (const xmlChar *)[name UTF8String]);
xmlNsPtr theNSNode = xmlNewNs(theElementNode, (const xmlChar *)[URI UTF8String], NULL);
theElementNode->ns = theNSNode;

CXMLElement *theElement = [[[CXMLElement alloc] initWithLibXMLNode:(xmlNodePtr)theElementNode freeOnDealloc:NO] autorelease];
return(theElement);
}

+ (id)elementWithName:(NSString *)name stringValue:(NSString *)string
{
xmlNodePtr theElementNode = xmlNewNode(NULL, (const xmlChar *)[name UTF8String]);
CXMLElement *theElement = [[[CXMLElement alloc] initWithLibXMLNode:(xmlNodePtr)theElementNode freeOnDealloc:NO] autorelease];
theElement.stringValue = string;
return(theElement);
}

+ (id)namespaceWithName:(NSString *)name stringValue:(NSString *)stringValue
{
	return [[[CXMLNamespaceNode alloc] initWithPrefix:name URI:stringValue parentElement:nil] autorelease];
}

+ (id)processingInstructionWithName:(NSString *)name stringValue:(NSString *)stringValue;
{
xmlNodePtr theNode = xmlNewPI((const xmlChar *)[name UTF8String], (const xmlChar *)[stringValue UTF8String]);
NSAssert(theNode != NULL, @"xmlNewPI failed");
CXMLNode *theNodeObject = [[[CXMLNode alloc] initWithLibXMLNode:theNode freeOnDealloc:NO] autorelease];
return(theNodeObject);
}

- (void)setStringValue:(NSString *)inStringValue
{
NSAssert(_node->type == XML_TEXT_NODE, @"CNode setStringValue only implemented for text nodes");    
xmlNodeSetContent(_node, (const xmlChar *)[inStringValue UTF8String]);
}

@end

