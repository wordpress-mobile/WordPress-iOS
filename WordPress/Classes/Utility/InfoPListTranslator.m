#import "InfoPListTranslator.h"

@implementation InfoPListTranslator

+ (void)translateStrings
{
    NSLocalizedString(@"NSLocationUsageDescription", @"Sentence to show when app asks permission from the user to use is location. At the moment this sentence in english is: WordPress would like to add your location to posts on sites where you have enabled geotagging.");
    NSLocalizedString(@"NSLocationWhenInUseUsageDescription", @"Sentence to show when app asks permission from the user to use is location. At the moment this sentence in english is: WordPress would like to add your location to posts on sites where you have enabled geotagging.");
    NSLocalizedString(@"NSCameraUsageDescription", @"Sentence to show when app asks permission from the user to use is camera. At the moment this sentence in english is:To take photos or videos to use in your posts.");
    NSLocalizedString(@"NSPhotoLibraryUsageDescription", @"Sentence to show when app asks permission from the user to access is Media Library. At the moment this sentence in english is: To add photos or videos to your posts.");
    NSLocalizedString(@"NSMicrophoneUsageDescription", @"Sentence to show when app asks permission from the user access is microphone to save sound on videos. At the moment this sentence in english is: For your videos to have sound on them.");
}

@end
