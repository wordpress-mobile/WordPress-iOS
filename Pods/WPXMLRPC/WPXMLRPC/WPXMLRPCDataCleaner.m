// WPXMLRPCDataCleaner.m
// Based on code from WordPress for iOS http://ios.wordpress.org/
//
// Copyright (c) 2013 WordPress - http://wordpress.org/
// Based on Eric Czarny's xmlrpc library - https://github.com/eczarny/xmlrpc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "WPXMLRPCDataCleaner.h"
#import <iconv.h>

@interface WPXMLRPCDataCleaner (CleaningSteps)
- (NSData *)cleanInvalidUTF8:(NSData *)str;
- (NSString *)cleanCharactersBeforePreamble:(NSString *)str;
- (NSString *)cleanInvalidXMLCharacters:(NSString *)str;
- (NSString *)cleanWithTidyIfPresent:(NSString *)str;
@end

@implementation WPXMLRPCDataCleaner {
    NSData *xmlData;
}

#pragma mark - initializers

- (id)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        xmlData = data;
    }
    return self;
}


#pragma mark - clean output

- (NSData *)cleanData {
    if (xmlData == nil)
        return nil;
    
    NSData *cleanData = [self cleanInvalidUTF8:xmlData];
    NSString *cleanString = [[NSString alloc] initWithData:cleanData encoding:NSUTF8StringEncoding];
    
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

@implementation WPXMLRPCDataCleaner (CleaningSteps)

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
    NSUInteger len = [str length];

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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id _CTidyInstance = [_CTidyClass performSelector:_CTidySelector];
#pragma clang diagnostic pop

        if (_CTidyInstance && [_CTidyInstance respondsToSelector:_CTidyTidyStringSelector]) {
            typedef NSString *(*_CTidyTidyStringMethodType)(id, SEL, NSString *, int, int, NSString *, NSError **);
            _CTidyTidyStringMethodType _CTidyTidyStringMethod;
            _CTidyTidyStringMethod = (_CTidyTidyStringMethodType)[_CTidyInstance methodForSelector:_CTidyTidyStringSelector];

            NSError *err = nil;
            NSString *result = _CTidyTidyStringMethod(_CTidyInstance, _CTidyTidyStringSelector, str, 1, 1, @"utf8", &err);

            if (result)
                return result;
        }        
    }
    
    // If we reach this point, something failed. Return the original string
    return str;
}

@end