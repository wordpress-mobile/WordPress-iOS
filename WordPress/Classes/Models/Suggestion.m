#import "Suggestion.h"

@implementation Suggestion

+ (instancetype)suggestionFromDictionary:(NSDictionary *)dictionary {
    Suggestion *suggestion = [Suggestion new];
    
    suggestion.userLogin = [dictionary stringForKey:@"user_login"];
    suggestion.displayName = [dictionary stringForKey:@"display_name"];
    suggestion.imageURL = [NSURL URLWithString:[dictionary stringForKey:@"image_URL"]];
    
    return suggestion;
}

@end
