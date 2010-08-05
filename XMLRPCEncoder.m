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
#import "XMLRPCEncoder.h"
#import "XMLRPCExtensions.h"
#import "NSString+XMLExtensions.h"

@interface XMLRPCEncoder (XMLRPCEncoderPrivate)

- (NSString *)valueTag: (NSString *)tag value: (NSString *)value;

#pragma mark -

- (NSString *)replaceTarget: (NSString *)target withValue: (NSString *)value inString: (NSString *)string;
- (NSString *)escapeValue: (NSString *)value;

#pragma mark -

- (NSString *)encodeObject: (id)object;

#pragma mark -

- (NSString *)encodeArray: (NSArray *)array;
- (NSString *)encodeDictionary: (NSDictionary *)dictionary;

#pragma mark -

- (NSString *)encodeBoolean: (CFBooleanRef)boolean;
- (NSString *)encodeNumber: (NSNumber *)number;
- (NSString *)encodeString: (NSString *)string;
- (NSString *)encodeDate: (NSDate *)date;
- (NSString *)encodeData: (NSData *)data;

@end

#pragma mark -

@implementation XMLRPCEncoder

- (id)init
{
	if (self = [super init])
	{
		_method = [[NSString alloc] init];
		_source = [[NSString alloc] init];
		_objects = [[NSArray alloc] init];
	}
	
	return self;
}

#pragma mark -

- (NSString *)encode
{
	NSMutableString *buffer = [NSMutableString stringWithString: @"<?xml version=\"1.0\"?><methodCall>"];
	
	[buffer appendFormat: @"<methodName>%@</methodName>", _method];
	
	if (_objects != nil)
	{
		NSEnumerator *enumerator = [_objects objectEnumerator];
		id object = nil;
		
		[buffer appendString: @"<params>"];
		
		while (object = [enumerator nextObject])
		{
			[buffer appendString: @"<param>"];
			[buffer appendString: [self encodeObject: object]];
			[buffer appendString: @"</param>"];
		}
		
		[buffer appendString: @"</params>"];
	}
	
	[buffer appendString: @"</methodCall>"];
	
	return buffer;
	
}

#pragma mark -

- (void)setMethod: (NSString *)method withObjects: (NSArray *)objects
{
	if (_method != nil)
	{
		[_method autorelease];
	}
	
	if (_objects != nil)
	{
		[_objects autorelease];
	}
	
	if (method == nil)
	{
		_method = nil;
	}
	else
	{
		_method = [method retain];
	}
	
	if (objects == nil)
	{
		_objects = nil;
	}
	else
	{
		_objects = [objects retain];
	}
}

#pragma mark -

- (NSString *)method
{
	return _method;
}

- (NSArray *)objects
{
	return _objects;
}

#pragma mark -

- (NSString *)source
{
	if (_source != nil)
	{
		[_source autorelease];
	}
	
	_source = [[self encode] retain];
	
	return _source;
}

#pragma mark -

- (void)dealloc
{
	[_method autorelease];
	[_source autorelease];
	[_objects autorelease];
	
	[super dealloc];
}

@end

#pragma mark -

@implementation XMLRPCEncoder (XMLRPCEncoderPrivate)

- (NSString *)valueTag: (NSString *)tag value: (NSString *)value
{
	return [NSString stringWithFormat: @"<value><%@>%@</%@></value>", tag, [self escapeValue: value], tag];
}

#pragma mark -

- (NSString *)replaceTarget: (NSString *)target withValue: (NSString *)value inString: (NSString *)string
{
	return [[string componentsSeparatedByString: target] componentsJoinedByString: value];	
}

- (NSString *)escapeValue: (NSString *)value
{
	//Comments --- Properly Encoding the special characters with XML 26Aug2008 ######
	return [NSString encodeXMLCharactersIn:value];	
}

#pragma mark -

