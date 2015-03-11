#import "WPWhatsNew.h"
#import "WPBackgroundDimmerView.h"
#import "WPWhatsNewView.h"

@implementation WPWhatsNew

#pragma mark - Loading resources

- (WPWhatsNewView*)loadWhatsNewViewFromNib
{
    NSArray* views = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([WPWhatsNewView class])
                                                   owner:nil
                                                 options:nil];
    NSAssert([views count] > 0,
             @"We expect to have at least one view in the nib we loaded.");
    
    WPWhatsNewView* whatsNewView = views[0];
    NSAssert([whatsNewView isKindOfClass:[WPWhatsNewView class]],
             @"We expect the whatsNewView to be of class WPWhatsNewView.");
    
    return whatsNewView;
}

#pragma mark - Showing

- (void)showWithDismissBlock:(WPWhatsNewDismissBlock)dismissBlock
{
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSAssert(versionString,
             @"We expect the version number to be set.");
    
    NSString *whatsNewDetails = [self detailsForAppVersion:versionString];
    NSString *whatsNewTitle = [self titleForAppVersion:versionString];
    
    BOOL appHasWhatsNewInfo = [whatsNewTitle length] > 0 && [whatsNewDetails length] > 0;
    
    if (appHasWhatsNewInfo) {
        
        UIImage* image = [UIImage imageNamed:@"icon-whats-new"];
        
        [self showWithTitle:whatsNewTitle
                    details:whatsNewDetails
                      image:image
               dismissBlock:dismissBlock];
    }
}

/**
 *  @brief      Shows the What's New popup with the specified title, details and image.
 *  @details    Should not be called directly in most cases.  Use method "show" instead.
 *
 *  @param      title           The title to display.  Cannot be nil or zero length.
 *  @param      details         The details to display.  Cannot be nil or zero length.
 *  @param      image           The image to show.  Cannot be nil.
 *  @param      dismissBlock    The dismiss block for the whats new view.  Can be nil.
 */
- (void)showWithTitle:(NSString*)title
              details:(NSString*)details
                image:(UIImage*)image
         dismissBlock:(WPWhatsNewDismissBlock)dismissBlock
{
    NSParameterAssert([title isKindOfClass:[NSString class]]);
    NSParameterAssert([title length] > 0);
    NSParameterAssert([details isKindOfClass:[NSString class]]);
    NSParameterAssert([details length] > 0);
    NSParameterAssert([image isKindOfClass:[UIImage class]]);
    
    // IMPORTANT: since loading the nib can take some time, we do it before the animations
    // start.  This will help us ensure the animations will flow and not have weird delays
    // while they're executing.
    //
    WPWhatsNewView* whatsNewView = [self loadWhatsNewViewFromNib];
    
    WPBackgroundDimmerView* dimmerView = [[WPBackgroundDimmerView alloc] init];
    
    UIView *keyView = [self keyView];
    
    [keyView.superview endEditing:YES];
    
    [keyView addSubview:dimmerView];
    [dimmerView addSubview:whatsNewView];
    
    [self configureConstraintsBetweenKeyView:keyView
                               andDimmerView:dimmerView];
    
    [self configureConstraintsBetweenDimmerView:dimmerView
                                andWhatsNewView:whatsNewView];
    
    whatsNewView.center = dimmerView.center;
    
    // WORKAROUND: if we set the text of these while selectable == NO, then the font and formatting
    // options are lost under iOS 7 (not sure about 8).
    //
    whatsNewView.title.selectable = YES;
    whatsNewView.details.selectable = YES;
    
    whatsNewView.title.text = title;
    whatsNewView.details.text = details;
    whatsNewView.imageView.image = image;
    
    // WORKAROUND: if we set the text of these while selectable == NO, then the font and formatting
    // options are lost under iOS 7 (not sure about 8).
    //
    whatsNewView.title.selectable = NO;
    whatsNewView.details.selectable = NO;

    whatsNewView.willDismissBlock = ^void() {
        [dimmerView hideAnimated:YES completion:^(BOOL finished) {
            [dimmerView removeFromSuperview];
        }];
    };
    
    whatsNewView.didDismissBlock = dismissBlock;
    
    [dimmerView showAnimated:YES completion:nil];
    [whatsNewView showAnimated:YES completion:nil];
}

#pragma mark - Key View

/**
 *  @brief      Gets the key view.
 *  @details    The key view is the view the what's new dialog should be added to.  It's the first
 *              subview of the key window.
 *
 *  @returns    The key view.
 */
- (UIView*)keyView
{
    UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];
    NSAssert([keyWindow isKindOfClass:[UIWindow class]],
             @"We're expecting the application window to exist when this method is called.");
    
    NSAssert([keyWindow.subviews count] > 0,
             @"We should only call this method when there's something on-screen.");
    UIView* keyView = [keyWindow.subviews objectAtIndex:0];
    NSAssert([keyView isKindOfClass:[UIView class]],
             @"We're expecting to have a keyView at this point.");
    
    return keyView;
}


#pragma mark - Localizable data

/**
 *  @brief      Call this method to retrieve the What's-New details for the specified app version.
 *
 *  @param      appVersion      The app version number.  Cannot be nil.
 *
 *  @returns    The requested details.  Make sure not to show any GUI elements if this is nil or
 *              empty.
 */
