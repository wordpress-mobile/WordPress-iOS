//
//  NoteCommentLoadingCell.m
//  WordPress
//
//  Created by Beau Collins on 12/21/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NoteCommentLoadingCell.h"

@interface NoteCommentLoadingCell ()
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@end

@implementation NoteCommentLoadingCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self setupLoadingIndicator];

    }
    return self;
}

- (void)prepareForReuse {
    [self.loadingIndicator startAnimating];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.loadingIndicator.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

- (void)setupLoadingIndicator {
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activity.center = CGPointMake(self.frame.size.width * 0.5f, 0.f);
    activity.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [activity startAnimating];
    activity.hidesWhenStopped = NO;
    
    self.loadingIndicator = activity;
    [self.contentView addSubview:self.loadingIndicator];
}


@end
