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
    //TODO: complete this
    /*
     if (![self noBlogsAndNoWordPressDotComAccount]) {
     
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
     UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Title"
     message:@"Message"
     preferredStyle:UIAlertControllerStyleAlert];
     
     [alertController addAction:[UIAlertAction actionWithTitle:@"Great, thanks!" style:UIActionSheetStyleAutomatic handler:^(UIAlertAction *action) {
     [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
     }]];
     
     [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
     });
     }*/

    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSAssert(versionString,
             @"We expect the version number to be set.");
    
    NSString *whatsNewDetails = [self detailsForAppVersion:versionString];
    NSString *whatsNewTitle = [self titleForAppVersion:versionString];
    
    BOOL appHasWhatsNewInfo = [whatsNewTitle length] > 0 && [whatsNewDetails length] > 0;
    
    // TEMPORARY: remove before final commit...
    if (!appHasWhatsNewInfo) {
        whatsNewTitle = @"Share your story.";
        whatsNewDetails = @"Share your story.";
        appHasWhatsNewInfo = YES;
    }
    
    if (appHasWhatsNewInfo) {
        
        UIImage* image = [UIImage imageNamed:@"attachment"];
        
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
    
    whatsNewView.title.text = title;
    whatsNewView.details.text = details;
    whatsNewView.imageView.image = image;
    
    whatsNewView.center = dimmerView.center;

    whatsNewView.willDismissBlock = ^void() {
        [dimmerView hideAnimated:YES completion:nil];
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
    
    NSString *key = [NSString stringWithFormat:@"v%@-whats-new-inapp-details", appVersion];
    
    NSString *details = NSLocalizedString(key,
                                          @"The details for the \"What's New\" dailog");
    
    // IMPORTANT: this sounds hackish, but it's actually the best way to check if a translation
    // wasn't found, as NSLocalizedString(...) does not return nil (it returns the key you used).
    //
    BOOL stringNotFound = (key == details);
    
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
    
    NSString *key = [NSString stringWithFormat:@"v%@-whats-new-inapp-title", appVersion];
    NSString *title = NSLocalizedString(key,
                                        @"The title for the \"What's New\" dailog");
    
    // IMPORTANT: this sounds hackish, but it's actually the best way to check if a translation
    // wasn't found, as NSLocalizedString(...) does not return nil (it returns the key you used).
    //
    BOOL stringNotFound = (key == title);
    
    if (stringNotFound) {
        title = nil;
    }
    
    return title;
}

@end
