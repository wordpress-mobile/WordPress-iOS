//
//  BasePostContentView.m
//  WordPress
//
//  Created by Eric Johnson on 2/28/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "BasePostContentView.h"
#import "WPContentViewSubclass.h"
#import "WPContentViewProvider.h"
#import "UILabel+SuggestSize.h"
#import "NSString+Helpers.h"

NSInteger const MaxNumberOfLinesForTitleForSummary = 3;

@implementation BasePostContentView

+ (CGFloat)heightForContentViewProvider:(id<WPContentViewProvider>)provider withWidth:(CGFloat)width showFullContent:(BOOL)showFullContent {
	CGFloat desiredHeight = 0.0f;
    
    // Margins
    CGFloat contentWidth = width;
    if (IS_IPAD) {
        contentWidth = WPTableViewFixedWidth;
    }
    
    desiredHeight += RPVAuthorPadding;
    desiredHeight += RPVAuthorViewHeight;
    desiredHeight += RPVAuthorPadding;
    
	// Are we showing an image? What size should it be?
    if ([provider featuredImageURLForDisplay]) {
		CGFloat height = ceilf((contentWidth * RPVMaxImageHeightPercentage));
		desiredHeight += height;
	}
    
    // Everything but the image has inner padding
    contentWidth -= RPVHorizontalInnerPadding * 2;
    
    // Title
    desiredHeight += RPVVerticalPadding;
    NSAttributedString *postTitle = [self titleAttributedStringForTitle:[provider titleForDisplay] showFullContent:showFullContent withWidth:contentWidth];
    desiredHeight += [postTitle boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height;
    desiredHeight += RPVTitlePaddingBottom;
    
    // Post summary
    if ([provider contentPreviewForDisplay] > 0) {
        NSAttributedString *postSummary = [self summaryAttributedStringForString:[provider contentPreviewForDisplay]];
        desiredHeight += [postSummary boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height;
    }
    desiredHeight += RPVVerticalPadding;
    
    // Tag
    // TODO: reenable tags once a better browsing experience is implemented
    /*    NSString *tagName = post.primaryTagName;
     if ([tagName length] > 0) {
     CGRect tagRect = [tagName boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX)
     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
     attributes:@{NSFontAttributeName : [self summaryFont]}
     context:nil];
     desiredHeight += tagRect.size.height;
     }
     */
    
    // Padding below the line
	desiredHeight += RPVVerticalPadding;
    
	// Size of the meta view
    desiredHeight += RPVMetaViewHeight;
    
	return ceil(desiredHeight);
}

+ (NSAttributedString *)titleAttributedStringForTitle:(NSString *)title showFullContent:(BOOL)showFullContent withWidth:(CGFloat) width {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineHeightMultiple:RPVLineHeightMultiple];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName : style,
                                 NSFontAttributeName : [self titleFont]};
    title = [title trim];
    if (title == nil) {
        title = @"";
    }
    
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:title
                                                                                    attributes:attributes];
    //Ellipsizing long titles
    if(!showFullContent) {
        if([title length] > 0) {
            
            CGFloat currentHeightOfTitle = [titleString
                                            boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                            options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            context:nil].size.height;
            
            CGFloat heightOfSingleLine = [[titleString attributedSubstringFromRange:NSMakeRange(0,1)]
                                          boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                          options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                          context:nil].size.height;
            
            NSInteger numberOfLines = currentHeightOfTitle / heightOfSingleLine;
            
            if(numberOfLines > MaxNumberOfLinesForTitleForSummary) {
                NSInteger newLength = [self calculateTitleLengthWithSingleLineHeight:heightOfSingleLine
                                                                             currentLineHeight:currentHeightOfTitle
                                                                                  currentTitle:titleString];
                
                titleString = [[NSMutableAttributedString alloc]initWithString:[title stringByEllipsizingWithMaxLength:newLength preserveWords:YES]
                                                                    attributes:attributes];
            }
        }
    }
    
    return titleString;
}

+ (NSInteger)calculateTitleLengthWithSingleLineHeight:(CGFloat)singleLineHeight currentLineHeight:(CGFloat)currentLineHeight currentTitle:(NSAttributedString *)title {
    CGFloat allowedHeight = singleLineHeight * MaxNumberOfLinesForTitleForSummary;
    CGFloat overageRatio = allowedHeight / currentLineHeight;
    return [title length] * overageRatio;
}

