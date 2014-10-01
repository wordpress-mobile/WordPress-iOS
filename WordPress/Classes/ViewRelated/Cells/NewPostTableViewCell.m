#import "NewPostTableViewCell.h"
#import "Post.h"

@implementation NewPostTableViewCell

+ (BOOL)shortDateString
{
    return NO;
}

+ (UIColor *)statusColorForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    Post *post = (Post *)contentProvider;

    if (post.remoteStatus == AbstractPostRemoteStatusSync) {
        if ([post.status isEqualToString:@"pending"]) {
            return [UIColor lightGrayColor];
        } else if ([post.status isEqualToString:@"draft"]) {
            return [WPStyleGuide jazzyOrange];
        }

        return [UIColor blackColor];
    }

    if (post.remoteStatus == AbstractPostRemoteStatusPushing) {
        return [WPStyleGuide newKidOnTheBlockBlue];
    } else if (post.remoteStatus == AbstractPostRemoteStatusFailed) {
        return [WPStyleGuide fireOrange];
    }

    return [WPStyleGuide jazzyOrange];
}

@end
