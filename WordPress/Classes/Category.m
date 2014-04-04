#import "Category.h"
#import "ContextManager.h"

@interface Category(PrivateMethods)
+ (Category *)newCategoryForBlog:(Blog *)blog;
@end

@implementation Category
@dynamic categoryID, categoryName, parentID, posts;
@dynamic blog;


@end
