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
NSString* md5( NSString *str );
- (NSURL *) gravatarURLforEmail:(NSString *)emailString;
@end

@implementation CommentTableViewCell

@synthesize comment = _comment, checked = _checked;

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
    [_nameLabel release];
    [_urlLabel release];
    [_commentLabel release];
    [_checkButton release];
    [super dealloc];
}

- (void)setEditing:(BOOL)value {
    [super setEditing:value];
    
    int buttonOffset = 0;
    
    [UIView beginAnimations:@"CommentCell" context:self];
    [UIView setAnimationDuration:0.25];
    
    if (self.editing) {
        buttonOffset = 35;
        _checkButton.alpha = 1;
        _checkButton.enabled = YES;
        self.accessoryType = UITableViewCellAccessoryNone;
    } else {
        _checkButton.alpha = 0;
        _checkButton.enabled = NO;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    CGRect nameRect = _nameLabel.frame;
    nameRect.origin.x = GRAVATAR_OFFSET + buttonOffset;
    nameRect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
    _nameLabel.frame = nameRect;
    
    CGRect urlRect = _urlLabel.frame;
    urlRect.origin.x = GRAVATAR_OFFSET + buttonOffset;
    urlRect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
    _urlLabel.frame = urlRect;
    
    CGRect commentRect = _commentLabel.frame;
    commentRect.origin.x = GRAVATAR_OFFSET + buttonOffset;
    commentRect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
    _commentLabel.frame = commentRect;
    
    CGRect gravatarRect = asynchronousImageView.frame;
    gravatarRect.origin.x = LEFT_OFFSET + buttonOffset;
    asynchronousImageView.frame = gravatarRect;
    
    [UIView commitAnimations];
}

- (void)setChecked:(BOOL)value {
    _checked = value;
    
    if (_checked) {
        [_checkButton setImage:[UIImage imageNamed:CHECK_BUTTON_CHECKED_ICON] forState:UIControlStateNormal];
    } else {
        [_checkButton setImage:[UIImage imageNamed:CHECK_BUTTON_UNCHECKED_ICON] forState:UIControlStateNormal];
    }
}

- (void)setComment:(NSDictionary *)value {
    _comment = value;
    
	NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
	NSString *author = [[_comment valueForKey:@"author"] stringByTrimmingCharactersInSet:whitespaceCS];
	_nameLabel.text = author;
	
	NSString *authorURL = [_comment valueForKey:@"author_url"];
	_urlLabel.text = authorURL;
	
	NSString *content= [_comment valueForKey:@"content"];
	_commentLabel.text = content;
    
    NSURL *theURL = [self gravatarURLforEmail:[_comment valueForKey:@"author_email"]];
    [asynchronousImageView loadImageFromURL:theURL];
}

// Calls the tableView:didCheckRowAtIndexPath method on the table view delegate.
- (void)checkButtonPressed {
//    UITableView *tableView = self.target;
    UITableView *tableView = (UITableView *)self.superview;

    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    
    [(id<CommentsTableViewDelegate>)tableView.delegate tableView:tableView didCheckRowAtIndexPath:indexPath];
}

#pragma mark Private methods

- (void)addCheckButton {
    CGRect rect = CGRectMake(LEFT_OFFSET, 15, 30, COMMENT_ROW_HEIGHT - 30);
    
    _checkButton = [[UIButton alloc] initWithFrame:rect]; 
    [_checkButton addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self setChecked:NO];

    [self.contentView addSubview:_checkButton];
}

- (void)addNameLabel {
    CGRect rect = CGRectMake(GRAVATAR_OFFSET, 10, COMMENT_LABEL_WIDTH, LABEL_HEIGHT);
    
    _nameLabel = [[UILabel alloc] initWithFrame:rect];
    _nameLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
    _nameLabel.highlightedTextColor = [UIColor whiteColor];
    _nameLabel.adjustsFontSizeToFitWidth = NO;
    
    [self.contentView addSubview:_nameLabel];
}

- (void)addURLLabel {
    CGRect rect = CGRectMake(GRAVATAR_OFFSET, _nameLabel.frame.origin.y + LABEL_HEIGHT, COMMENT_LABEL_WIDTH, LABEL_HEIGHT);
    
    _urlLabel = [[UILabel alloc]initWithFrame:rect];
    _urlLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    _urlLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
	_urlLabel.adjustsFontSizeToFitWidth = NO;
	_urlLabel.textColor = [UIColor grayColor];
    
    [self.contentView addSubview:_urlLabel];
}

- (void)addCommentLabel {
    CGRect rect = CGRectMake(GRAVATAR_OFFSET, _urlLabel.frame.origin.y + LABEL_HEIGHT + VERTICAL_OFFSET, COMMENT_LABEL_WIDTH, NAME_LABEL_HEIGHT);
    
    _commentLabel = [[UILabel alloc] initWithFrame:rect];
    _commentLabel.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
    _commentLabel.highlightedTextColor = [UIColor whiteColor];
    _commentLabel.textColor = [UIColor colorWithRed:0.560f green:0.560f blue:0.560f alpha:1];
    _commentLabel.numberOfLines = 3;
    _commentLabel.lineBreakMode = UILineBreakModeTailTruncation;
    _commentLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    
    [self.contentView addSubview:_commentLabel];
}

- (void)addAsynchronousImageView {
    CGRect rect = CGRectMake(LEFT_OFFSET, LEFT_OFFSET, 80, 80);
    
    asynchronousImageView = [[WPAsynchronousImageView alloc] initWithFrame:rect];
    [self.contentView addSubview:asynchronousImageView];
    [self bringSubviewToFront:asynchronousImageView];
}

- (NSURL *) gravatarURLforEmail:(NSString *)emailString {
    NSString *emailHash = [md5(emailString) lowercaseString];
    NSString *url = [[NSString alloc] initWithFormat:@"http://www.gravatar.com/avatar/%@s=80", emailHash];
    return [NSURL URLWithString:url];
}

#pragma mark -
#pragma mark md5

NSString* md5( NSString *str )
{
    const char *cStr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
            ];
} 

- (void) resetAsynchronousImageView {
    WPAsynchronousImageView* oldImage = asynchronousImageView;
	[oldImage removeFromSuperview];
    [self addAsynchronousImageView];
}

@end