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

@interface NoteCommentCell () <DTAttributedTextContentViewDelegate>
@property (nonatomic) BOOL loading;
@property (nonatomic, strong) UIButton *profileButton;
@property (nonatomic, strong) UIButton *emailButton;
@end

const CGFloat NoteCommentCellTextVerticalOffset = 112.f;

@implementation NoteCommentCell

+ darkBackgroundColor {
    return [UIColor UIColorFromHex:0xD5D6D5];
}

+ (CGFloat)heightForCellWithTextContent:(NSAttributedString *)textContent constrainedToWidth:(CGFloat)width {
    DTAttributedTextContentView *textContentView;
    [DTAttributedTextContentView setLayerClass:[CATiledLayer class]];
    textContentView = [[DTAttributedTextContentView alloc] initWithFrame:CGRectMake(0.f, 0.f, width, 0.f)];
    textContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textContentView.edgeInsets = UIEdgeInsetsMake(0.f, 10.f, 5.f, 10.f);
    textContentView.attributedString = textContent;
    CGSize size = [textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:width];
    return size.height + NoteCommentCellTextVerticalOffset + 20.f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.loading = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [DTAttributedTextContentView setLayerClass:[CATiledLayer class]];
        self.textContentView = [[DTAttributedTextContentView alloc] initWithFrame:CGRectMake(0.f, NoteCommentCellTextVerticalOffset, 320.f, 0.f)];
        self.textContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textContentView.edgeInsets = UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
        self.textContentView.shouldDrawLinks = NO;
        self.textContentView.delegate = self;
        [self.contentView addSubview:self.textContentView];
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
    [self.followButton removeFromSuperview];
    self.followButton = nil;
    self.backgroundView.backgroundColor = [UIColor whiteColor];
    self.textLabel.backgroundColor = [UIColor whiteColor];
    self.textContentView.hidden = NO;
    self.emailButton.backgroundColor = [UIColor whiteColor];
    self.profileButton.backgroundColor = [UIColor whiteColor];
    self.profileButton.hidden = YES;
    self.emailButton.hidden = YES;
    self.textLabel.text = @"";
    self.imageView.hidden = YES;
    self.imageView.image = nil;
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
    
    self.textContentView.hidden = self.textContentView.attributedString == nil;
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
    self.textContentView.backgroundColor = parentGrayColor;
    self.textLabel.backgroundColor = parentGrayColor;
    self.profileButton.backgroundColor = parentGrayColor;
    self.emailButton.backgroundColor = parentGrayColor;

}


- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame {
    NSDictionary *attributes = [string attributesAtIndex:0 effectiveRange:NULL];
    
    DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
    button.attributedString = string;
    button.URL = [attributes objectForKey:DTLinkAttribute];
    button.GUID = [attributes objectForKey:DTGUIDAttribute];
    
    NSMutableAttributedString *highlightedString = [string mutableCopy];
    NSRange range = NSMakeRange(0, [highlightedString length]);
	NSDictionary *highlightedAttributes = [NSDictionary dictionaryWithObject:(__bridge id)[UIColor redColor].CGColor forKey:(id)kCTForegroundColorAttributeName];
    
    [highlightedString addAttributes:highlightedAttributes range:range];
    
    button.highlightedAttributedString = highlightedString;
    
    [button addTarget:self action:@selector(linkPushed:) forControlEvents:UIControlEventTouchUpInside];
    return button;
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
