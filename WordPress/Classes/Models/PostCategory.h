#import <CoreData/CoreData.h>
#import "Blog.h"
#import "WordPressAppDelegate.h"

extern const NSInteger PostCategoryUncategorized;

@interface PostCategory : NSManagedObject

@property (nonatomic, strong) NSNumber *categoryID;
@property (nonatomic, strong) NSString *categoryName;
@property (nonatomic, strong) NSNumber *parentID;
@property (nonatomic, strong) NSSet *posts;
@property (nonatomic, strong) Blog *blog;

@end

@class Post;

@interface PostCategory (CoreDataGeneratedAccessors)

- (void)addPostsObject:(Post *)value;
- (void)removePostsObject:(Post *)value;
- (void)addPosts:(NSSet *)values;
- (void)removePosts:(NSSet *)values;

@end