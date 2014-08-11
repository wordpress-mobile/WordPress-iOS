#import "Suggestion.h"

@implementation Suggestion

@synthesize slug;
@synthesize description;
@synthesize avatarEmail;

+ (id)suggestionWithSlug:(NSString *)_slug
             description:(NSString *)_description
             avatarEmail:(NSString *)_avatarEmail
{    
    Suggestion *newSuggestion = [[self alloc] init];
    
    newSuggestion.slug = _slug;
    newSuggestion.description = _description;
    newSuggestion.avatarEmail = _avatarEmail;
    
    return newSuggestion;
}

@end
