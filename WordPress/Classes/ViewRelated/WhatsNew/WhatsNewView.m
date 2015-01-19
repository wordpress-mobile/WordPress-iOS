#import "WhatsNewView.h"
#import <QuartzCore/QuartzCore.h>

@interface WhatsNewView ()
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

@implementation WhatsNewView

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

@end
