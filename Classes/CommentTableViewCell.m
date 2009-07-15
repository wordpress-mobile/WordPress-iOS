//
//  CommentTableViewCell.m
//  WordPress
//
//  Created by Josh Bassett on 2/07/09.
//

#import "CommentTableViewCell.h"

#import "CommentsTableViewDelegate.h"
#import <CommonCrypto/CommonDigest.h>

#define PADDING                     5
#define CELL_PADDING                8

#define TOP_OFFSET                  CELL_PADDING
#define LEFT_OFFSET                 CELL_PADDING

#define MAIN_FONT_SIZE              17
#define DATE_FONT_SIZE              13

#define COMMENT_LABEL_HEIGHT        40
#define COMMENT_LABEL_WIDTH         280

#define DATE_LABEL_HEIGHT           20
#define NAME_LABEL_HEIGHT           20
#define URL_LABEL_HEIGHT            15
#define POST_LABEL_HEIGHT           15

#define CHECK_BUTTON_CHECKED_ICON   @"check.png"
#define CHECK_BUTTON_UNCHECKED_ICON @"uncheck.png"

#define GRAVATAR_URL                @"http://www.gravatar.com/avatar/%@s=80"
#define GRAVATAR_WIDTH              47
#define GRAVATAR_HEIGHT             47
#define GRAVATAR_LEFT_OFFSET        LEFT_OFFSET + GRAVATAR_WIDTH + PADDING
#define GRAVATAR_TOP_OFFSET         TOP_OFFSET + GRAVATAR_HEIGHT + PADDING


@interface CommentTableViewCell (Private)

- (void)updateLayout;
- (void)addCheckButton;
- (void)addNameLabel;
- (void)addURLLabel;
- (void)addPostLabel;
- (void)addCommentLabel;
- (void)addGravatarImageView;

- (NSURL *)gravatarURLforEmail:(NSString *)emailString;
NSString *md5(NSString *str);

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
    [checkButton release];
    [super dealloc];
}

- (void)setEditing:(BOOL)value {
    [super setEditing:value];
    [self updateLayout];
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

    NSString *authorURL = [comment valueForKey:@"author_url"];
    urlLabel.text = authorURL;
    
    NSString *postTitle = [comment valueForKey:@"post_title"];
    postLabel.text = [NSString stringWithFormat:@"On: %@", postTitle];

    NSString *content = [comment valueForKey:@"content"];
    commentLabel.text = content;

    NSURL *theURL = [self gravatarURLforEmail:[comment valueForKey:@"author_email"]];
    [gravatarImageView loadImageFromURL:theURL];
}

// Calls the tableView:didCheckRowAtIndexPath method on the table view delegate.
- (void)checkButtonPressed {
    UITableView *tableView = (UITableView *)self.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];

    [(id < CommentsTableViewDelegate >)tableView.delegate tableView:tableView didCheckRowAtIndexPath:indexPath];
}

#pragma mark Private Methods

- (void)updateLayout {
    int buttonOffset = 0;
    
    if (self.editing) {
        buttonOffset = 35;
        checkButton.alpha = 1;
        checkButton.enabled = YES;
        self.accessoryType = UITableViewCellAccessoryNone;
    } else {
        checkButton.alpha = 0;
        checkButton.enabled = NO;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    CGRect gravatarRect = gravatarImageView.frame;
    gravatarRect.origin.x = LEFT_OFFSET + buttonOffset;
    gravatarImageView.frame = gravatarRect;
    
    CGRect nameRect = nameLabel.frame;
    nameRect.origin.x = GRAVATAR_LEFT_OFFSET + buttonOffset;
    nameRect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
    nameLabel.frame = nameRect;
    
    CGRect urlRect = urlLabel.frame;
    urlRect.origin.x = GRAVATAR_LEFT_OFFSET + buttonOffset;
    urlRect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
    urlLabel.frame = urlRect;
    
    CGRect postRect = postLabel.frame;
    postRect.origin.x = GRAVATAR_LEFT_OFFSET + buttonOffset;
    postRect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
    postLabel.frame = postRect;
    
    CGRect commentRect = commentLabel.frame;
    commentRect.origin.x = LEFT_OFFSET + buttonOffset;
    commentRect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
    commentLabel.frame = commentRect;
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
    
    gravatarImageView = [[WPAsynchronousImageView alloc] initWithFrame:rect];
    
    [self.contentView addSubview:gravatarImageView];
}

- (void)addNameLabel {
    CGRect rect = CGRectMake(GRAVATAR_LEFT_OFFSET, TOP_OFFSET, COMMENT_LABEL_WIDTH, NAME_LABEL_HEIGHT);

    nameLabel = [[UILabel alloc] initWithFrame:rect];
    nameLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.highlightedTextColor = [UIColor whiteColor];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;

    [self.contentView addSubview:nameLabel];
}

- (void)addURLLabel {
    CGRect rect = CGRectMake(GRAVATAR_LEFT_OFFSET, nameLabel.frame.origin.y + NAME_LABEL_HEIGHT, COMMENT_LABEL_WIDTH, URL_LABEL_HEIGHT);

    urlLabel = [[UILabel alloc] initWithFrame:rect];
    urlLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    urlLabel.backgroundColor = [UIColor clearColor];
    urlLabel.textColor = [UIColor grayColor];
    urlLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;

    [self.contentView addSubview:urlLabel];
}

- (void)addPostLabel {
    CGRect rect = CGRectMake(GRAVATAR_LEFT_OFFSET, urlLabel.frame.origin.y + URL_LABEL_HEIGHT, COMMENT_LABEL_WIDTH, POST_LABEL_HEIGHT);
    
    postLabel = [[UILabel alloc] initWithFrame:rect];
    postLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    postLabel.backgroundColor = [UIColor clearColor];
    postLabel.textColor = [UIColor grayColor];
    postLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    
    [self.contentView addSubview:postLabel];
}

- (void)addCommentLabel {
    CGRect rect = CGRectMake(LEFT_OFFSET, GRAVATAR_TOP_OFFSET, COMMENT_LABEL_WIDTH, COMMENT_LABEL_HEIGHT);

    commentLabel = [[WPLabel alloc] initWithFrame:rect];
    commentLabel.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
    commentLabel.backgroundColor = [UIColor clearColor];
    commentLabel.textColor = [UIColor colorWithRed:0.560f green:0.560f blue:0.560f alpha:1];
    commentLabel.highlightedTextColor = [UIColor whiteColor];
    commentLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    commentLabel.numberOfLines = 2;
    commentLabel.lineBreakMode = UILineBreakModeTailTruncation;
    commentLabel.verticalAlignment = VerticalAlignmentTop;

    [self.contentView addSubview:commentLabel];
}

- (NSURL *)gravatarURLforEmail:(NSString *)emailString {
    NSString *emailHash = [md5(emailString) lowercaseString];
    NSString *url = [NSString stringWithFormat:GRAVATAR_URL, emailHash];
    return [NSURL URLWithString:url];
}

NSString *md5(NSString *str) {
    const char *cStr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(cStr, strlen(cStr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
            ];
}

@end
