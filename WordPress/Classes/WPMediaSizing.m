#import "WPMediaSizing.h"

@implementation WPMediaSizing

+ (MediaResize)mediaResizePreference
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *resizePreferenceNumber = @(0);
    NSString *resizePreferenceString = [[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"] != nil)
        resizePreferenceNumber = [numberFormatter numberFromString:resizePreferenceString];
    
    NSInteger resizePreferenceIndex = [resizePreferenceNumber integerValue];
    
    // Need to deal with preference index awkwardly due to the way we're storing preferences
    if (resizePreferenceIndex == 0) {
        // We used to support per-image resizing; replace that with large by default
        return MediaResizeLarge;
    } else if (resizePreferenceIndex == 1) {
        return MediaResizeSmall;
    } else if (resizePreferenceIndex == 2) {
        return MediaResizeMedium;
    } else if (resizePreferenceIndex == 3) {
        return MediaResizeLarge;
    }

    return MediaResizeOriginal;
}


@end
