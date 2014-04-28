#import "WPMediaUploader.h"
#import "Media.h"

// Notifications
extern NSString *const MediaShouldInsertBelowNotification;

@implementation WPMediaUploader

+ (void)uploadMedia:(Media *)media
{
    [media uploadWithSuccess:^{
        if ([media isDeleted]) {
            DDLogWarn(@"Media processor found deleted media while uploading (%@)", media);
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:MediaShouldInsertBelowNotification object:media];
        [media save];
    } failure:^(NSError *error) {
        if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
            DDLogWarn(@"Media processor failed with cancelled upload: %@", error.localizedDescription);
            return;
        }
        
        [WPError showAlertWithTitle:NSLocalizedString(@"Upload failed", nil) message:error.localizedDescription];
    }];
}

@end
