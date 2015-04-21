#import <Foundation/Foundation.h>

@interface DisplayableImageHelper : NSObject
+ (NSString *)searchPostAttachmentsForImageToDisplay:(NSDictionary *)attachmentsDict;
+ (NSString *)searchPostContentForImageToDisplay:(NSString *)content;
@end
