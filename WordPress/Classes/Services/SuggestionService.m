#import "SuggestionService.h"
#import "Suggestion.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "BlogService.h"
#import "Blog.h"
#import "WordPressAppDelegate.h"

NSString * const SuggestionListUpdatedNotification = @"SuggestionListUpdatedNotification";

@interface SuggestionService ()

@property (nonatomic, strong) NSCache *suggestionsCache;
@property (nonatomic, strong) NSMutableArray *siteIDsCurrentlyBeingRequested;

@end

@implementation SuggestionService

+ (id)sharedInstance
{
    static SuggestionService *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _suggestionsCache = [NSCache new];
        _siteIDsCurrentlyBeingRequested = [NSMutableArray new];
    }
    return self;
}

#pragma mark -

- (NSArray *)suggestionsForSiteID:(NSNumber *)siteID
{
    NSArray *suggestions = [self.suggestionsCache objectForKey:siteID];
    if (!suggestions) {
        [self updateSuggestionsForSiteID:siteID];
    }
    return suggestions;
}

- (void)updateSuggestionsForSiteID:(NSNumber *)siteID
{
    // if there is already a request in place for this siteID, just wait
    if ([self.siteIDsCurrentlyBeingRequested containsObject:siteID]) {
        return;
    }
    
    // add this siteID to currently being requested list
    [self.siteIDsCurrentlyBeingRequested addObject:siteID];
    
    NSString *suggestPath = @"users/suggest";
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    NSDictionary *params = @{@"site_id": siteID};
    
    __weak __typeof(self) weakSelf = self;
    
    [[defaultAccount restApi] GET:suggestPath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *restSuggestions = responseObject[@"suggestions"];
        NSMutableArray *suggestions = [[NSMutableArray alloc] initWithCapacity:restSuggestions.count];
        
        for (id restSuggestion in restSuggestions) {
            [suggestions addObject:[Suggestion suggestionFromDictionary:restSuggestion]];
        }
        [weakSelf.suggestionsCache setObject:suggestions forKey:siteID cost:suggestions.count];
        
        // send the siteID with the notification so it could be filtered out
        [[NSNotificationCenter defaultCenter] postNotificationName:SuggestionListUpdatedNotification object:siteID];
        
        // remove siteID from the currently being requested list
        [weakSelf.siteIDsCurrentlyBeingRequested removeObject:siteID];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        // remove siteID from the currently being requested list
        [weakSelf.siteIDsCurrentlyBeingRequested removeObject:siteID];

        DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);
    }];
}

- (BOOL)shouldShowSuggestionsForSiteID:(NSNumber *)siteID
{
    if (!siteID) {
        return NO;
    }
    
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedInstance];
    
    NSArray *suggestions = [self.suggestionsCache objectForKey:siteID];
    
    // if the device is offline and suggestion list is not yet retrieved
    if (!appDelegate.connectionAvailable && !suggestions) {
        return NO;
    }
        
    // if the suggestion list is already retrieved and there is nothing to show
    if (suggestions && suggestions.count == 0) {
        return NO;
    }
    
    // if the site is not hosted on WordPress.com
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *service            = [[BlogService alloc] initWithManagedObjectContext:context];
    Blog *blog                      = [service blogByBlogId:siteID];
    return [blog supports:BlogFeatureMentions];
}

@end
