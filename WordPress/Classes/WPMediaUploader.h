#import <Foundation/Foundation.h>

@class Media;
@interface WPMediaUploader : NSObject

@property (nonatomic, copy) void (^uploadProgressBlock)(NSUInteger numberOfImagesProcessed, NSUInteger numberOfImagesToUpload);
@property (nonatomic, copy) void (^uploadsCompletedBlock)(void);
@property (nonatomic, assign) BOOL isUploadingMedia;

- (void)uploadMediaObjects:(NSArray *)mediaObjects;
- (void)cancelAllUploads;

@end
