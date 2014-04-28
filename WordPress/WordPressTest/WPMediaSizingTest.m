#import <XCTest/XCTest.h>
#import "WPMediaSizing.h"

@interface WPMediaSizingTest : XCTestCase

@end

@implementation WPMediaSizingTest

- (void)testMediaResizePreference
{
    [self setMediaResizePreferenceValue:0];
    XCTAssertTrue(MediaResizeLarge == [WPMediaSizing mediaResizePreference]);
    
    [self setMediaResizePreferenceValue:1];
    XCTAssertTrue(MediaResizeSmall == [WPMediaSizing mediaResizePreference]);
    
    [self setMediaResizePreferenceValue:2];
    XCTAssertTrue(MediaResizeMedium == [WPMediaSizing mediaResizePreference]);
    
    [self setMediaResizePreferenceValue:3];
    XCTAssertTrue(MediaResizeLarge == [WPMediaSizing mediaResizePreference]);
}

- (void)testSizeForImageForMediaSizeSmall
{
    NSDictionary *sizes = [self sampleBlogResizeDimensions];
    CGSize smallSize =  [sizes[@"smallSize"] CGSizeValue];
    [self checkSizeForImageForMediaResize:MediaResizeSmall andImageSizeAccordingToBlog:smallSize];
}

- (void)testSizeForImageMediaSizeSmallAndLandscapeOrientation
{
    NSDictionary *sizes = [self sampleBlogResizeDimensions];
    CGSize smallSize =  [sizes[@"smallSize"] CGSizeValue];
    smallSize = CGSizeMake(smallSize.height, smallSize.width);
    [self checkSizeForImageForLandscapeOrientationsForMediaResize:MediaResizeSmall andImageSizeAccordingToBlog:smallSize];
}

- (void)testSizeForImageForMediaSizeMedium
{
    NSDictionary *sizes = [self sampleBlogResizeDimensions];
    CGSize mediumSize =  [sizes[@"mediumSize"] CGSizeValue];
    [self checkSizeForImageForMediaResize:MediaResizeMedium andImageSizeAccordingToBlog:mediumSize];
}

- (void)testSizeForImageMediaSizeMediumAndLandscapeOrientation
{
    NSDictionary *sizes = [self sampleBlogResizeDimensions];
    CGSize mediumSize =  [sizes[@"mediumSize"] CGSizeValue];
    mediumSize = CGSizeMake(mediumSize.height, mediumSize.width);
    [self checkSizeForImageForLandscapeOrientationsForMediaResize:MediaResizeMedium andImageSizeAccordingToBlog:mediumSize];
}

- (void)testSizeForImageForMediaSizeLarge
{
    NSDictionary *sizes = [self sampleBlogResizeDimensions];
    CGSize largeSize =  [sizes[@"largeSize"] CGSizeValue];
    [self checkSizeForImageForMediaResize:MediaResizeLarge andImageSizeAccordingToBlog:largeSize];
}

- (void)testSizeForImageMediaSizeLargeAndLandscapeOrientation
{
    NSDictionary *sizes = [self sampleBlogResizeDimensions];
    CGSize largeSize =  [sizes[@"largeSize"] CGSizeValue];
    largeSize = CGSizeMake(largeSize.height, largeSize.width);
    [self checkSizeForImageForLandscapeOrientationsForMediaResize:MediaResizeLarge andImageSizeAccordingToBlog:largeSize];
}

// This method is so we can reduce duplication across the test methods (testSizeForImage*)
- (void)checkSizeForImageForMediaResize:(MediaResize)mediaResize andImageSizeAccordingToBlog:(CGSize)imageSizeAccordingToBlog
{
    [self checkSizeForImageForMediaResize:mediaResize andImageSizeAccordingToBlog:imageSizeAccordingToBlog imageAdjustmentBlock:nil];
}

