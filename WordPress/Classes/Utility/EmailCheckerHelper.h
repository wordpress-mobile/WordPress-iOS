#import <Foundation/Foundation.h>

@interface EmailCheckerHelper : NSObject

/**
 A proxy for the EmailChecker pod. Allows the EmailChecker functionality to be
 used in .swift files. 
 */
+ (NSString *) suggestDomainCorrection:(NSString *)email;

@end
