//
//  PostTableViewCell.m
//  WordPress
//
//  Created by Josh Bassett on 1/07/09.
//

#import "PostTableViewCell.h"

@interface PostTableViewCell (Private)
- (void)addNameLabel;
- (void)addDateLabel;
- (void)addActivityIndicator;

@end

@implementation PostTableViewCell

@synthesize post;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        [self addNameLabel];
        [self addDateLabel];
        [self addActivityIndicator];
    }

    return self;
}

- (void)dealloc {
    [nameLabel release];
    [dateLabel release];
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

- (void)setPost:(NSDictionary *)value {
    post = value;

    static NSDateFormatter *dateFormatter = nil;

    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    }

    NSString *title = [[post valueForKey:@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (title == nil || ([title length] == 0)) {
        title = @"(no title)";
    }

    nameLabel.text = title;

    NSDate *date = [post valueForKey:@"date_created_gmt"];
    dateLabel.text = [dateFormatter stringFromDate:date];

    BOOL newSaving = [[post valueForKey:kAsyncPostFlag] boolValue];
    saving = newSaving;
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
    CGRect rect = CGRectMake(LEFT_OFFSET, nameLabel.frame.origin.y + LABEL_HEIGHT + VERTICAL_OFFSET, 320, DATE_LABEL_HEIGHT);

    dateLabel = [[UILabel alloc] initWithFrame:rect];
    dateLabel.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
    dateLabel.highlightedTextColor = [UIColor whiteColor];
    dateLabel.textColor = [UIColor lightGrayColor];
    dateLabel.backgroundColor = [UIColor clearColor];

    [self.contentView addSubview:dateLabel];
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
