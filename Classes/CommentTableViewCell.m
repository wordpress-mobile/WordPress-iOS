//
//  CommentTableViewCell.m
//  WordPress
//
//  Created by Josh Bassett on 2/07/09.
//

#import "CommentTableViewCell.h"
#import "CommentsTableViewDelegate.h"

#define PADDING                     5
#define CELL_PADDING                8

#define TOP_OFFSET                  CELL_PADDING
#define LEFT_OFFSET                 CELL_PADDING

#define NAME_FONT_SIZE              17
#define COMMENT_FONT_SIZE           13

#define COMMENT_LABEL_HEIGHT        40
#define COMMENT_LABEL_WIDTH         280

#define OTHER_LABEL_WIDTH           220
#define DATE_LABEL_HEIGHT           20
#define NAME_LABEL_HEIGHT           17
#define URL_LABEL_HEIGHT            15
#define POST_LABEL_HEIGHT           15

#define CHECK_BUTTON_CHECKED_ICON   @"check.png"
#define CHECK_BUTTON_UNCHECKED_ICON @"uncheck.png"

#define GRAVATAR_WIDTH              47
#define GRAVATAR_HEIGHT             47
#define GRAVATAR_LEFT_OFFSET        LEFT_OFFSET + GRAVATAR_WIDTH + CELL_PADDING
#define GRAVATAR_TOP_OFFSET         TOP_OFFSET + GRAVATAR_HEIGHT + PADDING


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

@synthesize comment, checked;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

        [self addCheckButton];
        [self addNameLabel];
        [self addURLLabel];
        [self addPostLabel];
        [self addCommentLabel];
        [self addGravatarImageView];
    }

    return self;
}

- (void)dealloc {
    [nameLabel release];
    [urlLabel release];
    [postLabel release];
    [commentLabel release];
    [gravatarImageView release];
    [checkButton release];
    [super dealloc];
}

- (void)setEditing:(BOOL)value animated:(BOOL)animated {
    if (animated) {
        [UIView beginAnimations:@"CommentCell" context:self];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.25];
    }

    [self updateLayout:value];

    if (animated) {
        [UIView commitAnimations];
    }
}

- (void)setChecked:(BOOL)value {
    checked = value;

    if (checked) {
        [checkButton setImage:[UIImage imageNamed:CHECK_BUTTON_CHECKED_ICON] forState:UIControlStateNormal];
    } else {
        [checkButton setImage:[UIImage imageNamed:CHECK_BUTTON_UNCHECKED_ICON] forState:UIControlStateNormal];
    }
}

- (void)setComment:(NSDictionary *)value {
    comment = value;

    NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
    NSString *author = [[comment valueForKey:@"author"] stringByTrimmingCharactersInSet:whitespaceCS];
    nameLabel.text = author;
	
//conditional load of author_email if url is empty per ticket #273
    NSString *authorURL = [comment valueForKey:@"author_url"];
	if ( authorURL == nil || [authorURL isEqualToString:@"http://"] || [authorURL isEqualToString:@""]) {
		//NSLog(@"authorURL was nill or empty");
		NSString *emailInsteadOfURL = [comment valueForKey:@"author_email"];
		urlLabel.text = emailInsteadOfURL;
	}else {
		urlLabel.text = authorURL;
	}

    
    NSString *postTitle = [comment valueForKey:@"post_title"];
    postLabel.text = [@"on " stringByAppendingString:postTitle];

    NSString *content = [comment valueForKey:@"content"];
    commentLabel.text = content;

    NSString *email = [comment valueForKey:@"author_email"];
    gravatarImageView.email = email;
}

// Calls the tableView:didCheckRowAtIndexPath method on the table view delegate.
- (void)checkButtonPressed {
    UITableView *tableView = (UITableView *)self.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];

    [(id<CommentsTableViewDelegate>)tableView.delegate tableView:tableView didCheckRowAtIndexPath:indexPath];
}

#pragma mark Private Methods

