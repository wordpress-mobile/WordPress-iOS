//
//  CommentTableViewCell.m
//  WordPress
//
//  Created by Josh Bassett on 2/07/09.
//

#import "CommentTableViewCell.h"
#import "CommentsTableViewDelegate.h"
#import <CommonCrypto/CommonDigest.h>

@interface CommentTableViewCell (Private)
- (void)addCheckButton;
- (void)addNameLabel;
- (void)addURLLabel;
- (void)addCommentLabel;
- (void)addAsynchronousImageView;
NSString *md5(NSString *str);

- (NSURL *)gravatarURLforEmail:(NSString *)emailString;
@end

@implementation CommentTableViewCell

@synthesize comment, checked;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

        [self addCheckButton];
        [self addNameLabel];
        [self addURLLabel];
        [self addCommentLabel];
        [self addAsynchronousImageView];
    }

    return self;
}

- (void)dealloc {
    [nameLabel release];
    [urlLabel release];
    [commentLabel release];
    [checkButton release];
    [super dealloc];
}

- (void)setEditing:(BOOL)value {
    [super setEditing:value];

    int buttonOffset = 0;

    [UIView beginAnimations:@"CommentCell" context:self];
    [UIView setAnimationDuration:0.25];

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

    CGRect nameRect = nameLabel.frame;
    nameRect.origin.x = GRAVATAR_OFFSET + buttonOffset;
    nameRect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
    nameLabel.frame = nameRect;

    CGRect urlRect = urlLabel.frame;
    urlRect.origin.x = GRAVATAR_OFFSET + buttonOffset;
    urlRect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
    urlLabel.frame = urlRect;

    CGRect commentRect = commentLabel.frame;
    commentRect.origin.x = GRAVATAR_OFFSET + buttonOffset;
    commentRect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
    commentLabel.frame = commentRect;

    CGRect gravatarRect = asynchronousImageView.frame;
    gravatarRect.origin.x = LEFT_OFFSET + buttonOffset;
    asynchronousImageView.frame = gravatarRect;

    [UIView commitAnimations];
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

    NSString *content = [comment valueForKey:@"content"];
    commentLabel.text = content;

    NSURL *theURL = [self gravatarURLforEmail:[comment valueForKey:@"author_email"]];
    [asynchronousImageView loadImageFromURL:theURL];
}

// Calls the tableView:didCheckRowAtIndexPath method on the table view delegate.
- (void)checkButtonPressed {
    UITableView *tableView = (UITableView *)self.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];

    [(id < CommentsTableViewDelegate >)tableView.delegate tableView:tableView didCheckRowAtIndexPath:indexPath];
}

#pragma mark Private methods

- (void)addCheckButton {
    CGRect rect = CGRectMake(LEFT_OFFSET, 15, 30, COMMENT_ROW_HEIGHT - 30);

    checkButton = [[UIButton alloc] initWithFrame:rect];
    [checkButton addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self setChecked:NO];

    [self.contentView addSubview:checkButton];
}

- (void)addNameLabel {
    CGRect rect = CGRectMake(GRAVATAR_OFFSET, 10, COMMENT_LABEL_WIDTH, LABEL_HEIGHT);

    nameLabel = [[UILabel alloc] initWithFrame:rect];
    nameLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
    nameLabel.highlightedTextColor = [UIColor whiteColor];
    nameLabel.adjustsFontSizeToFitWidth = NO;
    nameLabel.backgroundColor = [UIColor clearColor];

    [self.contentView addSubview:nameLabel];
}

- (void)addURLLabel {
    CGRect rect = CGRectMake(GRAVATAR_OFFSET, nameLabel.frame.origin.y + LABEL_HEIGHT, COMMENT_LABEL_WIDTH, LABEL_HEIGHT);

    urlLabel = [[UILabel alloc] initWithFrame:rect];
    urlLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    urlLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    urlLabel.adjustsFontSizeToFitWidth = NO;
    urlLabel.textColor = [UIColor grayColor];
    urlLabel.backgroundColor = [UIColor clearColor];

    [self.contentView addSubview:urlLabel];
}

- (void)addCommentLabel {
    CGRect rect = CGRectMake(GRAVATAR_OFFSET, urlLabel.frame.origin.y + LABEL_HEIGHT + VERTICAL_OFFSET, COMMENT_LABEL_WIDTH, NAME_LABEL_HEIGHT);

    commentLabel = [[UILabel alloc] initWithFrame:rect];
    commentLabel.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
    commentLabel.highlightedTextColor = [UIColor whiteColor];
    commentLabel.textColor = [UIColor colorWithRed:0.560f green:0.560f blue:0.560f alpha:1];
    commentLabel.numberOfLines = 3;
    commentLabel.lineBreakMode = UILineBreakModeTailTruncation;
    commentLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    commentLabel.backgroundColor = [UIColor clearColor];

    [self.contentView addSubview:commentLabel];
}

- (void)addAsynchronousImageView {
    CGRect rect = CGRectMake(LEFT_OFFSET, LEFT_OFFSET, 80, 80);

    asynchronousImageView = [[WPAsynchronousImageView alloc] initWithFrame:rect];
    [self.contentView addSubview:asynchronousImageView];
    [self bringSubviewToFront:asynchronousImageView];
}

- (NSURL *)gravatarURLforEmail:(NSString *)emailString {
    NSString *emailHash = [md5(emailString) lowercaseString];
    NSString *url = [[NSString alloc] initWithFormat:@"http://www.gravatar.com/avatar/%@s=80", emailHash];
    return [NSURL URLWithString:url];
}

#pragma mark -
#pragma mark md5

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

- (void)resetAsynchronousImageView {
    WPAsynchronousImageView *oldImage = asynchronousImageView;
    [oldImage removeFromSuperview];
    [self addAsynchronousImageView];
}

@end
