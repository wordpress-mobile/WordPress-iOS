
#import "WPAssetExporter.h"

#import "WPImageOptimizer.h"

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

    [self.operationQueue addOperationWithBlock:^{
        UIImage *thumbnail = [UIImage imageWithCGImage:asset.thumbnail];
        NSData *thumbnailJPEGData = UIImageJPEGRepresentation(thumbnail, 1.0);
        
        WPImageOptimizer *imageOptimizer = [[WPImageOptimizer alloc] init];
        CGSize newSize = [imageOptimizer sizeForOriginalSize:targetSize fittingSize:targetSize];
        NSData *data = [imageOptimizer optimizedDataFromAsset:asset fittingSize:targetSize stripGeoLocation:stripGeoLocation];
        if (!data && handler) {
            handler(NO, newSize, thumbnailJPEGData, nil);
        }
        NSError *error;
        if (![data writeToFile:filePath options:NSDataWritingAtomic error:&error] && handler) {
            handler(NO, newSize, thumbnailJPEGData, error);
        }
        
        if (handler){
            handler(YES, newSize, thumbnailJPEGData, nil);
        }
    }];
}

@end
