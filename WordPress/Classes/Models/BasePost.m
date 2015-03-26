#import "BasePost.h"
#import "Media.h"
#import "NSMutableDictionary+Helpers.h"
#import "ContextManager.h"
#import "WPComLanguages.h"
#import <WordPress-iOS-Shared/NSString+XMLExtensions.h>
#import <WordPress-iOS-Shared/NSString+Util.h>
#import "NSString+Helpers.h"

static const NSUInteger PostDerivedSummaryLength = 150;

@interface BasePost(ProtectedMethods)
+ (NSString *)titleForStatus:(NSString *)status;
+ (NSString *)statusForTitle:(NSString *)title;
@end

@implementation BasePost

@dynamic author;
@dynamic authorAvatarURL;
@dynamic content;
@dynamic date_created_gmt;
@dynamic postID;
@dynamic postTitle;
@dynamic status;
@dynamic password;
@dynamic remoteStatusNumber;
@dynamic permaLink;
@dynamic mt_excerpt;
@dynamic mt_text_more;
@dynamic wp_slug;
@dynamic post_thumbnail;

@synthesize isFeaturedImageChanged;

+ (NSString *)titleForStatus:(NSString *)status
{
    if ([status isEqualToString:@"draft"]) {
        return NSLocalizedString(@"Draft", @"Name for the status of a draft post.");

    } else if ([status isEqualToString:@"pending"]) {
        return NSLocalizedString(@"Pending review", @"Name for the status of a post pending review.");

    } else if ([status isEqualToString:@"private"]) {
        return NSLocalizedString(@"Privately published", @"Name for the status of a post that is marked private.");

    } else if ([status isEqualToString:@"publish"]) {
        return NSLocalizedString(@"Published", @"Name for the status of a published post.");

    } else if ([status isEqualToString:@"trash"]) {
        return NSLocalizedString(@"Trashed", @"Name for the status of a trashed post");

    } else if ([status isEqualToString:@"future"]) {
        return NSLocalizedString(@"Scheduled", @"Name for the status of a scheduled post");
    }

    return status;
}

+ (NSString *)statusForTitle:(NSString *)title
{
    if ([title isEqualToString:NSLocalizedString(@"Draft", @"")]) {
        return @"draft";
    } else if ([title isEqualToString:NSLocalizedString(@"Pending review", @"")]) {
        return @"pending";
    } else if ([title isEqualToString:NSLocalizedString(@"Privately published", @"")]) {
        return @"private";
    } else if ([title isEqualToString:NSLocalizedString(@"Published", @"")]) {
        return @"publish";
    } else if ([title isEqualToString:NSLocalizedString(@"Trashed", @"")]) {
        return @"trash";
    } else if ([title isEqualToString:NSLocalizedString(@"Scheduled", @"")]) {
        return @"future";
    }

    return title;
}

+ (NSString *)makePlainText:(NSString *)string
{
    NSCharacterSet *charSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    return [[[string stringByStrippingHTML] stringByDecodingXMLCharacters] stringByTrimmingCharactersInSet:charSet];
}

+ (NSString *)createSummaryFromContent:(NSString *)string
{
    string = [self makePlainText:string];
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
    return [string stringByEllipsizingWithMaxLength:PostDerivedSummaryLength preserveWords:YES];
}

- (NSArray *)availableStatuses
{
    return @[NSLocalizedString(@"Draft", @""),
             NSLocalizedString(@"Pending review", @""),
             NSLocalizedString(@"Private", @""),
             NSLocalizedString(@"Published", @"")];
}

- (BOOL)hasRemote
{
    return ((self.postID != nil) && ([self.postID longLongValue] > 0));
}

- (void)remove
{
    if (self.remoteStatus == AbstractPostRemoteStatusPushing || self.remoteStatus == AbstractPostRemoteStatusLocal) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadCancelled" object:self];
    }
    
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext deleteObject:self];
    }];

}

- (void)save
{
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

- (NSString *)statusTitle
{
    return [BasePost titleForStatus:self.status];
}

- (void)setStatusTitle:(NSString *)aTitle
{
    self.status = [BasePost statusForTitle:aTitle];
}

- (BOOL)isScheduled
{
    return ([self.status isEqualToString:@"publish"] && [self.dateCreated compare:[NSDate date]] == NSOrderedDescending);
}

- (AbstractPostRemoteStatus)remoteStatus
{
    return (AbstractPostRemoteStatus)[[self remoteStatusNumber] intValue];
}

- (void)setRemoteStatus:(AbstractPostRemoteStatus)aStatus
{
    [self setRemoteStatusNumber:[NSNumber numberWithInt:aStatus]];
}

- (void)upload
{
}

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus
{
    switch ([remoteStatus intValue]) {
        case AbstractPostRemoteStatusPushing:
            return NSLocalizedString(@"Uploading", @"");
        case AbstractPostRemoteStatusFailed:
            return NSLocalizedString(@"Failed", @"");
        case AbstractPostRemoteStatusSync:
            return NSLocalizedString(@"Posts", @"");
        default:
            return NSLocalizedString(@"Local", @"");
    }
}

- (NSString *)remoteStatusText
{
    return [BasePost titleForRemoteStatus:self.remoteStatusNumber];
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

#pragma mark - WPContentViewProvider protocol

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
    if (self.remoteStatus == AbstractPostRemoteStatusSync) {
        if ([self.status isEqualToString:@"publish"]) {
            if (self.dateCreated == [self.dateCreated laterDate:[NSDate date]]) {
                // XML-RPC returns scheduled posts with a status of `publish` so
                // the extra check is needed.
                return [BasePost titleForStatus:@"future"];
            }
            return [NSString string];
        }
        return self.statusTitle;
    }

    NSString *statusText = [AbstractPost titleForRemoteStatus:@((int)self.remoteStatus)];
    if ([statusText isEqualToString:NSLocalizedString(@"Uploading", nil)]) {
        if ([WPComLanguages isRightToLeft]) {
            return [NSString stringWithFormat:@"…%@", statusText];
        }

        return [NSString stringWithFormat:@"%@…", statusText];
    }
    return statusText;
}

@end
