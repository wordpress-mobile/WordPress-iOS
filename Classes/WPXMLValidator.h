#import <UIKit/UIKit.h>

// purpose is to check given xml string is valid or not.
@interface WPXMLValidator : NSObject 
{
}

+ (WPXMLValidator *)sharedValidator;

//NOTE  ... returns YES in case of nil, @"" as well.
- (BOOL)isValidXMLString:(NSString *)aStr;

@end
