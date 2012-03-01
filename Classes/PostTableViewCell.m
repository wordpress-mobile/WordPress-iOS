//
//  PostTableViewCell.m
//  WordPress
//
//  Created by Josh Bassett on 1/07/09.
//

#import "PostTableViewCell.h"
#import "NSString+XMLExtensions.h"

@interface PostTableViewCell (Private)
- (void)addNameLabel;
- (void)addDateLabel;
- (void)addStatusLabel;
- (void)addActivityIndicator;

@end

@implementation PostTableViewCell

@synthesize post;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        [self addNameLabel];
        [self addDateLabel];
		[self addStatusLabel];
        [self addActivityIndicator];
    }

    return self;
}

- (void)dealloc {
    [nameLabel release];
    [dateLabel release];
	[statusLabel release];
    [activityIndicator release];
    [super dealloc];
}

- (void)setSaving:(BOOL)value {
    saving = value;

    if (saving) {
        activityIndicator.hidden = NO;

        [activityIndicator startAnimating];

        UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:POST_LOCK_IMAGE]];
        self.accessoryView = image;
        [image release];
    } else {
        activityIndicator.hidden = YES;

        if ([activityIndicator isAnimating]) {
            [activityIndicator stopAnimating];
        }

        if ([self.accessoryView isKindOfClass:[UIImageView class]]) {
            self.accessoryView = nil;
        }
    }
}

- (AbstractPost *)post {
    return post;
}

- (void)setPost:(AbstractPost *)value {
    post = value;
    
    static NSDateFormatter *dateFormatter = nil;
    
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    }
    
    NSString *title = [[post valueForKey:@"postTitle"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (title == nil || ([title length] == 0)) {
        title = NSLocalizedString(@"(no title)", @"");
    }
    
    nameLabel.text = [title stringByDecodingXMLCharacters];
    if ([post.status isEqualToString:@"pending"]) {
        statusLabel.textColor = [UIColor lightGrayColor];
        statusLabel.text = NSLocalizedString(@"Pending", @"");
    } else if ([post.status isEqualToString:@"draft"]) {
        statusLabel.textColor = [UIColor colorWithRed:0.796875f green:0.0f blue:0.0f alpha:1.0f];
        statusLabel.text = post.statusTitle;
    } else {
        statusLabel.textColor = [UIColor blackColor];
        statusLabel.text = @"";
    }

    CGRect rect = statusLabel.frame;
    CGSize statusSize = [statusLabel.text sizeWithFont:statusLabel.font];
    rect.size.width = statusSize.width;
    rect.origin.x = 288 - statusSize.width;
    statusLabel.frame = rect;
    
    NSDate *date = [post valueForKey:@"dateCreated"];
    dateLabel.text = [dateFormatter stringFromDate:date];
    
    @try {
        if(post.remoteStatus != AbstractPostRemoteStatusPushing)
            saving = NO;
        else
            saving = YES;
    }
    @catch (NSException * e) {
        saving = NO;
    }
}

- (void)prepareForReuse{
	[super prepareForReuse];
	//change back the things that are different about the "more posts/pages/comments" cell so that reuse
	//does not cause UI strangeness for users
	self.contentView.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
	nameLabel.textColor = [UIColor blackColor];
	dateLabel.textColor = [UIColor lightGrayColor];
	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	self.selectionStyle = UITableViewCellSelectionStyleBlue;
	
	CGRect rect = CGRectMake(LEFT_OFFSET, nameLabel.frame.origin.y + LABEL_HEIGHT + VERTICAL_OFFSET, 320, DATE_LABEL_HEIGHT);
	dateLabel.frame = rect;
	
	
	[self runSpinner:NO];
}


#pragma mark Private methods

- (void)addNameLabel {
    CGRect rect = CGRectMake(LEFT_OFFSET, (POST_ROW_HEIGHT - LABEL_HEIGHT - DATE_LABEL_HEIGHT - VERTICAL_OFFSET) / 2.0, 288, LABEL_HEIGHT);

    nameLabel = [[UILabel alloc] initWithFrame:rect];
    nameLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
    nameLabel.highlightedTextColor = [UIColor whiteColor];
    nameLabel.backgroundColor = [UIColor clearColor];

    [self.contentView addSubview:nameLabel];
}

- (void)addDateLabel {
    CGRect rect = CGRectMake(LEFT_OFFSET, nameLabel.frame.origin.y + LABEL_HEIGHT + VERTICAL_OFFSET, RIGHT_OFFSET - LEFT_OFFSET, DATE_LABEL_HEIGHT);

    dateLabel = [[UILabel alloc] initWithFrame:rect];
    dateLabel.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
    dateLabel.highlightedTextColor = [UIColor whiteColor];
    dateLabel.textColor = [UIColor lightGrayColor];
    dateLabel.backgroundColor = [UIColor clearColor];

    [self.contentView addSubview:dateLabel];
}

- (void)addStatusLabel {
    CGRect rect = CGRectMake(288 - STATUS_LABEL_WIDTH, nameLabel.frame.origin.y + LABEL_HEIGHT + VERTICAL_OFFSET, STATUS_LABEL_WIDTH, DATE_LABEL_HEIGHT);
	
	statusLabel = [[UILabel alloc] initWithFrame:rect];
    statusLabel.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
    statusLabel.textColor = [UIColor blackColor];
    statusLabel.backgroundColor = [UIColor whiteColor];
//	statusLabel.layer.cornerRadius = DATE_LABEL_HEIGHT / 2;
	
    [self.contentView addSubview:statusLabel];
}

- (void)addActivityIndicator {
#if defined __IPHONE_3_0
    //CGRect rect = CGRectMake(self.frame.origin.x + self.frame.size.width - 35, dateLabel.frame.origin.y - 10, 20, 20);
	CGRect rect = CGRectMake(self.frame.origin.x + self.frame.size.width - 31, dateLabel.frame.origin.y - 13, 20, 20);
#else
    CGRect rect = CGRectMake(self.frame.origin.x + self.frame.size.width - 21, dateLabel.frame.origin.y - 13, 20, 20);
#endif

    activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:rect];
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    activityIndicator.hidden = YES;

    [self.contentView addSubview:activityIndicator];
}

- (void)changeCellLabelsForUpdate:(NSString *)postTotalString:(NSString *) loadingString:(BOOL)isLoading{
	
	if (isLoading) {
		nameLabel.textColor = [UIColor grayColor];
		
	}else {
		nameLabel.textColor = LOAD_MORE_DATA_TEXT_COLOR;
		//nameLabel.textColor = [UIColor blackColor];
	}
	
		nameLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
		dateLabel.textColor = [UIColor grayColor];
		dateLabel.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
		nameLabel.text = loadingString;
		dateLabel.text = postTotalString;
		self.accessoryType = UITableViewCellAccessoryNone;
		self.contentView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
	
		CGRect rect = CGRectMake(LEFT_OFFSET, nameLabel.frame.origin.y + LABEL_HEIGHT + VERTICAL_OFFSET -1, 320, DATE_LABEL_HEIGHT);
		dateLabel.frame = rect;
	
}

- (void)runSpinner:(BOOL)value {
	gettingMore = value;
	
    if (gettingMore) {
        activityIndicator.hidden = NO;
        [activityIndicator startAnimating];
		
    } else {
        activityIndicator.hidden = YES;
		
        if ([activityIndicator isAnimating]) {
            [activityIndicator stopAnimating];
        }
		
	}
}

@end