+ (NSAttributedString *)summaryAttributedStringForString:(NSString *)string {
    NSString *summary = [string trim];
    NSInteger newline = [summary rangeOfString:@"\n"].location;
    
    if (newline != NSNotFound) {
        summary = [summary substringToIndex:newline];
    }
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineHeightMultiple:RPVLineHeightMultiple];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName : style,
                                 NSFontAttributeName : [self summaryFont]};
    NSMutableAttributedString *attributedSummary = [[NSMutableAttributedString alloc] initWithString:summary
                                                                                          attributes:attributes];
    
    NSDictionary *moreContentAttributes = @{NSParagraphStyleAttributeName: style,
                                            NSFontAttributeName: [self moreContentFont],
                                            NSForegroundColorAttributeName: [WPStyleGuide baseLighterBlue]};
    NSAttributedString *moreContent = [[NSAttributedString alloc] initWithString:[@"   " stringByAppendingString:NSLocalizedString(@"more", @"")] attributes:moreContentAttributes];
    [attributedSummary appendAttributedString:moreContent];
    
    return attributedSummary;
}

#pragma mark - LifeCycle Methods

- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame showFullContent:NO];
}

- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent {
    self = [super initWithFrame:frame];
    if (self) {
        self.showFullContent = showFullContent;
    }
    return self;
}

- (void)configurePost:(BasePost *)post withWidth:(CGFloat)width {
    // Subclasses override
}

- (CGFloat)contentWidth {
    CGFloat contentWidth = CGRectGetWidth(self.frame);
    // On iPad, get the width from the cell instead in order to account for margins
    if (IS_IPAD) {
        contentWidth = CGRectGetWidth(self.superview.frame);
    }
    return contentWidth;
}

- (CGFloat)innerContentWidth {
    return [self contentWidth] - RPVHorizontalInnerPadding * 2;
}

- (CGFloat)layoutFeaturedImageAt:(CGFloat)yPosition {
    // Are we showing an image? What size should it be?
	if (self.cellImageView.hidden) {
        return yPosition;
    }
    
    CGFloat contentWidth = [self contentWidth];
    CGFloat height = ceil(contentWidth * RPVMaxImageHeightPercentage);
    self.cellImageView.frame = CGRectMake(0.0f, yPosition, contentWidth, height);
    
    return CGRectGetMaxY(self.cellImageView.frame);
}

- (CGFloat)layoutTitleAt:(CGFloat)yPosition {
    CGFloat innerContentWidth = [self innerContentWidth];
    
    if (self.cellImageView.hidden && !self.byView.hidden) {
        self.titleBorder.hidden = NO;
        self.titleBorder.frame = CGRectMake(RPVHorizontalInnerPadding, yPosition, innerContentWidth, RPVBorderHeight);
    } else {
        self.titleBorder.hidden = YES;
    }
    
    yPosition += RPVVerticalPadding;
    
	// Position the title
	CGFloat height = ceil([self.titleLabel suggestedSizeForWidth:innerContentWidth].height);
	self.titleLabel.frame = CGRectMake(RPVHorizontalInnerPadding, yPosition, innerContentWidth, height);
	yPosition += height + RPVTitlePaddingBottom * (self.showFullContent ? 2.0 : 1.0);
    
    return yPosition;
}

- (CGFloat)layoutTextContentAt:(CGFloat)yPosition {
	// Position the snippet / content
    CGFloat height;
    CGFloat contentWidth = [self contentWidth];
    
    CGRect frame = CGRectZero;
    if (self.showFullContent) {
        [self.textContentView relayoutText];
        height = [self.textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:contentWidth].height;
        frame = CGRectMake(0.0f, yPosition, contentWidth, height);
        self.textContentView.frame = frame;
    } else {
        CGFloat innerContentWidth = [self innerContentWidth];
        height = ceil([self.snippetLabel suggestedSizeForWidth:innerContentWidth].height);
        frame = CGRectMake(RPVHorizontalInnerPadding, yPosition, innerContentWidth, height);
        self.snippetLabel.frame = frame;
    }
    
    return CGRectGetMaxY(frame) + RPVVerticalPadding;
}

@end
