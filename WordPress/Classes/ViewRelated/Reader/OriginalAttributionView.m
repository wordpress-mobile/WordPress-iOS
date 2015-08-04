#import "OriginalAttributionView.h"

#import "UIImageView+Gravatar.h"
#import "WordPress-Swift.h"

static NSString * const GravatarImageName = @"gravatar-reader";
static NSString * const BlavatarImageName = @"post-blavatar-placeholder";

@interface OriginalAttributionView()
@property (nonatomic, weak) IBOutlet CircularImageView *imageView;
@property (nonatomic, weak) IBOutlet RichTextView *richTextView;
@property (nonatomic, strong) NSURL *authorURL;
@property (nonatomic, strong) NSURL *blogURL;
@end

@implementation OriginalAttributionView

#pragma mark - LifeCycle Methods

- (CGSize)intrinsicContentSize
{
    if ([self.richTextView.textStorage length] == 0) {
        return [super intrinsicContentSize];
    }
    return [self sizeThatFits:self.frame.size];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat textViewXOffset = CGRectGetMinX(self.richTextView.frame);
    CGSize adjustedSize = CGSizeMake(size.width - textViewXOffset, CGFLOAT_MAX);
    CGFloat height = [self.richTextView sizeThatFits:adjustedSize].height;
    height = MAX(height, CGRectGetMaxY(self.imageView.frame));
    return CGSizeMake(size.width, height);
}


#pragma mark - Instance Methods

- (void)reset
{
    self.imageView.shouldRoundCorners = YES;
    [self.imageView setImage:[UIImage imageNamed:GravatarImageName]];
    self.richTextView.attributedText = [NSAttributedString new];
    self.authorURL = nil;
    self.blogURL = nil;
    [self invalidateIntrinsicContentSize];
}

- (NSString *)originalPostAttributionForAuthor:(NSString *)authorName andBlog:(NSString *)blogName
{
    NSString *attribution;

    if (authorName && blogName) {
        NSString *pattern = NSLocalizedString(@"Originally posted by %@ on %@",
                                              @"Used to attribute a post back to its original author and blog.  The '%@' characters are placholders for the author's name, and the author's blog repsectively.");
        attribution = [NSString stringWithFormat:pattern, authorName, blogName];
    } else if (authorName) {
        NSString *pattern = NSLocalizedString(@"Originally posted by %@",
                                              @"Used to attribute a post back to its original author.  The '%@' characters are a placholder for the author's name.");
        attribution = [NSString stringWithFormat:pattern, authorName];
    } else if (blogName) {
        NSString *pattern = NSLocalizedString(@"Originally posted on %@",
                                              @"Used to attribute a post back to its original blog.  The '%@' characters are a placholder for the blog name.");
        attribution = [NSString stringWithFormat:pattern, blogName];
    }

    return attribution;
}


#pragma mark - Accessors

- (void)setPostAttributionWithGravatar:(NSURL *)avatarURL
                             forAuthor:(NSString *)authorName
                               blog:(NSString *)blogName
{
    self.imageView.shouldRoundCorners = YES;
    [self.imageView setImageWithURL:avatarURL placeholderImage:[UIImage imageNamed:GravatarImageName]];

    NSString *str = [self originalPostAttributionForAuthor:authorName andBlog:blogName];
    NSDictionary *attributes = [WPStyleGuide originalAttributionParagraphAttributes];
    self.richTextView.attributedText = [[NSAttributedString alloc] initWithString:str attributes:attributes];
    [self invalidateIntrinsicContentSize];
}

- (void)setSiteAttributionWithBlavatar:(NSURL *)blavatarURL
                               forBlog:(NSString *)blogName
{
    self.imageView.shouldRoundCorners = NO;
    [self.imageView setImageWithURL:blavatarURL placeholderImage:[UIImage imageNamed:BlavatarImageName]];

    NSString *pattern = NSLocalizedString(@"Visit %@",
                                          @"A call to action to visit the specified blog.  The '%@' characters are a placholder for the blog name.");
    NSString *str = [NSString stringWithFormat:pattern, blogName];
    NSDictionary *attributes = [WPStyleGuide siteAttributionParagraphAttributes];

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:str attributes:attributes];
    NSRange range = [str rangeOfString:blogName];
    UIFont *font = [WPFontManager openSansItalicFontOfSize:[WPStyleGuide originalAttributionFontSize]];
    [attributedString addAttribute:NSFontAttributeName value:font range:range];

    self.richTextView.attributedText = attributedString;
    [self invalidateIntrinsicContentSize];
}

@end
