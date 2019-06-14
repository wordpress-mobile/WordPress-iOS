#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WPException : NSObject

/**
 Exectues the provided block surrounded by a @try @catch block in objetive C. If an NSException is throw it's converted to an NSError

 @param block the block to execute.
 @param outError If an exception is raised this variable returns the an error that wraps the exception.
 @return return true if no exception is raised and false otherwise.
 */
+ (BOOL)objcTryBlock:(void (^)(void))block error:(NSError * __autoreleasing *)outError;

@end

NS_ASSUME_NONNULL_END
