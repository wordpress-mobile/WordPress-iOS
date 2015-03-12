#import <Foundation/Foundation.h>

@protocol LoginViewModelDelegate;
@class RACSignal;
@interface LoginViewModel : NSObject

@property (nonatomic, assign) BOOL authenticating;
@property (nonatomic, assign) BOOL shouldDisplayMultifactor;

@property (nonatomic, assign) id<LoginViewModelDelegate> delegate;

@end

@protocol LoginViewModelDelegate

- (void)showActivityIndicator:(BOOL)show;
- (void)setUsernameAlpha:(CGFloat)alpha;

@end
