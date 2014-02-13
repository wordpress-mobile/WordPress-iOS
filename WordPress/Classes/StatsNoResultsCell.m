/*
 * StatsNoResultsCell.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsNoResultsCell.h"

static CGFloat const CellPadding = 15.0f;

@interface StatsNoResultsCell ()

@property (nonatomic, weak) UILabel *noStatsDescriptionLabel;

@end

@implementation StatsNoResultsCell

+ (CGFloat)heightForRow {
    return 60.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)configureForSection:(StatsSection)section {
    UILabel *label = [[UILabel alloc] init];
    NSString *boldMessage;
    NSString *description;

    switch (section) {
        case StatsSectionTopPosts:
            boldMessage = NSLocalizedString(@"No top posts or pages.", @"");
            description = NSLocalizedString(@"This panel shows your most viewed posts and pages.", @"");
            break;
        case StatsSectionViewsByCountry:
            description = NSLocalizedString(@"No posts viewed.", @"");
            break;
        case StatsSectionClicks:
            boldMessage = NSLocalizedString(@"No clicks recorded.", @"");
            description = NSLocalizedString(@"\"Clicks\" are viewers clicking outbound links on your site.", @"");
            break;
        case StatsSectionReferrers:
            boldMessage = NSLocalizedString(@"No referrers.", @"");
            description = NSLocalizedString(@"A referrer is a click from another site that links to yours.", @"");
            break;
        case StatsSectionSearchTerms:
            boldMessage = NSLocalizedString(@"No search terms.", @"");
            description = NSLocalizedString(@"Search terms are words or phrases users find you with when they search.", @"");
            break;
        default:
            break;
    }
    NSString *localizedBoldString = boldMessage;
    NSString *localizedDescriptionString = description;
    NSString *completeString = [NSString stringWithFormat:@"%@ %@", localizedBoldString, localizedDescriptionString];
    
    NSDictionary *defaultAttributes = [WPStyleGuide regularTextAttributes];
    NSDictionary *boldAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[WPStyleGuide regularTextFontBold], NSFontAttributeName, nil];
    NSMutableAttributedString *noResultsAttributedString = [[NSMutableAttributedString alloc] initWithString:completeString attributes:defaultAttributes];
    [noResultsAttributedString setAttributes:boldAttributes range:NSMakeRange(0, localizedBoldString.length)];
    
    label.attributedText = noResultsAttributedString;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.textColor = [WPStyleGuide littleEddieGrey];
    label.opaque = YES;
    label.backgroundColor = [UIColor whiteColor];
    
    self.noStatsDescriptionLabel = label;
    [self.contentView addSubview:label];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect insetFrame = CGRectInset(CGRectMake(0, 0, self.contentView.frame.size.width, [StatsNoResultsCell heightForRow]), CellPadding, 0);
    CGRect labelRect = [self.noStatsDescriptionLabel.attributedText boundingRectWithSize:insetFrame.size options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    self.noStatsDescriptionLabel.frame = (CGRect) {
        .origin = insetFrame.origin,
        .size = labelRect.size
    };
}

- (void)prepareForReuse {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
