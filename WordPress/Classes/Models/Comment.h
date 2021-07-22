#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Blog;
@class BasePost;


@interface Comment: NSManagedObject

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) BasePost *post;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *author_email;
@property (nonatomic, strong) NSString *author_ip;
@property (nonatomic, strong) NSString *author_url;
@property (nonatomic, strong) NSString *authorAvatarURL;
@property (nonatomic, strong) NSNumber *commentID;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSDate *dateCreated;
@property (nonatomic, strong) NSNumber *depth;
// Hierarchy is a string representation of a comments ancestors. Each ancestor's
// is denoted by a ten character zero padded representation of its ID
// (e.g. "0000000001"). Ancestors are separated by a period.
// This allows hierarchical comments to be retrieved from core data by sorting
// on hierarchy, and allows for new comments to be inserted without needing to
// reorder the list. 
@property (nonatomic, strong) NSString *hierarchy;
@property (nonatomic, strong) NSString *link;
@property (nonatomic, strong) NSNumber *parentID;
@property (nonatomic, strong) NSNumber *postID;
@property (nonatomic, strong) NSString *postTitle;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSNumber *likeCount;
@property (nonatomic, strong) NSAttributedString *attributedContent;
@property (nonatomic) BOOL isLiked;
@property (nonatomic, assign) BOOL isNew;
@property (nonatomic) BOOL canModerate;

/// Helper methods
///
+ (NSString *)titleForStatus:(NSString *)status;
- (NSString *)authorUrlForDisplay;
- (BOOL)hasAuthorUrl;
- (BOOL)isApproved;
- (NSString *)sectionIdentifier;
- (BOOL)isReadOnly;
- (BOOL)authorIsPostAuthor;
- (NSNumber *)numberOfLikes;

@end
