#import "CommentActivity.h"

@implementation CommentActivity

- (GTLPlusMoment *)getMoment {
  GTLPlusMoment *moment = [super getMoment];
  moment.result = [[GTLPlusItemScope alloc] init];
  moment.result.type = @"http://schema.org/Comment";
  moment.result.url = self.commentURL;
  moment.result.text = self.text;
  moment.result.name = self.name;
  return moment;
}

@end
