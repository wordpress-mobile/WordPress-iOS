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
