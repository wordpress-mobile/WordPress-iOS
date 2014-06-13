#import "WPStatsNoResultsCell.h"
#import "WPStyleGuide.h"

static CGFloat const CellPadding = 15.0f;
static CGFloat const MinCellHeight = 60.0f;

@interface WPStatsNoResultsCell ()

@property (nonatomic, weak) UILabel *noStatsDescriptionLabel;
@property (nonatomic, assign) StatsSection currentSection;

@end

@implementation WPStatsNoResultsCell

+ (CGFloat)heightForRowForSection:(StatsSection)section withWidth:(CGFloat)width
{
    NSAttributedString *message = [self attributedStringMessageForSection:section];
    
    CGRect insetFrame = CGRectInset(CGRectMake(0, 0, width, CGFLOAT_MAX), CellPadding, 0);
    return MAX([message boundingRectWithSize:insetFrame.size
                                 options:NSStringDrawingUsesLineFragmentOrigin
                                 context:nil].size.height + CellPadding, MinCellHeight);
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)configureForSection:(StatsSection)section
{
    self.currentSection = section;
    
    UILabel *label = [[UILabel alloc] init];
    label.attributedText = [[self class] attributedStringMessageForSection:section];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.textColor = [WPStyleGuide littleEddieGrey];
    
    self.noStatsDescriptionLabel = label;
    [self.contentView addSubview:label];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect insetFrame = CGRectInset(CGRectMake(0, 0, CGRectGetWidth(self.contentView.frame), [WPStatsNoResultsCell heightForRowForSection:self.currentSection withWidth:CGRectGetWidth(self.contentView.frame)]), CellPadding, 0);
    CGRect labelRect = [self.noStatsDescriptionLabel.attributedText boundingRectWithSize:insetFrame.size options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    self.noStatsDescriptionLabel.frame = (CGRect) {
        .origin = insetFrame.origin,
        .size = labelRect.size
    };
}

- (void)prepareForReuse
{
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

#pragma mark - Private Methods

+ (NSAttributedString *)attributedStringMessageForSection:(StatsSection)section
{
    NSString *boldMessage = [[self class] boldMessageForSection:section];
    NSString *description = [[self class] descriptionForSection:section];
    NSString *completeString = [NSString stringWithFormat:@"%@ %@", boldMessage, description];
    
    NSDictionary *defaultAttributes = [WPStyleGuide regularTextAttributes];
    NSDictionary *boldAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[WPStyleGuide regularTextFontBold], NSFontAttributeName, nil];
    NSMutableAttributedString *noResultsAttributedString = [[NSMutableAttributedString alloc] initWithString:completeString attributes:defaultAttributes];
    [noResultsAttributedString setAttributes:boldAttributes range:NSMakeRange(0, boldMessage.length)];
    
    return noResultsAttributedString;
}

+ (NSString *)boldMessageForSection:(StatsSection)section
{
    NSString *boldMessage = @"";
    
    switch (section) {
        case StatsSectionTopPosts:
            boldMessage = NSLocalizedString(@"No top posts or pages.", @"");
            break;
        case StatsSectionClicks:
            boldMessage = NSLocalizedString(@"No clicks recorded.", @"");
            break;
        case StatsSectionReferrers:
            boldMessage = NSLocalizedString(@"No referrers.", @"");
            break;
        case StatsSectionSearchTerms:
            boldMessage = NSLocalizedString(@"No search terms.", @"");
            break;
        default:
            break;
    }
    
    return boldMessage;
}

+ (NSString *)descriptionForSection:(StatsSection)section
{
    NSString *description = @"";
    
    switch (section) {
        case StatsSectionTopPosts:
            description = NSLocalizedString(@"This panel shows your most viewed posts and pages.", @"");
            break;
        case StatsSectionViewsByCountry:
            description = NSLocalizedString(@"No posts viewed.", @"");
            break;
        case StatsSectionClicks:
            description = NSLocalizedString(@"\"Clicks\" are viewers clicking outbound links on your site.", @"");
            break;
        case StatsSectionReferrers:
            description = NSLocalizedString(@"A referrer is a click from another site that links to yours.", @"");
            break;
        case StatsSectionSearchTerms:
            description = NSLocalizedString(@"Search terms are words or phrases users find you with when they search.", @"");
            break;
        default:
            break;
    }
    
    return description;
}

@end
