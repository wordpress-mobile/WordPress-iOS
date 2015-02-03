#import "BasePost.h"
#import "Media.h"
#import "NSMutableDictionary+Helpers.h"
#import "ContextManager.h"
#import "WPComLanguages.h"
#import "NSString+XMLExtensions.h"

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
        return NSLocalizedString(@"Draft", @"");
    } else if ([status isEqualToString:@"pending"]) {
        return NSLocalizedString(@"Pending review", @"");
    } else if ([status isEqualToString:@"private"]) {
        return NSLocalizedString(@"Privately published", @"");
    } else if ([status isEqualToString:@"publish"]) {
        return NSLocalizedString(@"Published", @"");
    }

    return status;
}

+ (NSString *)statusForTitle:(NSString *)title
{
    if ([title isEqualToString:NSLocalizedString(@"Draft", @"")]) {
        return @"draft";
    } else if ([title isEqualToString:NSLocalizedString(@"Pending review", @"")]) {
        return @"pending";
    } else if ([title isEqualToString:NSLocalizedString(@"Private", @"")]) {
        return @"private";
    } else if ([title isEqualToString:NSLocalizedString(@"Published", @"")]) {
        return @"publish";
    }

    return title;
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
    return [title stringByDecodingXMLCharacters];}

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
        if ([self.status isEqualToString:@"pending"]) {
            return NSLocalizedString(@"Pending", @"");
        } else if ([self.status isEqualToString:@"draft"]) {
            return self.statusTitle;
        }

        return @"";
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
