//
//  ReviewActivity.m
//
//  Copyright 2013 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

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
