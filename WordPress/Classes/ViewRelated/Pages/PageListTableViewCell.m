#import "PageListTableViewCell.h"
#import "WPStyleGuide+Pages.h"
#import "WordPress-Swift.h"

@import Gridicons;


static CGFloat const PageListTableViewCellTagLabelRadius = 2.0;
static CGFloat const FeaturedImageSize = 120.0;

@interface PageListTableViewCell()

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *timestampLabel;
@property (nonatomic, strong) IBOutlet UILabel *badgesLabel;
@property (strong, nonatomic) IBOutlet CachedAnimatedImageView *featuredImageView;
@property (nonatomic, strong) IBOutlet UIButton *menuButton;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *labelsContainerTrailing;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *leadingContentConstraint;

@property (nonatomic, strong) ImageLoader *featuredImageLoader;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation PageListTableViewCell {
    CGFloat _indentationWidth;
    NSInteger _indentationLevel;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self applyStyles];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self applyStyles];
    [self.featuredImageLoader prepareForReuse];
    [self setNeedsDisplay];
}

- (ImageLoader *)featuredImageLoader
{
    if (_featuredImageLoader == nil) {
        _featuredImageLoader = [[ImageLoader alloc] initWithImageView:self.featuredImageView
                                                          gifStrategy:GIFStrategyLargeGIFs];
    }
    return _featuredImageLoader;
}

- (NSDateFormatter *)dateFormatter
{
    if (_dateFormatter == nil) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.doesRelativeDateFormatting = YES;
        _dateFormatter.dateStyle = NSDateFormatterNoStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return _dateFormatter;
}

- (CGFloat)indentationWidth
{
    return _indentationWidth;
}

- (NSInteger)indentationLevel
{
    return _indentationLevel;
}

- (void)setIndentationWidth:(CGFloat)indentationWidth
{
    _indentationWidth = indentationWidth;
    [self updateLeadingContentConstraint];
}

- (void)setIndentationLevel:(NSInteger)indentationLevel
{
    _indentationLevel = indentationLevel;
    [self updateLeadingContentConstraint];
}


#pragma mark - Accessors

- (void)setPost:(AbstractPost *)post
{
    [super setPost:post];
    [self configureTitle];
    [self configureForStatus];
    [self configureBadges];
    [self configureFeaturedImage];
}

#pragma mark - Configuration

- (void)applyStyles
{
    [WPStyleGuide configureTableViewCell:self];
    [WPStyleGuide configureLabel:self.timestampLabel textStyle:UIFontTextStyleSubheadline];
    [WPStyleGuide configureLabel:self.badgesLabel textStyle:UIFontTextStyleSubheadline];

    self.titleLabel.font = [WPStyleGuide notoBoldFontForTextStyle:UIFontTextStyleHeadline];
    self.titleLabel.adjustsFontForContentSizeCategory = YES;
    
    self.titleLabel.textColor = [UIColor murielText];
    self.badgesLabel.textColor = [UIColor murielTextSubtle];
    self.menuButton.tintColor = [UIColor murielTextSubtle];
    [self.menuButton setImage:[Gridicon iconOfType:GridiconTypeEllipsis] forState:UIControlStateNormal];

    self.backgroundColor = [UIColor murielNeutral5];
    self.contentView.backgroundColor = [UIColor murielNeutral5];
    
    self.featuredImageView.layer.cornerRadius = PageListTableViewCellTagLabelRadius;
}

- (void)configureTitle
{
    AbstractPost *post = [self.post hasRevision] ? [self.post revision] : self.post;
    self.titleLabel.text = [post titleForDisplay] ?: [NSString string];
}

- (void)configureForStatus
{
    if (self.post.isFailed && !self.post.hasLocalChanges) {
        self.titleLabel.textColor = [UIColor murielError];
        self.menuButton.tintColor = [UIColor murielError];
    }
}

- (void)updateLeadingContentConstraint
{
    self.leadingContentConstraint.constant = (CGFloat)_indentationLevel * _indentationWidth;
}

- (void)configureBadges
{
    Page *page = (Page *)self.post;

    NSMutableArray<NSString *> *badges = [NSMutableArray new];

    NSString *timestamp = [self.post isScheduled] ? [self.dateFormatter stringFromDate:self.post.dateCreated] : [self.post.dateCreated mediumString];
    [badges addObject:timestamp];
    
    if (page.hasPrivateState) {
        [badges addObject:NSLocalizedString(@"Private", @"Title of the Private Badge")];
    } else if (page.hasPendingReviewState) {
        [badges addObject:NSLocalizedString(@"Pending review", @"Title of the Pending Review Badge")];
    }
    
    if (page.hasLocalChanges) {
        [badges addObject:NSLocalizedString(@"Local changes", @"Title of the Local Changes Badge")];
    }
    
    self.badgesLabel.text = [badges componentsJoinedByString:@" · "];
}

- (void)configureFeaturedImage
{
    Page *page = (Page *)self.post;
    
    BOOL hideFeaturedImage = page.featuredImage == nil;
    self.featuredImageView.hidden = hideFeaturedImage;
    self.labelsContainerTrailing.active = !hideFeaturedImage;
    
    if (!hideFeaturedImage) {
        [self.featuredImageLoader loadImageFromMedia:page.featuredImage
                                       preferredSize:CGSizeMake(FeaturedImageSize, FeaturedImageSize)
                                         placeholder:nil
                                             success:nil
                                               error:^(NSError *error) {
                                                   DDLogError(@"Failed to load the media: %@", error);
                                               }];
        
    }
}

@end
