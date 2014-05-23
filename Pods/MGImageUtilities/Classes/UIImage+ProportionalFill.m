//
//  UIImage+ProportionalFill.m
//
//  Created by Matt Gemmell on 20/08/2008.
//  Copyright 2008 Instinctive Code.
//

#import "UIImage+ProportionalFill.h"


@implementation UIImage (MGProportionalFill)


- (UIImage *)imageToFitSize:(CGSize)fitSize method:(MGImageResizingMethod)resizeMethod ignoreAlpha:(BOOL)opaque
{
	float imageScaleFactor = 1.0;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
	if ([self respondsToSelector:@selector(scale)]) {
		imageScaleFactor = [self scale];
	}
#endif
	
	float sourceWidth = [self size].width * imageScaleFactor;
	float sourceHeight = [self size].height * imageScaleFactor;
	float targetWidth = fitSize.width;
	float targetHeight = fitSize.height;
	BOOL cropping = !(resizeMethod == MGImageResizeScale);
	
	// Calculate aspect ratios
	float sourceRatio = sourceWidth / sourceHeight;
	float targetRatio = targetWidth / targetHeight;
	
	// Determine what side of the source image to use for proportional scaling
	BOOL scaleWidth = (sourceRatio <= targetRatio);
	// Deal with the case of just scaling proportionally to fit, without cropping
	scaleWidth = (cropping) ? scaleWidth : !scaleWidth;
	
	// Proportionally scale source image
	float scalingFactor, scaledWidth, scaledHeight;
	if (scaleWidth) {
		scalingFactor = 1.0 / sourceRatio;
		scaledWidth = targetWidth;
		scaledHeight = round(targetWidth * scalingFactor);
	} else {
		scalingFactor = sourceRatio;
		scaledWidth = round(targetHeight * scalingFactor);
		scaledHeight = targetHeight;
	}
	float scaleFactor = scaledHeight / sourceHeight;
	
	// Calculate compositing rectangles
	CGRect sourceRect, destRect;
	if (cropping) {
		destRect = CGRectMake(0, 0, targetWidth, targetHeight);
		float destX, destY;
		if (resizeMethod == MGImageResizeCrop) {
			// Crop center
			destX = round((scaledWidth - targetWidth) / 2.0);
			destY = round((scaledHeight - targetHeight) / 2.0);
		} else if (resizeMethod == MGImageResizeCropStart) {
			// Crop top or left (prefer top)
			if (scaleWidth) {
				// Crop top
				destX = 0.0;
				destY = 0.0;
			} else {
				// Crop left
				destX = 0.0;
				destY = round((scaledHeight - targetHeight) / 2.0);
			}
		} else if (resizeMethod == MGImageResizeCropEnd) {
			// Crop bottom or right
			if (scaleWidth) {
				// Crop bottom
				destX = round((scaledWidth - targetWidth) / 2.0);
				destY = round(scaledHeight - targetHeight);
			} else {
				// Crop right
				destX = round(scaledWidth - targetWidth);
				destY = round((scaledHeight - targetHeight) / 2.0);
			}
		}
		sourceRect = CGRectMake(destX / scaleFactor, destY / scaleFactor, 
								targetWidth / scaleFactor, targetHeight / scaleFactor);
	} else {
		sourceRect = CGRectMake(0, 0, sourceWidth, sourceHeight);
		destRect = CGRectMake(0, 0, scaledWidth, scaledHeight);
	}
	
	UIImage* finalImage = nil;
	
	static const CGFloat kScaleForDevicesMainScreen = 0.f;
	UIGraphicsBeginImageContextWithOptions(destRect.size, opaque, kScaleForDevicesMainScreen);
	
	finalImage = [self cropToRect:sourceRect
				   andResizeToRec:destRect];
	
	UIGraphicsEndImageContext();
	
	return finalImage;

}

- (UIImage *)imageToFitSize:(CGSize)size method:(MGImageResizingMethod)resizeMethod
{
    return [self imageToFitSize:size method:resizeMethod ignoreAlpha:NO];
}

- (UIImage *)imageCroppedToFitSize:(CGSize)fitSize ignoreAlpha:(BOOL)opaque
{
	return [self imageToFitSize:fitSize method:MGImageResizeCrop ignoreAlpha:opaque];
}

- (UIImage *)imageCroppedToFitSize:(CGSize)size
{
    return [self imageCroppedToFitSize:size ignoreAlpha:NO];
}

- (UIImage *)imageScaledToFitSize:(CGSize)fitSize ignoreAlpha:(BOOL)opaque
{
	return [self imageToFitSize:fitSize method:MGImageResizeScale ignoreAlpha:opaque];
}

- (UIImage *)imageScaledToFitSize:(CGSize)fitSize
{
    return [self imageScaledToFitSize:fitSize ignoreAlpha:NO];
}


#pragma mark - ImageContext operations

/**
 *	@brief		Crops the image to the specified rect.
 *	@details	Does not support animated images directly, but support could be added by replicating
 *				cropToRect:andResizeToRect:'s logic.
 *
 *	@param		rect	The rect to crop this image to.
 *
 *	@returns	The cropped image.
 */
- (UIImage*)cropWithRect:(CGRect)rect
{
	CGImageRef cgImage = CGImageCreateWithImageInRect([self CGImage], rect);
	UIImage* image = [UIImage imageWithCGImage:cgImage
										 scale:0.0
								   orientation:self.imageOrientation];
	CGImageRelease(cgImage);
	
	return image;
}

/**
 *	@brief		Crops & resizes the image.
 *	@details	Supports animated images.
 *
 *	@param		cropRect	The rect to use for cropping.
 *	@param		resizeRect	The rect to use for resizing.
 *
 *	@returns	The resulting image.
 */
- (UIImage*)cropToRect:(CGRect)cropRect
		andResizeToRec:(CGRect)resizeRect
{
	UIImage* modifiedImage = nil;
	
	BOOL isAnimatedImage = (self.images != nil);
	
	if (!isAnimatedImage) {
		
		modifiedImage = [self cropWithRect:cropRect];
		modifiedImage = [modifiedImage resizeToRect:resizeRect];
	} else {
		NSMutableArray* modifiedImages = [NSMutableArray arrayWithCapacity:[self.images count]];
		
		for (UIImage* image in self.images)
		{
			image = [image cropToRect:cropRect
					   andResizeToRec:resizeRect];
			
			[modifiedImages addObject:image];
		}
		
		modifiedImage = [UIImage animatedImageWithImages:modifiedImages
												duration:self.duration];
	}
	
	return modifiedImage;
}

/**
 *	@brief		Resizes the image to the specified rect.
 *	@details	This method must be called after UIGraphicsBeginImageContext() and before
 *				UIGraphicsEndImageContext();.
 *				Does not support animated images directly, but support could be added by replicating
 *				cropToRect:andResizeToRect:'s logic.
 *
 *	@param		rect	The rect to resize this image to.
 *
 *	@returns	The resized image.
 */
- (UIImage*)resizeToRect:(CGRect)rect
{
	NSAssert(UIGraphicsGetCurrentContext() != NULL,
			 @"A context should be created before calling this method.");
	
	[self drawInRect:rect];
	UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
	
	return image;
}

@end
