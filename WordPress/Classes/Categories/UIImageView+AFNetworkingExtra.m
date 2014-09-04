#import "UIImageView+AFNetworkingExtra.h"
#import <AFNetworking/UIKit+AFNetworking.h>

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

- (void)setImageWithURL:(NSURL *)url emptyCachePlaceholderImage:(UIImage *)emptyCachePlaceholderImage
{
    UIImage *placeholderImage = [self cachedImageForURL:url] ?: emptyCachePlaceholderImage;
    [self setImageWithURL:url placeholderImage:placeholderImage];
}

- (UIImage *)cachedImageForURL:(NSURL *)url
{
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    if (![cachedResponse            isKindOfClass:[NSCachedURLResponse class]]  ||
        ![cachedResponse.response   isKindOfClass:[NSURLResponse class]]        ||
        ![cachedResponse.data       isKindOfClass:[NSData class]]               ||
        cachedResponse.data.length == 0) {
        return nil;
    }

    NSError *error = nil;
    id responseObject = [[AFImageResponseSerializer serializer] responseObjectForResponse:cachedResponse.response
                                                                                     data:cachedResponse.data
                                                                                    error:&error];

    if (error || ![responseObject isKindOfClass:[UIImage class]]) {
        return nil;
    }

    return responseObject;
}

@end
