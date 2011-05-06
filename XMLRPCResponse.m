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

#import "XMLRPCResponse.h"
#import "XMLRPCDecoder.h"
#import "CTidy.h"

@implementation XMLRPCResponse

- (NSData *)cleanUTF8:(NSData *)data {
	iconv_t cd = iconv_open("UTF-8", "UTF-8"); // convert to UTF-8 from UTF-8
	int one = 1;
	iconvctl(cd, ICONV_SET_DISCARD_ILSEQ, &one); // discard invalid characters
	
	size_t inbytesleft, outbytesleft;
	inbytesleft = outbytesleft = data.length;
	char *inbuf  = (char *)data.bytes;
	char *outbuf = malloc(sizeof(char) * data.length);
	char *outptr = outbuf;
	if (iconv(cd, &inbuf, &inbytesleft, &outptr, &outbytesleft) == (size_t)-1) {
		WPLog(@"this should not happen, seriously");
		return nil;
	}
	NSData *result = [NSData dataWithBytes:outbuf length:data.length - outbytesleft];
	iconv_close(cd);
	free(outbuf);
	return result;
}

- (id)initWithData: (NSData *)data
{
	if (data == nil)
	{
		return nil;
	}

	if (self = [super init])
	{
		//start cleaning the XML-RPC response message
		
		//1. removes characters outside the UTF-8 charset
		NSString  *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		//when there are characters outside the UTF-8 charset the str is nil at this point
		if(data != nil && str == nil) {
			NSData *dataCleaned = [self cleanUTF8:data];
			str = [[[NSString alloc] initWithData:dataCleaned encoding:NSUTF8StringEncoding] autorelease];
		}
		//this could never happen, but to make sure...
		if(data != nil && str == nil) {
			str = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
		}
				
				
		//2. get rid of weird characters before the xml preamble
		int responseLenght = [str length];
		//NSLog (@"String length is %i", responseLenght);
		int charIndex = 0;
		
		for( ; charIndex < responseLenght; charIndex++) {
			unichar testChar = [str characterAtIndex:charIndex];
			if(testChar == 60) {
				//NSLog (@"found the correct start char at index %i", charIndex);
				break;
			} else {
				//NSLog (@"invalid response char at index %i", charIndex );
			}
		} //end for
		
		if(charIndex != 0) {
			str = [str substringFromIndex: charIndex];
		}
		
		//3. remove invalid XML characters
		//props to benjchristensen http://benjchristensen.com/2008/02/07/how-to-strip-invalid-xml-characters/
		responseLenght = [str length];
		BOOL presenceOfInvalidCharacters = NO;
		for( int charIndex = 0; charIndex < responseLenght; charIndex++) {
			unichar testChar = [str characterAtIndex:charIndex];
			if((testChar == 0x9) ||
			   (testChar == 0xA) ||
			   (testChar == 0xD) ||
			   ((testChar >= 0x20) && (testChar <= 0xD7FF)) ||
			   ((testChar >= 0xE000) && (testChar <= 0xFFFD))
			   ) {
				//NSLog(@"valid char%C", testChar);
			} else {
				//NSLog(@"invalid chararactes found %C", testChar);
				presenceOfInvalidCharacters = YES;
				break;
			}
		} //end for
		
		if(presenceOfInvalidCharacters) {
			NSMutableString *superCleanedString = [NSMutableString stringWithCapacity:1];
			for( int charIndex = 0; charIndex < responseLenght; charIndex++) {
				unichar testChar = [str characterAtIndex:charIndex];
				if((testChar == 0x9) ||
				   (testChar == 0xA) ||
				   (testChar == 0xD) ||
				   ((testChar >= 0x20) && (testChar <= 0xD7FF)) ||
				   ((testChar >= 0xE000) && (testChar <= 0xFFFD))
				   ) {
					NSString *theString = [NSString stringWithFormat:@"%C", testChar];
					[superCleanedString appendString:theString];
				}
			} //end for
			
			str = superCleanedString;			
		}
		NSRange prefixRange = [[str stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] rangeOfString:@"<?xml"																													   options:(NSAnchoredSearch | NSCaseInsensitiveSearch)];
		if (prefixRange.location == NSNotFound) {
			// Not an xml document, don't parse
			NSDictionary *usrInfo = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Blog returned invalid data.", @""), NSLocalizedDescriptionKey, nil];
			NSError *theError = [[NSError errorWithDomain:@"org.wordpress.iphone" code:kNoXMLPrefix userInfo:usrInfo] retain];
			return (id) theError;
		}

		//the xml response should be cleaned at this point
		
		data = nil;
		data = [NSData dataWithData:[str dataUsingEncoding: NSUTF8StringEncoding]]; 
		// data should be cleaned here!
				
		XMLRPCDecoder *decoder = [[[XMLRPCDecoder alloc] initWithData: data] autorelease];
		
		if (decoder == nil)
		{
			return nil;
		}
	
		_data = [[NSData alloc] initWithData: data];
		_source = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		_object = [[decoder decode] retain];
		
		if ( _object == nil )
		{
			_isParseError = TRUE;
			NSDictionary *usrInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Parse Error. Please check your XML-RPC endpoint.", NSLocalizedDescriptionKey, nil];
			_object = [[NSError errorWithDomain:@"come.effigent.iphone.parseerror" code:-1 userInfo:usrInfo] retain];
		}
		else if( [_object isKindOfClass:[NSError class]] )
		{
			//If there's a parse error, clean the response with CTidy and try again
			//NSLog (@"--begin tidy process");
			NSError *theError = NULL;
			NSString *cleanedString = [[CTidy tidy] tidyString:str inputFormat:TidyFormat_XML outputFormat:TidyFormat_XML diagnostics:NULL error:&theError];
			if( theError != NULL )
			{
				//TODO: we may need to create a XMLRPCResponse with the error. and return
				return (id) [theError retain];
			}
			//NSLog (@"cleaned response msg: %@", cleanedString);
			//NSLog (@"--end tidy process");			data = nil;
			data = [NSData dataWithData:[cleanedString dataUsingEncoding: NSUTF8StringEncoding]];
			
			decoder = nil;
			decoder = [[[XMLRPCDecoder alloc] initWithData: data] autorelease];
			
			if (decoder == nil)
			{
				return nil;
			}
			
			_data = [[NSData alloc] initWithData: data];
			_source = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
			_object = [[decoder decode] retain];
			
			if ( _object == nil )
			{	_isParseError = TRUE;
				NSDictionary *usrInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Parse Error. Please check your XML-RPC endpoint.", NSLocalizedDescriptionKey, nil];
				_object = [[NSError errorWithDomain:@"come.effigent.iphone.parseerror" code:-1 userInfo:usrInfo] retain];
			}
			else if( [_object isKindOfClass:[NSError class]] )
			{
				_isParseError = TRUE;
			}
			else
			{
				_isParseError = FALSE;
			}
		}
		else
		{
			_isParseError = FALSE;
		}
		
		_isFault = [decoder isFault];
	}
	
	return self;
}

#pragma mark -

- (BOOL)isFault
{
	return _isFault;
}

- (NSNumber *)code
{
	if (_isFault)
	{
		if(![_object isKindOfClass:[NSError class]])
			return [_object objectForKey: @"faultCode"];
		else
			return [NSNumber numberWithInt:0];
	}
	
	return nil;
}

- (NSString *)fault
{
	if (_isFault)
	{
		if(![_object isKindOfClass:[NSError class]])
			return [_object objectForKey: @"faultString"];
		else
			return [(NSError *)_object localizedDescription];
	}
	
	return nil;
}

#pragma mark -

- (BOOL)isParseError
{
	return _isParseError;
}

#pragma mark -

- (id)object
{
	return _object;
}

#pragma mark -

- (NSString *)source
{
	return _source;
}

- (int)length
{
	return [_data length];
}

#pragma mark -

- (void)dealloc
{
	[_data autorelease];
	[_source autorelease];
	[_object autorelease];
	
	[super dealloc];
}

@end