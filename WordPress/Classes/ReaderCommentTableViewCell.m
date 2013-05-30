//
//  ReaderCommentTableViewCell.m
//  WordPress
//
//  Created by Eric J on 5/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderCommentTableViewCell.h"
#import <DTCoreText/DTCoreText.h>
#import "UIImageView+Gravatar.h"
#import "WordPressAppDelegate.h"

#define RCTVCVerticalPadding 5.0f;

@interface ReaderCommentTableViewCell()<DTAttributedTextContentViewDelegate>

@property (nonatomic, strong) ReaderComment *comment;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *dateLabel;

- (CGFloat)requiredRowHeightForWidth:(CGFloat)width tableStyle:(UITableViewStyle)style;

@end

@implementation ReaderCommentTableViewCell

+ (NSArray *)cellHeightsForComments:(NSArray *)comments
							  width:(CGFloat)width
						 tableStyle:(UITableViewStyle)tableStyle
						  cellStyle:(UITableViewCellStyle)cellStyle
					reuseIdentifier:(NSString *)reuseIdentifier {
	
	NSMutableArray *heights = [NSMutableArray arrayWithCapacity:[comments count]];
	ReaderCommentTableViewCell *cell = [[ReaderCommentTableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:reuseIdentifier];
	for (ReaderComment *comment in comments) {
		[cell configureCell:comment];
		CGFloat height = [cell requiredRowHeightForWidth:width tableStyle:tableStyle];
		[heights addObject:[NSNumber numberWithFloat:height]];
	}
	
	return heights;
}


#pragma mark - Lifecycle Methods

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		CGFloat width = self.frame.size.width;
		
		[self.cellImageView setFrame:CGRectMake(10.0f, 10.0f, 20.0f, 20.0f)];
		self.cellImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		
		self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - (10.0f + 30.0f), 10.0f, 30.0f, 20.0f)];
		[_dateLabel setFont:[UIFont systemFontOfSize:14.0f]];
		_dateLabel.textColor = [UIColor grayColor];
		_dateLabel.textAlignment = NSTextAlignmentRight;
		_dateLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		_dateLabel.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:_dateLabel];
		
		self.authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(40.0f, 10.0f, (_dateLabel.frame.origin.x - 50.0f), 20.0f)];
		[_authorLabel setFont:[UIFont systemFontOfSize:14.0f]];
		_dateLabel.textColor = [UIColor grayColor];
		_authorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_authorLabel.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:_authorLabel];
		
		
		UIImageView *separatorImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-separator"]];
		separatorImageView.frame = CGRectMake(0.0f, 0.0f, width, 2.0f);
		separatorImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:separatorImageView];
		
		self.textContentView.frame = CGRectMake(0.0f, _authorLabel.frame.size.height + 10.0f, width, 44.0f);
		
		UIView *view = [[UIView alloc] initWithFrame:self.bounds];
		view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		view.backgroundColor = [UIColor colorWithHexString:@"A9E2F3"];
		
		CGRect rect = CGRectMake(0, 0, 1, 1);
		UIGraphicsBeginImageContext(rect.size);
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSetFillColorWithColor(context, [[UIColor colorWithHexString:@"EFEFEF"] CGColor]);
		CGContextFillRect(context, rect);
		UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		UIView *colorView = [[UIImageView alloc] initWithImage:img];
		colorView.frame = CGRectMake(0.0f, 0.0f, width, 2.0f);
		colorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

		[view addSubview:colorView];

		[self setSelectedBackgroundView:view];
    }
	
    return self;
}


- (void)layoutSubviews {
	[super layoutSubviews];
	
	// We have to manually update the indentation of the content view? wtf.
	CGRect frame = self.contentView.frame;
	frame.origin.x += (self.indentationWidth * self.indentationLevel);
	frame.size.width -= frame.origin.x;
	self.contentView.frame = frame;
	
	[self.cellImageView setFrame:CGRectMake(10.0f, 10.0f, 20.0f, 20.0f)];
	
	CGFloat width = self.contentView.frame.size.width;
	CGFloat height = [self.textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:width].height;

	self.textContentView.frame = CGRectMake(0.0f, _authorLabel.frame.size.height + 10.0f, width, height);
	[self.textContentView layoutSubviews];
}


- (void)prepareForReuse {
	[super prepareForReuse];
	
	_authorLabel.text = @"";
	_dateLabel.text = @"";
}


#pragma mark - Instance Methods

- (CGFloat)requiredRowHeightForWidth:(CGFloat)width tableStyle:(UITableViewStyle)style {
	
	CGFloat desiredHeight = self.authorLabel.frame.size.height + 15.0f; // author + padding above, below, and between
	
	// Do the math. We can't trust the cell's contentView's frame because
	// its not updated at a useful time during rotation.
	CGFloat contentWidth = width;
	
	// reduce width for accessories
	switch (self.accessoryType) {
		case UITableViewCellAccessoryDisclosureIndicator:
		case UITableViewCellAccessoryCheckmark:
			contentWidth -= 20.0f;
			break;
		case UITableViewCellAccessoryDetailDisclosureButton:
			contentWidth -= 33.0f;
			break;
		case UITableViewCellAccessoryNone:
			break;
	}
	
	// reduce width for grouped table views
	if (style == UITableViewStyleGrouped) {
		contentWidth -= 19;
	}
	
	// Cell indentation 
	contentWidth -= (self.indentationLevel * self.indentationWidth);
	
	desiredHeight += [self.textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:contentWidth].height;
	
	return desiredHeight;
}


- (void)configureCell:(ReaderComment *)comment {
	self.comment = comment;
	
	self.indentationWidth = 10.0f;
	self.indentationLevel = [comment.depth integerValue];
	
	[self.contentView addSubview:self.cellImageView];
	
	_dateLabel.text = [comment shortDate];
	_authorLabel.text = comment.author;
	[self.cellImageView setImageWithURL:[NSURL URLWithString:comment.authorAvatarURL] placeholderImage:[UIImage imageNamed:@"blavatar-wpcom.png"]];
	
	NSString *html = [NSString stringWithFormat:@"<style>a{color:#3478E3;}</style>%@", comment.content];
	self.textContentView.attributedString = [self convertHTMLToAttributedString:html withOptions:nil];
}

@end
