#import "UIImageView+AFNetworkingExtra.h"

@implementation UIImageView (AFNetworkingExtra)


- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
				success:(void (^)(UIImage *image))success
				failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
	
	__block UIImageView *selfRef = self;
    [self setImageWithURLRequest:request
				placeholderImage:placeholderImage
						 success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
							 selfRef.image = image;
							 if (success) success(image);
						 } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
							 if (failure) failure(error);
						 }];
}



@end
