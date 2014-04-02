#import "NoteAction.h"
#import "NSDictionary+SafeExpectations.h"



@interface NoteAction ()
@property (nonatomic, strong) NSDictionary *rawAction;
@end


@implementation NoteAction

- (NSString *)type
{
	return [self.rawAction stringForKey:@"type"];
}

- (NSDictionary *)parameters
{
	return [self.rawAction dictionaryForKey:@"params"];
}

- (NSString *)blogDomain
{
	return [self.parameters stringForKey:@"blog_domain"];
}

- (NSString *)blogID
{
	return [self.parameters stringForKey:@"blog_id"];
}

- (NSString *)blogTitle
{
	return [self.parameters stringForKey:@"blog_title"];
}

- (NSURL *)blogURL
{
	NSString *rawURL = [self.parameters stringForKey:@"blog_url"];
	return rawURL.length ? [NSURL URLWithString:rawURL] : nil;
}

- (NSNumber *)siteID
{
	return [self.parameters numberForKey:@"site_id"];
}

- (BOOL)following
{
	return [[self.parameters numberForKey:@"is_following"] boolValue];
}

- (void)setFollowing:(BOOL)following
{
	NSMutableDictionary *updatedAction	= [self.rawAction mutableCopy];
	NSMutableDictionary *updatedParams	= [self.parameters mutableCopy];
	updatedParams[@"is_following"]		= @(following);
	updatedAction[@"params"]			= updatedParams;
	
	self.rawAction = updatedAction;
}

- (NSString *)statsSource
{
	return [self.parameters stringForKey:@"stat-source"];
}

+ (NoteAction *)parseAction:(NSDictionary *)dict
{
	NoteAction *action = [NoteAction new];
	action.rawAction = dict;
	return action;
}

@end
