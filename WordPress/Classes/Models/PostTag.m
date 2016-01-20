#import "PostTag.h"

@implementation PostTag

@dynamic tagID;
@dynamic name;
@dynamic slug;
@dynamic blog;

+ (NSString *)entityName
{
    return @"PostTag";
}

@end
