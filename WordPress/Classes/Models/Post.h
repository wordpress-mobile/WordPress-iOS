#import <CoreData/CoreData.h>
#import "AbstractPost.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const PostTypeDefaultIdentifier;

@class Coordinate;

@interface Post : AbstractPost

///-------------------------------
/// @name Specific Post properties
///-------------------------------
@property (nonatomic, strong, nullable) NSNumber *commentCount;
@property (nonatomic, strong, nullable) NSNumber *likeCount;
@property (nonatomic, strong, nullable) Coordinate *geolocation;
@property (nonatomic, strong, nullable) NSString *tags;
@property (nonatomic, strong, nullable) NSString *postType;
@property (nonatomic, strong, nullable) NSString *postFormat;
@property (nonatomic, strong, nullable) NSString *postFormatText;
@property (nonatomic, strong, nullable) NSSet *categories;

// We shouldn't need to store this, but if we don't send IDs on edits
// custom fields get duplicated and stop working
@property (nonatomic, retain, nullable) NSString *latitudeID;
@property (nonatomic, retain, nullable) NSString *longitudeID;
@property (nonatomic, retain, nullable) NSString *publicID;

/**
 A tag for specific post workflows. Only QuickPhoto for now.
 Used for usage stats only.
 */
@property (nonatomic, strong, nullable) NSString *specialType;

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
- (void)setCategoriesFromNames:(nullable NSArray *)categoryNames;

#pragma mark - Convenience methods

- (NSInteger)numberOfComments;
- (NSInteger)numberOfLikes;

@end

@class PostCategory;

@interface Post (CoreDataGeneratedAccessors)

- (void)addCategoriesObject:(PostCategory *)value;
- (void)removeCategoriesObject:(PostCategory *)value;
- (void)addCategories:(NSSet *)values;
- (void)removeCategories:(NSSet *)values;

@end

NS_ASSUME_NONNULL_END
