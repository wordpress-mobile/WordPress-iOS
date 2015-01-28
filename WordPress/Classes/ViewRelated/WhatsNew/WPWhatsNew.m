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

- (void)show
{
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSAssert(versionString,
             @"We expect the version number to be set.");
    
    NSString *whatsNewDetails = [self detailsForAppVersion:versionString];
    NSString *whatsNewTitle = [self titleForAppVersion:versionString];
    
    BOOL appHasWhatsNewInfo = [whatsNewTitle length] > 0 && [whatsNewDetails length] > 0;
    
    if (appHasWhatsNewInfo) {
        
        UIImage* image = [UIImage imageNamed:@"icon-tab-newpost"];
        
        [self showWithTitle:whatsNewTitle details:whatsNewDetails image:image];
    }
}

/**
 *  @brief      Shows the What's New popup with the specified title, details and image.
 *  @details    Should not be called directly in most cases.  Use method "show" instead.
 *
 *  @param      title       The title to display.  Cannot be nil or zero length.
 *  @param      details     The details to display.  Cannot be nil or zero length.
 *  @param      image       The image to show.  Cannot be nil.
 */
- (void)showWithTitle:(NSString*)title
              details:(NSString*)details
                image:(UIImage*)image
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
    
    UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];
    NSAssert([keyWindow isKindOfClass:[UIWindow class]],
             @"We're expecting the application window to exist when this method is called.");
    
    [keyWindow addSubview:dimmerView];
    [dimmerView addSubview:whatsNewView];
    
    [self configureConstraintsBetweenKeyWindow:keyWindow
                                 andDimmerView:dimmerView];
    
    [self configureConstraintsBetweenDimmerView:dimmerView
                                andWhatsNewView:whatsNewView];
    
    whatsNewView.center = dimmerView.center;
    
    whatsNewView.title.text = title;
    whatsNewView.details.text = details;
    whatsNewView.imageView.image = image;

    whatsNewView.willDismissBlock = ^void() {
        [dimmerView hideAnimated:YES completion:^(BOOL finished) {
            [dimmerView removeFromSuperview];
        }];
    };
    
    [dimmerView showAnimated:YES completion:nil];
    [whatsNewView showAnimated:YES completion:nil];
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
                                                          @"This version of the WordPress app includes a beautiful new visual editor. Try it out by creating a new post.",
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

- (void)configureConstraintsBetweenKeyWindow:(UIWindow*)keyWindow
                               andDimmerView:(WPBackgroundDimmerView*)dimmerView
{
    NSParameterAssert([keyWindow isKindOfClass:[UIWindow class]]);
    NSParameterAssert([dimmerView isKindOfClass:[WPBackgroundDimmerView class]]);
    NSAssert([keyWindow.subviews containsObject:dimmerView],
             @"The key window should already contain the dimmer view at this point.");
    
    [dimmerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSLayoutConstraint* dimmerLeft = [NSLayoutConstraint constraintWithItem:keyWindow
                                                                  attribute:NSLayoutAttributeLeft
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:dimmerView
                                                                  attribute:NSLayoutAttributeLeft
                                                                 multiplier:1.0f
                                                                   constant:0.0f];
    
    NSLayoutConstraint* dimmerRight = [NSLayoutConstraint constraintWithItem:keyWindow
                                                                   attribute:NSLayoutAttributeRight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:dimmerView
                                                                   attribute:NSLayoutAttributeRight
                                                                  multiplier:1.0f
                                                                    constant:0.0f];
    
    NSLayoutConstraint* dimmerTop = [NSLayoutConstraint constraintWithItem:keyWindow
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:dimmerView
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1.0f
                                                                  constant:0.0f];
    
    NSLayoutConstraint* dimmerBottom = [NSLayoutConstraint constraintWithItem:keyWindow
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:dimmerView
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0f
                                                                     constant:0.0f];

    [keyWindow addConstraints:@[dimmerLeft, dimmerRight, dimmerTop, dimmerBottom]];
}

@end
