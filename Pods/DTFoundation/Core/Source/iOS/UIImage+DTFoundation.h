//
//  UIImage+DTFoundation.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 3/8/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Methods to help with working with images.
 */
@interface UIImage (DTFoundation)


/**
 @name Loading from RemoteURLs
 */


/**
 Creates and returns an image object synchronously by loading the image data from the specified URL and optionally caching it.
 
 Useful values for cachePolicy are:
 
 - NSURLRequestUseProtocolCachePolicy (default)
 - NSURLRequestReloadIgnoringLocalCacheData
 - NSURLRequestReturnCacheDataElseLoad
 - NSURLRequestReturnCacheDataDontLoad
 
 @param URL The URL to load the image from
 @param cachePolicy The cache policy to apply.
 @param error An optional output parameter to return an error if the loading fails
 @returns The image object for the specified URL, or nil if the method could not load the specified image.
 */
+ (UIImage *)imageWithContentsOfURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy error:(NSError **)error;


 /**
 @name Drawing
 */
 
/**
 Mimicks the way images are drawn differently by UIImageView based on the set content mode.
 @param rect The rectangle to drawn in
 @param contentMode The content mode. Note that UIViewContentModeRedraw is treated the same as UIViewContentModeScaleToFill.
 */
- (void)drawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode;

/**
 @name Working with Tiles
 */
 
/**
 Cuts out a tile at the given row and column
 
 @param column The index of the column
 @param columns The total number of columns
 @param row The index of the row
 @param rows The total number of rows
 @returns The resulting image
 */
- (UIImage *)tileImageAtColumn:(NSUInteger)column ofColumns:(NSUInteger)columns row:(NSUInteger)row ofRows:(NSUInteger)rows;

/**
 Cuts out a tile at the given clip rect relative to the bounds
 
 @param clipRect The clipping rect to extract
 @param bounds The bounds to which the clipRect is relative to
 @param scale The image scale
 @returns The resulting image
 */
- (UIImage *)tileImageInClipRect:(CGRect)clipRect inBounds:(CGRect)bounds scale:(CGFloat)scale;


/**
 @name Modifying Images
 */

/**
 Resizes the receiver to the given size.
 
 @param newSize The target image size
 @returns The resulting image
 */
- (UIImage *)imageScaledToSize:(CGSize)newSize;

@end
