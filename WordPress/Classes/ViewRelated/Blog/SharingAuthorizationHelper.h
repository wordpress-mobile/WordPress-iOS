#import <Foundation/Foundation.h>

@protocol SharingAuthorizationHelperDelegate;
@class PublicizeService;
@class KeyringConnection;
@class PublicizeConnection;
@class Blog;

/**
 A helper class for managing aspects of a publicize service.  Supports creating,
 updating and deleting connections to a publicize service for a specified blog.
 */
@interface SharingAuthorizationHelper : NSObject

@property (nonatomic, weak) id<SharingAuthorizationHelperDelegate>delegate;
@property (nonatomic, strong) UIView *popoverSourceView;

/**
 Returns a new instance.

 @param viewController: A view controller to act as the presenter for the modal auth and account selection view controllers.
 @param blog: The blog whose publicize connections are being managed.
 @param publicizeServices: The list of available publicize services.

 @return A new instance
 */
- (instancetype)initWithViewController:(UIViewController *)viewController blog:(Blog *)blog publicizeService:(PublicizeService *)publicizeService;

/**
 Starts the process of connecting to publicize service passed when the instance was created.
 A `SharingAuthorizationWebViewController` is presented modally allowing the user
 to establish the necessary oAuth handshake with a publicize service.
 */
- (void)connectPublicizeService;

/**
 Starts the process of reconnecting a broken publicize connection.
 A `SharingAuthorizationWebViewController` is presented modally allowing the user
 to repair the necessary oAuth handshake with a publicize service.
 
 @param publicizeConnection: An existing publicize connection to the publicize service
 being managed.
 */
- (void)reconnectPublicizeConnection:(PublicizeConnection *)publicizeConnection;

@end

@protocol SharingAuthorizationHelperDelegate <NSObject>

@optional

- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper authorizationSucceededForService:(PublicizeService *)service;
- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper authorizationFailedForService:(PublicizeService *)service;
- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper authorizationCancelledForService:(PublicizeService *)service;

- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper willFetchKeyringsForService:(PublicizeService *)service;
- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper didFetchKeyringsForService:(PublicizeService *)service;
- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper keyringFetchFailedForService:(PublicizeService *)service;

- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper willConnectToService:(PublicizeService *)service usingKeyringConnection:(KeyringConnection *)keyringConnection;
- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper didConnectToService:(PublicizeService *)service withPublicizeConnection:(PublicizeConnection *)keyringConnection;

- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper connectionFailedForService:(PublicizeService *)service;
- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper connectionCancelledForService:(PublicizeService *)service;

@end