/* */
- (NSString *)encodeObject: (id)object
{
	if (object == nil)
	{
		return nil;
	}
	
	if ([object isKindOfClass: [NSArray class]])
	{
		return [self encodeArray: object];
	}
	else if ([object isKindOfClass: [NSDictionary class]])
	{
		return [self encodeDictionary: object];
	}
	else if (((CFBooleanRef)object == kCFBooleanTrue) || ((CFBooleanRef)object == kCFBooleanFalse))
	{
		return [self encodeBoolean: (CFBooleanRef)object];
	}
	else if ([object isKindOfClass: [NSNumber class]])
	{
		return [self encodeNumber: object];
	}
	else if ([object isKindOfClass: [NSString class]])
	{
		return [self encodeString: object];
	}
	else if ([object isKindOfClass: [NSDate class]])
	{
		return [self encodeDate: object];
	}
	else if ([object isKindOfClass: [NSData class]])
	{
		return [self encodeData: object];
	}
	else
	{
		return [self encodeString: object];
	}
}

#pragma mark -

/* */
- (NSString *)encodeArray: (NSArray *)array
{
	NSMutableString *buffer = [NSMutableString string];
	NSEnumerator *enumerator = [array objectEnumerator];
	
	[buffer appendString: @"<value><array><data>"];
	
	id object = nil;
	while (object = [enumerator nextObject])
	{
		[buffer appendString: [self encodeObject: object]];
	}
	
	[buffer appendString: @"</data></array></value>"];
	return (NSString *)buffer;
}

- (NSString *)encodeDictionary: (NSDictionary *)dictionary {
	NSMutableString * buffer = [NSMutableString string];
	NSEnumerator *enumerator = [dictionary keyEnumerator];
	[buffer appendString: @"<value><struct>"];
	
	NSString *key = nil;
	while (key = [enumerator nextObject])
	{
		[buffer appendString: @"<member>"];
		[buffer appendFormat: @"<name>%@</name>", key];
		[buffer appendString: [self encodeObject: [dictionary objectForKey: key]]];
		[buffer appendString: @"</member>"];
	}
	
	[buffer appendString: @"</struct></value>"];
	return (NSString *)buffer;
}

#pragma mark -

- (NSString *)encodeBoolean:(CFBooleanRef)boolean {
	if (boolean == kCFBooleanTrue)
		return [self valueTag: @"boolean" value: @"true"];
	else
		return [self valueTag: @"boolean" value: @"false"];
}

- (NSString *)encodeNumber: (NSNumber *)number
{
	return [self valueTag: @"i4" value: [number stringValue]];
}

- (NSString *)encodeString: (NSString *)string
{
	return [self valueTag: @"string" value: string];
}

- (NSString *)encodeDate: (NSDate *)date {
	NSCalendar *cal = [NSCalendar currentCalendar];	
	NSDateComponents *comps = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit
																	 fromDate:date];
	
	NSString *month = [NSString stringWithFormat:@"%d",[comps month]];
	NSString *day = [NSString stringWithFormat:@"%d",[comps day]];
	NSString *hour = [NSString stringWithFormat:@"%d",[comps hour]];
	NSString *minute = [NSString stringWithFormat:@"%d",[comps minute]];
	NSString *second = [NSString stringWithFormat:@"%d",[comps second]];

	if ([month length] == 1)	month = [NSString stringWithFormat:@"0%@",month];	
	if ([day length] == 1)	day = [NSString stringWithFormat:@"0%@",day];
	if ([hour length] == 1)	hour = [NSString stringWithFormat:@"0%@",hour];
	if ([minute length] == 1)	minute = [NSString stringWithFormat:@"0%@",minute];
	if ([second length] == 1)	second = [NSString stringWithFormat:@"0%@",second];
	
	NSString *buffer = [NSString stringWithFormat:@"%d%@%@T%@:%@:%@", [comps year]	,month	,day		,hour	,minute,second];
	
	
	return [self valueTag: @"dateTime.iso8601" value: buffer];
}

- (NSString *)encodeData: (NSData *)data
{
//	NSString *buffer = [NSString base64StringFromData: data
//		length: [data length]];
//	return [self valueTag: @"base64" value: buffer];

	NSData *d = [NSPropertyListSerialization dataFromPropertyList:data  format:NSPropertyListXMLFormat_v1_0 errorDescription:NULL];
	NSString *str =  [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];//[NSString stringWithUTF8String:[d bytes]];
	NSRange r = [str rangeOfString:@"<data>"];
	str = [str substringFromIndex:r.location+7];
	r = [str rangeOfString:@"</data>"];
	str = [str substringToIndex:r.location-1];
	str = [NSString stringWithFormat:@"<value><base64>%@</base64></value>",str];
	return str;
}

@end