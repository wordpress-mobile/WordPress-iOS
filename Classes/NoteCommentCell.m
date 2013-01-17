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

+ darkBackgroundColor {
    return [UIColor UIColorFromHex:0xD5D6D5];
}

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
        
//        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
//        self.backgroundView.backgroundColor = [UIColor whiteColor];
  }
    return self;
}

- (void)showLoadingIndicator {
    
}

- (void)prepareButton:(UIButton *)button {
    button.titleLabel.textAlignment = NSTextAlignmentLeft;
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [button setTitleColor:[UIColor UIColorFromHex:0x0074A2] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor UIColorFromHex:0x5F5F5F] forState:UIControlStateHighlighted];
    button.backgroundColor = [UIColor whiteColor];
    button.hidden = YES;
}

- (void)prepareForReuse {
    self.delegate = nil;
    self.backgroundView.backgroundColor = [UIColor whiteColor];
    self.textLabel.backgroundColor = [UIColor whiteColor];
    self.emailButton.backgroundColor = [UIColor whiteColor];
    self.profileButton.backgroundColor = [UIColor whiteColor];
    self.profileButton.hidden = YES;
    self.emailButton.hidden = YES;
    self.textLabel.text = @"";
    self.imageView.hidden = YES;
}

- (void)setFollowButton:(FollowButton *)followButton {
    _followButton = followButton;
    [self.contentView addSubview:self.followButton];
}

- (void)layoutSubviews {

    [super layoutSubviews];
    self.imageView.backgroundColor = [UIColor grayColor];
    self.imageView.frame = CGRectMake(10.f, 10.f, 92.f, 92.f);
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


- (void)setAvatarURL:(NSURL *)avatarURL {
    [self.imageView setImageWithURL:avatarURL placeholderImage:[UIImage imageNamed:@"note_icon_placeholder"]];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}


- (void)displayAsParentComment {
    UIColor *parentGrayColor = [[self class] darkBackgroundColor];
    self.parentComment = YES;
    self.backgroundView.backgroundColor = parentGrayColor;
    self.textLabel.backgroundColor = parentGrayColor;
    self.profileButton.backgroundColor = parentGrayColor;
    self.emailButton.backgroundColor = parentGrayColor;

}

- (void)linkPushed:(id)sender {
    DTLinkButton *button = (DTLinkButton *)sender;
    [self sendUrlToDelegate:button.URL];

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
