#import <CoreData/CoreData.h>
#import "Blog.h"

@interface PostStatus : NSManagedObject

@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * isProtected;
@property (nonatomic, retain) NSNumber * isPrivate;
@property (nonatomic, retain) NSNumber * isPublic;
@property (nonatomic, retain) Blog *blog;

@end
