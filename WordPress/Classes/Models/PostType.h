#import <CoreData/CoreData.h>

@class Blog;

NS_ASSUME_NONNULL_BEGIN

@interface PostType : NSManagedObject

@property (nullable, nonatomic, retain) NSString *label;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *apiQueryable;
@property (nullable, nonatomic, retain) Blog *blog;

@end

NS_ASSUME_NONNULL_END
