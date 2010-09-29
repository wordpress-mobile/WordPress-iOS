//
//  CTidy.m
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

#ifdef TOUCHXMLUSETIDY

#import "CTidy.h"

@interface CTidy ()
@end

#pragma mark -

@implementation CTidy

+ (CTidy *)tidy
{
return([[[self alloc] init] autorelease]);
}

- (NSData *)tidyData:(NSData *)inData inputFormat:(CTidyFormat)inInputFormat outputFormat:(CTidyFormat)inOutputFormat diagnostics:(NSString **)outDiagnostics error:(NSError **)outError
{
TidyDoc theTidyDocument = tidyCreate();

int theResultCode = 0;

// Set input format if input is XML (xhtml & html are the tidy 'default')
if (inInputFormat == TidyFormat_XML)
	{
	theResultCode = tidyOptSetBool(theTidyDocument, TidyXmlTags, YES);
	NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");
	}

// Set output format
TidyOptionId theOutputValue = TidyXmlOut;
if (inOutputFormat == TidyFormat_HTML)
	theOutputValue = TidyHtmlOut;
else if (inOutputFormat == TidyFormat_XHTML)
	theOutputValue = TidyXhtmlOut;
theResultCode = tidyOptSetBool(theTidyDocument, theOutputValue, YES);
NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");

// Force output even if errors found
theResultCode = tidyOptSetBool(theTidyDocument, TidyForceOutput, YES);
NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");

theResultCode = tidySetOutCharEncoding(theTidyDocument, "utf8");
NSAssert(theResultCode >= 0, @"tidySetOutCharEncoding() should return 0");

// Create an error buffer
TidyBuffer theErrorBuffer;
tidyBufInit(&theErrorBuffer);
theResultCode = tidySetErrorBuffer(theTidyDocument, &theErrorBuffer);
NSAssert(theResultCode >= 0, @"tidySetErrorBuffer() should return 0");

// #############################################################################

// Create an input buffer and copy input to it (TODO uses 2X memory == bad!)
TidyBuffer theInputBuffer;
tidyBufAlloc(&theInputBuffer, [inData length]);
memcpy(theInputBuffer.bp, [inData bytes], [inData length]);
theInputBuffer.size = [inData length];

// Parse the data.
theResultCode = tidyParseBuffer(theTidyDocument, &theInputBuffer);
if (theResultCode < 0)
	{
	if (outError)
		{
		NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSString stringWithUTF8String:(char *)theErrorBuffer.bp], NSLocalizedDescriptionKey,
			NULL];
		*outError = [NSError errorWithDomain:@"TODO_DOMAIN" code:theResultCode userInfo:theUserInfo];
		}
	return(NO);
	}

// Clean up input buffer.	
tidyBufFree(&theInputBuffer);

// Repair the data
theResultCode = tidyCleanAndRepair(theTidyDocument);
if (theResultCode < 0)
	{
	return(NULL);
	}

//theResultCode = tidyRunDiagnostics(theTidyDocument);

// 
TidyBuffer theOutputBuffer;
tidyBufInit(&theOutputBuffer);
theResultCode = tidySaveBuffer(theTidyDocument, &theOutputBuffer);
if (theResultCode < 0)
	return(NULL);
NSAssert(theOutputBuffer.bp != NULL, @"The buffer should not be null.");
NSData *theOutput = [NSData dataWithBytes:theOutputBuffer.bp length:theOutputBuffer.size];
tidyBufFree(&theOutputBuffer);

// 
if (outDiagnostics && theErrorBuffer.bp != NULL)
	{
	NSData *theErrorData = [NSData dataWithBytes:theErrorBuffer.bp length:theErrorBuffer.size];
	*outDiagnostics = [[[NSString alloc] initWithData:theErrorData encoding:NSUTF8StringEncoding] autorelease];
	}
tidyBufFree(&theErrorBuffer);

// #############################################################################

tidyRelease(theTidyDocument);

return(theOutput);
}

- (NSString *)tidyString:(NSString *)inString inputFormat:(CTidyFormat)inInputFormat outputFormat:(CTidyFormat)inOutputFormat diagnostics:(NSString **)outDiagnostics error:(NSError **)outError
{
TidyDoc theTidyDocument = tidyCreate();

int theResultCode = 0;

// Set input format if input is XML (xhtml & html are the tidy 'default')
if (inInputFormat == TidyFormat_XML)
	{
	theResultCode = tidyOptSetBool(theTidyDocument, TidyXmlTags, YES);
	NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");
	}

// Set output format
TidyOptionId theOutputValue = TidyXmlOut;
if (inOutputFormat == TidyFormat_HTML)
	theOutputValue = TidyHtmlOut;
else if (inOutputFormat == TidyFormat_XHTML)
	theOutputValue = TidyXhtmlOut;
theResultCode = tidyOptSetBool(theTidyDocument, theOutputValue, YES);
NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");

// Force output even if errors found
theResultCode = tidyOptSetBool(theTidyDocument, TidyForceOutput, YES);
NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");

theResultCode = tidySetCharEncoding(theTidyDocument, "utf8");
NSAssert(theResultCode >= 0, @"tidySetOutCharEncoding() should return 0");

// Create an error buffer
TidyBuffer theErrorBuffer;
tidyBufInit(&theErrorBuffer);
theResultCode = tidySetErrorBuffer(theTidyDocument, &theErrorBuffer);
NSAssert(theResultCode >= 0, @"tidySetErrorBuffer() should return 0");

// #############################################################################

// Parse the data.
theResultCode = tidyParseString(theTidyDocument, [inString UTF8String]);
if (theResultCode < 0)
	{
	if (outError)
		{
		NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSString stringWithUTF8String:(char *)theErrorBuffer.bp], NSLocalizedDescriptionKey,
			NULL];
		*outError = [NSError errorWithDomain:@"TODO_DOMAIN" code:theResultCode userInfo:theUserInfo];
		}
	return(NO);
	}

// Repair the data
theResultCode = tidyCleanAndRepair(theTidyDocument);
if (theResultCode < 0)
	{
	return(NULL);
	}

//theResultCode = tidyRunDiagnostics(theTidyDocument);

// 
uint theBufferLength = 0;

theResultCode = tidySaveString(theTidyDocument, NULL, &theBufferLength);

NSMutableData *theOutputBuffer = [NSMutableData dataWithLength:theBufferLength];

theResultCode = tidySaveString(theTidyDocument, [theOutputBuffer mutableBytes], &theBufferLength);

NSString *theString = [[[NSString alloc] initWithData:theOutputBuffer encoding:NSUTF8StringEncoding] autorelease];

// 
if (outDiagnostics && theErrorBuffer.bp != NULL)
	{
	NSData *theErrorData = [NSData dataWithBytes:theErrorBuffer.bp length:theErrorBuffer.size];
	*outDiagnostics = [[[NSString alloc] initWithData:theErrorData encoding:NSUTF8StringEncoding] autorelease];
	}
tidyBufFree(&theErrorBuffer);

// #############################################################################

tidyRelease(theTidyDocument);

return(theString);
}

@end

#endif /* TOUCHXMLUSETIDY */
