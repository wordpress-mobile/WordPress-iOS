#import <UIKit/UIKit.h>

typedef void (^MeHeaderViewCallback)(void);
typedef void (^MeHeaderViewDropCallback)(UIImage * _Nonnull image);

@interface MeHeaderView : UIView

@property (nonatomic, nullable, copy) NSString *displayName;
@property (nonatomic, nonnull, copy) NSString *username;
@property (nonatomic, nullable, copy) NSString *gravatarEmail;
@property (nonatomic, nullable, copy) MeHeaderViewCallback onGravatarPress;
@property (nonatomic, nullable, copy) MeHeaderViewDropCallback onDroppedImage;
@property (nonatomic, assign) BOOL showsActivityIndicator;

/// Overrides the current Gravatar Image (set via Email) with a given image reference.
///
- (void)overrideGravatarImage:(UIImage * _Nonnull)gravatarImage;

@end
