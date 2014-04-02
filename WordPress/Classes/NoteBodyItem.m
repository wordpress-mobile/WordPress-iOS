#import "NoteBodyItem.h"
#import "NoteAction.h"
#import "NSDictionary+SafeExpectations.h"



@interface NoteBodyItem ()
@property (nonatomic, strong) NSDictionary	*rawItem;
@property (nonatomic, strong) NoteAction	*action;
@end


@implementation NoteBodyItem

- (NSString *)headerHtml
{
	return [self.rawItem stringForKey:@"header"];
}

- (NSString *)headerText
{
	return [self.rawItem stringForKey:@"header_text"];
}

- (NSString *)headerLink
{
	return [self.rawItem stringForKey:@"header_link"];
}

- (NSString *)bodyHtml
{
	return [self.rawItem stringForKey:@"html"];
}

- (NSURL *)iconURL
{
	NSString *rawURL = [self.rawItem stringForKey:@"icon"];
	if (rawURL.length == 0) {
		return nil;
	}
	
	rawURL = [rawURL stringByReplacingOccurrencesOfString:@"s=256" withString:@"s=160"];
	return [NSURL URLWithString:rawURL];
}

- (CGSize)iconSize
{
	NSInteger height = [[self.rawItem numberForKey:@"icon_height"] intValue];
	NSInteger width  = [[self.rawItem numberForKey:@"icon_width"] intValue];
	
	return CGSizeMake(width, height);
}

- (NoteAction *)action
{
	if (_action) {
		return _action;
	}
	
	NSDictionary *rawAction = [self.rawItem dictionaryForKey:@"action"];
	if (rawAction) {
		_action = [NoteAction parseAction:rawAction];
	}
	
	return _action;
}

+ (NSArray *)parseItems:(NSArray *)rawItems
{
	NSMutableArray *parsed = [NSMutableArray array];
	for (NSDictionary *rawItem in rawItems)
	{
		NoteBodyItem *item = [NoteBodyItem new];
		item.rawItem = rawItem;
		[parsed addObject:item];
	}
	
	return parsed;
}

@end
