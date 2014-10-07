#import "Suggestion.h"
#import "WPAvatarSource.h"

@implementation Suggestion

+ (instancetype)suggestionFromDictionary:(NSDictionary *)dictionary {
    Suggestion *suggestion = [Suggestion new];
    
    suggestion.userLogin = [dictionary stringForKey:@"user_login"];
    suggestion.displayName = [dictionary stringForKey:@"display_name"];
    suggestion.imageURL = [NSURL URLWithString:[dictionary stringForKey:@"image_URL"]];
    
    return suggestion;
}

- (UIImage *)cachedAvatarWithSize:(CGSize)size
{
    NSString *hash;
    WPAvatarSourceType type = [self avatarSourceTypeWithHash:&hash];
    if (!hash) {
        return nil;
    }
    return [[WPAvatarSource sharedSource] cachedImageForAvatarHash:hash ofType:type withSize:size];
}

- (void)fetchAvatarWithSize:(CGSize)size success:(void (^)(UIImage *image))success
{
    NSString *hash;
    WPAvatarSourceType type = [self avatarSourceTypeWithHash:&hash];
    
    if (hash) {
        [[WPAvatarSource sharedSource] fetchImageForAvatarHash:hash ofType:type withSize:size success:success];
    } else if (success) {
        success(nil);
    }
}

- (WPAvatarSourceType)avatarSourceTypeWithHash:(NSString **)hash
{
    if (self.imageURL) {
        return [[WPAvatarSource sharedSource] parseURL:self.imageURL forAvatarHash:hash];
    }
    return WPAvatarSourceTypeUnknown;
}

@end
