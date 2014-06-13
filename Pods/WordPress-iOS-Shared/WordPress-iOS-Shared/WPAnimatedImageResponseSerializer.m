#import "WPAnimatedImageResponseSerializer.h"


@implementation WPAnimatedImageResponseSerializer

#pragma mark - AFImageResponseSerializer

/**
 *	@brief		Override to handle GIFs.
 *	@details	Error handling and other image formats are left for the superclass to handle.
 *
 *	@param		response	The request response.
 *	@param		data		The image data if all went well.
 *	@param		error		Request errors.
 *
 *	@returns	The image.
 */
- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
	UIImage* image = nil;
	
	static NSString* kGifMimeType = @"image/gif";
	
	BOOL isNotAGif = ![response.MIMEType isEqualToString:kGifMimeType];
	BOOL invalidResponse = ![self validateResponse:(NSHTTPURLResponse*)response data:data error:error];
	BOOL mustBeHandledBySuperclass = invalidResponse || isNotAGif;
	
    if (mustBeHandledBySuperclass) {
        image = [super responseObjectForResponse:response
											data:data
										   error:error];
    } else {
		image = [[UIImage alloc] initWithData:data
										scale:self.imageScale];
	}
	
	return image;
}

@end
