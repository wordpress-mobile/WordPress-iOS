/*
 * StatsNoResultsCell.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsNoResultsCell.h"

static CGFloat const CellPadding = 10.0f;

@implementation StatsNoResultsCell

+ (CGFloat)heightForRow {
    return 45.0f;
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
            boldMessage = @"No top posts or pages.";
            description = @"This panel shows your most viewed posts and pages.";
            break;
        case StatsSectionViewsByCountry:
            description = @"No posts viewed.";
            break;
        case StatsSectionClicks:
            boldMessage = @"No clicks recorded.";
            description = @"\"Clicks\" are viewers clicking outbound links on your site.";
            break;
        case StatsSectionReferrers:
            boldMessage = @"No referrers.";
            description = @"A referrer is a click from another site that links to yours.";
            break;
        case StatsSectionSearchTerms:
            boldMessage = @"No search terms.";
            description = @"Search terms are words or phrases users find you with when they search.";
            break;
        default:
            break;
    }
    NSString *localizedBoldString = NSLocalizedString(boldMessage, nil);
    NSString *localizedDescriptionString = NSLocalizedString(description, nil);
    NSString *completeString = [NSString stringWithFormat:@"%@ %@",localizedBoldString,localizedDescriptionString];
    
    NSDictionary *defaultAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[WPStyleGuide subtitleFont], NSFontAttributeName, nil];
    NSDictionary *boldAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[WPStyleGuide subtitleFontBold], NSFontAttributeName, nil];
    NSMutableAttributedString *noResultsAttributedString = [[NSMutableAttributedString alloc] initWithString:completeString attributes:defaultAttributes];
    [noResultsAttributedString setAttributes:boldAttributes range:NSMakeRange(0, localizedBoldString.length)];
    
    label.attributedText = noResultsAttributedString;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    
    CGRect insetFrame = CGRectInset(CGRectMake(0, 0, self.contentView.frame.size.width, [StatsNoResultsCell heightForRow]), CellPadding, 0);
    CGRect labelRect = [noResultsAttributedString boundingRectWithSize:insetFrame.size options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    label.frame = (CGRect) {
        .origin = insetFrame.origin,
        .size = labelRect.size
    };
    
    [self.contentView addSubview:label];
}

- (void)prepareForReuse {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
