//
//  XMLRPCDataCleaner.m
//  Based on code from WordPress for iOS http://ios.wordpress.org/
//
//  Created by Jorge Bernal on 12/15/11.
//  Original code by Danilo Ercoli
//  Copyright (c) 2011 WordPress.
//

#import "XMLRPCDataCleaner.h"
#import <iconv.h>

@interface XMLRPCDataCleaner (CleaningSteps)
- (NSData *)cleanInvalidUTF8:(NSData *)str;
- (NSString *)cleanCharactersBeforePreamble:(NSString *)str;
- (NSString *)cleanInvalidXMLCharacters:(NSString *)str;
- (NSString *)cleanWithTidyIfPresent:(NSString *)str;
@end

@implementation XMLRPCDataCleaner

#pragma mark - initializers

- (id)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        xmlData = [data retain];
    }
    return self;
}

- (void)dealloc {
    [xmlData release];
    [super dealloc];
}

#pragma mark - clean output

- (NSData *)cleanData {
    if (xmlData == nil)
        return nil;
    
    NSData *cleanData = [self cleanInvalidUTF8:xmlData];
    NSString *cleanString = [[[NSString alloc] initWithData:cleanData encoding:NSUTF8StringEncoding] autorelease];
    
    if (cleanString == nil) {
        // Although it shouldn't happen, fall back to Latin1 if data is not proper UTF-8
        cleanString = [[NSString alloc] initWithData:cleanData encoding:NSISOLatin1StringEncoding];
    }
    
    cleanString = [self cleanCharactersBeforePreamble:cleanString];
    cleanString = [self cleanInvalidXMLCharacters:cleanString];
    cleanString = [self cleanWithTidyIfPresent:cleanString];
    
    cleanData = [cleanString dataUsingEncoding:NSUTF8StringEncoding];
    
    return cleanData;
}

@end

@implementation XMLRPCDataCleaner (CleaningSteps)

/**
 Runs the given data through iconv to discard any invalid UTF-8 characters
 */
- (NSData *)cleanInvalidUTF8:(NSData *)data {
    NSData *result;
    iconv_t cd = iconv_open("UTF-8", "UTF-8"); // convert to UTF-8 from UTF-8
	int one = 1;
	iconvctl(cd, ICONV_SET_DISCARD_ILSEQ, &one); // discard invalid characters
	
	size_t inbytesleft, outbytesleft;
	inbytesleft = outbytesleft = data.length;

	char *inbuf  = (char *)data.bytes;
	char *outbuf = malloc(sizeof(char) * data.length);
	char *outptr = outbuf;

	if (iconv(cd, &inbuf, &inbytesleft, &outptr, &outbytesleft) == (size_t)-1) {
		// Failed iconv, possible errors to encounter in `errno`:
        //
        //     E2BIG - There is not sufficient room at *outbuf.
        //     EILSEQ - An invalid multibyte sequence has been encountered in the input.
        //     EINVAL - An incomplete multibyte sequence has been encountered in the input.
        //
        // It should never happen since we've told iconv to discard anything invalid

		result = data;
    } else {
        result = [NSData dataWithBytes:outbuf length:data.length - outbytesleft];
    }
	
	iconv_close(cd);
	free(outbuf);

	return result;
}

/**
 Remove any text before the XML preamble `<?xml`
 */
- (NSString *)cleanCharactersBeforePreamble:(NSString *)str {
    NSRange range = [str rangeOfString:@"<?xml"];
    // Did we find the string "<?xml" ?
    if (range.location != NSNotFound && range.length > 0 && range.location > 0) {   
        str = [str substringFromIndex:range.location];
    }
    return str;
}

/**
 Remove invalid characters as specified by the XML 1.0 standard
 
 Based on http://benjchristensen.com/2008/02/07/how-to-strip-invalid-xml-characters/
 */
- (NSString *)cleanInvalidXMLCharacters:(NSString *)str {
    int len = [str length];

    NSMutableString *result = [NSMutableString stringWithCapacity:len];
    for( int charIndex = 0; charIndex < len; charIndex++) {
        unichar testChar = [str characterAtIndex:charIndex];
        if((testChar == 0x9) ||
           (testChar == 0xA) ||
           (testChar == 0xD) ||
           ((testChar >= 0x20) && (testChar <= 0xD7FF)) ||
           ((testChar >= 0xE000) && (testChar <= 0xFFFD))
           ) {
            NSString *validCharacter = [NSString stringWithFormat:@"%C", testChar];
            [result appendString:validCharacter];
        }
    }
    return result;
}

/**
 If CTidy is available, run the cleaned XML through tidy as a last fix before parsing
 */
- (NSString *)cleanWithTidyIfPresent:(NSString *)str {
    /*
     The conditional code we're executing is the equivalent of:
     
     [[CTidy tidy] tidyString:str inputFormat:TidyFormat_XML outputFormat:TidyFormat_XML diagnostics:NULL error:&err];
     */
    id _CTidyClass = NSClassFromString(@"CTidy");
    SEL _CTidySelector = NSSelectorFromString(@"tidy");
    SEL _CTidyTidyStringSelector = NSSelectorFromString(@"tidyString:inputFormat:outputFormat:encoding:diagnostics:error:");
    
    if (_CTidyClass && [_CTidyClass respondsToSelector:_CTidySelector]) {
        id _CTidyInstance = [_CTidyClass performSelector:_CTidySelector];
        
        if (_CTidyInstance && [_CTidyInstance respondsToSelector:_CTidyTidyStringSelector]) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_CTidyInstance methodSignatureForSelector:_CTidyTidyStringSelector]];
            invocation.target = _CTidyInstance;
            invocation.selector = _CTidyTidyStringSelector;
            
            // arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
            [invocation setArgument:&str atIndex:2]; // tidyString:
            int format = 1; // TidyFormat_XML
            [invocation setArgument:&format atIndex:3]; // inputFormat:
            [invocation setArgument:&format atIndex:4]; // outputFormat:
            NSString *encoding = @"utf8";
            [invocation setArgument:&encoding atIndex:5]; // encoding:
            // 6 diagnostics: nil
            NSError *err = nil;
            [invocation setArgument:&err atIndex:7]; // error:
            
            [invocation invoke];
            
            NSString *result = nil;
            [invocation getReturnValue:&result];
            if (result)
                return result;
        }        
    }
    
    // If we reach this point, something failed. Return the original string
    return str;
}

@end