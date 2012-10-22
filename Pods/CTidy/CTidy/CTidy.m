//
//  CTidy.m
//  TouchCode
//
//  Created by Jonathan Wight on 03/07/08.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

#import "CTidy.h"

@interface CTidy ()
@end

#pragma mark -

@implementation CTidy

+ (CTidy *)tidy
{
    return([[self alloc] init]);
}

- (NSData *)tidyData:(NSData *)inData inputFormat:(CTidyFormat)inInputFormat outputFormat:(CTidyFormat)inOutputFormat encoding:(NSString*)inEncoding diagnostics:(NSString **)outDiagnostics error:(NSError **)outError
{
    TidyDoc theTidyDocument = ig_tidyCreate();

    int theResultCode = 0;
    
    // Set input format if input is XML (xhtml & html are the tidy 'default')
    if (inInputFormat == CTidyFormatXML)
	{
        theResultCode = ig_tidyOptSetBool(theTidyDocument, TidyXmlTags, YES);
        NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");
	}
    
    // Set output format
    TidyOptionId theOutputValue = TidyXmlOut;
    if (inOutputFormat == CTidyFormatHTML)
        theOutputValue = TidyHtmlOut;
    else if (inOutputFormat == CTidyFormatXHTML)
        theOutputValue = TidyXhtmlOut;
    theResultCode = ig_tidyOptSetBool(theTidyDocument, theOutputValue, YES);
    NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");
    
    // Force output even if errors found
    theResultCode = ig_tidyOptSetBool(theTidyDocument, TidyForceOutput, YES);
    NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");
    
    // Don't wrap long lines
    theResultCode = ig_tidyOptSetInt(theTidyDocument, TidyWrapLen, 0);
    NSAssert(theResultCode >= 0, @"tidyOptSetInt() should return 0");
    
    // Set encoding - same for input and output
    theResultCode = ig_tidySetInCharEncoding(theTidyDocument, inEncoding.UTF8String);
    NSAssert(theResultCode >= 0, @"tidySetInCharEncoding() should return 0");
    theResultCode = ig_tidySetOutCharEncoding(theTidyDocument, inEncoding.UTF8String);
    NSAssert(theResultCode >= 0, @"tidySetOutCharEncoding() should return 0");
    
    // Create an error buffer
    TidyBuffer theErrorBuffer;
    ig_tidyBufInit(&theErrorBuffer);
    theResultCode = ig_tidySetErrorBuffer(theTidyDocument, &theErrorBuffer);
    NSAssert(theResultCode >= 0, @"tidySetErrorBuffer() should return 0");
    
    // #############################################################################
    
    // Create an input buffer and copy input to it (TODO uses 2X memory == bad!)
    TidyBuffer theInputBuffer;
    ig_tidyBufAlloc(&theInputBuffer, [inData length]);
    memcpy(theInputBuffer.bp, [inData bytes], [inData length]);
    theInputBuffer.size = [inData length];
    
    // Parse the data.
    theResultCode = ig_tidyParseBuffer(theTidyDocument, &theInputBuffer);
    if (theResultCode < 0)
	{
        if (outError)
		{
            NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSString stringWithUTF8String:(char *)theErrorBuffer.bp], NSLocalizedDescriptionKey,
                                         NULL];
            *outError = [NSError errorWithDomain:@"TODO_DOMAIN" code:theResultCode userInfo:theUserInfo];
		}
        return(NULL);
	}
    
    // Clean up input buffer.	
    ig_tidyBufFree(&theInputBuffer);
    
    // Repair the data
    theResultCode = ig_tidyCleanAndRepair(theTidyDocument);
    if (theResultCode < 0)
	{
        return(NULL);
	}
    
    //theResultCode = tidyRunDiagnostics(theTidyDocument);
    
    // 
    TidyBuffer theOutputBuffer;
    ig_tidyBufInit(&theOutputBuffer);
    theResultCode = ig_tidySaveBuffer(theTidyDocument, &theOutputBuffer);
    if (theResultCode < 0)
        return(NULL);
    NSAssert(theOutputBuffer.bp != NULL, @"The buffer should not be null.");
    NSData *theOutput = [NSData dataWithBytes:theOutputBuffer.bp length:theOutputBuffer.size];
    ig_tidyBufFree(&theOutputBuffer);
    
    // 
    if (outDiagnostics && theErrorBuffer.bp != NULL)
	{
        NSData *theErrorData = [NSData dataWithBytes:theErrorBuffer.bp length:theErrorBuffer.size];
        *outDiagnostics = [[NSString alloc] initWithData:theErrorData encoding:NSUTF8StringEncoding];
	}
    ig_tidyBufFree(&theErrorBuffer);
    
    // #############################################################################
    
    ig_tidyRelease(theTidyDocument);
    
    return(theOutput);
}

