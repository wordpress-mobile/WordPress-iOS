#import "WPAccount.h"
#import "WordPressData-Swift.h"
@import WordPressKit;

@implementation WPAccount

@dynamic username;
@dynamic blogs;
@dynamic defaultBlog;
@dynamic primaryBlogID;
@dynamic uuid;
@dynamic dateCreated;
@dynamic email;
@dynamic emailVerified;
@dynamic displayName;
@dynamic userID;
@dynamic avatarURL;
@dynamic settings;
@synthesize _private_wordPressComRestApi;
@synthesize cachedToken;

#pragma mark - NSManagedObject subclass methods

- (void)prepareForDeletion
{
    // Only do these deletions in the primary context (no parent)
    if (self.managedObjectContext.concurrencyType != NSMainQueueConcurrencyType) {
        return;
    }

    [_private_wordPressComRestApi invalidateAndCancelTasks];
    _private_wordPressComRestApi = nil;
    self.authToken = nil;
}

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];
    _private_wordPressComRestApi = nil;
    self.cachedToken = nil;
}

+ (NSString *)entityName
{
    return @"Account";
}

#pragma mark - Custom accessors

- (void)setUsername:(NSString *)username
{
    NSString *previousUsername = self.username;

    BOOL usernameChanged = ![previousUsername isEqualToString:username];
    NSString *authToken = nil;

    if (usernameChanged) {
        authToken = self.authToken;
        self.authToken = nil;
    }

    [self willChangeValueForKey:@"username"];
    [self setPrimitiveValue:username forKey:@"username"];
    [self didChangeValueForKey:@"username"];

    if (usernameChanged) {
        self.authToken = authToken;
    }
}

- (BOOL)hasAtomicSite {
    for (Blog *blog in self.blogs) {
        if ([blog isAtomic]) {
            return YES;
        }
    }
    return NO;
}

@end
