#import <Foundation/Foundation.h>

@interface Suggestion : NSObject

@property (nonatomic, strong) NSString *userLogin;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSURL *imageURL;

+ (id)suggestionWithUserLogin:(NSString*)_userLogin
                  displayName:(NSString *)_displayName
                     imageURL:(NSURL *)_imageURL;

@end
