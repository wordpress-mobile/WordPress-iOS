//
//  ReaderAttributionView.m
//  WordPress
//
//  Created by aerych on 1/14/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "ReaderAttributionView.h"
#import "WPContentViewSubclass.h"
#import "UILabel+SuggestSize.h"

@interface ReaderAttributionView()

@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong, readwrite) UIButton *linkButton;
@property (nonatomic, strong, readwrite) ContentActionButton *followButton;
@property (nonatomic, strong, readwrite) UIImageView *avatarImageView;

@end

@implementation ReaderAttributionView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGRect avatarFrame = CGRectMake(RPVHorizontalInnerPadding, RPVAuthorPadding, RPVAvatarSize, RPVAvatarSize);
        _avatarImageView = [[UIImageView alloc] initWithFrame:avatarFrame];
        [self addSubview:_avatarImageView];
        
        self.authorLabel = [[UILabel alloc] init];
        self.authorLabel.numberOfLines = 1;
        self.authorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.authorLabel.font = [WPStyleGuide subtitleFont];
        self.authorLabel.adjustsFontSizeToFitWidth = NO;
        self.authorLabel.textColor = [WPStyleGuide littleEddieGrey];
        [self addSubview:self.authorLabel];
        
        self.linkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.linkButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.linkButton.titleLabel.font = [WPStyleGuide subtitleFont];
        self.linkButton.enabled = NO;
        self.linkButton.hidden = YES;
        [self.linkButton setTitleColor:[WPStyleGuide buttonActionColor] forState:UIControlStateNormal];
        [self addSubview:self.linkButton];
        
        self.followButton = [ContentActionButton buttonWithType:UIButtonTypeCustom];
        self.followButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.followButton.titleLabel.font = [WPStyleGuide subtitleFont];
        NSString *followString = NSLocalizedString(@"Follow", @"Prompt to follow a blog.");
        NSString *followedString = NSLocalizedString(@"Following", @"User is following the blog.");
        [self.followButton setTitle:followString forState:UIControlStateNormal];
        [self.followButton setTitle:followedString forState:UIControlStateSelected];
        [self.followButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPVSmallButtonLeftPadding, 0, 0)];
        [self.followButton setImage:[UIImage imageNamed:@"reader-postaction-follow"] forState:UIControlStateNormal];
        [self.followButton setImage:[UIImage imageNamed:@"reader-postaction-following"] forState:UIControlStateSelected];
        [self.followButton setTitleColor:[WPStyleGuide theFonzGrey] forState:UIControlStateNormal];
        self.followButton.hidden = YES;
        [self addSubview:self.followButton];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat contentWidth = self.frame.size.width;
    
    CGFloat bylineX = RPVAvatarSize + RPVAuthorPadding + RPVHorizontalInnerPadding;
    self.authorLabel.frame = CGRectMake(bylineX, RPVAuthorPadding - 2.0f, contentWidth - bylineX, 18.0f);
    self.linkButton.frame = CGRectMake(bylineX, self.authorLabel.frame.origin.y + 18.0f, contentWidth - bylineX, 18.0f);
    
    CGFloat height = 0.0f;
    if (self.followButton.hidden == NO) {
        CGFloat followX = bylineX - 4; // Fudge factor for image alignment
        CGFloat followY = RPVAuthorPadding + self.authorLabel.frame.size.height - 2;
        height = ceil([self.followButton.titleLabel suggestedSizeForWidth:self.frame.size.width].height);
        self.followButton.frame = CGRectMake(followX, followY, RPVFollowButtonWidth, height);
    }
}

- (void)setAuthorDisplayName:(NSString *)authorName authorLink:(NSString *)authorLink {
    self.authorName = authorName;
    self.authorLink = authorLink;
}

- (NSString *)authorName {
    return self.authorLabel.text;
}

- (void)setAuthorName:(NSString *)authorName {
    self.authorLabel.text = authorName;
}

- (NSString *)authorLink {
    return [self.linkButton titleForState:UIControlStateNormal];
}

- (void)setAuthorURL:(NSString *)authorURL {
    [self.linkButton setTitle:authorURL forState:UIControlStateNormal];
    
    BOOL enableButton = (authorURL) ? YES : NO;
    self.linkButton.enabled = enableButton;
    self.linkButton.hidden = !enableButton;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    
    self.authorLabel.backgroundColor = backgroundColor;
    self.linkButton.backgroundColor = backgroundColor;
    self.followButton.backgroundColor = backgroundColor;
}

@end
