#import <Foundation/Foundation.h>

@interface Suggestion : NSObject

@property (nonatomic, strong) NSString *slug;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *avatarEmail;

+ (id)suggestionWithSlug:(NSString*)_slug
            description:(NSString *)_description
            avatarEmail:(NSString *)_avatarEmail;

@end
