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

@synthesize post = _post;

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
    [_nameLabel release];
    [_dateLabel release];
    [_activityIndicator release];
    [super dealloc];
}

- (void)setSaving:(BOOL)value {
    _saving = value;

    if (_saving) {
        _activityIndicator.hidden = NO;

        [_activityIndicator startAnimating];

        UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:POST_LOCK_IMAGE]];
        self.accessoryView = image;
        [image release];
    } else {
        _activityIndicator.hidden = YES;

        if ([_activityIndicator isAnimating]) {
            [_activityIndicator stopAnimating];
        }

        if ([self.accessoryView isKindOfClass:[UIImageView class]]) {
            self.accessoryView = nil;
        }
    }
}

- (void)setPost:(NSDictionary *)value {
    _post = value;

    static NSDateFormatter *dateFormatter = nil;

    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    }

    NSString *title = [[_post valueForKey:@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (title == nil || ([title length] == 0)) {
        title = @"(no title)";
    }

    _nameLabel.text = title;

    NSDate *date = [_post valueForKey:@"date_created_gmt"];
    _dateLabel.text = [dateFormatter stringFromDate:date];

    BOOL saving = [[_post valueForKey:kAsyncPostFlag] boolValue];
    _saving = saving;
}

#pragma mark Private methods

- (void)addNameLabel {
    CGRect rect = CGRectMake(LEFT_OFFSET, (POST_ROW_HEIGHT - LABEL_HEIGHT - DATE_LABEL_HEIGHT - VERTICAL_OFFSET) / 2.0, 288, LABEL_HEIGHT);

    _nameLabel = [[UILabel alloc] initWithFrame:rect];
    _nameLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
    _nameLabel.highlightedTextColor = [UIColor whiteColor];

    [self.contentView addSubview:_nameLabel];
}

- (void)addDateLabel {
    CGRect rect = CGRectMake(LEFT_OFFSET, _nameLabel.frame.origin.y + LABEL_HEIGHT + VERTICAL_OFFSET, 320, DATE_LABEL_HEIGHT);

    _dateLabel = [[UILabel alloc] initWithFrame:rect];
    _dateLabel.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
    _dateLabel.highlightedTextColor = [UIColor whiteColor];
    _dateLabel.textColor = [UIColor lightGrayColor];

    [self.contentView addSubview:_dateLabel];
}

- (void)addActivityIndicator {
#if defined __IPHONE_3_0
    CGRect rect = CGRectMake(self.frame.origin.x + self.frame.size.width - 35, _dateLabel.frame.origin.y - 10, 20, 20);
#else
    CGRect rect = CGRectMake(self.frame.origin.x + self.frame.size.width - 25, _dateLabel.frame.origin.y - 10, 20, 20);
#endif

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:rect];
    _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    _activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    _activityIndicator.hidden = YES;

    [self.contentView addSubview:_activityIndicator];
}

@end
