#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class Blog;
@class ManagedAccountSettings;
@class WordPressComRestApi;

@interface WPAccount : NSManagedObject

///-----------------
/// @name Properties
///-----------------

/*
 The nullablity annotation on the Core Data properties follows the data scheme in the model file. Some of these
 annotations do not make much sense (like how can userId be nullable?). But we'll follow the Core Data scheme to be
 extra safe.
 */

@property (nonatomic, strong, nullable)   NSNumber    *userID;
@property (nonatomic, strong, nullable)   NSString    *avatarURL;
@property (nonatomic, copy, nonnull)     NSString    *username;
@property (nonatomic, copy, nullable)     NSString    *uuid;
@property (nonatomic, strong, nullable)   NSDate      *dateCreated;
@property (nonatomic, strong, nullable)   NSString    *email;
@property (nonatomic, strong, nullable)   NSString    *displayName;
@property (nonatomic, strong, nullable)   NSNumber    *emailVerified;
@property (nonatomic, strong, nullable)   NSNumber    *primaryBlogID;
@property (nonatomic, strong, nullable)   NSSet<Blog *>       *blogs;
@property (nonatomic, strong, nullable)   Blog        *defaultBlog;
@property (nonatomic, strong, nullable)   ManagedAccountSettings *settings;

/**
 The OAuth2 auth token for WordPress.com accounts
 */
@property (nonatomic, copy, nullable) NSString *authToken;

///------------------
/// @name API Helpers
///------------------

/// A WordPressRestComApi object if the account is a WordPress.com account. Otherwise, it returns `nil`.
///
/// Important: Do not set this directly!
///
/// It's reserved for Objective-C to Swift interoperability in the context of separating this model from the app target and will be removed at some point.
@property (nonatomic, strong, nullable) WordPressComRestApi *_private_wordPressComRestApi;

@end

@interface WPAccount (CoreDataGeneratedAccessors)

- (void)addBlogsObject:(Blog *)value;
- (void)removeBlogsObject:(Blog *)value;
- (void)addBlogs:(NSSet *)values;
- (void)removeBlogs:(NSSet *)values;
+ (NSString * _Nullable)tokenForUsername:(NSString *)username isJetpack:(BOOL)isJetpack error:(NSError ** _Nullable)error;
- (BOOL)hasAtomicSite;

@end

NS_ASSUME_NONNULL_END
