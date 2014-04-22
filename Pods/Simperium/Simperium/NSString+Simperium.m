//
//  NSString+Simperium.m
//  Simperium
//
//  Created by Michael Johnston on 11-06-03.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "NSString+Simperium.h"
#import <CommonCrypto/CommonDigest.h>

static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@implementation NSString(NSString_Simperium)

// From https://github.com/mikeho/QSUtilities
+ (NSString *)sp_encodeBase64WithString:(NSString *)strData {
    return [NSString sp_encodeBase64WithData:[strData dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSString *)sp_encodeBase64WithData:(NSData *)objData {
    if ([NSData instancesRespondToSelector:@selector(base64EncodedStringWithOptions:)]) {
        return [objData base64EncodedStringWithOptions:0];
    }
    const unsigned char * objRawData = [objData bytes];
    char * objPointer;
    char * strResult;
    
    // Get the Raw Data length and ensure we actually have data
    int intLength = (int)[objData length];
    if (intLength == 0) {
		return nil;	
	}
    
    // Setup the String-based Result placeholder and pointer within that placeholder
    strResult = (char *)calloc(((intLength + 2) / 3) * 4, sizeof(char));
    objPointer = strResult;
    
    // Iterate through everything
    while (intLength > 2) { // keep going until we have less than 24 bits
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
        *objPointer++ = _base64EncodingTable[((objRawData[1] & 0x0f) << 2) + (objRawData[2] >> 6)];
        *objPointer++ = _base64EncodingTable[objRawData[2] & 0x3f];
        
        // we just handled 3 octets (24 bits) of data
        objRawData += 3;
        intLength -= 3; 
    }
    
    // now deal with the tail end of things
    if (intLength != 0) {
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        if (intLength > 1) {
            *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
            *objPointer++ = _base64EncodingTable[(objRawData[1] & 0x0f) << 2];
            *objPointer++ = '=';
        } else {
            *objPointer++ = _base64EncodingTable[(objRawData[0] & 0x03) << 4];
            *objPointer++ = '=';
            *objPointer++ = '=';
        }
    }
    
    // Terminate the string-based result
    *objPointer = '\0';
    
    // Return the results as an NSString object
	return [[NSString alloc] initWithBytesNoCopy:strResult length:(objPointer - strResult) encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

+ (NSString *)sp_makeUUID
{
    // From http://stackoverflow.com/questions/427180/how-to-create-a-guid-uuid-using-the-iphone-sdk
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	NSString *str = CFBridgingRelease(CFUUIDCreateString(NULL, theUUID));
	CFRelease(theUUID);
    
    return [[str stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
}

+ (NSString *)sp_md5StringFromData:(NSData *)data
{
    // http://stackoverflow.com/questions/1028742/compute-a-checksum-on-the-iphone-from-nsdata
    void *cData = malloc([data length]);
    unsigned char resultCString[16];
    [data getBytes:cData length:[data length]];
	
    CC_MD5(cData, (int)[data length], resultCString);
    free(cData);
	
    NSString *result = [NSString stringWithFormat:
                        @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                        resultCString[0], resultCString[1], resultCString[2], resultCString[3], 
                        resultCString[4], resultCString[5], resultCString[6], resultCString[7],
                        resultCString[8], resultCString[9], resultCString[10], resultCString[11],
                        resultCString[12], resultCString[13], resultCString[14], resultCString[15]
                        ];
    return result;
}

- (NSString *)sp_urlEncodeString
{
    return (NSString *) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self,
                                                                                  NULL, (CFStringRef)@";/?:@&=$+{}<>!*'()%#[],",
                                                                                  CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
}  

- (NSArray *)sp_componentsSeparatedByString:(NSString *)separator limit:(NSInteger)limit
{
    NSMutableArray *components  = [NSMutableArray array];
    NSString *pending           = self;
    NSRange range               = [pending rangeOfString:separator];

    while ( (range.location != NSNotFound) && (components.count < limit - 1) ) {
        NSString *left = [pending substringToIndex:range.location];
        if (left) {
            [components addObject:left];
        }
        
        pending = [pending substringFromIndex:range.location+range.length];
        range   = [pending rangeOfString:separator];
    }
    
    if (pending) {
        [components addObject:pending];
    }
    
    return components;
}

@end
