#import "WhatsNewView.h"
#import <QuartzCore/QuartzCore.h>

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

- (void)setupOutletsWithImage:image
                        title:title
                      details:details
{
    NSAssert([details isKindOfClass:[UIImage class]],
             @"The WhatsNewView needs details to show.");
    NSAssert([image isKindOfClass:[UIImage class]],
             @"The WhatsNewView needs an image to show.");
    NSAssert([title isKindOfClass:[NSString class]],
             @"The WhatsNewView needs an title to show.");
    
    _details = details;
    _image = image;
    _title = title;
}

@end
