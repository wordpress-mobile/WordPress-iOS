#import "StatsLinkToWebviewCell.h"

static CGFloat const CellPadding = 15.0f;
static CGFloat const LabelVerticalOffset = 2.0f;

@interface StatsLinkToWebviewCell ()

@property (nonatomic, weak) UILabel *linkToWebviewLabel;

@end

@implementation StatsLinkToWebviewCell

+ (CGFloat)heightForRow {
    return 60.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.userInteractionEnabled = YES;
    }
    return self;
}

- (void)configureForSection:(StatsSection)section {
    UILabel *label = [[UILabel alloc] init];
    label.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"View web version of stats", @"Stats - Link at bottom of stats page allowing the user to open the web version of stats") attributes:[WPStyleGuide regularTextAttributes]];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.textColor = [WPStyleGuide littleEddieGrey];
    label.numberOfLines = 0;
    label.opaque = YES;
    label.backgroundColor = [UIColor whiteColor];
    [label sizeToFit];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedLabel)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.contentView addGestureRecognizer:tapGestureRecognizer];
    
    self.linkToWebviewLabel = label;
    [self.contentView addSubview:label];
}

- (void)tappedLabel
{
    if (self.onTappedLinkToWebview != nil) {
        self.onTappedLinkToWebview();
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect insetFrame = CGRectInset(CGRectMake(0, 0, self.contentView.frame.size.width, [StatsLinkToWebviewCell heightForRow]), CellPadding, 0);
    CGRect labelRect = [self.linkToWebviewLabel.attributedText boundingRectWithSize:insetFrame.size options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    CGFloat x = CGRectGetMinX(insetFrame);
    CGFloat y = floorf((CGRectGetHeight(self.contentView.frame) - CGRectGetHeight(labelRect)) / 2.0) - LabelVerticalOffset;
    
    self.linkToWebviewLabel.frame = (CGRect) {
        .origin = CGPointMake(x, y),
        .size = labelRect.size
    };
}

- (void)prepareForReuse {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
