#import <Foundation/Foundation.h>

/**
 The minimum Jetpack version required for the app to work.
 */
extern NSString * const JetpackVersionMinimumRequired;

/**
 🚀 Encapsulates the Jetpack-related options for a blog.
 */
@interface JetpackState : NSObject

#pragma mark Primitives

@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *connectedUsername;
@property (nonatomic, strong) NSString *connectedEmail;

#pragma mark Helpers

/**
 Returns YES if Jetpack is installed and activated on the site.
 */
- (BOOL)isInstalled;

/**
 Returns YES if Jetpack is connected to WordPress.com.
 
 @warn Before Jetpack 3.6, a site might appear connected if it was connected and then disconnected. See https://github.com/Automattic/jetpack/issues/2137
 */
- (BOOL)isConnected;

/**
 Returns YES if the detected version meets the app requirements.
 
 @see JetpackVersionMinimumRequired
 */
- (BOOL)isUpdatedToRequiredVersion;

@end
