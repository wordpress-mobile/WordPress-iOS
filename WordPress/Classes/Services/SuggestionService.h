#import <Foundation/Foundation.h>

extern NSString * const SuggestionListUpdatedNotification;

@interface SuggestionService : NSObject

+ (id)sharedInstance;

/**
 Returns the cached @mention suggestions (if any) for a given siteID.  Calls
 updateSuggestionsForSiteID if no suggestions for the site have been cached.
 
 @param siteID ID of the blog/site to retrieve suggestions for
 @return An array of suggestions
 */
- (NSArray *)suggestionsForSiteID:(NSNumber *)siteID;

/**
 Performs a REST API request for the siteID given.
 
 @param siteID ID of the blog/site to retrieve suggestions for
 */
- (void)updateSuggestionsForSiteID:(NSNumber *)siteID;

/**
 Tells the caller if it is a good idea to show suggestions right now for a given siteID.
 
 @param siteID ID of the blog/site to check for
 @return BOOL Whether the caller should show suggestions
 */
- (BOOL)shouldShowSuggestionsForSiteID:(NSNumber *)siteID;

@end
