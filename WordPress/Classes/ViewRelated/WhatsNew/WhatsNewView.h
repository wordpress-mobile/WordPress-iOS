#import <Foundation/Foundation.h>

/**
 *  @class      WhatsNewView
 *  @brief      Shows the user what's new in WP iOS.
 */
@interface WhatsNewView : UIView

#pragma mark - Properties: on screen

/**
 *  @brief      The details to show below the title.
 */
@property (nonatomic, copy, readonly) NSString* details;

/**
 *  @brief      The image to show on top of the view.
 */
@property (nonatomic, copy, readonly) UIImage* image;

/**
 *  @title      The title for the new features.
 */
@property (nonatomic, copy, readonly) NSString* title;

#pragma mark - Initialization

/**
 *  @brief      Initializes the view with the given parameters.
 *
 *  @param      frame       The frame for the view.
 *  @param      image       The image to show on top of the view.  Cannot be nil.
 *  @param      title       The title to show below the image.  Cannot be nil.
 *  @param      details     The details to show below the title, explaining the new features.
 *                          Cannot be nil.
 *
 *  @returns    The initialized object.
 */
- (instancetype)initWithFrame:(CGRect)frame
                        image:(UIImage*)image
                        title:(NSString*)title
                      details:(NSString*)details;

@end
