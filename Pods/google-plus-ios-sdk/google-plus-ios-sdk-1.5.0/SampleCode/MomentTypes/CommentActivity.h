#import "Activity.h"

@interface CommentActivity : Activity

@property(copy, nonatomic) NSString *commentURL;
@property(copy, nonatomic) NSString *text;
@property(copy, nonatomic) NSString *name;

@end
