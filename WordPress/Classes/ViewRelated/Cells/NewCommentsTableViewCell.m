#import "NewCommentsTableViewCell.h"
#import "Comment.h"
#import "NSString+XMLExtensions.h"

@implementation NewCommentsTableViewCell

+ (BOOL)showGravatarImage
{
    return YES;
}

+ (NSAttributedString *)titleAttributedTextForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    // combine author and title
    NSString *author = [contentProvider authorForDisplay];
    NSString *postTitle = [contentProvider titleForDisplay];
    NSString *content = [contentProvider contentPreviewForDisplay];
    if (!(postTitle.length > 0)) {
        postTitle = NSLocalizedString(@"(No Title)", nil);
    }

    /*
     The code ahead might look odd, but it's a way to retain the formatting
     we want and make the string easy to translate

     Note that we use printf modifiers because translators will be used to those
     and less likely to break them, but we do the substitutions manually so we
     can replace both the placeholders' content and their formatting.
     */
    NSString *title;
    if (content.length > 0) {
        title = NSLocalizedString(@"%1$@ on %2$@: %3$@", @"'AUTHOR on POST TITLE: COMMENT' in a comment list");
    } else {
        title = NSLocalizedString(@"%1$@ on %2$@", @"'AUTHOR on POST TITLE' in a comment list");
    }

    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:[[self class] titleAttributes]];

    NSRange authorRange = [[attributedTitle string] rangeOfString:@"%1$@"];
    if (authorRange.location != NSNotFound) {
        [attributedTitle replaceCharactersInRange:authorRange withAttributedString:[[NSAttributedString alloc] initWithString:author attributes:[[self class] titleAttributesBold]]];
    }

    NSRange postTitleRange = [[attributedTitle string] rangeOfString:@"%2$@"];
    if (postTitleRange.location != NSNotFound) {
        [attributedTitle replaceCharactersInRange:postTitleRange withAttributedString:[[NSAttributedString alloc] initWithString:postTitle attributes:[[self class] titleAttributesBold]]];
    }

    NSRange contentRange = [[attributedTitle string] rangeOfString:@"%3$@"];
    if (contentRange.location != NSNotFound) {
        [attributedTitle replaceCharactersInRange:contentRange withString:content];
    }

    return attributedTitle;
}

@end
