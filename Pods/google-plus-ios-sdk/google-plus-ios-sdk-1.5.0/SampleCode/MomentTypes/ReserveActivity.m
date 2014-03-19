#import "ReserveActivity.h"

@implementation ReserveActivity

- (GTLPlusMoment *)getMoment {
  GTLPlusMoment *moment = [super getMoment];
  moment.result = [[GTLPlusItemScope alloc] init];
  moment.result.type = @"http://schemas.google.com/Reservation";
  moment.result.startDate = self.startDate;
  moment.result.attendeeCount = self.attendeeCount;
  return moment;
}

@end
