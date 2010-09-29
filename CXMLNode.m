//
//  CXMLNode.m
//  TouchCode
//
//  Created by Jonathan Wight on 03/07/08.
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

#import "CXMLNode_PrivateExtensions.h"
#import "CXMLDocument.h"
#import "CXMLElement.h"
#import "CXMLNode_CreationExtensions.h"

#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxml/xmlIO.h>

static int MyXmlOutputWriteCallback(void * context, const char * buffer, int len);
static int MyXmlOutputCloseCallback(void * context);


@implementation CXMLNode

- (void)dealloc
{
if (_node)
	{
	if (_node->_private == self)
		_node->_private = NULL;

	if (_freeNodeOnRelease)
		{
		xmlFreeNode(_node);
		}

	_node = NULL;
	}
//
[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone;
{
#pragma unused (zone)
xmlNodePtr theNewNode = xmlCopyNode(_node, 1);
CXMLNode *theNode = [[[self class] alloc] initWithLibXMLNode:theNewNode freeOnDealloc:YES];
theNewNode->_private = theNode;
return(theNode);
}

#pragma mark -

- (CXMLNodeKind)kind
{
NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");
return(_node->type); // TODO this isn't 100% accurate!
}

- (NSString *)name
{
	NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");
	// TODO use xmlCheckUTF8 to check name
	if (_node->name == NULL)
		return(NULL);
	
	NSString *localName = [NSString stringWithUTF8String:(const char *)_node->name];
	
	if (_node->ns == NULL || _node->ns->prefix == NULL)
		return localName;
	
	return [NSString stringWithFormat:@"%@:%@",	[NSString stringWithUTF8String:(const char *)_node->ns->prefix], localName];
}

- (NSString *)stringValue
{
	NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");
	
	if (_node->type == XML_TEXT_NODE || _node->type == XML_CDATA_SECTION_NODE) 
		return [NSString stringWithUTF8String:(const char *)_node->content];
	
	if (_node->type == XML_ATTRIBUTE_NODE)
		return [NSString stringWithUTF8String:(const char *)_node->children->content];

	NSMutableString *theStringValue = [[[NSMutableString alloc] init] autorelease];
	
	for (CXMLNode *child in [self children])
	{
		[theStringValue appendString:[child stringValue]];
	}
	
	return theStringValue;
}

- (NSUInteger)index
{
NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");

xmlNodePtr theCurrentNode = _node->prev;
NSUInteger N;
for (N = 0; theCurrentNode != NULL; ++N, theCurrentNode = theCurrentNode->prev)
	;
return(N);
}

- (NSUInteger)level
{
NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");

xmlNodePtr theCurrentNode = _node->parent;
NSUInteger N;
for (N = 0; theCurrentNode != NULL; ++N, theCurrentNode = theCurrentNode->parent)
	;
return(N);
}

- (CXMLDocument *)rootDocument
{
NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");

return(_node->doc->_private);
}

- (CXMLNode *)parent
{
NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");

if (_node->parent == NULL)
	return(NULL);
else
	return (_node->parent->_private);
}

- (NSUInteger)childCount
{
	NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");
	
	if (_node->type == CXMLAttributeKind)
		return 0; // NSXMLNodes of type NSXMLAttributeKind can't have children
		
	xmlNodePtr theCurrentNode = _node->children;
	NSUInteger N;
	for (N = 0; theCurrentNode != NULL; ++N, theCurrentNode = theCurrentNode->next)
		;
	return(N);
}

- (NSArray *)children
{
	NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");
	
	NSMutableArray *theChildren = [NSMutableArray array];
	
	if (_node->type != CXMLAttributeKind) // NSXML Attribs don't have children.
	{
		xmlNodePtr theCurrentNode = _node->children;
		while (theCurrentNode != NULL)
		{
			CXMLNode *theNode = [CXMLNode nodeWithLibXMLNode:theCurrentNode freeOnDealloc:NO];
			[theChildren addObject:theNode];
			theCurrentNode = theCurrentNode->next;
		}
	}
	return(theChildren);      
}

- (CXMLNode *)childAtIndex:(NSUInteger)index
{
NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");

xmlNodePtr theCurrentNode = _node->children;
NSUInteger N;
for (N = 0; theCurrentNode != NULL && N != index; ++N, theCurrentNode = theCurrentNode->next)
	;
if (theCurrentNode)
	return([CXMLNode nodeWithLibXMLNode:theCurrentNode freeOnDealloc:NO]);
return(NULL);
}

- (CXMLNode *)previousSibling
{
NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");

if (_node->prev == NULL)
	return(NULL);
else
	return([CXMLNode nodeWithLibXMLNode:_node->prev freeOnDealloc:NO]);
}

- (CXMLNode *)nextSibling
{
NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");

if (_node->next == NULL)
	return(NULL);
else
	return([CXMLNode nodeWithLibXMLNode:_node->next freeOnDealloc:NO]);
}

//- (CXMLNode *)previousNode;
//- (CXMLNode *)nextNode;
//- (NSString *)XPath;

- (NSString *)localName
{
NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");
// TODO use xmlCheckUTF8 to check name
if (_node->name == NULL)
	return(NULL);
else
	return([NSString stringWithUTF8String:(const char *)_node->name]);
}

- (NSString *)prefix
{
if (_node->ns && _node->ns->prefix)
	return([NSString stringWithUTF8String:(const char *)_node->ns->prefix]);
else
	return(@"");
}

- (NSString *)URI
{
if (_node->ns)
	return([NSString stringWithUTF8String:(const char *)_node->ns->href]);
else
	return(NULL);
}

+ (NSString *)localNameForName:(NSString *)name
{
	NSRange split = [name rangeOfString:@":"];
	
	if (split.length > 0)
		return [name substringFromIndex:split.location + 1];
	
	return name;
}

+ (NSString *)prefixForName:(NSString *)name
{
	NSRange split = [name rangeOfString:@":"];
	
	if (split.length > 0)
		return [name substringToIndex:split.location];
	
	return @"";
}

+ (CXMLNode *)predefinedNamespaceForPrefix:(NSString *)name
{
	if ([name isEqualToString:@"xml"])
		return [CXMLNode namespaceWithName:@"xml" stringValue:@"http://www.w3.org/XML/1998/namespace"];
	
	if ([name isEqualToString:@"xs"])
		return [CXMLNode namespaceWithName:@"xs" stringValue:@"http://www.w3.org/2001/XMLSchema"];
	
	if ([name isEqualToString:@"xsi"])
		return [CXMLNode namespaceWithName:@"xsi" stringValue:@"http://www.w3.org/2001/XMLSchema-instance"];
	
	if ([name isEqualToString:@"xmlns"]) // Not in Cocoa, but should be as it's reserved by W3C
		return [CXMLNode namespaceWithName:@"xmlns" stringValue:@"http://www.w3.org/2000/xmlns/"];
	
	return nil;
}

- (NSString *)description
{
NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");

return([NSString stringWithFormat:@"<%@ %p [%p] %@ %@>", NSStringFromClass([self class]), self, self->_node, [self name], [self XMLStringWithOptions:0]]);
}

- (NSString *)XMLString
{
return([self XMLStringWithOptions:0]);
}

- (NSString *)XMLStringWithOptions:(NSUInteger)options
{
#pragma unused (options)

NSMutableData *theData = [[[NSMutableData alloc] init] autorelease];

xmlOutputBufferPtr theOutputBuffer = xmlOutputBufferCreateIO(MyXmlOutputWriteCallback, MyXmlOutputCloseCallback, theData, NULL);

xmlNodeDumpOutput(theOutputBuffer, _node->doc, _node, 0, 0, "utf-8");

xmlOutputBufferFlush(theOutputBuffer);

NSString *theString = [[[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding] autorelease];

xmlOutputBufferClose(theOutputBuffer);

return(theString);
}
//- (NSString *)canonicalXMLStringPreservingComments:(BOOL)comments;

- (NSArray *)nodesForXPath:(NSString *)xpath error:(NSError **)error
{
#pragma unused (error)

NSAssert(_node != NULL, @"CXMLNode does not have attached libxml2 _node.");

NSArray *theResult = NULL;

xmlXPathContextPtr theXPathContext = xmlXPathNewContext(_node->doc);
theXPathContext->node = _node;

// TODO considering putting xmlChar <-> UTF8 into a NSString category
xmlXPathObjectPtr theXPathObject = xmlXPathEvalExpression((const xmlChar *)[xpath UTF8String], theXPathContext);
if (theXPathObject == NULL)
	{
	if (error)
		*error = [NSError errorWithDomain:@"TODO_DOMAIN" code:-1 userInfo:NULL];
	return(NULL);
	}
if (xmlXPathNodeSetIsEmpty(theXPathObject->nodesetval))
	theResult = [NSArray array]; // TODO better to return NULL?
else
	{
	NSMutableArray *theArray = [NSMutableArray array];
	int N;
	for (N = 0; N < theXPathObject->nodesetval->nodeNr; N++)
		{
		xmlNodePtr theNode = theXPathObject->nodesetval->nodeTab[N];
		[theArray addObject:[CXMLNode nodeWithLibXMLNode:theNode freeOnDealloc:NO]];
		}
		
	theResult = theArray;
	}

xmlXPathFreeObject(theXPathObject);
xmlXPathFreeContext(theXPathContext);
return(theResult);
}

//- (NSArray *)objectsForXQuery:(NSString *)xquery constants:(NSDictionary *)constants error:(NSError **)error;
//- (NSArray *)objectsForXQuery:(NSString *)xquery error:(NSError **)error;


@end

static int MyXmlOutputWriteCallback(void * context, const char * buffer, int len)
{
NSMutableData *theData = context;
[theData appendBytes:buffer length:len];
return(len);
}

static int MyXmlOutputCloseCallback(void * context)
{
return(0);
}
