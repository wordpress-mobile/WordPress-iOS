#import <Foundation/Foundation.h>


@interface NSObject (ObjectValidation)

/**
 Validate if a class is a valid NSObject and if it's not nil

 @return Bool value
 */
- (BOOL)wp_isValidObject;

/**
 Validate if a class is a valid NSString and if it's not nil

 @return Bool value
 */
- (BOOL)wp_isValidString;
@end
