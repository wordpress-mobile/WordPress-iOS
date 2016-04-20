#import <UIKit/UIKit.h>

#import "WPWebViewController.h"

@class PublicizeService;
@class Blog;

/**
 *	@brief	Results of attempted authorization
 */
@protocol SharingAuthorizationDelegate <NSObject>
- (void)authorizeDidSucceed:(PublicizeService *)publicizer;
- (void)authorize:(PublicizeService *)publicizer didFailWithError:(NSError *)error;
- (void)authorizeDidCancel:(PublicizeService *)publicizer;
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
 *  @param  connectionURL the URL to use for the connection
 *  @param  blog        the blog to publicize
 *
 *  @returns New instance of SharingAuthorizationWebViewController
 */
+ (instancetype)controllerWithPublicizer:(PublicizeService *)publicizer
                           connectionURL:(NSURL *)connectionURL
                                 forBlog:(Blog *)blog;

@end
