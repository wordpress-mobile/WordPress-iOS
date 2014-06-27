#import <UIKit/UIKit.h>
#import "WPContentViewProvider.h"

#import "WPContentAttributionView.h"
#import "WPContentActionView.h"

extern const CGFloat WPContentViewHorizontalInnerPadding;
extern const CGFloat WPContentViewOuterMargin;
extern const CGFloat WPContentViewAttributionVerticalPadding;
extern const CGFloat WPContentViewVerticalPadding;
extern const CGFloat WPContentViewTitleContentPadding;
extern const CGFloat WPContentViewMaxImageHeightPercentage;
extern const CGFloat WPContentViewAuthorAvatarSize;
extern const CGFloat WPContentViewAuthorViewHeight;
extern const CGFloat WPContentViewActionViewHeight;
extern const CGFloat WPContentViewBorderHeight;
extern const CGFloat WPContentViewLineHeightMultiple;

// Control buttons (Like, Reblog, ...)


@class WPContentViewBase;

@protocol WPContentViewBaseDelegate <NSObject>

@optional

/**
 
 */
- (void)contentView:(UIView *)contentView didReceiveFeaturedImageAction:(id)sender;

/**

 */
- (void)contentView:(UIView *)contentView didReceiveAttributionLinkAction:(id)sender;

@end




@interface WPContentViewBase : UIView

@property (nonatomic, strong) WPContentAttributionView *attributionView;
@property (nonatomic, strong) UIImageView *featuredImageView;
@property (nonatomic, strong) UIView *attributionBorderView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) WPContentActionView *actionView;

/**

 */
@property (nonatomic, weak) id<WPContentViewBaseDelegate> delegate;

/**

 */
@property (nonatomic, weak) id<WPContentViewProvider> contentProvider;


- (void)configureView;
- (void)configureAttributionView;
- (CGSize)sizeThatFitsContent:(CGSize)size;

/**

 */
// TODO: Should this be moved to the Action view?
- (UIButton *)addActionButtonWithImage:(UIImage *)buttonImage selectedImage:(UIImage *)selectedButtonImage;

/**

 */
- (void)updateActionButtons;

/**

 */
- (void)reset;

/**
 
 */
- (void)setFeaturedImage:(UIImage *)image;

/**
 
 */
- (void)setAvatarImage:(UIImage *)image;

/**
 
 */
- (BOOL)privateContent;

@end
