#import <UIKit/UIKit.h>
#import "WPContentViewProvider.h"
#import "WordPress-Swift.h"

extern const CGFloat WPContentAttributionViewAvatarSize;

@class WPContentAttributionView;

/**
 The delegate of the`WPContentAttributionView` should adopt the `WPContentAttributionViewDelegate` protocol.
 Protocol methods allow the delegate to respond to user interactions.
 */
@protocol WPContentAttributionViewDelegate <NSObject>
@optional

/**
 Tells the delegate the user has tapped the attribution avatar.
 */
- (void)attributionViewDidReceiveAvatarAction:(WPContentAttributionView *)attributionView;

/**
 Tells the delegate the user has tapped the attribution button.
 */
- (void)attributionView:(WPContentAttributionView *)attributionView didReceiveAttributionLinkAction:(id)sender;

/**
 Tells the delegate the user has tapped the attribution menu.
 */
- (void)attributionView:(WPContentAttributionView *)attributionView didReceiveAttributionMenuAction:(id)sender;

@end


/**
 An object, consuming a `WPContentViewProvider`, and displaying:
 - Authorship or attribution
 - An UIImageView for an avatar
 - A label showing the name of the entity being attributed
 - A button linking to the URL specified in the content provider
 */
@interface WPContentAttributionView : UIView

/**
 The object specifying the content (text, images, etc.) to display.
 */
@property (nonatomic, weak) id<WPContentViewProvider>contentProvider;

/**
 The object that acts as the delegate of the receiving attribution view.
 */
@property (nonatomic, weak) id<WPContentAttributionViewDelegate>delegate;

/**
 Set's the image to display as the avatar.
 
 @param image A UIImage with a width and height equal to `WPContentAttributionViewAvatarSize`
 */
- (void)setAvatarImage:(UIImage *)image;

/**
 Shows or hides the attribution button.
 
 @param hide A Boolean value indicating whether the button should be hidden.
 */
- (void)hideAttributionButton:(BOOL)hide;

/**
 Selects or deselects the attribution button
 @param select A Boolean value indicating whether the button should be selected.
 */
- (void)selectAttributionButton:(BOOL)select;

/**
 Shows or hides the attribution menu.

 @param hide A Boolean value indicating whether the menu should be hidden.
 */
- (void)hideAttributionMenu:(BOOL)hide;


#pragma mark - Private Subclass Members and Methods

// Subviews
@property (nonatomic, strong) CircularImageView *avatarImageView;
@property (nonatomic, strong) UILabel *attributionNameLabel;
@property (nonatomic, strong) UIButton *attributionLinkButton;
@property (nonatomic, strong) UIButton *attributionMenuButton;
@property (nonatomic, strong) UIView *borderView;

// Configuration
- (void)configureAttributionButton;

@end
