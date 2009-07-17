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
    CGRect rect = CGRectMake(self.frame.origin.x + self.frame.size.width - 35, dateLabel.frame.origin.y - 10, 20, 20);
#else
    CGRect rect = CGRectMake(self.frame.origin.x + self.frame.size.width - 25, dateLabel.frame.origin.y - 10, 20, 20);
#endif

    activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:rect];
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    activityIndicator.hidden = YES;

    [self.contentView addSubview:activityIndicator];
}

@end
