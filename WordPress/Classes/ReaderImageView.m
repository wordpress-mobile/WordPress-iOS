#import "ReaderImageView.h"
#import "ReaderMediaView.h"

@implementation ReaderImageView

- (void)setImageWithURL:(NSURL *)url
	   placeholderImage:(UIImage *)image
				success:(void (^)(ReaderMediaView *))success
				failure:(void (^)(ReaderMediaView *, NSError *))failure {

	self.contentURL = url;
	[super setImageWithURL:url placeholderImage:image success:success failure:failure];
}


@end
