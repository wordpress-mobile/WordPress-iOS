//
//  WPAccount.h
//  WordPress
//
//  Created by Jorge Bernal on 4/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import <WordPressApi/WordPressApi.h>

#import "WordPressComApi.h"

@class Blog;

extern NSString *const WPAccountDefaultWordPressComAccountChangedNotification;

@interface WPAccount : NSManagedObject

///-----------------
/// @name Properties
///-----------------

@property (nonatomic, readonly, retain) NSString *xmlrpc;
@property (nonatomic, readonly, retain) NSString *username;
@property (nonatomic, readonly) BOOL isWpcom;
@property (nonatomic, retain) NSSet *blogs;
@property (nonatomic, retain) NSSet *jetpackBlogs;
@property (nonatomic, readonly) NSArray *visibleBlogs;

/**
 The account's password
 
 Note that the password is stored using the keychain, not core data
 */
@property (nonatomic, retain) NSString *password;

/**
 The OAuth2 auth token for WordPress.com accounts
 */
@property (nonatomic, readonly) NSString *authToken;

///------------------------------------
/// @name Default WordPress.com account
///------------------------------------

/**
 Returns the default WordPress.com account
 
 The default WordPress.com account is the one used for Reader and Notifications
 
 @return the default WordPress.com account
 @see setDefaultWordPressComAccount:
 @see removeDefaultWordPressComAccount
 */
+ (WPAccount *)defaultWordPressComAccount;

/**
 Sets the default WordPress.com account
 
 @param account the account to set as default for WordPress.com
 @see defaultWordPressComAccount
 @see removeDefaultWordPressComAccount
 */
+ (void)setDefaultWordPressComAccount:(WPAccount *)account;

/**
 Removes the default WordPress.com account

 @see defaultWordPressComAccount
 @see setDefaultWordPressComAccount:
*/
+ (void)removeDefaultWordPressComAccount;

/**
 Removes the default WordPress.com account 
 on the context of choice
 
 @param context the NSManagedObjectContext
 */
+ (void)removeDefaultWordPressComAccountWithContext:(NSManagedObjectContext *)context;

///-----------------------
/// @name Account creation
///-----------------------

/**
 Creates a new WordPress.com account or updates the password if there is a matching account

 There can only be one WordPress.com account per username, so if one already exists for the given `username` its password is updated

 @param username the WordPress.com account's username
 @param password the WordPress.com account's password
 @param authToken the OAuth2 token returned by signIntoWordPressDotComWithUsername:password:success:failure:
 @param context the NSManagedObjectContext used to create or update the account
 @return a WordPress.com `WPAccount` object for the given `username`
 */
+ (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username
                                                    password:(NSString *)password
                                                   authToken:(NSString *)authToken
                                                     context:(NSManagedObjectContext *)context;

/**
 Creates a new WordPress.com account or updates the password if there is a matching account

 There can only be one WordPress.com account per username, so if one already exists for the given `username` its password is updated
 
 Uses a background managed object context.

 @param username the WordPress.com account's username
 @param password the WordPress.com account's password
 @param authToken the OAuth2 token returned by signIntoWordPressDotComWithUsername:password:success:failure:
 @return a WordPress.com `WPAccount` object for the given `username`
 @see createOrUpdateWordPressComAccountWithUsername:password:authToken:context:
 */
+ (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username
                                                    password:(NSString *)password
                                                   authToken:(NSString *)authToken;

/**
 Creates a new self hosted account or updates the password if there is a matching account

 There can only be one account per XML-RPC endpoint and username, so if one already exists its password is updated

 @param xmlrpc the account XML-RPC endpoint
 @param username the account's username
 @param password the account's password
 @param context the NSManagedObjectContext used to create or update the account
 @return a `WPAccount` object for the given `xmlrpc` endpoint and `username`
 */
+ (WPAccount *)createOrUpdateSelfHostedAccountWithXmlrpc:(NSString *)xmlrpc
                                                username:(NSString *)username
                                             andPassword:(NSString *)password
                                             withContext:(NSManagedObjectContext *)context;
/**
 Creates a new self hosted account or updates the password if there is a matching account

 There can only be one account per XML-RPC endpoint and username, so if one already exists its password is updated
 
 Uses a background managed object context.

 @param xmlrpc the account XML-RPC endpoint
 @param username the account's username
 @param password the account's password
 @return a `WPAccount` object for the given `xmlrpc` endpoint and `username`
 */
+ (WPAccount *)createOrUpdateSelfHostedAccountWithXmlrpc:(NSString *)xmlrpc
                                                username:(NSString *)username
                                             andPassword:(NSString *)password;

///--------------------
/// @name Blog creation
///--------------------

/**
 Creates a `Blog` object for this account with the given XML-RPC dictionary
 
 If a there is an existing blog with the same `url`, it is returned as-is.
 
 @param blogInfo a dictionary containing `url`, `blogName`, `xmlrpc`, and `blogid`; as returned by `wp.getUsersBlogs`
 @return the newly created blog
 */
- (Blog *)findOrCreateBlogFromDictionary:(NSDictionary *)blogInfo withContext:(NSManagedObjectContext*)context;

- (void)syncBlogsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

///------------------
/// @name API Helpers
///------------------

/**
 A WordPressComApi object if the account is a WordPress.com account. Otherwise, it returns `nil`
 */
@property (nonatomic, readonly) WordPressComApi *restApi;

/**
 A WordPressXMLRPCApi object configured for the XML-RPC endpoint
 */
@property (nonatomic, readonly) WordPressXMLRPCApi *xmlrpcApi;

@end

@interface WPAccount (CoreDataGeneratedAccessors)

- (void)addBlogsObject:(Blog *)value;
- (void)removeBlogsObject:(Blog *)value;
- (void)addBlogs:(NSSet *)values;
- (void)removeBlogs:(NSSet *)values;

- (void)addJetpackBlogsObject:(Blog *)value;
- (void)removeJetpackBlogsObject:(Blog *)value;
- (void)addJetpackBlogs:(NSSet *)values;
- (void)removeJetpackBlogs:(NSSet *)values;

@end
