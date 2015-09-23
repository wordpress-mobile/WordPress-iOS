#import "RelatedPostsPreviewTableViewCell.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"

static CGFloat HorizontalMargin = 10.0;
static CGFloat VerticalMargin = 5.0;
static CGFloat ImageHeight = 96.0;

@interface RelatedPostsPreview : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *site;
@property (nonatomic, strong) NSString *imageName;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *siteLabel;
@property (nonatomic, strong) UIImageView *imageView;

- (instancetype)initWithTitle:(NSString *)title site:(NSString *)site imageName:(NSString *)imageName;

@end

@implementation RelatedPostsPreview

- (instancetype)initWithTitle:(NSString *)title site:(NSString *)site imageName:(NSString *)imageName
{
    self = [super init];
    if (self) {
        _title = title;
        _site = site;
        _imageName = imageName;
    }
    
    return self;
}

@end

@interface RelatedPostsPreviewTableViewCell()

@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) NSArray *previewPosts;

@end;

@implementation RelatedPostsPreviewTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _enabledHeader = YES;
        _enabledImages = YES;
        _headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _headerLabel.text = NSLocalizedString(@"Related Posts", @"Label for Related Post header preview");
        _headerLabel.textColor = [WPStyleGuide greyDarken20];
        _headerLabel.font = [WPFontManager openSansSemiBoldFontOfSize:11.0];
        [self.contentView addSubview:_headerLabel];
        
        RelatedPostsPreview *preview1 = [[RelatedPostsPreview alloc] initWithTitle:NSLocalizedString(@"Big iPhone/iPad Update Now Available", @"Text for related post cell preview")
                                                                              site:NSLocalizedString(@"in \"Mobile\"", @"Text for related post cell preview")
                                                                         imageName:@"relatedPostsPreview1"];
        RelatedPostsPreview *preview2 = [[RelatedPostsPreview alloc] initWithTitle:NSLocalizedString(@"The WordPress for Android App Gets a Big Facelift", @"Text for related post cell preview")
                                                                              site:NSLocalizedString(@"in \"Apps\"", @"Text for related post cell preview")
                                                                         imageName:@"relatedPostsPreview2"];
        RelatedPostsPreview *preview3 = [[RelatedPostsPreview alloc] initWithTitle:NSLocalizedString(@"Upgrade Focus: VideoPress For Weddings", @"Text for related post cell preview")
                                                                              site:NSLocalizedString(@"in \"Upgrade\"", @"Text for related post cell preview")
                                                                         imageName:@"relatedPostsPreview3"];

        _previewPosts = @[preview1, preview2, preview3];
        
        for (RelatedPostsPreview *relatedPostPreview in _previewPosts) {
            relatedPostPreview.imageView = [[self class ] imageViewWithImageNamed:relatedPostPreview.imageName];
            [self.contentView addSubview:relatedPostPreview.imageView];
            relatedPostPreview.titleLabel = [[self class] titleLabelWithText:relatedPostPreview.title];
            [self.contentView addSubview:relatedPostPreview.titleLabel];
            relatedPostPreview.siteLabel = [[self class] siteLabelWithText:relatedPostPreview.site];
            [self.contentView addSubview:relatedPostPreview.siteLabel];
        }
    }
    return self;
}

+ (UILabel *)titleLabelWithText:(NSString *)text
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.textColor = [WPStyleGuide darkGrey];
    label.font = [WPFontManager openSansSemiBoldFontOfSize:14.0];
    label.numberOfLines = 0;
    return label;
}

+ (UILabel *)siteLabelWithText:(NSString *)text
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.textColor = [WPStyleGuide greyDarken20];
    label.font = [WPFontManager openSansItalicFontOfSize:11.0];
    label.numberOfLines = 0;
    return label;
}

+ (UIImageView *)imageViewWithImageNamed:(NSString *)imageName
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    [imageView setContentMode:UIViewContentModeScaleAspectFill];
    [imageView setClipsToBounds:YES];
    return imageView;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.contentView.frame.size.width - (2 * HorizontalMargin);
    CGFloat height = 0;
    CGSize sizeRestriction = CGSizeMake(width, CGFLOAT_MAX);
    if (self.enabledHeader) {
        height = ceilf([self.headerLabel sizeThatFits:sizeRestriction].height);
        self.headerLabel.frame = CGRectMake(HorizontalMargin, VerticalMargin, width, height);
    } else {
        self.headerLabel.frame = CGRectZero;
    }
    UIView *referenceView = self.headerLabel;
    for (RelatedPostsPreview *relatedPostPreview in _previewPosts) {
        if (self.enabledImages) {
            relatedPostPreview.imageView.frame = CGRectMake(HorizontalMargin, CGRectGetMaxY(referenceView.frame) + (2 * VerticalMargin), width, ImageHeight);
            relatedPostPreview.imageView.hidden = NO;
            referenceView = relatedPostPreview.imageView;
        } else {
            relatedPostPreview.imageView.frame = CGRectZero;
            relatedPostPreview.imageView.hidden = YES;
        }
        
        height = ceilf([relatedPostPreview.titleLabel sizeThatFits:sizeRestriction].height);
        relatedPostPreview.titleLabel.frame = CGRectMake(HorizontalMargin, CGRectGetMaxY(referenceView.frame) + VerticalMargin, width, height);
        referenceView = relatedPostPreview.titleLabel;
        
        height = ceilf([relatedPostPreview.siteLabel sizeThatFits:sizeRestriction].height);
        relatedPostPreview.siteLabel.frame = CGRectMake(HorizontalMargin, CGRectGetMaxY(referenceView.frame), width, height);
        referenceView = relatedPostPreview.siteLabel;
    }
}

- (CGFloat)heightForWidth:(CGFloat)availableWidth
{
    CGFloat width = self.contentView.frame.size.width - (2 * HorizontalMargin);
    CGFloat height = 0;
    CGSize sizeRestriction = CGSizeMake(width, CGFLOAT_MAX);
    if (self.enabledHeader) {
        height += ceilf([self.headerLabel sizeThatFits:sizeRestriction].height) + VerticalMargin;
    }
    for (RelatedPostsPreview *relatedPostPreview in _previewPosts) {
        if (self.enabledImages) {
            height += ImageHeight + (2 * VerticalMargin);
        }
        height += ceilf([relatedPostPreview.titleLabel sizeThatFits:sizeRestriction].height) + VerticalMargin;
        height += ceilf([relatedPostPreview.siteLabel sizeThatFits:sizeRestriction].height);
    }
    height += VerticalMargin;
    
    return height;
}

@end

