#import "OriginalSiteAttributionView.h"
#import "WordPress-Swift.h"

@implementation OriginalSiteAttributionView

- (void)reset
{
    self.attributedText = nil;
}

- (void)setPostAttributionWithGravatar:(NSURL *)avatarURL
                             forAuthor:(NSString *)authorName
                                  blog:(NSString *)blogName
{
    [self setSiteAttributionWithBlavatar:avatarURL forBlog:blogName];
}

- (void)setSiteAttributionWithBlavatar:(NSURL *)blavatarURL
                               forBlog:(NSString *)blogName
{
    if (!blogName) {
        [self reset];
        return;
    }

    NSString *pattern = NSLocalizedString(@"Visit %@ for more",
                                          @"A call to action to visit the specified blog.  The '%@' characters are a placholder for the blog name.");
    NSString *str = [NSString stringWithFormat:pattern, blogName];
    NSDictionary *attributes = [WPStyleGuide siteAttributionParagraphAttributes];

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:str attributes:attributes];
    NSRange range = [str rangeOfString:blogName];
    UIFont *font = [WPFontManager openSansItalicFontOfSize:[WPStyleGuide originalAttributionFontSize]];
    [attributedString addAttribute:NSFontAttributeName value:font range:range];
    
    self.attributedText = attributedString;
    [self invalidateIntrinsicContentSize];
}

@end
