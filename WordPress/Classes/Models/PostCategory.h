#import <CoreData/CoreData.h>
#import "Blog.h"
#import "WordPressAppDelegate.h"

@interface PostCategory : NSManagedObject

@property (nonatomic, strong) NSNumber *categoryID;
@property (nonatomic, strong) NSString *categoryName;
@property (nonatomic, strong) NSNumber *parentID;
@property (nonatomic, strong) NSMutableSet *posts;
@property (nonatomic, strong) Blog *blog;

@end
