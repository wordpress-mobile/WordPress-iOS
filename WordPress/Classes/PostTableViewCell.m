//
//  PostTableViewCell.m
//  WordPress
//
//  Created by Josh Bassett on 1/07/09.
//

#import "PostTableViewCell.h"
#import "NSString+XMLExtensions.h"

static const float statusLabelMaxWidthLandscape = 200.f;
static const float statusLabelMaxWidthPortrait = 100.f;

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


- (void)setSaving:(BOOL)value {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    saving = value;

    if (saving) {
        activityIndicator.hidden = NO;

        [activityIndicator startAnimating];

        UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:POST_LOCK_IMAGE]];
        self.accessoryView = image;
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
   // nameLabel.backgroundColor = [UIColor orangeColor];
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

   // statusLabel.backgroundColor = [UIColor orangeColor];
    
    NSDate *date = [post valueForKey:@"dateCreated"];
    dateLabel.text = [dateFormatter stringFromDate:date];
  //  dateLabel.backgroundColor = [UIColor redColor];
    
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

- (void)layoutSubviews {
    [super layoutSubviews];
   
    CGSize expectedstatusLabelSize = [statusLabel.text sizeWithFont:[UIFont systemFontOfSize:DATE_FONT_SIZE]];   
    CGFloat expectedStatusLabelWidth = 0.f;    
    if ( IS_IPHONE && UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation]) ) {
        expectedStatusLabelWidth = expectedstatusLabelSize.width > statusLabelMaxWidthPortrait ? statusLabelMaxWidthPortrait : expectedstatusLabelSize.width;
    } else {
        expectedStatusLabelWidth = expectedstatusLabelSize.width > statusLabelMaxWidthLandscape ? statusLabelMaxWidthLandscape : expectedstatusLabelSize.width;
    }
    
    //NSLog(@"width of status label %f", expectedStatusLabelLength);
    
    CGFloat x = self.frame.size.width - expectedStatusLabelWidth - RIGHT_MARGIN;
    if ( IS_IPHONE )
        x = x - 22; //the disclousure size
    
    CGRect rect = CGRectMake(x, nameLabel.frame.origin.y + LABEL_HEIGHT + VERTICAL_OFFSET, expectedStatusLabelWidth, DATE_LABEL_HEIGHT);
    statusLabel.frame = rect;
    
    if ( self.isEditing ) 
        statusLabel.hidden = YES;
    else 
        statusLabel.hidden = NO;
    
    CGFloat dateWidth = self.frame.size.width - LEFT_OFFSET - RIGHT_MARGIN -  ( IS_IPHONE ? expectedStatusLabelWidth + 22 : expectedStatusLabelWidth);  //Max space available for the Date
    rect = CGRectMake(LEFT_OFFSET, nameLabel.frame.origin.y + LABEL_HEIGHT + VERTICAL_OFFSET, dateWidth, DATE_LABEL_HEIGHT);
    dateLabel.frame = rect;
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
	
	[self runSpinner:NO];
}


#pragma mark Private methods

- (void)addNameLabel {
    CGFloat w = self.frame.size.width - LEFT_OFFSET - RIGHT_MARGIN;
    CGRect rect = CGRectMake(LEFT_OFFSET, (POST_ROW_HEIGHT - LABEL_HEIGHT - DATE_LABEL_HEIGHT - VERTICAL_OFFSET) / 2.0, w, LABEL_HEIGHT);

    nameLabel = [[UILabel alloc] initWithFrame:rect];
    nameLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
    nameLabel.highlightedTextColor = [UIColor whiteColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [self.contentView addSubview:nameLabel];
}

- (void)addDateLabel {
    dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    dateLabel.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
    dateLabel.highlightedTextColor = [UIColor whiteColor];
    dateLabel.textColor = [UIColor lightGrayColor];
    dateLabel.backgroundColor = [UIColor clearColor];

    [self.contentView addSubview:dateLabel];
}

- (void)addStatusLabel {
	statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    statusLabel.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
    statusLabel.textColor = [UIColor blackColor];
    statusLabel.backgroundColor = [UIColor clearColor];
    statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    statusLabel.textAlignment = UITextAlignmentRight;
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
