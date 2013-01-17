//
//  NoteCommentContentCell.m
//  WordPress
//
//  Created by Beau Collins on 1/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NoteCommentContentCell.h"

@interface NoteCommentContentCell () <DTAttributedTextContentViewDelegate>

@property (nonatomic, strong) DTAttributedTextContentView *attributedTextView;

@end

@implementation NoteCommentContentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.attributedTextView = [[DTAttributedTextContentView alloc] initWithFrame:CGRectMake(0.f, 0, 320.f, 0.f)];
        self.attributedTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.attributedTextView.edgeInsets = UIEdgeInsetsMake(10.f, 10.f, 20.f, 10.f);
        self.attributedTextView.shouldDrawLinks = NO;
        self.attributedTextView.delegate = self;
        self.attributedTextView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.attributedTextView];
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundView.backgroundColor = [UIColor whiteColor];
    }
    return self;
}


- (NSAttributedString *)attributedString {
    return self.attributedTextView.attributedString;
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
    self.attributedTextView.attributedString = attributedString;
}

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame {
    NSDictionary *attributes = [string attributesAtIndex:0 effectiveRange:NULL];
    
    DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
    button.URL = [attributes objectForKey:DTLinkAttribute];
    button.GUID = [attributes objectForKey:DTGUIDAttribute];
    
    NSMutableAttributedString *attributedString = [string mutableCopy];
    NSRange range = NSMakeRange(0, [attributedString length]);
	NSDictionary *stringAttributes = [NSDictionary dictionaryWithObject:(__bridge id)WP_LINK_COLOR.CGColor forKey:(id)kCTForegroundColorAttributeName];
    
    [attributedString addAttributes:stringAttributes range:range];
    button.attributedString = attributedString;
    
    NSMutableAttributedString *highlightedString = [string mutableCopy];
	NSDictionary *highlightedAttributes = [NSDictionary dictionaryWithObject:(__bridge id)[UIColor darkGrayColor].CGColor forKey:(id)kCTForegroundColorAttributeName];
    
    [highlightedString addAttributes:highlightedAttributes range:range];
    
    button.highlightedAttributedString = highlightedString;
    
    [button addTarget:self action:@selector(linkPushed:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)linkPushed:(id)sender {
    DTLinkButton *button = (DTLinkButton *)sender;
    [self sendUrlToDelegate:button.URL];
    
}

- (void)sendUrlToDelegate:(NSURL *)url {
    if ([self.delegate respondsToSelector:@selector(commentCell:didTapURL:)]) {
        [self.delegate commentCell:self didTapURL:url];
    }
}

- (void)displayAsParentComment {
    self.isParentComment = YES;
    
    NSMutableAttributedString *colorString = [self.attributedString mutableCopy];
    NSRange range = NSMakeRange(0, [colorString length]);
    NSDictionary *stringAttributes = [NSDictionary dictionaryWithObject:(__bridge id)[UIColor UIColorFromHex:0x494949].CGColor forKey:(id)kCTForegroundColorAttributeName];
    [colorString addAttributes:stringAttributes range:range];
    self.attributedTextView.attributedString = colorString;
    
    self.backgroundView.backgroundColor = COMMENT_PARENT_BACKGROUND_COLOR;
}

@end
