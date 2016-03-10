#import <CoreData/CoreData.h>

@class Blog;

@interface PostType : NSManagedObject

@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *apiQueryable;
@property (nonatomic, strong) Blog *blog;

@end

