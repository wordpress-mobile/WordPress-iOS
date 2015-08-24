#import <UIKit/UIKit.h>

#import "WPWebViewController.h"

@class Publicizer;
@class Blog;

/**
 *	@brief	Results of attempted authorization
 */
@protocol SharingAuthorizationDelegate <NSObject>
@optional
- (void)authorizeDidSucceed:(Publicizer *)publicizer;
- (void)authorize:(Publicizer *)publicizer didFailWithError:(NSError *)error;
- (void)authorizeDidCancel:(Publicizer *)publicizer;
@end

/**
 *	@brief	Modal controller for hosting 3rd party service (Publicize) login
 */
@interface SharingAuthorizationWebViewController : WPWebViewController

/**
 *	@brief	delegate to be called with results
 */
@property (nonatomic, weak) id<SharingAuthorizationDelegate> delegate;

/**
 *	@brief	Convenience initializer
 *
 *  @param  publicizer  the service to connect to
 *  @param  blog        the blog to publicize
 *
 *  @returns New instance of SharingAuthorizationWebViewController
 */
+ (instancetype)controllerWithPublicizer:(Publicizer *)publicizer
                                 forBlog:(Blog *)blog;

@end
