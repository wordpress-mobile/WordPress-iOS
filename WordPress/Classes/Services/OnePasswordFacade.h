#import <Foundation/Foundation.h>

typedef void (^OnePasswordFacadeCallback)(NSString *username, NSString *password, NSError *);

@protocol OnePasswordFacade

- (void)findLoginForURLString:(NSString *)loginUrl viewController:(UIViewController *)viewController completion:(OnePasswordFacadeCallback)completion;
- (BOOL)isOnePasswordEnabled;

@end

@interface OnePasswordFacade : NSObject <OnePasswordFacade>

@end