- (void)updateLayout:(BOOL)editing {
    CGRect rect;
    int buttonOffset = 0;
    
    if (editing) {
        buttonOffset = 35;
        checkButton.alpha = 1;
        checkButton.enabled = YES;
        self.accessoryType = UITableViewCellAccessoryNone;
    } else {
        checkButton.alpha = 0;
        checkButton.enabled = NO;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    rect = gravatarImageView.frame;
    rect.origin.x = LEFT_OFFSET + buttonOffset;
    gravatarImageView.frame = rect;
    
    rect = nameLabel.frame;
    rect.origin.x = GRAVATAR_LEFT_OFFSET + buttonOffset;
    rect.size.width = OTHER_LABEL_WIDTH - buttonOffset;
    nameLabel.frame = rect;
    
    rect = urlLabel.frame;
    rect.origin.x = GRAVATAR_LEFT_OFFSET + buttonOffset;
    rect.size.width = OTHER_LABEL_WIDTH - buttonOffset;
    urlLabel.frame = rect;
    
    rect = postLabel.frame;
    rect.origin.x = GRAVATAR_LEFT_OFFSET + buttonOffset;
    rect.size.width = OTHER_LABEL_WIDTH - buttonOffset;
    postLabel.frame = rect;
    
    rect = commentLabel.frame;
    rect.origin.x = LEFT_OFFSET + buttonOffset;
    rect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
    commentLabel.frame = rect;
}

- (void)addCheckButton {
    CGRect rect = CGRectMake(LEFT_OFFSET, 15, 30, COMMENT_ROW_HEIGHT - 30);

    checkButton = [[UIButton alloc] initWithFrame:rect];
    [checkButton addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self setChecked:NO];

    [self.contentView addSubview:checkButton];
}

- (void)addGravatarImageView {
    CGRect rect = CGRectMake(LEFT_OFFSET, TOP_OFFSET, GRAVATAR_WIDTH, GRAVATAR_HEIGHT);
    
    gravatarImageView = [[GravatarImageView alloc] initWithFrame:rect];
    
    [self.contentView addSubview:gravatarImageView];
}

- (void)addNameLabel {
    CGRect rect = CGRectMake(GRAVATAR_LEFT_OFFSET, TOP_OFFSET, OTHER_LABEL_WIDTH, NAME_LABEL_HEIGHT);

    nameLabel = [[UILabel alloc] initWithFrame:rect];
    nameLabel.font = [UIFont boldSystemFontOfSize:NAME_FONT_SIZE];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.highlightedTextColor = [UIColor whiteColor];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;

    [self.contentView addSubview:nameLabel];
}

- (void)addURLLabel {
    CGRect rect = CGRectMake(GRAVATAR_LEFT_OFFSET, nameLabel.frame.origin.y + NAME_LABEL_HEIGHT, OTHER_LABEL_WIDTH, URL_LABEL_HEIGHT);

    urlLabel = [[UILabel alloc] initWithFrame:rect];
    urlLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    urlLabel.backgroundColor = [UIColor clearColor];
    urlLabel.textColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8];
    urlLabel.highlightedTextColor = [UIColor whiteColor];
    urlLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;

    [self.contentView addSubview:urlLabel];
}

- (void)addPostLabel {
    CGRect rect = CGRectMake(GRAVATAR_LEFT_OFFSET, urlLabel.frame.origin.y + URL_LABEL_HEIGHT, OTHER_LABEL_WIDTH, POST_LABEL_HEIGHT);
    
    postLabel = [[UILabel alloc] initWithFrame:rect];
    postLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    postLabel.backgroundColor = [UIColor clearColor];
    postLabel.textColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8];
	postLabel.highlightedTextColor = [UIColor whiteColor];
    postLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    
    [self.contentView addSubview:postLabel];
}

- (void)addCommentLabel {
    CGRect rect = CGRectMake(LEFT_OFFSET, GRAVATAR_TOP_OFFSET, COMMENT_LABEL_WIDTH, COMMENT_LABEL_HEIGHT);

    commentLabel = [[WPLabel alloc] initWithFrame:rect];
    commentLabel.font = [UIFont systemFontOfSize:COMMENT_FONT_SIZE];
    commentLabel.backgroundColor = [UIColor clearColor];
    commentLabel.textColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8];
    commentLabel.highlightedTextColor = [UIColor whiteColor];
    commentLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    commentLabel.numberOfLines = 2;
    commentLabel.lineBreakMode = UILineBreakModeTailTruncation;
    commentLabel.verticalAlignment = VerticalAlignmentTop;

    [self.contentView addSubview:commentLabel];
}

@end
