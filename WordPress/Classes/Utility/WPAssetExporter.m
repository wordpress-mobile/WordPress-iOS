#import "WPAssetExporter.h"
#import "WPImageOptimizer.h"
#import "WPVideoOptimizer.h"

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
    NSString * assetType = [asset valueForProperty:ALAssetPropertyType];
    if (assetType == ALAssetTypePhoto) {
        [self exportPhotoAsset:asset
                        toFile:filePath
                      resizing:targetSize
              stripGeoLocation:stripGeoLocation
             completionHandler:handler];
    } else if (assetType == ALAssetTypeVideo) {
        [self exportVideoAsset:asset
                        toFile:filePath
                      resizing:targetSize
              stripGeoLocation:stripGeoLocation
             completionHandler:handler];
    }
    
}

- (void)exportPhotoAsset:(ALAsset *)asset
             toFile:(NSString *)filePath
           resizing:(CGSize)targetSize
   stripGeoLocation:(BOOL)stripGeoLocation
       completionHandler:(void (^)(BOOL success, CGSize resultingSize, NSData *thumbnailData, NSError *error)) handler
{
    NSParameterAssert(filePath);
    if (!asset.defaultRepresentation) {
        if (handler) {
            NSDictionary * userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(@"This Photo Stream image cannot be added to your WordPress. Try saving it to your Camera Roll before uploading.", @"Message that explains to a user that the current asset they selected is not available on the device. This normally happens when user selects a photo that belongs to a photostream that needs to be downloaded locally first.")};
            NSError * error = [NSError errorWithDomain:WPAssetExportErrorDomain
                                                  code:WPAssetExportErrorCodeMissingAsset
                                              userInfo:userInfo];
            handler(NO, CGSizeZero, nil, error);
        }
        return;
    }
    NSString * type = asset.defaultRepresentation.UTI;
    // File path extension takes precedence over the default representation.
    if ([filePath pathExtension]) {
        // Get the UTI from the file's extension:
        CFStringRef pathExtension = (__bridge_retained CFStringRef)[filePath pathExtension];
        NSString * extensionType = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
        if (extensionType.length > 0) {
            type = extensionType;
        }
        CFRelease(pathExtension);
    }
    
    [self.operationQueue addOperationWithBlock:^{
        
        UIImage *thumbnail = [UIImage imageWithCGImage:asset.thumbnail];
        NSData *thumbnailJPEGData = UIImageJPEGRepresentation(thumbnail, 1.0);
        
        WPImageOptimizer *imageOptimizer = [[WPImageOptimizer alloc] init];
        CGSize newSize = [imageOptimizer sizeForOriginalSize:targetSize fittingSize:targetSize];
        NSData *data = [imageOptimizer optimizedDataFromAsset:asset
                                                  fittingSize:targetSize
                                             stripGeoLocation:stripGeoLocation
                                              convertToType:type];
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

- (void)exportVideoAsset:(ALAsset *)asset
                  toFile:(NSString *)filePath
                resizing:(CGSize)targetSize
        stripGeoLocation:(BOOL)stripGeoLocation
       completionHandler:(void (^)(BOOL success, CGSize resultingSize, NSData *thumbnailData, NSError *error))handler
{
    if (!asset.defaultRepresentation) {
        if (handler) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"This Photo Stream video cannot be added to your WordPress. Try saving it to your Camera Roll before uploading.", @"Message that explains to a user that the current asset they selected is not available on the device. This normally happens when user selects a video that belongs to a photostream that needs to be downloaded locally first.") };
            NSError *error = [NSError errorWithDomain:WPAssetExportErrorDomain
                                                 code:WPAssetExportErrorCodeMissingAsset
                                             userInfo:userInfo];
            handler(NO, CGSizeZero, nil, error);
        }
        return;
    }
    [self.operationQueue addOperationWithBlock:^{
        UIImage *thumbnail = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
        NSData *thumbnailJPEGData = UIImageJPEGRepresentation(thumbnail, 1.0);
        WPVideoOptimizer *videoOptimizer = [[WPVideoOptimizer alloc] init];
        [videoOptimizer optimizeAsset:asset resize:NO toPath:filePath withHandler:^(CGSize newSize, NSError *error) {
            if (handler){
                if (error) {
                    handler(NO, CGSizeZero, nil, error);
                } else {
                    handler(YES, newSize, thumbnailJPEGData, nil);
                }
                return;
            }
        }];
    }];
}

@end
