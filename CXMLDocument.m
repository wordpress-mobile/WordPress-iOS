//
//  CXMLDocument.m
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

#import "CXMLDocument.h"

#include <libxml/parser.h>

#import "CXMLNode_PrivateExtensions.h"
#import "CXMLElement.h"

#if TOUCHXMLUSETIDY
#import "CTidy.h"
#endif /* TOUCHXMLUSETIDY */

@implementation CXMLDocument

- (id)initWithXMLString:(NSString *)inString options:(NSUInteger)inOptions error:(NSError **)outError
{
#pragma unused (inOptions)
if ((self = [super init]) != NULL)
	{
	NSError *theError = NULL;
	
	#if TOUCHXMLUSETIDY
	if (inOptions & CXMLDocumentTidyHTML)
		{
		inString = [[CTidy tidy] tidyString:inString inputFormat:TidyFormat_HTML outputFormat:TidyFormat_XHTML diagnostics:NULL error:&theError];
		}
	else if (inOptions & CXMLDocumentTidyXML)
		{
		inString = [[CTidy tidy] tidyString:inString inputFormat:TidyFormat_XML outputFormat:TidyFormat_XML diagnostics:NULL error:&theError];
		}
	#endif
	
	xmlDocPtr theDoc = xmlParseDoc((xmlChar *)[inString UTF8String]);
	if (theDoc != NULL)
		{
		_node = (xmlNodePtr)theDoc;
		NSAssert(_node->_private == NULL, @"TODO");
		_node->_private = self; // Note. NOT retained (TODO think more about _private usage)
		}
	else
		{
		xmlErrorPtr	theLastErrorPtr = xmlGetLastError();
		
		NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSString stringWithUTF8String:theLastErrorPtr->message], NSLocalizedDescriptionKey,
			NULL];
		
		
		theError = [NSError errorWithDomain:@"CXMLErrorDomain" code:1 userInfo:theUserInfo];
		
		xmlResetLastError();
		}

	if (outError)
		*outError = theError;

	if (theError != NULL)
		{
		[self release];
		self = NULL;
		}
	}
return(self);
}

- (id)initWithData:(NSData *)inData options:(NSUInteger)inOptions error:(NSError **)outError
{
	return [self initWithData:inData encoding:NSUTF8StringEncoding options:inOptions error:outError];	 
}

- (id)initWithData:(NSData *)inData encoding:(NSStringEncoding)encoding options:(NSUInteger)inOptions error:(NSError **)outError
{
#pragma unused (inOptions)
if ((self = [super init]) != NULL)
	{
	NSError *theError = NULL;
	
	#if TOUCHXMLUSETIDY
	if (inOptions & CXMLDocumentTidyHTML)
		{
		inData = [[CTidy tidy] tidyData:inData inputFormat:TidyFormat_HTML outputFormat:TidyFormat_XHTML diagnostics:NULL error:&theError];
		}
	else if (inOptions & CXMLDocumentTidyXML)
		{
		inData = [[CTidy tidy] tidyData:inData inputFormat:TidyFormat_XML outputFormat:TidyFormat_XML diagnostics:NULL error:&theError];
		}
	#endif
	
	if (theError == NULL)
		{
		xmlDocPtr theDoc = NULL;
		if (inData && inData.length > 0)
			{
			CFStringEncoding cfenc = CFStringConvertNSStringEncodingToEncoding(encoding);
			CFStringRef cfencstr = CFStringConvertEncodingToIANACharSetName(cfenc);
			const char *enc = CFStringGetCStringPtr(cfencstr, 0);
			theDoc = xmlReadMemory([inData bytes], [inData length], NULL, enc, XML_PARSE_RECOVER | XML_PARSE_NOWARNING);
			}
		
		if (theDoc != NULL)
			{
			_node = (xmlNodePtr)theDoc;
			_node->_private = self; // Note. NOT retained (TODO think more about _private usage)
			}
		else
			{
			theError = [NSError errorWithDomain:@"CXMLErrorDomain" code:-1 userInfo:NULL];
			}
		}

	if (outError)
		*outError = theError;

	if (theError != NULL)
		{
		[self release];
		self = NULL;
		}
	}
return(self);
}

- (id)initWithContentsOfURL:(NSURL *)inURL options:(NSUInteger)inOptions error:(NSError **)outError
{
	return [self initWithContentsOfURL:inURL encoding:NSUTF8StringEncoding options:inOptions error:outError];
}

- (id)initWithContentsOfURL:(NSURL *)inURL encoding:(NSStringEncoding)encoding options:(NSUInteger)inOptions error:(NSError **)outError
{
if (outError)
	*outError = NULL;

NSData *theData = [NSData dataWithContentsOfURL:inURL options:NSUncachedRead error:outError];
if (theData)
	{
	self = [self initWithData:theData encoding:encoding options:inOptions error:outError];
	}
else
	{
	self = NULL;
	}
	
return(self);
}


- (void)dealloc
{
// Fix for #35 http://code.google.com/p/touchcode/issues/detail?id=35 -- clear up the node objects first (inside a pool so I _know_ they're cleared) and then freeing the document

NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];

[nodePool release];
nodePool = NULL;

[thePool release];
//
xmlFreeDoc((xmlDocPtr)_node);
_node = NULL;
//
[super dealloc];
}

//- (NSString *)characterEncoding;
//- (NSString *)version;
//- (BOOL)isStandalone;
//- (CXMLDocumentContentKind)documentContentKind;
//- (NSString *)MIMEType;
//- (CXMLDTD *)DTD;

- (CXMLElement *)rootElement
{
xmlNodePtr theLibXMLNode = xmlDocGetRootElement((xmlDocPtr)_node);
	
return([CXMLNode nodeWithLibXMLNode:theLibXMLNode freeOnDealloc:NO]);
}

- (NSData *)XMLData
{
return([self XMLDataWithOptions:0]);
}

- (NSData *)XMLDataWithOptions:(NSUInteger)options
{
#pragma unused (options)
xmlChar *theBuffer = NULL;
int theBufferSize = 0;
xmlDocDumpMemory((xmlDocPtr)self->_node, &theBuffer, &theBufferSize);

NSData *theData = [NSData dataWithBytes:theBuffer length:theBufferSize];

xmlFree(theBuffer);

return(theData);
}

//- (id)objectByApplyingXSLT:(NSData *)xslt arguments:(NSDictionary *)arguments error:(NSError **)error;
//- (id)objectByApplyingXSLTString:(NSString *)xslt arguments:(NSDictionary *)arguments error:(NSError **)error;
//- (id)objectByApplyingXSLTAtURL:(NSURL *)xsltURL arguments:(NSDictionary *)argument error:(NSError **)error;
- (id)XMLStringWithOptions:(NSUInteger)options
{
id root = [self rootElement];
NSMutableString* xmlString = [NSMutableString string];
[xmlString appendString:[root XMLStringWithOptions:options]];
return xmlString;
}

- (NSString *)description
{
NSAssert(_node != NULL, @"TODO");

NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p [%p]> ", NSStringFromClass([self class]), self, self->_node];
xmlChar *xmlbuff;
int buffersize;

xmlDocDumpFormatMemory((xmlDocPtr)(self->_node), &xmlbuff, &buffersize, 1);
NSString *dump = [[[NSString alloc] initWithBytes:xmlbuff length:buffersize encoding:NSUTF8StringEncoding] autorelease];
xmlFree(xmlbuff);
						   
[result appendString:dump];
return result;
}

@end
