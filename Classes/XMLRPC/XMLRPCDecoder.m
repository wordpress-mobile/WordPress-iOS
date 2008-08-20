//
//  Cocoa XML-RPC Client Framework
//  XMLRPCConnection.m
//
//  Created by Eric J. Czarny on Thu Jan 15 2004.
//  Copyright (c) 2004 Divisible by Zero.
//

//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without 
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or 
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
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
#import "XMLRPCDecoder.h"
#import "XMLRPCExtensions.h"

@implementation XMLRPCDecoder

- (id)initWithData: (NSData *)data
{
	if (data == nil)
	{
		return nil;
	}

	if (self = [super init])
	{
		
		_parser = [[NSXMLParser alloc] initWithData:data];
//		_parent = CFXMLTreeCreateFromData(kCFAllocatorDefault, (CFDataRef)data,
//			NULL, kCFXMLParserSkipWhitespace, kCFXMLNodeCurrentVersion);
			
		// Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
		[_parser setDelegate:self];
		// Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
		[_parser setShouldProcessNamespaces:NO];
		[_parser setShouldReportNamespacePrefixes:NO];
		[_parser setShouldResolveExternalEntities:NO];
				
		if (_parser == nil)
		{
			return nil;
		}
		
		_isFault = FALSE;
	}
	
	return self;
}

#pragma mark -

- (void)valueDecoder:(XMLValueDecoder *)aValueDecoder decodedValue:(id)aValue
{
	decodedValue = [aValue retain];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (qName) 
	{		
        elementName = qName;
    }
//	WPLog(@"parser %@ didEndElement elementName %@ namespaceURI %@ qName:%@",parser, elementName, namespaceURI, qName);
	
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (qName) {
        elementName = qName;
    }

	if( [elementName isEqualToString:@"fault"] )
	{
		_isFault = YES;
	}	
	if( [elementName isEqualToString:@"value"] )
	{
		started = YES;
		XMLValueDecoder *child = [XMLValueDecoder valueDecoderWithXMLParser:parser andParentDecoder:self];
		[[child retain] autorelease];
	}
	
}
	
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
//	WPLog(@"parserDidStartDocument");
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
//	WPLog(@"parserDidEndDocument");
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
//	WPLog(@"foundCharacters:%@:", string);
}

- (id)decode
{
	[_parser parse];
	
	NSError *parseError = [_parser parserError];
//	WPLog(@"parserError %@", parseError);
//	WPLog(@"decodedValue %@", decodedValue);
	if (parseError) {
		return parseError;
	}
	
	return decodedValue;
}

#pragma mark -

- (BOOL)isFault
{
	return _isFault;
}

#pragma mark -

- (void)dealloc
{
	[decodedValue release];
	[_parser release];
	
	[super dealloc];
}

@end
