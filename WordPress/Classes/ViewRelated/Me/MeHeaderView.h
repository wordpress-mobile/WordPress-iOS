#import <UIKit/UIKit.h>

typedef void (^MeHeaderViewCallback)(void);

@interface MeHeaderView : UIView

@property (nonatomic,   copy) NSString              *displayName;
@property (nonatomic,   copy) NSString              *username;
@property (nonatomic,   copy) NSString              *gravatarEmail;
@property (nonatomic,   copy) MeHeaderViewCallback  onGravatarPress;
@property (nonatomic, assign) BOOL                  showsActivityIndicator;

/// Overrides the current Gravatar Image (set via Email) with a given image reference.
/// Plus, AFNetworking's internal cache is updated, to prevent undesired glitches upon refresh.
///
- (void)overrideGravatarImage:(UIImage *)gravatarImage;

@end
