#import <CoreData/CoreData.h>

@class Blog;

NS_ASSUME_NONNULL_BEGIN

@interface PostTag : NSManagedObject

@property (nullable, nonatomic, retain) NSNumber *tagID;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *slug;
@property (nullable, nonatomic, retain) Blog *blog;

+ (NSString *)entityName;

@end

NS_ASSUME_NONNULL_END
