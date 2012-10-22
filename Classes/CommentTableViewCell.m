//
//  CommentTableViewCell.m
//  WordPress
//
//  Created by Josh Bassett on 2/07/09.
//

#import <QuartzCore/QuartzCore.h>
#import "CommentTableViewCell.h"
#import "CommentsTableViewDelegate.h"
#import "NSString+XMLExtensions.h" 
#import "UIImageView+Gravatar.h"

#define PADDING                     5
#define CELL_PADDING                8

#define TOP_OFFSET                  CELL_PADDING
#define LEFT_OFFSET                 CELL_PADDING

#define NAME_FONT_SIZE              17
#define COMMENT_FONT_SIZE           15

#define COMMENT_LABEL_HEIGHT        80
#define COMMENT_LABEL_WIDTH         280

#define OTHER_LABEL_WIDTH           220
#define DATE_LABEL_HEIGHT           20
#define NAME_LABEL_HEIGHT           19
#define URL_LABEL_HEIGHT            15
#define POST_LABEL_HEIGHT           15

#define CHECK_BUTTON_CHECKED_ICON   @"check.png"
#define CHECK_BUTTON_UNCHECKED_ICON @"uncheck.png"

#define GRAVATAR_WIDTH              47
#define GRAVATAR_HEIGHT             47
#define GRAVATAR_LEFT_OFFSET        ( LEFT_OFFSET + GRAVATAR_WIDTH + CELL_PADDING )
#define GRAVATAR_TOP_OFFSET         ( TOP_OFFSET + GRAVATAR_HEIGHT + PADDING )


@interface CommentTableViewCell (Private)

- (void)updateLayout:(BOOL)editing;
- (void)addCheckButton;
- (void)addNameLabel;
- (void)addURLLabel;
- (void)addPostLabel;
- (void)addCommentLabel;
- (void)addGravatarImageView;

@end


@implementation CommentTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        [self addCheckButton];
        [self addNameLabel];
        [self addURLLabel];
        [self addPostLabel];
        [self addCommentLabel];
        [self addGravatarImageView];
    }

    return self;
}


- (BOOL)checked {
    return checked;
}

- (void)setChecked:(BOOL)value {
    checked = value;

    if (checked) {
        [checkButton setImage:[UIImage imageNamed:CHECK_BUTTON_CHECKED_ICON] forState:UIControlStateNormal];
    } else {
        [checkButton setImage:[UIImage imageNamed:CHECK_BUTTON_UNCHECKED_ICON] forState:UIControlStateNormal];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [self setChecked:checked];
    [super setEditing:editing animated:animated];
}

- (Comment *)comment {
    return comment;
}

- (void)setComment:(Comment *)value {
    comment = value;

    NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
    NSString *author = [[comment.author stringByDecodingXMLCharacters] stringByTrimmingCharactersInSet:whitespaceCS];
    nameLabel.text = author;
	
//conditional load of author_email if url is empty per ticket #273
    NSString *authorURL = comment.author_url;
	if ( authorURL == nil || [authorURL isEqualToString:@"http://"] || [authorURL isEqualToString:@""]) {
		//NSLog(@"authorURL was nill or empty");
		urlLabel.text = comment.author_email;
	}else {
		urlLabel.text = authorURL;
	}

    if (comment.postTitle)
		postLabel.text = [NSLocalizedString(@"on ", @"") stringByAppendingString:[comment.postTitle stringByDecodingXMLCharacters]];
    commentLabel.text = [comment.content stringByDecodingXMLCharacters];
    [gravatarImageView setImageWithGravatarEmail:comment.author_email];
}

// Calls the tableView:didCheckRowAtIndexPath method on the table view delegate.
- (void)checkButtonPressed {
    UITableView *tableView = (UITableView *)self.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];

    [(id<CommentsTableViewDelegate>)tableView.delegate tableView:tableView didCheckRowAtIndexPath:indexPath];
}

