#import "SuggestionService.h"
#import "Suggestion.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "BlogService.h"
#import "Blog.h"
#import "WordPress-Swift.h"

NSString * const SuggestionListUpdatedNotification = @"SuggestionListUpdatedNotification";

@interface SuggestionService ()

@property (nonatomic, strong) NSMutableArray *siteIDsCurrentlyBeingRequested;

@end

@implementation SuggestionService

+ (instancetype)sharedInstance
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
        _siteIDsCurrentlyBeingRequested = [NSMutableArray new];
    }
    return self;
}

#pragma mark -

- (NSArray <UserAutocomplete *>*)suggestionsForSiteID:(NSNumber *)siteID
{
    Autocompleter *autocompleter = [self retrieveAutocompleterForSiteID:siteID];

    if (!autocompleter.userAutocompletes) {
        [self updateSuggestionsForSiteID:siteID];
    }
    return [autocompleter.userAutocompletes allObjects];
}

- (void)updateSuggestionsForSiteID:(NSNumber *)siteID
{
    // if there is already a request in place for this siteID, just wait
    if ([self.siteIDsCurrentlyBeingRequested containsObject:siteID]) {
        return;
    }
    
    // add this siteID to currently being requested list
    [self.siteIDsCurrentlyBeingRequested addObject:siteID];
    
    NSString *suggestPath = @"rest/v1.1/users/suggest";
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    NSDictionary *params = @{@"site_id": siteID};
    
    __weak __typeof(self) weakSelf = self;
    
    [[defaultAccount wordPressComRestApi] GET:suggestPath
                                   parameters:params
                                      success:^(id responseObject, NSHTTPURLResponse *httpResponse) {

        NSArray *restSuggestions = responseObject[@"suggestions"];

        [self updateUserAutocompletesForSiteID:siteID suggestions:restSuggestions];

        // remove siteID from the currently being requested list
        [weakSelf.siteIDsCurrentlyBeingRequested removeObject:siteID];
    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse){
        // remove siteID from the currently being requested list
        [weakSelf.siteIDsCurrentlyBeingRequested removeObject:siteID];

        DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);
    }];
}

- (Autocompleter *)retrieveAutocompleterForSiteID:(NSNumber *)siteID
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];

    NSFetchRequest *request = Autocompleter.fetchRequest;
    [request setPredicate:[NSPredicate predicateWithFormat:@"siteID == %@", siteID]];
    NSError *error;
    NSArray *sites = [context executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"Could not fetch Autocompleter for site %@, error", siteID, error);
        return nil;
    } else if (sites.count > 1) {
        DDLogError(@"Retrieved more than one Autocompleter for site %@", siteID);
        return nil;
    } else {
        return [sites firstObject];
    }
}

- (Autocompleter *)insertAutocompleterForSiteID:(NSNumber *)siteID
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    Autocompleter *autocompleter = [NSEntityDescription insertNewObjectForEntityForName:@"Autocompleter" inManagedObjectContext:context];
    autocompleter.siteID = siteID;
    return autocompleter;
}

- (void)deleteUserAutocompletesForAutocompleter:(Autocompleter *)autocompleter
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    for (UserAutocomplete *userAutocomplete in autocompleter.userAutocompletes) {
        [context deleteObject:[context objectWithID:userAutocomplete.objectID]];
    }
}

- (void)updateUserAutocompletesForSiteID:(NSNumber *)siteID suggestions:(NSArray *)suggestions
{
    Autocompleter *autocompleter = [self retrieveAutocompleterForSiteID:siteID];

    if (autocompleter) {
        [self deleteUserAutocompletesForAutocompleter:autocompleter];
    } else {
        autocompleter = [self insertAutocompleterForSiteID:siteID];
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    for (NSDictionary *suggestion in suggestions) {
        UserAutocomplete *userAutocomplete = [NSEntityDescription insertNewObjectForEntityForName:@"UserAutocomplete" inManagedObjectContext:context];
        userAutocomplete.username = [suggestion stringForKey:@"user_login"];
        userAutocomplete.displayName = [suggestion stringForKey:@"display_name"];
        userAutocomplete.imageURL = [NSURL URLWithString:[suggestion stringForKey:@"image_URL"]];
        userAutocomplete.autocompleter = autocompleter;
    }

    NSError *error;
    if (![context save:&error]) {
        DDLogError(@"Can't save UserAutocompletes for site %@, error: %@", siteID, error);
    } else {
        // send the siteID with the notification so it could be filtered out
        [[NSNotificationCenter defaultCenter] postNotificationName:SuggestionListUpdatedNotification object:siteID];
    }
}

- (BOOL)shouldShowSuggestionsForSiteID:(NSNumber *)siteID
{
    if (!siteID) {
        return NO;
    }

    // if the device is offline
    if (![WordPressAppDelegate shared].connectionAvailable) {
        return NO;
    }
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSFetchRequest *request = UserAutocomplete.fetchRequest;
    NSError *error;
    NSUInteger count = [context countForFetchRequest:request error:&error];
        
    // if there is nothing to show
    if (count == 0) {
        return NO;
    }
    
    // if the site is not hosted on WordPress.com
    BlogService *service            = [[BlogService alloc] initWithManagedObjectContext:context];
    Blog *blog                      = [service blogByBlogId:siteID];
    return [blog supports:BlogFeatureMentions];
}

@end
