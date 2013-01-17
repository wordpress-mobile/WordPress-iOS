//
//  NoteCommentCell.m
//  WordPress
//
//  Created by Beau Collins on 12/6/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NoteCommentCell.h"
#import "UIColor+Helpers.h"

@interface NoteCommentCell ()
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic) BOOL loading;
@end

@implementation NoteCommentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor purpleColor];
        self.loading = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)prepareForReuse {
    self.imageView.hidden = NO;
    [self.followButton removeFromSuperview];
    self.followButton = nil;
    [self.loadingIndicator removeFromSuperview];
    self.backgroundView = nil;
}

- (void)setFollowButton:(FollowButton *)followButton {
    if (_followButton != followButton) {
        [_followButton removeFromSuperview];
        _followButton = followButton;
        [self.contentView addSubview:self.followButton];
    }
}

- (void)layoutSubviews {

    [super layoutSubviews];
    self.imageView.backgroundColor = [UIColor grayColor];
    self.imageView.frame = CGRectMake(10.f, 10.f, 92.f, 92.f);
    self.loadingIndicator.center = CGPointMake( self.bounds.size.width * 0.5f, self.bounds.size.height * 0.5f);
    CGFloat metaX = CGRectGetMaxX(self.imageView.frame);
    CGFloat availableWidth = self.bounds.size.width - metaX;
    CGRect labelFrame = CGRectInset( CGRectMake(metaX, self.imageView.frame.origin.y, availableWidth, 30.f), 10.f, 0.f);
    
    if (self.followButton != nil) {
        CGRect followFrame = self.followButton.frame;
        followFrame.origin = labelFrame.origin;
        self.followButton.frame = followFrame;
        self.followButton.maxButtonWidth = labelFrame.size.width;
        self.textLabel.hidden = YES;
    } else {
        self.textLabel.hidden = NO;
        self.textLabel.frame = labelFrame;
    }
    
}

- (void)setAvatarURL:(NSURL *)avatarURL {
    [self.imageView setImageWithURL:avatarURL placeholderImage:[UIImage imageNamed:@"note_icon_placeholder"]];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    NSLog(@"Image View: %@", self.imageView);

    // Configure the view for the selected state
}

- (void)showLoadingIndicator {
    self.loading = YES;
    if ( self.loadingIndicator == nil ) {
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activity.center = CGPointMake(self.frame.size.width * 0.5f, 0.f);
        activity.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [activity startAnimating];
        
        self.loadingIndicator = activity;
    }
    [self.contentView addSubview:self.loadingIndicator];
    [self.loadingIndicator startAnimating];
}

- (void)displayAsParentComment {
    self.parentComment = YES;
    UIImage *backgroundImage = [[UIImage imageNamed:@"note_comment_parent_indicator"] resizableImageWithCapInsets:UIEdgeInsetsMake(1.f, 65.f, 13.f, 2.f)];
    self.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
}

@end
