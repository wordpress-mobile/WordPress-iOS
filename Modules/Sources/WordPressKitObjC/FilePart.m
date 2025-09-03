#import "FilePart.h"

@implementation FilePart

- (instancetype)initWithParameterName:(NSString *)parameterName
                                  url:(NSURL *)url
                             fileName:(NSString *)fileName
                             mimeType:(NSString *)mimeType
{
    self = [super init];
    self.parameterName = parameterName;
    self.url = url;
    self.fileName = fileName;
    self.mimeType = mimeType;
    return self;
}

@end
