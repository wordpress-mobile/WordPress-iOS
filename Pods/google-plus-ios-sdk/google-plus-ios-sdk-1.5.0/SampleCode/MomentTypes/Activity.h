#import <GoogleOpenSource/GoogleOpenSource.h>

// This class is meant to be abstract.
@interface Activity : NSObject

@property(copy, nonatomic) NSString *url;

- (GTLPlusMoment *)getMoment;

@end
