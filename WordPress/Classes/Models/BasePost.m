#import "BasePost.h"
#import "Media.h"
#import "NSMutableDictionary+Helpers.h"
#import "ContextManager.h"
#import <WordPressShared/NSString+Util.h>
#import <WordPressShared/NSString+XMLExtensions.h>
#import "NSString+Helpers.h"

static const NSUInteger PostDerivedSummaryLength = 150;

@implementation BasePost

@dynamic authorID;
@dynamic author;
@dynamic authorAvatarURL;
@dynamic content;
@dynamic date_created_gmt;
@dynamic postID;
@dynamic postTitle;
@dynamic password;
@dynamic remoteStatusNumber;
@dynamic permaLink;
@dynamic mt_excerpt;
@dynamic wp_slug;
@dynamic suggested_slug;
@dynamic post_thumbnail;
@dynamic pathForDisplayImage;

@synthesize isFeaturedImageChanged;

+ (NSString *)summaryFromContent:(NSString *)string
{
    string = [NSString makePlainText:string];
    string = [NSString stripShortcodesFromString:string];
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
    return [string stringByEllipsizingWithMaxLength:PostDerivedSummaryLength preserveWords:YES];
}

- (NSDate *)dateCreated
{
    return self.date_created_gmt;
}

- (void)setDateCreated:(NSDate *)localDate
{
    self.date_created_gmt = localDate;
}

- (void)findComments
{
}


#pragma mark - PostContentProvider protocol

- (NSString *)titleForDisplay
{
    NSString *title = [self.postTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (title == nil || ([title length] == 0)) {
        title = NSLocalizedString(@"(no title)", @"");
    }
    return [title stringByDecodingXMLCharacters];
}

- (NSString *)authorForDisplay
{
    return self.author;
}

- (NSString *)blogNameForDisplay
{
    return @"";
}

- (NSString *)contentForDisplay
{
    return self.content;
}

- (NSString *)contentPreviewForDisplay
{
    return self.content;
}

- (NSString *)gravatarEmailForDisplay
{
    return nil;
}

- (NSURL *)avatarURLForDisplay
{
    return nil;
}

- (NSDate *)dateForDisplay
{
    return [self dateCreated];
}

- (NSString *)statusForDisplay
{
    return [self valueForKey:@"status"];
}

@end
