#import <Foundation/Foundation.h>

/**
 *  @brief      This block type is used for animation completion calls.
 *
 *  @param      finished        YES means the animation was able to finish, NO means it was
 *                              interrupted, probably by the view being dismissed.
 */
typedef void(^WPWhatsNewAnimationCompleteBlock)(BOOL finished);

/**
 *  @brief      This block type is used for the dismissal of this view.
 */
typedef void(^WPWhatsNewDismissBlock)();

/**
 *  @class      WhatsNewView
 *  @brief      Shows the user what's new in WP iOS.
 */
@interface WPWhatsNewView : UIView

#pragma mark - Properties: Outlets

/**
 *  @brief      The details to show below the title.
 */
@property (nonatomic, weak, readonly) IBOutlet UITextView *details;

/**
 *  @brief      The details height constraint.
 *  @details    The outlet is useful for updating the height of the details text view.
 */
@property (nonatomic, weak, readonly) IBOutlet NSLayoutConstraint *detailsHeightConstraint;

/**
 *  @brief      The image to show on top of the view.
 */
@property (nonatomic, weak, readonly) IBOutlet UIImageView *imageView;

/**
 *  @title      The title for the new features.
 */
@property (nonatomic, weak, readonly) IBOutlet UITextView *title;

/**
 *  @brief      The accept button that dismissess the popup.
 */
@property (nonatomic, weak, readonly) IBOutlet UIButton *acceptButton;

#pragma mark - Properties: Blocks

/**
 *  @brief      This block will be called right before the popup is dismissed.  Can be nil.
 */
@property (nonatomic, copy, readwrite) WPWhatsNewDismissBlock willDismissBlock;

/**
 *  @brief      This block will be called after the popup is dismissed and removed from the
 *              superview.  Can be nil.
 */
@property (nonatomic, copy, readwrite) WPWhatsNewDismissBlock didDismissBlock;

#pragma mark - Showing & hiding

/**
 *  @brief      Hides the view.
 *
 *  @param      animated    YES means the transition will be animated.  NO means it will be
 *                          instantaneous.
 *  @param      completion  The block that will be executed after the view is hidden.  Can be nil.
 */
- (void)hideAnimated:(BOOL)animated
          completion:(WPWhatsNewAnimationCompleteBlock)completion;

/**
 *  @brief      Shows the view.
 *
 *  @param      animated    YES means the transition will be animated.  NO means it will be
 *                          instantaneous.
 *  @param      completion  The block that will be executed after the view is shown.  Can be nil.
 */
- (void)showAnimated:(BOOL)animated
          completion:(WPWhatsNewAnimationCompleteBlock)completion;

#pragma mark - IBActions

/**
 *  @brief      Action to dismiss the popup.
 *
 *  @param      sender      The outlet that called this action.
 */
- (IBAction)dismissPopup:(id)sender;

@end
