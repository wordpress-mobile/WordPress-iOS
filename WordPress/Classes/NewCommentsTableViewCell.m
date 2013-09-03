//
//  NewCommentsTableViewCell.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewCommentsTableViewCell.h"
#import "Comment.h"
#import "NSString+XMLExtensions.h"
#import "UIImageView+Gravatar.h"

@interface NewCommentsTableViewCell() {
    Comment __weak *_comment;
    UIImageView *_gravatarImageView;
    UILabel *_authorNameLabel;
    UILabel *_postTitleLabel;
    UILabel *_commentTextLabel;
}

@end

@implementation NewCommentsTableViewCell

CGFloat const CommentCellImageWidth = 48.0;
CGFloat const CommentCellImageHeight = 48.0;
CGFloat const CommentCellStandardOffset = 16.0;
CGFloat const CommentCellAccessoryViewOffset = 25.0;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        _gravatarImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_gravatarImageView];
        
        _authorNameLabel = [[UILabel alloc] init];
        _authorNameLabel.backgroundColor = [UIColor clearColor];
        _authorNameLabel.textAlignment = NSTextAlignmentLeft;
        _authorNameLabel.numberOfLines = 0;
        _authorNameLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _authorNameLabel.font = [[self class] authorNameFont];
        _authorNameLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _authorNameLabel.textColor = [WPStyleGuide littleEddieGrey];
        [self.contentView addSubview:_authorNameLabel];
        
        _postTitleLabel = [[UILabel alloc] init];
        _postTitleLabel.backgroundColor = [UIColor clearColor];
        _postTitleLabel.textAlignment = NSTextAlignmentLeft;
        _postTitleLabel.numberOfLines = 0;
        _postTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _postTitleLabel.font = [[self class] postTitleFont];
        _postTitleLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _postTitleLabel.textColor = [WPStyleGuide allTAllShadeGrey];
        [self.contentView addSubview:_postTitleLabel];
        
        _commentTextLabel = [[UILabel alloc] init];
        _commentTextLabel.backgroundColor = [UIColor clearColor];
        _commentTextLabel.textAlignment = NSTextAlignmentLeft;
        _commentTextLabel.numberOfLines = 3;
        _commentTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _commentTextLabel.font = [[self class] commentTextFont];
        _commentTextLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _commentTextLabel.textColor = [WPStyleGuide littleEddieGrey];
        [self.contentView addSubview:_commentTextLabel];
    }
    
    return self;
}

- (Comment *)comment
{
    return _comment;
}

