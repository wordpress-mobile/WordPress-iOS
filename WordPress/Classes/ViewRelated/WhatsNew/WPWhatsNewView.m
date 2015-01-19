#import "WPWhatsNewView.h"
#import <QuartzCore/QuartzCore.h>

@interface WPWhatsNewView ()
#pragma mark - Properties: Outlets

/**
 *  @brief      The details to show below the title.
 */
@property (nonatomic, copy, readwrite) IBOutlet UITextView* details;

/**
 *  @brief      The image to show on top of the view.
 */
@property (nonatomic, copy, readwrite) IBOutlet UIImageView* image;

/**
 *  @title      The title for the new features.
 */
@property (nonatomic, copy, readwrite) IBOutlet UITextView* title;
@end

@implementation WPWhatsNewView

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame
                        image:(UIImage*)image
                        title:(NSString*)title
                      details:(NSString *)details
{
    NSAssert([details isKindOfClass:[UIImage class]],
             @"The WhatsNewView needs details to show.");
    NSAssert([image isKindOfClass:[UIImage class]],
             @"The WhatsNewView needs an image to show.");
    NSAssert([title isKindOfClass:[NSString class]],
             @"The WhatsNewView needs an title to show.");
    
    self = [super initWithFrame:frame];

    if (self) {
        [self setupOutletsWithImage:image title:title details:details];
        
        self.layer.cornerRadius = 5;
        self.layer.masksToBounds = YES;
    }

    return self;
}

#pragma mark - Init helpers

/**
 *  @brief      Initial set-up of the outlets for this view.
 *  @details    This method requires the outlets to be already wired before it's called.
 *
 *  @param      image       The image to show.  Cannot be nil.
 *  @param      title       The title to show.  Cannot be nil.
 *  @param      details     The details to describe what's new.  Cannot be nil.
 */
- (void)setupOutletsWithImage:(UIImage*)image
                        title:(NSString*)title
                      details:(NSString*)details
{
    NSAssert([details isKindOfClass:[UIImage class]],
             @"The WhatsNewView needs details to show.");
    NSAssert([image isKindOfClass:[UIImage class]],
             @"The WhatsNewView needs an image to show.");
    NSAssert([title isKindOfClass:[NSString class]],
             @"The WhatsNewView needs an title to show.");
    
    NSAssert([_details isKindOfClass:[UITextView class]],
             @"Details outlet not wired.");
    NSAssert([_image isKindOfClass:[UIImageView class]],
             @"Image outlet not wired.");
    NSAssert([_details isKindOfClass:[UITextView class]],
             @"Details outlet not wired.");
    
    _details.text = details;
    _image.image = image;
    _title.text = title;
}

#pragma mark - Showing & hiding

- (void)hideAnimated:(BOOL)animated
{
    // Hides the view in the superView... does not remove it...
}

- (void)showAnimated:(BOOL)animated
{
    // Shows the view in the superView... does not remove it...
}

@end
