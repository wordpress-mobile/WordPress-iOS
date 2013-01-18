//
//  Post.h
//  WordPress
//
//  Created by Chris Boyd on 8/9/10.
//

#import <CoreData/CoreData.h>
#import "WordPressAppDelegate.h"
#import "Category.h"
#import "Coordinate.h"
#import "AbstractPost.h"
#import "Media.h"

@interface Post :  AbstractPost {
    WordPressAppDelegate *appDelegate;
}

///-------------------------------
/// @name Specific Post properties
///-------------------------------

@property (nonatomic, strong) Coordinate * geolocation;
@property (nonatomic, strong) NSString * tags;
@property (nonatomic, strong) NSString * postFormat;
@property (nonatomic, strong) NSString * postFormatText;
@property (nonatomic, strong) NSMutableSet * categories;
@property (nonatomic, strong) NSString *featuredImageURL;

/**
 A tag for specific post workflows. Only QuickPhoto for now.
 Used for usage stats only.
 */
@property (nonatomic, strong) NSString *specialType;

///---------------------
/// @name Helper methods
///---------------------

/**
 Returns categories as a comma-separated list
 */
- (NSString *)categoriesText;

/**
 Set the categories for a post
 
 @param categoryNames a `NSArray` with the names of the categories for this post. If a given category name doesn't exist it's ignored.
 */
- (void)setCategoriesFromNames:(NSArray *)categoryNames;

///---------------------------------
/// @name Creating and finding posts
///---------------------------------

/**
 Creates an empty local post associated with blog
 */
+ (Post *)newDraftForBlog:(Blog *)blog;

/**
 Retrieves the post with the specified `postID` for a given blog
 
 @returns the specified post. Returns nil if there is no post with that id on the blog
 */
+ (Post *)findWithBlog:(Blog *)blog andPostID:(NSNumber *)postID;

/**
 Takes the NSDictionary from a XMLRPC call and creates or updates a post
 */
+ (Post *)createOrReplaceFromDictionary:(NSDictionary *)postInfo forBlog:(Blog *)blog;

///------------------------
/// @name Remote management
///------------------------
///
/// The following methods will change the post on the WordPress site

/**
 Uploads a new post or changes to an edited post
 */
- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

- (void)getFeaturedImageURLWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;


@end