#import "ReviewActivity.h"

@implementation ReviewActivity

- (GTLPlusMoment *)getMoment {
  GTLPlusMoment *moment = [super getMoment];
  moment.result = [[GTLPlusItemScope alloc] init];
  moment.result.type = @"http://schema.org/Review";
  moment.result.url = self.reviewURL;
  moment.result.text = self.text;
  moment.result.name = self.name;

  if (self.ratingValue || self.bestRating || self.worstRating) {
    GTLPlusItemScope *rating = [[GTLPlusItemScope alloc] init];
    rating.type = @"http://schema.org/Rating";
    rating.ratingValue = self.ratingValue;
    rating.bestRating = self.bestRating;
    rating.worstRating = self.worstRating;
    moment.result.reviewRating = rating;
  }

  return moment;
}

@end
