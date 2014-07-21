#import <CoreData/CoreData.h>
#import "WordPressAppDelegate.h"
#import "Category.h"
#import "Coordinate.h"
#import "AbstractPost.h"
#import "Media.h"

@interface Post :  AbstractPost

///-------------------------------
/// @name Specific Post properties
///-------------------------------

@property (nonatomic, strong) Coordinate * geolocation;
@property (nonatomic, strong) NSString * tags;
@property (nonatomic, strong) NSString * postFormat;
@property (nonatomic, strong) NSString * postFormatText;
@property (nonatomic, strong) NSMutableSet * categories;
@property (nonatomic, strong) NSString *authorAvatarURL;

/**
 A tag for specific post workflows. Only QuickPhoto for now.
 Used for usage stats only.
 */
@property (nonatomic, strong) NSString *specialType;

/**
 Stored in order to avoid re-parsing the content
 */
@property (nonatomic, strong) NSString *summary;

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

- (UIImage *)cachedAvatarWithSize:(CGSize)size;

- (void)fetchAvatarWithSize:(CGSize)size success:(void (^)(UIImage *image))success;

@end