#import "WPException.h"

@implementation WPException

+ (BOOL)objcTryBlock:(void (^)(void))block error:(NSError * __autoreleasing *)outError;
{
    @try {
        if (block) {
            block();
        }
        return true;
    } @catch (NSException *exception) {
        if (outError) {
            *outError = [NSError errorWithDomain:exception.name code:0 userInfo:exception.userInfo];
        }
        return false;
    } @finally {

    }
}

@end
