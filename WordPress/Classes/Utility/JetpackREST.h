#import <Foundation/Foundation.h>

/**
 Utility class to manage support for Jetpack REST
 */
@interface JetpackREST : NSObject

/**
 Returns if Jetpack REST is enabled
 */
+ (BOOL)enabled;

/**
 Enables or disables Jetpack REST
 
 Since calling this method might require migrating some data in the models, it has 
 a completion block.
 */
+ (void)setEnabled:(BOOL)enabled withCompletion:(void(^)())completion;

@end
