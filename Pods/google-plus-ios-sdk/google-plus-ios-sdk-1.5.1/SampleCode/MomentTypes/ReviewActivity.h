#import "Activity.h"

@interface ReviewActivity : Activity

@property(copy, nonatomic) NSString *reviewURL;
@property(copy, nonatomic) NSString *text;
@property(copy, nonatomic) NSString *name;
@property(copy, nonatomic) NSString *ratingValue;
@property(copy, nonatomic) NSString *bestRating;
@property(copy, nonatomic) NSString *worstRating;

@end
