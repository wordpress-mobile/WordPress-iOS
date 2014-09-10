//
//  ShareActivity.m
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

#import "ShareActivity.h"

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>

@interface ShareActivity ()

// The prefilled GPPShareBuilder object.
@property(nonatomic, strong) id<GPPShareBuilder> builder;

@end

@implementation ShareActivity

- (NSString *)activityType {
  return @"googleplus.share";
}

- (NSString *)activityTitle {
  return @"Google+";
}

- (UIImage *)activityImage {
  return [UIImage imageNamed:@"ShareSheetMask"];
}

// In the minimum case, we can still present an empty share box.
- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
  return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
  for (NSObject *item in activityItems) {
    if ([item conformsToProtocol:@protocol(GPPShareBuilder)]) {
      self.builder = (id<GPPShareBuilder>)item;
    }
  }
}

- (void)performActivity {
  [self activityDidFinish:YES];
  if (![self.builder open]) {
    GTMLoggerError(@"Status: Error (see console).");
  }
}

@end
