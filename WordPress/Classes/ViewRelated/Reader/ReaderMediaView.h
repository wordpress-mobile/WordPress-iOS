#import <Foundation/Foundation.h>

@interface ReaderMediaView : UIControl

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) UIEdgeInsets edgeInsets;
@property (nonatomic, strong) NSURL *contentURL;
@property (nonatomic) BOOL isShowingPlaceholder;

- (UIImage *)image;
- (void)setImage:(UIImage *)image;
- (NSURL *)contentURL;
- (void)setPlaceholder:(UIImage *)image;
- (void)setImageWithURL:(NSURL *)url
	   placeholderImage:(UIImage *)image
				success:(void (^)(ReaderMediaView *readerMediaView))success
				failure:(void (^)(ReaderMediaView *readerMediaView, NSError *error))failure;
@end
