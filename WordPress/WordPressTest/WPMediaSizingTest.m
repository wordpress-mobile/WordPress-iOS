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


#pragma mark - Helper Methods

- (void)setMediaResizePreferenceValue:(NSUInteger)value
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%d", value] forKey:@"media_resize_preference"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
