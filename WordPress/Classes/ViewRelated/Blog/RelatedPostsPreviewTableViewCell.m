#import "RelatedPostsPreviewTableViewCell.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"

static CGFloat HorizontalMargin = 10.0;
static CGFloat VerticalMargin = 5.0;
static CGFloat ImageHeight = 96.0;

@interface RelatedPostsPreview : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *site;
@property (nonatomic, copy) NSString *imageName;

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

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.textColor = [WPStyleGuide darkGrey];
        _titleLabel.font = [WPFontManager systemSemiBoldFontOfSize:14.0];
        _titleLabel.numberOfLines = 0;
    }
    _titleLabel.text = self.title;
    return _titleLabel;
}

- (UILabel *)siteLabel
{
    if (!_siteLabel) {
        _siteLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _siteLabel.textColor = [WPStyleGuide greyDarken20];
        _siteLabel.font = [WPFontManager systemItalicFontOfSize:11.0];
        _siteLabel.numberOfLines = 0;
    }
    _siteLabel.text = self.site;
    return _siteLabel;
}

- (UIImageView *)imageView
{
    if (!_imageView){
        _imageView = [[UIImageView alloc] init];
        [_imageView setContentMode:UIViewContentModeScaleAspectFill];
        [_imageView setClipsToBounds:YES];
    }
    _imageView.image = [UIImage imageNamed:self.imageName];
    return _imageView;
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
        _headerLabel.font = [WPFontManager systemSemiBoldFontOfSize:11.0];
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
            [self.contentView addSubview:relatedPostPreview.imageView];
            [self.contentView addSubview:relatedPostPreview.titleLabel];
            [self.contentView addSubview:relatedPostPreview.siteLabel];
        }
    }
    return self;
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

