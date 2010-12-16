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

- (id)initWithData: (NSData *)data
{
	if (data == nil)
	{
		return nil;
	}

	if (self = [super init])
	{
		
		//cleaning the XML-RPC response message
		NSString  *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		//get rid of weird characters before the xml preamble
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
		
		//NSLog (@"--begin tidy process");
		NSError *theError = NULL;
		NSString *cleanedString = [[CTidy tidy] tidyString:str inputFormat:TidyFormat_XML outputFormat:TidyFormat_XML diagnostics:NULL error:&theError];
		
		if( theError != NULL )
		{
			//TODO: we may need to create a XMLRPCResponse with the error. and return
			return (id) theError;
		}
        //NSLog (@"cleaned response msg: %@", cleanedString);
        //NSLog (@"--end tidy process");
		
		data = nil;
		data = [NSData dataWithData:[cleanedString dataUsingEncoding: NSUTF8StringEncoding]];
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
			_isParseError = TRUE;
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