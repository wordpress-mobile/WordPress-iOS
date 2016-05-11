#import "EmailCheckerHelper.h"
#import <EmailChecker/EmailChecker.h>

@implementation EmailCheckerHelper

+ (NSString *) suggestDomainCorrection:(NSString *)email
{
    return [EmailChecker suggestDomainCorrection:email];
}

@end
