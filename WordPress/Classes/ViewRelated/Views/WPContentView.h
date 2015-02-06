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

@class WPContentView;

/**
 The delegate of the`WPContentView` should adopt the `WPContentViewDelegate` protocol.
 Protocol methods allow the delegate to respond to user interactions.
 */
@protocol WPContentViewDelegate <NSObject>
@optional

/**
 Tells the delegate the user has tapped on the attribution avatar.
 */
- (void)contentViewDidReceiveAvatarAction:(UIView *)contentView;

/**
 Tells the delegate the user has tapped on the featured image.
 
 @param contentView The content view informing the delegate of the event.
 @param sender A reference to the receiving `UIControl`, in this case a UIImageView.
 */
- (void)contentView:(UIView *)contentView didReceiveFeaturedImageAction:(id)sender;

/**
 Tells the delegate the user has tapped on the button in the content view's attribution view.

 @param contentView The content view informing the delegate of the event.
 @param sender A reference to the receiving `UIControl`.
 */
- (void)contentView:(UIView *)contentView didReceiveAttributionLinkAction:(id)sender;

/**
 Tells the delegate the user has tapped on the menu button in the content view's attribution view.

 @param contentView The content view informing the delegate of the event.
 @param sender A reference to the receiving `UIControl`.
 */
- (void)contentView:(UIView *)contentView didReceiveAttributionMenuAction:(id)sender;

@end


/**
 An object, consuming a `WPContentViewProvider`, and displaying:
    - Authorship or attribution
    - An optional featured image
    - A title
    - A small block of plain text
    - A short date.
 */
@interface WPContentView : UIView

/**
 The object that acts as the delegate of the receiving content view.
 */
@property (nonatomic, weak) id<WPContentViewDelegate> delegate;

/**
The object specifying the content (text, images, etc.) to display.
 */
@property (nonatomic, weak) id<WPContentViewProvider> contentProvider;

/**
 A Boolean value specifying whether a featured image should be hidden, even if 
 the content provider specifies one.
 */
@property (nonatomic, assign) BOOL alwaysHidesFeaturedImage;

/**
 An array of 'action' buttons to display in the internal `WPContentActionView`
 */
@property (nonatomic, strong) NSArray *actionButtons;

/**
 Resets the content view's appearance.
 */
- (void)reset;

/**
 Set's the image to display as the content view's featured image. This should be
 the image specified by the content provider.
 */
- (void)setFeaturedImage:(UIImage *)image;

/**
 Set's the image to display as the content view's attribution view's avatar.
 */
- (void)setAvatarImage:(UIImage *)image;

/**
 A Boolean value that determines whether the content displayed belongs to a private blog.
 */
- (BOOL)privateContent;


#pragma mark - Private Subclass Members and Methods

/* Subviews */
@property (nonatomic, strong) WPContentAttributionView *attributionView;
@property (nonatomic, strong) UIImageView *featuredImageView;
@property (nonatomic, strong) UIView *attributionBorderView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) WPContentActionView *actionView;

/* Factory methos for subviews */
- (void)buildAttributionView;
- (void)buildAttributionBorderView;
- (void)buildFeaturedImageview;
- (void)buildTitleLabel;
- (void)buildContentView;
- (void)buildActionView;

/**
 Configures the appearance of the attribution view based on the content provider.
 */
- (void)configureAttributionView;

/**
 Configures the appearance of the action view based on the content provider.
 */
- (void)configureActionView;

/**
 Create a new button with the specified image for use with the internal action bar.

 @param buttonImage The image for the button's normal state.
 @param selectedButtonImage The image for the button's selected state.
 @return The newly created button.
 */
- (UIButton *)createActionButtonWithImage:(UIImage *)buttonImage selectedImage:(UIImage *)selectedButtonImage;

/**
 Manually refresh the appearance of the buttons in the action bar. Useful if a
 button's title should be updated, or selection state should change.
 */
- (void)updateActionButtons;

/**
 Specifies the width for the `contentView`'s margin. The default margin is
 `WPContentViewHorizontalInnerPadding`.  Subclasses may override to specify a margin
 best suited to its `contentView`.
 @return The width for the margin.
 */
- (CGFloat)horizontalMarginForContent;

/**
 Specifies a `CGSize` that the `contentView`'s content will fit inside for the 
 specified size. By default this returns the value of `sizeThatFits:` on the 
 `contentView` but subclasses may override to call `intrinsicSize` for example.
 */
- (CGSize)sizeThatFitsContent:(CGSize)size;

/**
 Sets up the autolayout constraints for subviews.
 */
- (void)configureConstraints;

@end
