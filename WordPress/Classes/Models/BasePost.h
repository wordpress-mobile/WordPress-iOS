#import <Foundation/Foundation.h>
#import "Blog.h"
#import "DateUtils.h"
#import "PostContentProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BasePost : NSManagedObject<PostContentProvider>

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
@property (nonatomic, strong, nullable) NSNumber * post_thumbnail;

// Helpers
/**
 Cached path of an image from the post to use for display purposes. 
 Not part of the post's canoncial data.
 */
@property (nonatomic, strong, nullable) NSString *pathForDisplayImage;
/**
 BOOL flag if the feature image was changed.
 */
@property (nonatomic, assign) BOOL isFeaturedImageChanged;

/**
 Create a summary for the post based on the post's content.

 @param string The post's content string. This should be the formatted content string.
 @return A summary for the post.
 */
+ (NSString *)summaryFromContent:(NSString *)string;


//date conversion
@property (nonatomic, strong, nullable) NSDate * dateCreated;

//comments
- (void)findComments;

@end

NS_ASSUME_NONNULL_END
