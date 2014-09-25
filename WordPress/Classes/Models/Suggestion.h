#import <Foundation/Foundation.h>

@interface Suggestion : NSObject

@property (nonatomic, strong) NSString *userLogin;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSURL *imageURL;

+ (instancetype)suggestionFromDictionary:(NSDictionary *)dictionary;

- (UIImage *)cachedAvatarWithSize:(CGSize)size;
- (void)fetchAvatarWithSize:(CGSize)size success:(void (^)(UIImage *image))success;

@end
