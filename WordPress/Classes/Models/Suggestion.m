#import "Suggestion.h"

@implementation Suggestion

+ (id)suggestionWithUserLogin:(NSString *)_userLogin
                  displayName:(NSString *)_displayName
                     imageURL:(NSURL *)_imageURL
{    
    Suggestion *newSuggestion = [[self alloc] init];
    
    newSuggestion.userLogin = _userLogin;
    newSuggestion.displayName = _displayName;
    newSuggestion.imageURL = _imageURL;
    
    return newSuggestion;
}

@end
