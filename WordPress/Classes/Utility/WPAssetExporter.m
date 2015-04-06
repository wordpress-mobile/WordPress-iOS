#import "WPAssetExporter.h"
#import "WPImageOptimizer.h"
#import "Media.h"

NSString * const WPAssetExportErrorDomain = @"org.wordpress.assetexporter";
const NSInteger WPAssetExportErrorCodeMissingAsset = 1;

@interface WPAssetExporter ()

@property (nonatomic, strong) NSOperationQueue * operationQueue;

@end

@implementation WPAssetExporter

- (instancetype)init
{
    self = [super init];
    if (self){
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.name = [NSString stringWithFormat:@"org.worpress.%@", NSStringFromClass([self class])];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

+ (instancetype) sharedInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (void)exportAsset:(ALAsset *)asset
             toFile:(NSString *)filePath
           resizing:(CGSize)targetSize
   stripGeoLocation:(BOOL)stripGeoLocation
  completionHandler:(void (^)(BOOL success, CGSize resultingSize, NSData *thumbnailData, NSError *error)) handler
{
    if (!asset.defaultRepresentation) {
        if (handler) {
            NSDictionary * userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(@"This Photo Stream image cannot be added to your WordPress. Try saving it to your Camera Roll before uploading.", @"Message that explains to a user that the current asset they selected is not available on the device. This normally happens when user selects a media that belogns to a photostream that needs to be downloaded locally first.")};
            NSError * error = [NSError errorWithDomain:WPAssetExportErrorDomain
                                                  code:WPAssetExportErrorCodeMissingAsset
                                              userInfo:userInfo];
            handler(NO, CGSizeZero, nil, error);
        }
        return;
    }
    [self.operationQueue addOperationWithBlock:^{
        UIImage *thumbnail = [Media thumbnailImageFromAsset:asset];
        NSData *thumbnailJPEGData = [Media thumbnailDataFrom:thumbnail];
        
        WPImageOptimizer *imageOptimizer = [[WPImageOptimizer alloc] init];
        CGSize newSize = [imageOptimizer sizeForOriginalSize:targetSize fittingSize:targetSize];
        NSData *data = [imageOptimizer optimizedDataFromAsset:asset fittingSize:targetSize stripGeoLocation:stripGeoLocation];
        if (!data) {
            if (handler) {
                handler(NO, newSize, thumbnailJPEGData, nil);
            }
            return;
        }
        NSError *error;
        if (![data writeToFile:filePath options:NSDataWritingAtomic error:&error]) {
            if (handler){
                handler(NO, newSize, thumbnailJPEGData, error);
            }
            return;
        }
        
        if (handler){
            handler(YES, newSize, thumbnailJPEGData, nil);
            return;
        }
    }];
}

@end
