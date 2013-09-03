//
//  NewNotificationsTableViewCell.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/27/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewNotificationsTableViewCell.h"
#import "Note.h"
#import "UIImageView+Gravatar.h"
#import "NSString+XMLExtensions.h"

@interface NewNotificationsTableViewCell() {
    __weak Note *_note;
    UIImageView *_gravatarImageView;
    UILabel *_subjectLabel;
    UILabel *_comment;
    UILabel *_detailTextLabel;
    UILabel *_unreadTextLabel;
}

@end

@implementation NewNotificationsTableViewCell

CGFloat const NotificationCellImageWidth = 48.0;
CGFloat const NotificationCellImageHeight = 48.0;
CGFloat const NotificationCellStandardOffset = 16.0;
CGFloat const NotificationCellAccessoryViewOffset = 25.0;
CGFloat const NotificationCellDetailTextNumberOfLines = 2;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        _gravatarImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_gravatarImageView];

        _subjectLabel = [[UILabel alloc] init];
        _subjectLabel.backgroundColor = [UIColor clearColor];
        _subjectLabel.textAlignment = NSTextAlignmentLeft;
        _subjectLabel.numberOfLines = 0;
        _subjectLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _subjectLabel.font = [[self class] subjectFont];
        _subjectLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _subjectLabel.textColor = [UIColor blackColor];
        [self.contentView addSubview:_subjectLabel];

        _detailTextLabel = [[UILabel alloc] init];
        _detailTextLabel.backgroundColor = [UIColor clearColor];
        _detailTextLabel.textAlignment = NSTextAlignmentLeft;
        _detailTextLabel.numberOfLines = NotificationCellDetailTextNumberOfLines;
        _detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _detailTextLabel.font = [[self class] detailFont];
        _detailTextLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _detailTextLabel.textColor = [WPStyleGuide allTAllShadeGrey];
        [self.contentView addSubview:_detailTextLabel];
        
        _unreadTextLabel = [[UILabel alloc] init];
        _unreadTextLabel.backgroundColor = [UIColor clearColor];
        _unreadTextLabel.textAlignment = NSTextAlignmentLeft;
        _unreadTextLabel.numberOfLines = 0;
        _unreadTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _unreadTextLabel.font = [[self class] unreadFont];
        _unreadTextLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _unreadTextLabel.textColor = [WPStyleGuide baseDarkerBlue];
        _unreadTextLabel.text = @"•";
        [self.contentView addSubview:_unreadTextLabel];
    }
    return self;
}

- (Note *)note
{
    return _note;
}

