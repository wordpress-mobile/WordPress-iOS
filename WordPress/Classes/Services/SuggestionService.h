#import <Foundation/Foundation.h>

extern NSString * const SuggestionListUpdatedNotification;

@interface SuggestionService : NSObject

+ (id)shared;

- (NSArray *)suggestionsForSiteID:(NSNumber *)siteID;
- (BOOL)shouldShowSuggestionsPageForSiteID:(NSNumber *)siteID;

@end
