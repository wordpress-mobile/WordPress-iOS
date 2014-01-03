/*
 * StatsTwoLabelCell.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsTwoLabelCell.h"

@implementation StatsTwoLabelCell

+ (CGFloat)heightForRow {
    return 44.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setLeftLabelText:(NSString *)title {
    UILabel *titleLabel = [self createAndInsertLabelWithTitle:title];
    titleLabel.frame = (CGRect) {
        .origin = CGPointMake(10, 10),
        .size = titleLabel.frame.size
    };
}

- (void)setRightLabelText:(NSString *)title {
    UILabel *titleLabel = [self createAndInsertLabelWithTitle:title];
    titleLabel.frame = (CGRect) {
        .origin = CGPointMake(self.contentView.frame.size.width - (titleLabel.frame.size.width + 10), 10),
        .size = titleLabel.frame.size
    };
}

- (UILabel *)createAndInsertLabelWithTitle:(NSString *)title {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [WPStyleGuide subtitleFont];
    [titleLabel sizeToFit];
    [self.contentView addSubview:titleLabel];
    return titleLabel;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