// This method is so we can reduce duplication across the test methods (testSizeForImage*)
- (void)checkSizeForImageForMediaResize:(MediaResize)mediaResize andImageSizeAccordingToBlog:(CGSize)imageSizeAccordingToBlog imageAdjustmentBlock:(UIImage *(^)(UIImage *))imageAdjustmentBlock
{
    NSDictionary *sizes = [self sampleBlogResizeDimensions];
    CGSize size;
    UIImage *image;
    
    image = [self generateTestImageOfSize:CGSizeMake(imageSizeAccordingToBlog.width - 1, imageSizeAccordingToBlog.height) imageAdjustmentBlock:imageAdjustmentBlock];
    size = [WPMediaSizing sizeForImage:image mediaResize:mediaResize blogResizeDimensions:sizes];
    XCTAssertTrue(CGSizeEqualToSize(image.size, size), @"Width being smaller but height being the same shouldn't result in the image size being adjusted");
    
    image = [self generateTestImageOfSize:CGSizeMake(imageSizeAccordingToBlog.width, imageSizeAccordingToBlog.height - 1) imageAdjustmentBlock:imageAdjustmentBlock];
    size = [WPMediaSizing sizeForImage:image mediaResize:mediaResize blogResizeDimensions:sizes];
    XCTAssertTrue(CGSizeEqualToSize(image.size, size), @"Height being smaller but width being the same shouldn't result in the image size being adjusted");
    
    image = [self generateTestImageOfSize:CGSizeMake(imageSizeAccordingToBlog.width, imageSizeAccordingToBlog.height) imageAdjustmentBlock:imageAdjustmentBlock];
    size = [WPMediaSizing sizeForImage:image mediaResize:mediaResize blogResizeDimensions:sizes];
    XCTAssertTrue(CGSizeEqualToSize(image.size, size), @"Equal size image shouldn't change size");
    
    image = [self generateTestImageOfSize:CGSizeMake(imageSizeAccordingToBlog.width + 1, imageSizeAccordingToBlog.height) imageAdjustmentBlock:imageAdjustmentBlock];
    size = [WPMediaSizing sizeForImage:image mediaResize:mediaResize blogResizeDimensions:sizes];
    XCTAssertTrue(CGSizeEqualToSize(imageSizeAccordingToBlog, size), @"Width being larger but height being equal should result in the image size being adjusted");
    
    image = [self generateTestImageOfSize:CGSizeMake(imageSizeAccordingToBlog.width, imageSizeAccordingToBlog.height + 1) imageAdjustmentBlock:imageAdjustmentBlock];
    size = [WPMediaSizing sizeForImage:image mediaResize:mediaResize blogResizeDimensions:sizes];
    XCTAssertTrue(CGSizeEqualToSize(imageSizeAccordingToBlog, size), @"Height being larger but width being equal should result in the image size being adjusted");
    
    image = [self generateTestImageOfSize:CGSizeMake(imageSizeAccordingToBlog.width + 1, imageSizeAccordingToBlog.height + 1) imageAdjustmentBlock:imageAdjustmentBlock];
    size = [WPMediaSizing sizeForImage:image mediaResize:mediaResize blogResizeDimensions:sizes];
    XCTAssertTrue(CGSizeEqualToSize(imageSizeAccordingToBlog, size), @"Height and width being larger should result in the image size being adjusted");
}

// This method is so we can reduce duplication across the test methods (testSizeForImage*)
- (void)checkSizeForImageForLandscapeOrientationsForMediaResize:(MediaResize)mediaResize andImageSizeAccordingToBlog:(CGSize)imageSizeAccordingToBlog
{
    [self checkSizeForImageForMediaResize:mediaResize andImageSizeAccordingToBlog:imageSizeAccordingToBlog imageAdjustmentBlock:^(UIImage *image) {
        return [UIImage imageWithCGImage:[image CGImage] scale:1.0 orientation:UIImageOrientationLeft];
    }];
    [self checkSizeForImageForMediaResize:mediaResize andImageSizeAccordingToBlog:imageSizeAccordingToBlog imageAdjustmentBlock:^(UIImage *image) {
        return [UIImage imageWithCGImage:[image CGImage] scale:1.0 orientation:UIImageOrientationLeftMirrored];
    }];
    [self checkSizeForImageForMediaResize:mediaResize andImageSizeAccordingToBlog:imageSizeAccordingToBlog imageAdjustmentBlock:^(UIImage *image) {
        return [UIImage imageWithCGImage:[image CGImage] scale:1.0 orientation:UIImageOrientationRight];
    }];
    [self checkSizeForImageForMediaResize:mediaResize andImageSizeAccordingToBlog:imageSizeAccordingToBlog imageAdjustmentBlock:^(UIImage *image) {
        return [UIImage imageWithCGImage:[image CGImage] scale:1.0 orientation:UIImageOrientationRightMirrored];
    }];
}


#pragma mark - Helper Methods

- (void)setMediaResizePreferenceValue:(NSUInteger)value
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%d", value] forKey:@"media_resize_preference"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDictionary *)sampleBlogResizeDimensions
{
    CGSize smallSize = CGSizeMake(5, 5);
    CGSize mediumSize = CGSizeMake(10, 10);
    CGSize largeSize = CGSizeMake(15, 15);
    
    return @{@"smallSize": [NSValue valueWithCGSize:smallSize],
             @"mediumSize": [NSValue valueWithCGSize:mediumSize],
             @"largeSize": [NSValue valueWithCGSize:largeSize]};
}

- (UIImage *)generateTestImageOfSize:(CGSize)size
{
    return [self generateTestImageOfSize:size imageAdjustmentBlock:nil];
}

- (UIImage *)generateTestImageOfSize:(CGSize)size imageAdjustmentBlock:(UIImage *(^)(UIImage *))imageAdjustmentBlock
{
    
    UIGraphicsBeginImageContext(size);
    [[UIColor blackColor] set];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (imageAdjustmentBlock) {
        image = imageAdjustmentBlock(image);
    }
    
    return image;
}


@end
