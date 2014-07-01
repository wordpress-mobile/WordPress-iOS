#import "NoteBlockImageTableViewCell.h"
#import "Notification.h"

#import "WPStyleGuide+Notifications.h"

#import <AFNetworking/UIKit+AFNetworking.h>



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSTimeInterval const NotificationAnimationDuration   = 0.5f;
static NSTimeInterval const NotificationAnimationDelay      = 0.2f;
static CGFloat const NotificationAnimationDamping           = 0.7f;
static CGFloat const NotificationAnimationVelocity          = 0.5f;
static CGFloat NotificationAnimationInitialScale            = 0.0f;
static CGFloat NotificationAnimationFinalScale              = 1.0f;

static CGFloat NotificationImageBlockHeight                 = 200.0f;


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface NoteBlockImageTableViewCell ()
@property (nonatomic, weak) IBOutlet UIImageView *blockImageView;
@end


#pragma mark ====================================================================================
#pragma mark NotificationBlockImageCell
#pragma mark ====================================================================================

@implementation NoteBlockImageTableViewCell

- (void)awakeFromNib
{
    NSAssert(self.blockImageView, nil);
    self.selectionStyle     = UITableViewCellSelectionStyleNone;
    self.backgroundColor    = [WPStyleGuide notificationBlockBackgroundColor];
}

- (void)setImageURL:(NSURL *)imageURL
{
    if ([imageURL isEqual:_imageURL]) {
        return;
    }
    
    if (imageURL) {
        [self downloadImageWithURL:imageURL];
    } else {
        self.imageView.image = nil;
    }
    
    _imageURL = imageURL;
}


#pragma mark - Image Helpers

- (void)downloadImageWithURL:(NSURL *)url
{
    if (!url) {
        return;
    }
    
    __weak __typeof(self) weakSelf  = self;
    NSURLRequest *urlRequest        = [[NSURLRequest alloc] initWithURL:url];
    
    [_blockImageView setImageWithURLRequest:urlRequest
                           placeholderImage:nil
                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                        [weakSelf displayImage:image];
                                    }
                                    failure:nil
     ];
}

- (void)displayImage:(UIImage *)image
{
    if (!image) {
        return;
    }

    _blockImageView.image       = image;
    _blockImageView.hidden      = NO;
    _blockImageView.transform   = CGAffineTransformMakeScale(NotificationAnimationInitialScale, NotificationAnimationInitialScale);
    
    [UIView animateWithDuration:NotificationAnimationDuration
                          delay:NotificationAnimationDelay
         usingSpringWithDamping:NotificationAnimationDamping
          initialSpringVelocity:NotificationAnimationVelocity
                        options:nil
                     animations:^{
                         _blockImageView.transform = CGAffineTransformMakeScale(NotificationAnimationFinalScale, NotificationAnimationFinalScale);
                     }
                     completion:nil
     ];
}

#pragma mark - NoteBlockTableViewCell Methods

+ (CGFloat)heightWithText:(NSString *)text
{
    return NotificationImageBlockHeight;
}

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
