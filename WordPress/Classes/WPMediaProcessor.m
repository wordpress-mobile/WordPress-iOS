#import "WPMediaProcessor.h"
#import "Media.h"
#import "UIImage+Resize.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "WPMediaPersister.h"

// Notifications
extern NSString *const MediaShouldInsertBelowNotification;

@implementation WPMediaProcessor

- (void)processImage:(UIImage *)theImage media:(Media *)imageMedia metadata:(NSDictionary *)metadata
{
    [WPMediaPersister saveMedia:imageMedia withImage:theImage andMetadata:metadata];
    
    [imageMedia uploadWithSuccess:^{
        if ([imageMedia isDeleted]) {
            DDLogWarn(@"Media processor found deleted media while uploading (%@)", imageMedia);
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:MediaShouldInsertBelowNotification object:imageMedia];
        [imageMedia save];
    } failure:^(NSError *error) {
        if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
            DDLogWarn(@"Media processor failed with cancelled upload: %@", error.localizedDescription);
            return;
        }
        
        [WPError showAlertWithTitle:NSLocalizedString(@"Upload failed", nil) message:error.localizedDescription];
    }];
    
}

@end