#pragma mark Private Methods

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect;
    int buttonOffset = 0;
    
    if (self.editing) {
        buttonOffset = 35;
        checkButton.alpha = 1;
        checkButton.enabled = YES;
        self.accessoryType = UITableViewCellAccessoryNone;
    } else {
        checkButton.alpha = 0;
        checkButton.enabled = NO;
        if (IS_IPAD == YES) {
            self.accessoryType = UITableViewCellAccessoryNone;
        } else {
            self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
 
    CGFloat width = self.bounds.size.width - CELL_PADDING;
    CGFloat gravatarWidth = width - GRAVATAR_LEFT_OFFSET;
    
    if ( self.accessoryType == UITableViewCellAccessoryDisclosureIndicator ) {
        gravatarWidth -= 22;
        width -= 22;
    }
    
    rect = gravatarImageView.frame;
    rect.origin.x = LEFT_OFFSET + buttonOffset;
    gravatarImageView.frame = rect;
    
    rect = nameLabel.frame;
    rect.origin.x = GRAVATAR_LEFT_OFFSET + buttonOffset;
    rect.size.width = gravatarWidth - buttonOffset;
    nameLabel.frame = rect;
    
    rect = urlLabel.frame;
    rect.origin.x = GRAVATAR_LEFT_OFFSET + buttonOffset;
    rect.size.width = gravatarWidth - buttonOffset;
    urlLabel.frame = rect;
    
    rect = postLabel.frame;
    rect.origin.x = GRAVATAR_LEFT_OFFSET + buttonOffset;
    rect.size.width = gravatarWidth - buttonOffset;
    postLabel.frame = rect;
    
    rect = commentLabel.frame;
    rect.origin.x = LEFT_OFFSET + buttonOffset;
    rect.size.width = width - buttonOffset;
    commentLabel.frame = rect;
    
    rect = checkButton.frame;
    rect.origin.y = (self.frame.size.height - 30.0f) / 2.0f;
    checkButton.frame = rect;
}

+ (float) calculateCommentCellHeight:(NSString *)commentText availableWidth:(CGFloat)availableWidth {
    CGFloat width = availableWidth - CELL_PADDING;
    if (IS_IPHONE) 
         width -= 22;
    CGSize maximumLabelSize = CGSizeMake(width,COMMENT_LABEL_HEIGHT);
    CGSize expectedLabelSize = [commentText sizeWithFont:[UIFont systemFontOfSize:COMMENT_FONT_SIZE] constrainedToSize:maximumLabelSize lineBreakMode:UILineBreakModeTailTruncation];   
    // WPLog(@"Expected text size: %f", expectedLabelSize.height);
    return GRAVATAR_TOP_OFFSET + MIN(expectedLabelSize.height, 60) + CELL_PADDING;
}

- (void)addCheckButton {

    CGRect rect = CGRectMake(LEFT_OFFSET, (COMMENT_ROW_HEIGHT - 30.0f)/2, 30.0, 30.0f);
    checkButton = [[UIButton alloc] initWithFrame:rect];
    [checkButton addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self setChecked:NO];
    checkButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:checkButton];
}

- (void)addGravatarImageView {
    CGRect rect = CGRectMake(LEFT_OFFSET, TOP_OFFSET, GRAVATAR_WIDTH, GRAVATAR_HEIGHT);
    
    gravatarImageView = [[UIImageView alloc] initWithFrame:rect];
    
    [self.contentView addSubview:gravatarImageView];
}

- (void)addNameLabel {
    CGRect rect = CGRectMake(GRAVATAR_LEFT_OFFSET, TOP_OFFSET, OTHER_LABEL_WIDTH, NAME_LABEL_HEIGHT);

    nameLabel = [[UILabel alloc] initWithFrame:rect];
    nameLabel.font = [UIFont boldSystemFontOfSize:NAME_FONT_SIZE];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.highlightedTextColor = [UIColor whiteColor];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [self.contentView addSubview:nameLabel];
}

- (void)addURLLabel {
    CGRect rect = CGRectMake(GRAVATAR_LEFT_OFFSET, TOP_OFFSET + NAME_LABEL_HEIGHT, OTHER_LABEL_WIDTH, URL_LABEL_HEIGHT);

    urlLabel = [[UILabel alloc] initWithFrame:rect];
    urlLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    urlLabel.backgroundColor = [UIColor clearColor];
    urlLabel.textColor = [UIColor colorWithRed:70.0f/255.0f green:70.0f/255.0f blue:70.0f/255.0f alpha:1.0f];
    urlLabel.highlightedTextColor = [UIColor whiteColor];
    urlLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;

    [self.contentView addSubview:urlLabel];
}

- (void)addPostLabel {
    CGRect rect = CGRectMake(GRAVATAR_LEFT_OFFSET, TOP_OFFSET + NAME_LABEL_HEIGHT + URL_LABEL_HEIGHT, OTHER_LABEL_WIDTH, POST_LABEL_HEIGHT);
    
    postLabel = [[UILabel alloc] initWithFrame:rect];
    postLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    postLabel.backgroundColor = [UIColor clearColor];
    postLabel.textColor = [UIColor colorWithRed:70.0f/255.0f green:70.0f/255.0f blue:70.0f/255.0f alpha:1.0f];
	postLabel.highlightedTextColor = [UIColor whiteColor];
    postLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    
    [self.contentView addSubview:postLabel];
}

- (void)addCommentLabel {
    CGRect rect = CGRectMake(LEFT_OFFSET, GRAVATAR_TOP_OFFSET, COMMENT_LABEL_WIDTH, COMMENT_LABEL_HEIGHT);

    commentLabel = [[WPLabel alloc] initWithFrame:rect];
    commentLabel.font = [UIFont systemFontOfSize:COMMENT_FONT_SIZE];
    commentLabel.backgroundColor = [UIColor clearColor];
    commentLabel.textColor = [UIColor colorWithRed:34.0f/255.0f green:34.0f/255.0f blue:34.0f/255.0f alpha:1.0f];
    commentLabel.highlightedTextColor = [UIColor whiteColor];
    commentLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    commentLabel.numberOfLines = 3;
    commentLabel.lineBreakMode = UILineBreakModeTailTruncation;
    commentLabel.verticalAlignment = VerticalAlignmentTop;

    [self.contentView addSubview:commentLabel];
}

@end
