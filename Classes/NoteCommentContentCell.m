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
        [self.contentView addSubview:self.attributedTextView];

    }
    return self;
}


- (NSAttributedString *)attributedString {
    return  self.attributedTextView.attributedString;
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
    self.attributedTextView.attributedString = attributedString;
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

- (void)sendUrlToDelegate:(NSURL *)url {
    if ([self.delegate respondsToSelector:@selector(commentCell:didTapURL:)]) {
        [self.delegate commentCell:self didTapURL:url];
    }
}

@end
