#import <Foundation/Foundation.h>

/// Represents the infomartion needed to encode a file on a multipart form request.
@interface FilePart: NSObject

@property (strong, nonatomic) NSString * _Nonnull parameterName;
@property (strong, nonatomic) NSURL * _Nonnull url;
@property (strong, nonatomic) NSString * _Nonnull fileName;
@property (strong, nonatomic) NSString * _Nonnull mimeType;

- (instancetype _Nonnull)initWithParameterName:(NSString * _Nonnull)parameterName
                                           url:(NSURL * _Nonnull)url
                                      fileName:(NSString * _Nonnull)fileName
                                      mimeType:(NSString * _Nonnull)mimeType;

@end