- (void)setNote:(Note *)note
{
    _note = note;
    
    NSString *iconURL = self.note.icon;
    if (iconURL) {
        iconURL = [iconURL stringByReplacingOccurrencesOfString:@"s=256" withString:[NSString stringWithFormat:@"s=%d", NotificationCellImageWidth]];
        [_gravatarImageView setImageWithURL:[NSURL URLWithString:iconURL] placeholderImage:[UIImage imageNamed:@"gravatar.jpg"]];
    } else {
        [_gravatarImageView setImage:[UIImage imageNamed:@"gravatar.jpg"]];
    }
    
    _subjectLabel.text =  [[self class] subjectText:_note];
    _detailTextLabel.text = [[self class] detailText:note];
    
    if (IS_IOS7) {
        if (_subjectLabel.text != nil) {
            _subjectLabel.attributedText = [[NSAttributedString alloc] initWithString:_subjectLabel.text attributes:[[self class] subjectAttributes]];
        }
        
        if (_detailTextLabel.text != nil) {
            _detailTextLabel.attributedText = [[NSAttributedString alloc] initWithString:_detailTextLabel.text attributes:[[self class] detailAttributes]];
        }
    }

    _unreadTextLabel.hidden = [note isRead];
    if ([self.note isComment]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat maxWidth = CGRectGetWidth(self.bounds);
    
    Note *note = _note;
    _gravatarImageView.frame =  [[self class] gravatarImageFrame];
    _subjectLabel.frame = [[self class] subjectFrameForNotification:note leftFrame:_gravatarImageView.frame andMaxWidth:maxWidth];
    _detailTextLabel.frame = [[self class] detailFrameForNotification:note leftFrame:_gravatarImageView.frame topFrame:_subjectLabel.frame andMaxWidth:maxWidth];
    _unreadTextLabel.frame = [[self class] unreadFrameForMaxWidth:maxWidth];
}

+ (CGFloat)rowHeightForNotification:(Note *)note andMaxWidth:(CGFloat)maxWidth
{
    CGRect gravatarImageFrame =  [[self class] gravatarImageFrame];
    CGRect subjectFrame = [[self class] subjectFrameForNotification:note leftFrame:gravatarImageFrame andMaxWidth:maxWidth];
    CGRect detailFrame = [[self class] detailFrameForNotification:note leftFrame:gravatarImageFrame topFrame:subjectFrame andMaxWidth:maxWidth];
    
    return CGRectGetMaxY(detailFrame) + NotificationCellStandardOffset;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    _unreadTextLabel.hidden = YES;
    _gravatarImageView.image = nil;
}


#pragma mark - Private Methods

+ (UIFont *)subjectFont
{
    return [WPStyleGuide postTitleFont];
}

+ (NSDictionary *)subjectAttributes
{
    return [WPStyleGuide postTitleAttributes];
}

+ (NSString *)subjectText:(Note *)note
{
    return [NSString decodeXMLCharactersIn:note.subject];
}

+ (UIFont *)detailFont
{
    return [WPStyleGuide subtitleFont];
}

+ (NSDictionary *)detailAttributes
{
    return [WPStyleGuide subtitleAttributes];
}

+ (NSString *)detailText:(Note *)note
{
    return [NSString decodeXMLCharactersIn:note.commentText];
}

+ (UIFont *)unreadFont
{
    return [WPStyleGuide subtitleFont];
}

+ (CGRect)gravatarImageFrame
{
    return CGRectMake(NotificationCellStandardOffset, NotificationCellStandardOffset, NotificationCellImageWidth, NotificationCellImageHeight);
}


+ (CGFloat)textWidth:(CGFloat)maxWidth
{
    CGRect gravatarFrame = [[self class] gravatarImageFrame];
    return maxWidth - CGRectGetMaxX(gravatarFrame) - NotificationCellStandardOffset - NotificationCellAccessoryViewOffset;
}

+ (CGRect)subjectFrameForNotification:(Note *)note leftFrame:(CGRect)leftFrame andMaxWidth:(CGFloat )maxWidth
{
    NSString *subjectText = [self subjectText:note];
    CGSize size;
    if (IS_IOS7) {
        size = [subjectText boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[self subjectAttributes] context:nil].size;
    } else {
        size = [subjectText sizeWithFont:[self subjectFont] constrainedToSize:CGSizeMake([self textWidth:maxWidth], CGFLOAT_MAX) lineBreakMode:NSLineBreakByTruncatingTail];
    }
    return CGRectMake(CGRectGetMaxX(leftFrame) + NotificationCellStandardOffset, NotificationCellStandardOffset, size.width, size.height);
}

+ (CGRect)detailFrameForNotification:(Note *)note leftFrame:(CGRect)leftFrame topFrame:(CGRect)topFrame andMaxWidth:(CGFloat)maxWidth
{
    NSString *detailText = [self detailText:note];

    if ([detailText length] == 0) {
        return CGRectMake(CGRectGetMaxX(leftFrame) + NotificationCellStandardOffset, CGRectGetMaxY(topFrame), 0, 0);
    }

    CGFloat singleLineHeight = [@"W" sizeWithFont:[self detailFont]].height;
    CGSize size;
    if (IS_IOS7) {
        size = [detailText boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], singleLineHeight * NotificationCellDetailTextNumberOfLines) options:NSStringDrawingUsesLineFragmentOrigin attributes:[self detailAttributes] context:nil].size;
    } else {
        size = [detailText sizeWithFont:[self detailFont] constrainedToSize:CGSizeMake([self textWidth:maxWidth], singleLineHeight * NotificationCellDetailTextNumberOfLines) lineBreakMode:NSLineBreakByTruncatingTail];
    }
    return CGRectMake(CGRectGetMaxX(leftFrame) + NotificationCellStandardOffset, CGRectGetMaxY(topFrame), size.width, size.height);
}

+ (CGRect)unreadFrameForMaxWidth:(CGFloat)maxWidth
{
    CGSize size = [@"•" sizeWithFont:[self unreadFont]];
    return CGRectMake(maxWidth - size.width - NotificationCellStandardOffset * 0.5 , NotificationCellStandardOffset * 0.5, size.width, size.height);
}


@end
