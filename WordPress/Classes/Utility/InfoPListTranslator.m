#import "InfoPListTranslator.h"

@implementation InfoPListTranslator

+ (void)translateStrings
{
    NSLocalizedString(@"WordPress would like to add your location to posts on sites where you have enabled geotagging.", @"NSLocationUsageDescription: This sentence is show when the app asks permission from the user to use is location. ");
    NSLocalizedString(@"WordPress would like to add your location to posts on sites where you have enabled geotagging.", @"NSLocationWhenInUseUsageDescription: this sentence is show when the app asks permission from the user to use is location.");
    NSLocalizedString(@"To take photos or videos to use in your posts.", @"NSCameraUsageDescription: Sentence to justify why the app is asking permission from the user to use is camera.");
    NSLocalizedString(@"To add photos or videos to your posts.", @"NSPhotoLibraryUsageDescription: Sentence to justify why the app asks permission from the user to access is Media Library.");
    NSLocalizedString(@"To add photos or videos to your posts.", @"NSPhotoLibraryAddUsageDescription: Sentence to justify why the app asks permission from the user to access is Media Library.");
    NSLocalizedString(@"Enable microphone access to record sound in your videos.", @"NSMicrophoneUsageDescription: Sentence to justify why the app asks permission from the user to access the device microphone.");
    NSLocalizedString(@"Save as Draft", @"WordPressDraftActionExtension.CFBundleDisplayName and WordPressDraftActionExtension.CFBundleName: The localised name of the Draft Extension. It will be displayed in the system Share Sheets.");

    // gutenberg mobile strings
    NSLocalizedString(@"Add text or type / to add content");
    NSLocalizedString(@"Add URL");
    NSLocalizedString(@"Alt Text");
    NSLocalizedString(@"Reset to Original");
    NSLocalizedString(@"Failed to insert media.\nPlease tap for options.");
    NSLocalizedString(@"Upload a new image or select a file from your library.");
    NSLocalizedString(@"Device Library");
    NSLocalizedString(@"Take photo");
    NSLocalizedString(@"Start writing or press ⊕ to add content");
    NSLocalizedString(@"Unsupported Block");
    NSLocalizedString(@"Unsupported block type.");
    NSLocalizedString(@"ADD BLOCK");
    NSLocalizedString(@"ADD BLOCK HERE");
    NSLocalizedString(@"Move block up");
    NSLocalizedString(@"Move block down" );
    NSLocalizedString(@"Remove content");
}

@end
