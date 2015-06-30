#import "InfoPListTranslator.h"

@implementation InfoPListTranslator

+ (void)translateStrings
{
    NSLocalizedString(@"WordPress would like to add your location to posts on sites where you have enabled geotagging.", @"NSLocationUsageDescription: This sentence is show when the app asks permission from the user to use is location. ");
    NSLocalizedString(@"WordPress would like to add your location to posts on sites where you have enabled geotagging.", @"NSLocationWhenInUseUsageDescription: this sentence is show when the app asks permission from the user to use is location.");
    NSLocalizedString(@"To take photos or videos to use in your posts.", @"NSCameraUsageDescription: Sentence to justify why the app is asking permission from the user to use is camera.");
    NSLocalizedString(@"To add photos or videos to your posts.", @"NSPhotoLibraryUsageDescription: Sentence to justify why the app asks permission from the user to access is Media Library.");
    NSLocalizedString(@"For your videos to have sound on them.", @"NSMicrophoneUsageDescription: Sentence to justify why the app asks permission from the user to access the device microphone.");
}

@end
