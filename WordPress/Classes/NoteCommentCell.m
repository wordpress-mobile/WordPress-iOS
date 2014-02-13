//
//  NoteCommentCell.m
//  WordPress
//
//  Created by Beau Collins on 12/6/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NoteCommentCell.h"
#import "UIColor+Helpers.h"

@interface NoteCommentCell ()
@property (nonatomic) BOOL loading;
@property (nonatomic, strong) UIButton *profileButton;
@property (nonatomic, strong) UIButton *emailButton;
@end

const CGFloat NoteCommentCellHeight = 102.f;

@implementation NoteCommentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.loading = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [DTAttributedTextContentView setLayerClass:[CATiledLayer class]];
        self.profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.emailButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self prepareButton:self.profileButton];
        [self prepareButton:self.emailButton];
        [self.contentView addSubview:self.profileButton];
        [self.contentView addSubview:self.emailButton];
        [self.profileButton addTarget:self action:@selector(openProfileURL:) forControlEvents:UIControlEventTouchUpInside];
        
        self.textLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundView.backgroundColor = [UIColor whiteColor];
  }
    return self;
}

- (void)showLoadingIndicator {
    
}

- (void)prepareButton:(UIButton *)button {
    button.titleLabel.textAlignment = NSTextAlignmentLeft;
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [button setTitleColor:WP_LINK_COLOR forState:UIControlStateNormal];
    [button setTitleColor:[UIColor UIColorFromHex:0x5F5F5F] forState:UIControlStateHighlighted];
    button.backgroundColor = [UIColor whiteColor];
    button.hidden = YES;
}

- (void)prepareForReuse {
    self.delegate = nil;
    self.parentComment = NO;
    self.backgroundView.backgroundColor = [UIColor whiteColor];
    self.textLabel.backgroundColor = [UIColor whiteColor];
    self.emailButton.backgroundColor = [UIColor whiteColor];
    self.profileButton.backgroundColor = [UIColor whiteColor];
    self.profileButton.hidden = YES;
    self.emailButton.hidden = YES;
    [self.profileButton setTitleColor:WP_LINK_COLOR forState:UIControlStateNormal];
    self.textLabel.text = @"";
    self.imageView.hidden = YES;
    self.imageView.frame = CGRectMake(10.f, 10.f, 92.f, 92.f);
}

- (void)setFollowButton:(FollowButton *)followButton {
    if (_followButton != followButton) {
        if(_followButton.superview == self.contentView)
            [_followButton removeFromSuperview];

        _followButton = followButton;
        [self.contentView addSubview:self.followButton];
    }
}

- (void)layoutSubviews {

    [super layoutSubviews];
    self.imageView.backgroundColor = [UIColor grayColor];
    CGFloat gravatarSize = [self gravatarSize];
    self.imageView.frame = CGRectMake(10.f, 10.f, gravatarSize, gravatarSize);
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
    
    if (self.profileURL != nil) {
        [self.profileButton setTitle:self.profileURL.host forState:UIControlStateNormal];
        self.profileButton.hidden = NO;
        labelFrame.origin.y += labelFrame.size.height;
        self.profileButton.frame = labelFrame;
    }
    
}

- (CGFloat)gravatarSize {
    if (self.parentComment)
        return 58.0f;
    else
        return 92.f;
}

- (void)setAvatarURL:(NSURL *)avatarURL {
    CGFloat gravatarSize = [self gravatarSize] * [[UIScreen mainScreen] scale];
    NSURL *resizedURL = [NSURL URLWithString:[[avatarURL absoluteString] stringByReplacingOccurrencesOfString:@"s=256" withString:[NSString stringWithFormat:@"s=%d", (int)gravatarSize]]];
    WPFLogMethodParam(resizedURL);
    [self.imageView setImageWithURL:resizedURL placeholderImage:[UIImage imageNamed:@"gravatar.jpg"]];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}


- (void)displayAsParentComment {
    self.parentComment = YES;
    self.backgroundView.backgroundColor = COMMENT_PARENT_BACKGROUND_COLOR;
    self.textLabel.backgroundColor = COMMENT_PARENT_BACKGROUND_COLOR;
    self.profileButton.backgroundColor = COMMENT_PARENT_BACKGROUND_COLOR;
    self.emailButton.backgroundColor = COMMENT_PARENT_BACKGROUND_COLOR;
    [self.profileButton setTitleColor:[UIColor UIColorFromHex:0x287087] forState:UIControlStateNormal];
}

- (void)linkPushed:(id)sender {
    DTLinkButton *button = (DTLinkButton *)sender;
    if (button.URL) {
        [self sendUrlToDelegate:button.URL];
    }
}

- (void)openProfileURL:(id)sender {
    [self sendUrlToDelegate:self.profileURL];
}

- (void)sendUrlToDelegate:(NSURL *)url {
    if ([self.delegate respondsToSelector:@selector(commentCell:didTapURL:)]) {
        [self.delegate commentCell:self didTapURL:url];
    }
}


@end
