#import "Activity.h"

@implementation Activity

- (GTLPlusMoment *)getMoment {
  GTLPlusItemScope *target = [[GTLPlusItemScope alloc] init];
  target.url = _url;

  GTLPlusMoment *moment = [[GTLPlusMoment alloc] init];
  moment.type = [[self class]
                    momentTypeForActivity:NSStringFromClass([self class])];

  moment.target = target;
  return moment;
}

+ (NSString *)momentTypeForActivity:(NSString *)activity {
  return [NSString stringWithFormat:@"http://schemas.google.com/%@", activity];
}

@end
