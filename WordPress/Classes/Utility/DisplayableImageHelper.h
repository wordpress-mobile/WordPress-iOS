#import <Foundation/Foundation.h>

/**
 Helper for searching a post's content or attachments for an image suitable for 
 using as the displayed image in the post list. 
 */
@interface DisplayableImageHelper : NSObject

/**
 Get the url path of the image to display for a post.

 @param dict A dictionary representing a posts attachments from the REST API.
 @param string The post content. The attachment url must exist in the content.
 @return The url path for the featured image or nil
 */
+ (NSString *)searchPostAttachmentsForImageToDisplay:(NSDictionary *)attachmentsDict existingInContent:(NSString *)content;

/**
 Search the passed string for an image that is a good candidate to feature.

 @details Loops over all img tags in the passed html content, extracts the URL from the
 src attribute and checks for an acceptable width. The image URL with the best
 width is returned.
 @param content The content string to search.
 @return The URL path for the image or an empty string.
 */
+ (NSString *)searchPostContentForImageToDisplay:(NSString *)content;

/**
 Find attachments ids in post content

 @param content The content string to search

 @return A set with all the attachment id that where found in galleries
 */
+ (NSSet *)searchPostContentForAttachmentIdsInGalleries:(NSString *)content;

@end
