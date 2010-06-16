#import <Foundation/Foundation.h>

@protocol HTTPHelperDelegate

- (void) httpSuccessWithDataString: (NSString*) dataStr;
- (void) httpFailWithError: (NSError*) error;

@end