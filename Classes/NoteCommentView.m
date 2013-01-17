//
//  NoteCommentView.m
//  WordPress
//
//  Created by Beau Collins on 12/6/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NoteCommentView.h"

@interface NoteCommentView () <DTAttributedTextContentViewDelegate>

@end

@implementation NoteCommentView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        self.avatarImageView = [[UIImageView
                                 alloc] initWithFrame:CGRectMake(10.f, 10.f, 80.f, 80.f)];
        [self addSubview:self.avatarImageView];
        
        [DTAttributedTextContentView setLayerClass:[CATiledLayer class]];
        CGRect frame = CGRectMake( 0, CGRectGetMaxY(self.avatarImageView.frame), self.bounds.size.width, 100.f);
        
        self.contentView = [[DTAttributedTextContentView alloc] initWithFrame:frame];
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.contentView.edgeInsets = UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
        self.contentView.shouldDrawLinks = NO;
        self.contentView.delegate = self;
        [self addSubview:self.contentView];
        
        CGFloat avatarRightX = CGRectGetMaxX(self.avatarImageView.frame);
        
        self.profileButton = [[UIButton alloc] initWithFrame:CGRectMake(avatarRightX, 10.f, CGRectGetMaxX(self.bounds) - avatarRightX, 32.f)];
        [self setupMetaButton:self.profileButton];
        [self addSubview:self.profileButton];
        
        CGRect emailButtonFrame = self.profileButton.frame;
        emailButtonFrame.origin.y = CGRectGetMaxY(emailButtonFrame);
        self.emailButton = [[UIButton alloc] initWithFrame:emailButtonFrame];
        [self setupMetaButton:self.emailButton];
        [self addSubview:self.emailButton];
        
        [self.profileButton addTarget:self action:@selector(tappedProfileButton:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.emailButton addTarget:self action:@selector(tappedEmailButton:) forControlEvents:UIControlEventTouchUpInside];
        
        
        [self positionMetaButtons];
        NSLog(@"added a follow button: %@", self.followButton);
        
    }
    return self;
}

- (void)setupMetaButton:(UIButton *)button {
    button.titleLabel.textAlignment = NSTextAlignmentLeft;
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    button.titleLabel.layer.borderWidth = 1.f;
    button.titleLabel.layer.borderColor = [[UIColor whiteColor] CGColor];
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

- (void)positionMetaButtons {
    
    CGRect imageFrame = self.avatarImageView.frame;
    CGPoint startPoint = CGPointMake(CGRectGetMaxX(imageFrame) + 10.f, CGRectGetMinY(imageFrame));
    CGFloat availableWidth = self.bounds.size.width - startPoint.x - 10.f;
    CGRect frame = CGRectZero;
    if (self.followButton) {
        frame = self.followButton.frame;
        frame.origin = startPoint;
        self.followButton.maxButtonWidth = availableWidth;
        self.followButton.frame = frame;
        frame.origin.y += frame.size.height;
    } else {
        frame.origin = startPoint;
    }
    
    frame.size.width = availableWidth;
    frame.size.height = self.profileButton.frame.size.height;
    
    self.profileButton.frame = frame;
    frame.origin.y += frame.size.height;
    
    self.emailButton.frame = frame;
    
}

- (void)setComment:(NSDictionary *)comment {
    if(_comment != comment){
        _comment = comment;
    }
        
    
    NSString *html = [self.comment valueForKeyPath:@"content"];
    
    NSDictionary *options = @{
    DTDefaultFontFamily : @"Helvetica",
    NSTextSizeMultiplierDocumentOption : [NSNumber numberWithFloat:1.4]
    };
    
    NSAttributedString *content = [[NSAttributedString alloc] initWithHTMLData:[html dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:NULL];
    
    self.contentView.attributedString = content;
    
    NSString *profileURL = [self.comment valueForKeyPath:@"author.URL"];
    
    [self.profileButton setTitle:profileURL forState:UIControlStateNormal];
    
    id emailAddress = [self.comment valueForKeyPath:@"author.email"];
    if ([emailAddress isKindOfClass:[NSString class]]) {
        [self.emailButton setTitle:emailAddress forState:UIControlStateNormal];
        self.emailButton.hidden = NO;
    } else {
        self.emailButton.hidden = YES;
    }
    
    
    CGRect frame = self.frame;
    frame.size.height = CGRectGetMaxY(self.contentView.frame);
    self.frame = frame;

}

- (void)setFollowButton:(FollowButton *)followButton {
    if (_followButton != followButton) {
        [_followButton removeFromSuperview];
        _followButton = followButton;
        [self addSubview:_followButton];
        [self positionMetaButtons];
    }
    
}

- (void)tappedEmailButton:(id)sender {
    id emailAddress = [self.comment valueForKeyPath:@"author.email"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", emailAddress]];
    [self sendURLtoDelegate:url];

}

- (void)tappedProfileButton:(id)sender {
    NSString *profileURL = [self.comment valueForKeyPath:@"author.URL"];
    NSURL *url = [NSURL URLWithString:profileURL];
    [self sendURLtoDelegate:url];
}

- (void)sendURLtoDelegate:(NSURL *)url {
    if ([self.delegate respondsToSelector:@selector(commentView:didRequestURL:)]) {
        [self.delegate commentView:self didRequestURL:url];
    }
}

#pragma mark DTAttributedTextContentViewDelegate

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
    [self sendURLtoDelegate:button.URL];
//    WPWebViewController *webView = [[WPWebViewController alloc] initWithNibName:nil bundle:nil];
//    [webView setUrl:button.URL];
//    [self.panelNavigationController pushViewController:webView animated:YES];
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
