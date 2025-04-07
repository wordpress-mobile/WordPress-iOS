#import "PostCategory.h"

NSString * const PostCategoryEntityName = @"Category";
NSString * const PostCategoryNameKey = @"categoryName";
const NSInteger PostCategoryUncategorized = 1;

@implementation PostCategory

@dynamic categoryID;
@dynamic categoryName;
@dynamic parentID;
@dynamic posts;
@dynamic blog;

+ (NSString *)entityName
{
    return @"Category";
}

@end