- (NSString*)detailsForAppVersion:(NSString*)appVersion
{
    NSParameterAssert([appVersion isKindOfClass:[NSString class]]);
    NSParameterAssert([appVersion length] > 0);
    
    // IMPORTANT: enable the following line if you don't want to show any what's new dialog in the
    // upcoming version of the app.
    //
    // return nil;
    
    // IMPORTANT: since we don't have a default EN(US) translation, but instead rely on the default
    // values for that, we'll have to modify the default value below, whenever the details need
    // to change for a version of the app.
    //
    // Really ugly, but there's no easy way around this at this time.
    //
    NSString *details = NSLocalizedStringWithDefaultValue(@"whats-new-inapp-details",
                                                          nil,
                                                          [NSBundle mainBundle],
                                                          @"The WordPress app for iOS now includes a beautiful new visual editor. Try it out by creating a new post.",
                                                          @"The details for the \"What's New\" dialog");
    
    // IMPORTANT: this sounds hackish, but it's actually the best way to check if a translation
    // wasn't found, as NS-LocalizedString (slash added to avoid breaking localize.py) does not
    // return nil (it returns the key you used).
    //
    BOOL stringNotFound = [details isEqualToString:@"whats-new-inapp-details"];
    
    if (stringNotFound) {
        details = nil;
    }
    
    return details;
}

/**
 *  @brief      Call this method to retrieve the What's-New details for the specified app version.
 *
 *  @param      appVersion      The app version number.  Cannot be nil.
 *
 *  @returns    The requested title.  Make sure not to show any GUI elements if this is nil or
 *              empty.
 */
- (NSString*)titleForAppVersion:(NSString*)appVersion
{
    NSParameterAssert([appVersion isKindOfClass:[NSString class]]);
    NSParameterAssert([appVersion length] > 0);
    
    // IMPORTANT: enable the following line if you don't want to show any what's new dialog in the
    // upcoming version of the app.
    //
    // return nil;
    
    // IMPORTANT: since we don't have a default EN(US) translation, but instead rely on the default
    // values for that, we'll have to modify the default value below, whenever the details need
    // to change for a version of the app.
    //
    // Really ugly, but there's no easy way around this at this time.
    //
    NSString *title = NSLocalizedStringWithDefaultValue(@"whats-new-inapp-title",
                                                        nil,
                                                        [NSBundle mainBundle],
                                                        @"Brand new editor",
                                                        @"The title for the \"What's New\" dialog");
    
    // IMPORTANT: this sounds hackish, but it's actually the best way to check if a translation
    // wasn't found, as NS-LocalizedString (slash added to avoid breaking localize.py) does not
    // return nil (it returns the key you used).
    //
    BOOL stringNotFound = [title isEqualToString:@"whats-new-inapp-title"];
    
    if (stringNotFound) {
        title = nil;
    }
    
    return title;
}

#pragma mark - Constraints

- (void)configureConstraintsBetweenDimmerView:(WPBackgroundDimmerView*)dimmerView
                              andWhatsNewView:(WPWhatsNewView*)whatsNewView
{
    NSParameterAssert([dimmerView isKindOfClass:[WPBackgroundDimmerView class]]);
    NSParameterAssert([whatsNewView isKindOfClass:[WPWhatsNewView class]]);
    NSAssert([dimmerView.subviews containsObject:whatsNewView],
             @"The whatsNew view should already be a child of dimmerView here.");
    
    NSLayoutConstraint* xAlignment = [NSLayoutConstraint constraintWithItem:dimmerView
                                                                  attribute:NSLayoutAttributeCenterX
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:whatsNewView
                                                                  attribute:NSLayoutAttributeCenterX
                                                                 multiplier:1.0f
                                                                   constant:0.0f];
    
    NSLayoutConstraint* yAlignment = [NSLayoutConstraint constraintWithItem:dimmerView
                                                                  attribute:NSLayoutAttributeCenterY
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:whatsNewView
                                                                  attribute:NSLayoutAttributeCenterY
                                                                 multiplier:1.0f
                                                                   constant:0.0f];
    
    [dimmerView addConstraints:@[xAlignment, yAlignment]];
}

- (void)configureConstraintsBetweenKeyView:(UIView*)keyView
                             andDimmerView:(WPBackgroundDimmerView*)dimmerView
{
    NSParameterAssert([keyView isKindOfClass:[UIView class]]);
    NSParameterAssert([dimmerView isKindOfClass:[WPBackgroundDimmerView class]]);
    NSAssert([keyView.subviews containsObject:dimmerView],
             @"The key window should already contain the dimmer view at this point.");
    
    [dimmerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSLayoutConstraint* dimmerLeft = [NSLayoutConstraint constraintWithItem:keyView
                                                                  attribute:NSLayoutAttributeLeft
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:dimmerView
                                                                  attribute:NSLayoutAttributeLeft
                                                                 multiplier:1.0f
                                                                   constant:0.0f];
    
    NSLayoutConstraint* dimmerRight = [NSLayoutConstraint constraintWithItem:keyView
                                                                   attribute:NSLayoutAttributeRight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:dimmerView
                                                                   attribute:NSLayoutAttributeRight
                                                                  multiplier:1.0f
                                                                    constant:0.0f];
    
    NSLayoutConstraint* dimmerTop = [NSLayoutConstraint constraintWithItem:keyView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:dimmerView
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1.0f
                                                                  constant:0.0f];
    
    NSLayoutConstraint* dimmerBottom = [NSLayoutConstraint constraintWithItem:keyView
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:dimmerView
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0f
                                                                     constant:0.0f];

    [keyView addConstraints:@[dimmerLeft, dimmerRight, dimmerTop, dimmerBottom]];
}

@end
