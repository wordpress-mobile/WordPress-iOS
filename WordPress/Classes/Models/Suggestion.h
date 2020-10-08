#import <Foundation/Foundation.h>

typedef void(^SuggestionAvatarFetchSuccessBlock)(UIImage* image);

@interface Suggestion : NSObject

@property (nonatomic, strong) NSString *userLogin;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSURL *imageURL;

+ (instancetype)suggestionFromDictionary:(NSDictionary *)dictionary;

- (UIImage *)cachedAvatarWithSize:(CGSize)size;
- (void)fetchAvatarWithSize:(CGSize)size success:(SuggestionAvatarFetchSuccessBlock)success;

@end
