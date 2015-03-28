#import <Foundation/Foundation.h>

typedef void (^OnePasswordServiceCallback)(NSString *username, NSString *password, NSError *);

@protocol OnePasswordService

- (void)findLoginForURLString:(NSString *)loginUrl viewController:(UIViewController *)viewController completion:(OnePasswordServiceCallback)completion;
- (BOOL)isOnePasswordEnabled;

@end

@interface OnePasswordService : NSObject <OnePasswordService>

@end
