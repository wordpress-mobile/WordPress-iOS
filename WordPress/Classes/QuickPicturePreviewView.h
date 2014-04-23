#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@protocol QuickPicturePreviewViewDelegate <NSObject>
@optional
- (void)pictureWillZoom;
- (void)pictureDidZoom;
- (void)pictureWillRestore;
- (void)pictureDidRestore;

@end

@interface QuickPicturePreviewView : UIView {
    UIImageView *imageView;
    CALayer *frameLayer;
    BOOL zoomed;
    BOOL zooming;
    CGRect normalFrame, normalImageFrame;
}

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, weak) IBOutlet id<QuickPicturePreviewViewDelegate> delegate;

@end