- (NSString *)tidyString:(NSString *)inString inputFormat:(CTidyFormat)inInputFormat outputFormat:(CTidyFormat)inOutputFormat encoding:(NSString*)inEncoding diagnostics:(NSString **)outDiagnostics error:(NSError **)outError
{
    TidyDoc theTidyDocument = ig_tidyCreate();
    
    int theResultCode = 0;
    
    // Set input format if input is XML (xhtml & html are the tidy 'default')
    if (inInputFormat == CTidyFormatXML)
	{
        theResultCode = ig_tidyOptSetBool(theTidyDocument, TidyXmlTags, YES);
        NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");
	}
    
    // Set output format
    TidyOptionId theOutputValue = TidyXmlOut;
    if (inOutputFormat == CTidyFormatHTML)
        theOutputValue = TidyHtmlOut;
    else if (inOutputFormat == CTidyFormatXHTML)
        theOutputValue = TidyXhtmlOut;
    theResultCode = ig_tidyOptSetBool(theTidyDocument, theOutputValue, YES);
    NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");
    
    // Force output even if errors found
    theResultCode = ig_tidyOptSetBool(theTidyDocument, TidyForceOutput, YES);
    NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");
    
    // Set encoding - same for input and output
    theResultCode = ig_tidySetInCharEncoding(theTidyDocument, inEncoding.UTF8String);
    NSAssert(theResultCode >= 0, @"tidySetInCharEncoding() should return 0");
    theResultCode = ig_tidySetOutCharEncoding(theTidyDocument, inEncoding.UTF8String);
    NSAssert(theResultCode >= 0, @"tidySetOutCharEncoding() should return 0");
    
    // Create an error buffer
    TidyBuffer theErrorBuffer;
    ig_tidyBufInit(&theErrorBuffer);
    theResultCode = ig_tidySetErrorBuffer(theTidyDocument, &theErrorBuffer);
    NSAssert(theResultCode >= 0, @"tidySetErrorBuffer() should return 0");
    
    // #############################################################################
    
    // Parse the data.
    theResultCode = ig_tidyParseString(theTidyDocument, [inString UTF8String]);
    if (theResultCode < 0)
	{
        if (outError)
		{
            NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSString stringWithUTF8String:(char *)theErrorBuffer.bp], NSLocalizedDescriptionKey,
                                         NULL];
            *outError = [NSError errorWithDomain:@"TODO_DOMAIN" code:theResultCode userInfo:theUserInfo];
		}
        return(NULL);
	}
    
    // Repair the data
    theResultCode = ig_tidyCleanAndRepair(theTidyDocument);
    if (theResultCode < 0)
	{
        return(NULL);
	}
    
    //theResultCode = tidyRunDiagnostics(theTidyDocument);
    
    // 
    uint theBufferLength = 0;
    
    theResultCode = ig_tidySaveString(theTidyDocument, NULL, &theBufferLength);
    
    NSMutableData *theOutputBuffer = [NSMutableData dataWithLength:theBufferLength];
    
    theResultCode = ig_tidySaveString(theTidyDocument, [theOutputBuffer mutableBytes], &theBufferLength);
    
    NSString *theString = [[NSString alloc] initWithData:theOutputBuffer encoding:NSUTF8StringEncoding];
    
    // 
    if (outDiagnostics && theErrorBuffer.bp != NULL)
	{
        NSData *theErrorData = [NSData dataWithBytes:theErrorBuffer.bp length:theErrorBuffer.size];
        *outDiagnostics = [[NSString alloc] initWithData:theErrorData encoding:NSUTF8StringEncoding];
	}
    ig_tidyBufFree(&theErrorBuffer);
    
    // #############################################################################
    
    ig_tidyRelease(theTidyDocument);
    
    return(theString);
}

- (NSString *)tidyHTMLString:(NSString *)inString encoding:(NSString*)inEncoding error:(NSError **)outError {
    return [self tidyString:inString inputFormat:CTidyFormatHTML outputFormat:CTidyFormatXHTML encoding:inEncoding diagnostics:nil error:outError];
}

@end
