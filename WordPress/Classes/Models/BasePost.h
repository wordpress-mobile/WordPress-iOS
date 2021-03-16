#import <Foundation/Foundation.h>
#import "Blog.h"
#import "PostContentProvider.h"
@import WordPressShared;

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
 BOOL flag set to true if the post is first time published.
 */
@property (nonatomic, assign) BOOL isFirstTimePublish;

//date conversion
@property (nonatomic, strong, nullable) NSDate * dateCreated;

//comments
- (void)findComments;

// Returns true if title or content is non empty
- (BOOL)hasContent;

// True if the content field is empty, independent of the title field.
- (BOOL)isContentEmpty;

@end

NS_ASSUME_NONNULL_END
