#import <UIKit/UIKit.h>

@interface MeHeaderView : UIView

@property (nonatomic, nullable, copy) NSString *displayName;
@property (nonatomic, nonnull, copy) NSString *username;
@property (nonatomic, nullable, copy) NSString *gravatarEmail;

/// Overrides the current Gravatar Image (set via Email) with a given image reference.
///
- (void)overrideGravatarImage:(UIImage * _Nonnull)gravatarImage;

@end
