//
//  NoteCommentContentCell.m
//  WordPress
//
//  Created by Beau Collins on 1/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NoteCommentContentCell.h"

@interface NoteCommentContentCell () <DTAttributedTextContentViewDelegate>

@end

@implementation NoteCommentContentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.attributedTextContextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.attributedTextContextView.edgeInsets = UIEdgeInsetsMake(10.f, 10.f, 20.f, 10.f);
        self.attributedTextContextView.shouldDrawLinks = NO;
        self.attributedTextContextView.delegate = self;
        self.attributedTextContextView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.attributedTextContextView];
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundView.backgroundColor = [UIColor whiteColor];
    }
    return self;
}


- (NSAttributedString *)attributedString {
    return self.attributedTextContextView.attributedString;
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
    self.attributedTextContextView.attributedString = attributedString;
}

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame {
	NSDictionary *attributes = [string attributesAtIndex:0 effectiveRange:nil];

	DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
	button.URL = [attributes objectForKey:DTLinkAttribute];
	button.GUID = [attributes objectForKey:DTGUIDAttribute];
	button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough

	// get image with normal link text
	UIImage *normalImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDefault];
	[button setImage:normalImage forState:UIControlStateNormal];
	
	// get image for highlighted link text
	UIImage *highlightImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDrawLinksHighlighted];
	[button setImage:highlightImage forState:UIControlStateHighlighted];
	
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
    NSDictionary *stringAttributes = [NSDictionary dictionaryWithObject:(__bridge id)[UIColor UIColorFromHex:0x464646].CGColor forKey:(id)kCTForegroundColorAttributeName];
    [colorString addAttributes:stringAttributes range:range];

    self.attributedTextContextView.attributedString = colorString;
    
    self.backgroundView.backgroundColor = COMMENT_PARENT_BACKGROUND_COLOR;
}

@end
