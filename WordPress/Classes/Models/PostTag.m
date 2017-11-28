#import "PostTag.h"

@implementation PostTag

@dynamic tagID;
@dynamic name;
@dynamic slug;
@dynamic tagDescription;
@dynamic postCount;
@dynamic blog;

+ (NSString *)entityName
{
    return @"PostTag";
}

@end