- (void)setComment:(Comment *)comment
{
    _comment = comment;
    
    _authorNameLabel.text = [[self class] authorNameText:comment];
    _postTitleLabel.attributedText = [[self class] postTitleTextForComment:comment];
    _commentTextLabel.text = [[self class] commentTextForComment:comment];
    
    [_gravatarImageView setImageWithGravatarEmail:[self.comment.author_email trim] fallbackImage:[UIImage imageNamed:@"comment-default-gravatar-image"]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat maxWidth = CGRectGetWidth(self.bounds);
    
    Comment *comment = _comment;
    
    _gravatarImageView.frame =  [[self class] gravatarImageFrame];
    _authorNameLabel.frame = [[self class] authorNameFrameForComment:comment leftFrame:_gravatarImageView.frame andMaxWidth:maxWidth];
    _postTitleLabel.frame = [[self class] postTitleFrameForComment:comment topFrame:_authorNameLabel.frame leftFrame:_gravatarImageView.frame andMaxWidth:maxWidth];
    _commentTextLabel.frame = [[self class] commentFrameForComment:comment topFrame:_postTitleLabel.frame leftFrame:_gravatarImageView.frame andMaxWidth:maxWidth];
}

+ (CGFloat)rowHeightForComment:(Comment *)comment andMaxWidth:(CGFloat)maxWidth;
{
    CGRect gravatarFrame = [[self class] gravatarImageFrame];
    CGRect authorNameFrame = [[self class] authorNameFrameForComment:comment leftFrame:gravatarFrame andMaxWidth:maxWidth];
    CGRect postTitleFrame = [[self class] postTitleFrameForComment:comment topFrame:authorNameFrame leftFrame:gravatarFrame andMaxWidth:maxWidth];
    CGRect commentTextFrame = [[self class] commentFrameForComment:comment topFrame:postTitleFrame leftFrame:gravatarFrame andMaxWidth:maxWidth];
    
    return CGRectGetMaxY(commentTextFrame) + CommentCellStandardOffset;
}


#pragma mark - Private Methods

+ (NSString *)authorNameText:(Comment *)comment
{
    NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
    NSString *author = [[comment.author stringByDecodingXMLCharacters] stringByTrimmingCharactersInSet:whitespaceCS];
    return author;
}

+ (NSAttributedString *)postTitleTextForComment:(Comment *)comment
{
    NSString *postTitle = [comment.postTitle stringByDecodingXMLCharacters];
    if (comment.postTitle) {
        NSString *string = [NSLocalizedString(@"on ", @"") stringByAppendingString:postTitle];
        NSRange italicTextRange = [string rangeOfString:postTitle];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
        [attributedString addAttribute:NSFontAttributeName value:[WPStyleGuide subtitleFontItalic] range:italicTextRange];
        return attributedString;
    } else {
        NSString *string = [NSLocalizedString(@"on ", @"") stringByAppendingString:NSLocalizedString(@"(No Title)", nil)];
        NSRange italicTextRange = [string rangeOfString:NSLocalizedString(@"(No Title)", nil)];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
        [attributedString addAttribute:NSFontAttributeName value:[WPStyleGuide subtitleFontItalic] range:italicTextRange];
        return attributedString;
    }
}

+ (NSString *)commentTextForComment:(Comment *)comment
{
    return [comment.content stringByDecodingXMLCharacters];
}

+ (UIFont *)authorNameFont
{
    return [WPStyleGuide postTitleFont];
}

+ (UIFont *)postTitleFont
{
    return [WPStyleGuide subtitleFont];
}

+ (UIFont *)commentTextFont
{
    return [WPStyleGuide subtitleFont];
}

+ (CGFloat)textWidth:(CGFloat)maxWidth
{
    CGRect gravatarFrame = [[self class] gravatarImageFrame];
    return maxWidth - CGRectGetMaxX(gravatarFrame) - CommentCellStandardOffset - CommentCellAccessoryViewOffset;
}

+ (CGRect)gravatarImageFrame
{
    return CGRectMake(CommentCellStandardOffset, CommentCellStandardOffset, CommentCellImageWidth, CommentCellImageHeight);
}

+ (CGRect)authorNameFrameForComment:(Comment *)comment leftFrame:(CGRect)leftFrame andMaxWidth:(CGFloat)maxWidth
{
    NSString *authorName = [self authorNameText:comment];
    CGSize size = [authorName sizeWithFont:[self authorNameFont] constrainedToSize:CGSizeMake([self textWidth:maxWidth], CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    return CGRectMake(CGRectGetMaxX(leftFrame) + CommentCellStandardOffset, CommentCellStandardOffset, size.width, size.height);
}

+ (CGRect)postTitleFrameForComment:(Comment *)comment topFrame:(CGRect)topFrame leftFrame:(CGRect)leftFrame andMaxWidth:(CGFloat)maxWidth
{
    NSAttributedString *postTitle = [[self class] postTitleTextForComment:comment];
    CGSize size = [[postTitle string] sizeWithFont:[self postTitleFont] constrainedToSize:CGSizeMake([self textWidth:maxWidth], CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    return CGRectMake(CGRectGetMaxX(leftFrame) + CommentCellStandardOffset, CGRectGetMaxY(topFrame), size.width, size.height);
}

+ (CGRect)commentFrameForComment:(Comment *)comment topFrame:(CGRect)topFrame leftFrame:(CGRect)leftFrame andMaxWidth:(CGFloat)maxWidth
{
    NSString *commentText = [self commentTextForComment:comment];
    CGSize singeLineHeight = [@"A" sizeWithFont:[self commentTextFont]];
    CGSize size = [commentText sizeWithFont:[self commentTextFont] constrainedToSize:CGSizeMake([self textWidth:maxWidth], singeLineHeight.height*3) lineBreakMode:NSLineBreakByTruncatingTail];
    return CGRectMake(CGRectGetMaxX(leftFrame) + CommentCellStandardOffset, CGRectGetMaxY(topFrame) + CommentCellStandardOffset, size.width, size.height);
}

@end

