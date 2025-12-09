#import <Foundation/Foundation.h>
#import <WordPressData/Blog.h>

@class Comment;

NS_ASSUME_NONNULL_BEGIN

@interface BasePost : NSManagedObject

// Attributes
@property (nonatomic, strong, nullable) NSNumber * postID;
@property (nonatomic, strong, nullable) NSNumber * authorID;
@property (nonatomic, strong, nullable) NSString * author;
@property (nonatomic, strong, nullable) NSString * authorAvatarURL;
@property (nonatomic, strong, nullable) NSDate * date_created_gmt;
@property (nonatomic, strong, nullable) NSString * postTitle;
@property (nonatomic, strong, nullable) NSString * content;
@property (nonatomic, strong, nullable) NSString * password;
@property (nonatomic, strong, nullable) NSString * permaLink;
@property (nonatomic, strong, nullable) NSString * mt_excerpt;
@property (nonatomic, strong, nullable) NSString * wp_slug;
@property (nonatomic, strong, nullable) NSString * suggested_slug;
@property (nonatomic, strong, nullable) NSNumber * remoteStatusNumber;
@property (nonatomic, strong, nullable) NSSet *comments;

// Helpers
/**
 Cached path of an image from the post to use for display purposes. 
 Not part of the post's canoncial data.
 */
@property (nonatomic, strong, nullable) NSString *pathForDisplayImage;

@end

@interface BasePost (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end

NS_ASSUME_NONNULL_END
