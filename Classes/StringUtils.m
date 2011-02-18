//
//  StringUtils.m
//  WordPress
//
//  Created by Danilo Ercoli on 18/02/11.
//  Copyright 2011 WordPress. All rights reserved.
//
//
// This class is based on the UTF8 fixup methods by William Denniss, http://williamdeniss.com/ 
//
//
// These are regxep examples using during tests, that match overly long 2 byte sequences, as well as characters above U+10000 
/*
 $some_string = preg_replace('/[\x00-\x08\x10\x0B\x0C\x0E-\x19\x7F]'.
 '|[\x00-\x7F][\x80-\xBF]+'.
 '|([\xC0\xC1]|[\xF0-\xFF])[\x80-\xBF]*'.
 '|[\xC2-\xDF]((?![\x80-\xBF])|[\x80-\xBF]{2,})'.
 '|[\xE0-\xEF](([\x80-\xBF](?![\x80-\xBF]))|(?![\x80-\xBF]{2})|[\x80-\xBF]{3,})/S',
 '?', $some_string );
 
 //overly long 3 byte sequences and UTF-16 surrogates and replace with ?
 $some_string = preg_replace('/\xE0[\x80-\x9F][\x80-\xBF]'.
 '|\xED[\xA0-\xBF][\x80-\xBF]/S','?', $some_string );
 */


#import "StringUtils.h"


@implementation StringUtils


/*
 * Convenience method to do the check and validation in one.
 */
+ (NSString*) makeValidUTF8:(NSString*) stringToCheck
{
	if (![StringUtils isValidUTF8:stringToCheck])
	{
		return [StringUtils removeInvalidCharsFromString:stringToCheck];
	}
	else
	{
		return stringToCheck;
	}
}

/*
 * Returns true if the string can be converted to UTF8
 */
+ (BOOL) isValidUTF8:(NSString*) stringToCheck
{
	return ([stringToCheck UTF8String] != nil);
}

/*
 * Removes invalid UTF8 chars from the NSString
 * This method is slow, so only run it on strings that fail the +Util::isValidUTF8 check.
 */
+ (NSString*) removeInvalidCharsFromString:(NSString*) stringToCheck
{
	NSMutableString* fixedUp = [[[NSMutableString alloc] initWithCapacity:[stringToCheck length]] autorelease];
	
	// iterates all characters of the string to check
	for (NSUInteger i = 0; i < [stringToCheck length]; i++)
	{
		// gets the character as a one-char string
		unichar character = [stringToCheck characterAtIndex:i];
		NSString* charString = [[NSString alloc] initWithCharacters:&character length:1];
		
		// converts it individually to UTF8, testing for errors
		if ([charString UTF8String] == nil)
		{
			WPLog(@"Invalid UTF-8 sequence encountered at position %lu. Code: %hu (%X). Replacing with \ufffd", (unsigned long) i, character, character);
			[fixedUp appendString:@"\ufffd"];
		}
		else
		{
			[fixedUp appendString:charString];
		}
		[charString release];
	}
	
	WPLog(@"Util:makeValidUTF8 WARNING: string was NOT valid utf-8.  Orig length %d, fixed length %d", [stringToCheck length], [fixedUp length]);
	
	//NSAssert([fixedUp UTF8String] != nil, @"still nil");
	
	return fixedUp;
}

@end
