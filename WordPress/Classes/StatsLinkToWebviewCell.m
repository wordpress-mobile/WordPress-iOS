//
//  StatsLinkToWebView.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 2/27/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsLinkToWebviewCell.h"

static CGFloat const CellPadding = 15.0f;

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

    NSDictionary *defaultAttributes = [WPStyleGuide regularTextAttributes];
    NSDictionary *colorAttributes = @{NSForegroundColorAttributeName: [WPStyleGuide newKidOnTheBlockBlue], NSFontAttributeName : [WPStyleGuide regularTextFontBold] };
    NSMutableAttributedString *noResultsAttributedString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Tap here to see the web version of stats.", @"Stats - Link at bottom of stats page allowing the user to open the web version of stats") attributes:defaultAttributes];
    [noResultsAttributedString addAttribute:NSForegroundColorAttributeName value:[WPStyleGuide littleEddieGrey] range:NSMakeRange(0, [noResultsAttributedString length])];
    NSRange coloredTextRange = [noResultsAttributedString.string rangeOfString:NSLocalizedString(@"here", @"Stats - this is the text that is highlighted in the text 'Tap here to see the web version of stats.'")];
    [noResultsAttributedString setAttributes:colorAttributes range:coloredTextRange];
    
    label.attributedText = noResultsAttributedString;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.opaque = YES;
    label.backgroundColor = [UIColor whiteColor];
    
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
    
    self.linkToWebviewLabel.frame = (CGRect) {
        .origin = insetFrame.origin,
        .size = labelRect.size
    };
}

- (void)prepareForReuse {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
