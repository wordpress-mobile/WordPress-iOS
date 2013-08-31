//
//  NewSidebarCell.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/13/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewSidebarCell.h"
#import "SidebarBadgeView.h"
#import "UIColor+Helpers.h"

@interface NewSidebarCell() {
    NSArray *_horizontalConstraints;
    NSArray *_verticalConstraints;
}

@property (nonatomic, strong) IBOutlet UIImageView *mainImageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *accessoryViewFirstImageView;
@property (nonatomic, strong) IBOutlet UIImageView *accessoryViewSecondImageView;
@property (nonatomic, strong) IBOutlet UIView *content;
@property (nonatomic, strong) IBOutlet SidebarBadgeView *badgeView;

@end

@implementation NewSidebarCell

- (id)init {
    
    UITableViewCellStyle style = UITableViewCellStyleDefault;
    NSString *identifier = @"Cell";
    
    if ((self = [super initWithStyle:style reuseIdentifier:identifier])) {
        [[NSBundle mainBundle] loadNibNamed:@"NewSidebarCell"
                                      owner:self
                                    options:nil];
        [self addSubview:self.content];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _horizontalConstraints = [NSArray array];
        _verticalConstraints = [NSArray array];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    
    if (CGRectContainsPoint(self.accessoryViewFirstImageView.frame, touchPoint)) {
        if (self.tappedFirstAccessoryView != nil) {
            self.tappedFirstAccessoryView();
        }
    } else if (CGRectContainsPoint(self.accessoryViewSecondImageView.frame, touchPoint)) {
        if (self.tappedSecondAccessoryView != nil) {
            self.tappedSecondAccessoryView();
        }
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self setNeedsLayout];
}

- (void)setTitle:(NSString *)title
{
    if (_title != title) {
        _title = title;
        self.titleLabel.text = title;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setShowsBadge:(BOOL)showsBadge
{
    if (_showsBadge != showsBadge) {
        _showsBadge = showsBadge;
        [self setNeedsDisplay];
    }
}

- (void)setBadgeNumber:(NSUInteger)badgeNumber
{
    if (_badgeNumber != badgeNumber) {
        _badgeNumber = badgeNumber;
        [self setNeedsDisplay];
    }
}

- (void)setCellBackgroundColor:(SidebarTableViewCellBackgroundColor)cellBackgroundColor
{
    if (_cellBackgroundColor != cellBackgroundColor) {
        _cellBackgroundColor = cellBackgroundColor;
        [self setNeedsDisplay];
    }
}

- (void)setMainImage:(UIImage *)mainImage
{
    if (_mainImage != mainImage) {
        _mainImage = mainImage;
        self.mainImageView.image = mainImage;
        [self setNeedsDisplay];
    }
}

- (void)setSelectedImage:(UIImage *)selectedImage
{
    if (_selectedImage != selectedImage) {
        _selectedImage = selectedImage;
        if (self.selected) {
            self.mainImageView.image = selectedImage;
        }
        [self setNeedsDisplay];
    }
}

- (void)prepareForReuse
{
    self.showsBadge = NO;
    self.badgeNumber = 0;
    self.tappedFirstAccessoryView = nil;
    self.tappedSecondAccessoryView = nil;
    self.selected = NO;
}

- (void)layoutSubviews
{
    if (self.cellBackgroundColor == SidebarTableViewCellBackgroundColorLight) {
        self.content.backgroundColor = [WPStyleGuide bigEddieGrey];
    } else {
        self.content.backgroundColor = [WPStyleGuide darkAsNightGrey];
    }
    
    if (self.selected) {
        self.mainImageView.image = self.selectedImage;
        self.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0];
    } else {
        self.mainImageView.image = self.mainImage;
        self.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16.0];
    }
    
    if (self.showsBadge) {
        self.badgeView.hidden = NO;
        self.badgeView.badgeCount = self.badgeNumber;
        self.accessoryViewFirstImageView.hidden = YES;
        self.accessoryViewSecondImageView.hidden = YES;
    } else {
        self.badgeView.hidden = YES;
        self.accessoryViewFirstImageView.hidden = NO;
        self.accessoryViewSecondImageView.hidden = NO;
        self.accessoryViewFirstImageView.image = self.firstAccessoryViewImage;
        self.accessoryViewSecondImageView.image = self.secondAccessoryViewImage;
    }
}

@end
