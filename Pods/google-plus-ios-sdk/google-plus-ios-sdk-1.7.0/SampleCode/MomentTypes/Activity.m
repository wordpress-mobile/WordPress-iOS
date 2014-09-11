//
//  Activity.m
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
