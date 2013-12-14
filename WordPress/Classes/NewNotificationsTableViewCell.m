//
//  NewNotificationsTableViewCell.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/27/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewNotificationsTableViewCell.h"
#import "Note.h"


@interface NewNotificationsTableViewCell() {
    UILabel *_unreadTextLabel;
}

@end

CGFloat const NewNotificationsCellStandardOffset = 16.0;


@implementation NewNotificationsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _unreadTextLabel = [[UILabel alloc] init];
        _unreadTextLabel.backgroundColor = [UIColor clearColor];
        _unreadTextLabel.textAlignment = NSTextAlignmentLeft;
        _unreadTextLabel.numberOfLines = 0;
        _unreadTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _unreadTextLabel.font = [[self class] unreadFont];
        _unreadTextLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _unreadTextLabel.textColor = [WPStyleGuide jazzyOrange];
        _unreadTextLabel.text = @"•";
        [self.contentView addSubview:_unreadTextLabel];
    }
    return self;
}

+ (BOOL)showGravatarImage {
    return YES;
}

- (Note *)note {
    return (Note *)[self contentProvider];
}

- (void)setContentProvider:(id<WPContentViewProvider>)contentProvider
{
    [super setContentProvider:contentProvider];
    
    _unreadTextLabel.hidden = [[self note] isRead];
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
    _unreadTextLabel.frame = [[self class] unreadFrameForMaxWidth:maxWidth];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _unreadTextLabel.hidden = YES;
}

#pragma mark - Private Methods

+ (UIFont *)unreadFont
{
    return [WPStyleGuide subtitleFont];
}

+ (CGRect)unreadFrameForMaxWidth:(CGFloat)maxWidth
{
    CGSize size = [@"•" sizeWithAttributes:@{NSFontAttributeName:[self unreadFont]}];
    return CGRectMake(maxWidth - size.width - NewNotificationsCellStandardOffset * 0.5 , NewNotificationsCellStandardOffset * 0.5, size.width, size.height);
}




@end
