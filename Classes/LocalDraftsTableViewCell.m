//
//  LocalDraftsTableViewCell.m
//  WordPress
//
//  Created by Josh Bassett on 1/07/09.
//

#import "LocalDraftsTableViewCell.h"

#define LOCAL_DRAFTS_LABEL_FONT_SIZE    14
#define LOCAL_DRAFTS_LABEL              @"Local Drafts"
#define LOCAL_DRAFTS_ICON               @"DraftsFolder.png"
#define LOCAL_DRAFTS_ROW_HEIGHT         44

#define BADGE_FONT_SIZE                 15
#define BADGE_LABEL_X                   210
#define BADGE_LABEL_WIDTH               80
#define BADGE_LABEL_HEIGHT              19

@implementation LocalDraftsTableViewCell

@synthesize badgeLabel = _badgeLabel;

- (void)dealloc {
    [_badgeLabel release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
#if defined __IPHONE_3_0
		self.textLabel.text = LOCAL_DRAFTS_LABEL;
		self.textLabel.font = [UIFont boldSystemFontOfSize:LOCAL_DRAFTS_LABEL_FONT_SIZE];
		self.imageView.image = [UIImage imageNamed:LOCAL_DRAFTS_ICON];
#else
		self.text = LOCAL_DRAFTS_LABEL;
		self.font = [UIFont boldSystemFontOfSize:LOCAL_DRAFTS_LABEL_FONT_SIZE];
		self.image = [UIImage imageNamed:LOCAL_DRAFTS_ICON];
#endif
		
        CGRect frame = CGRectMake(BADGE_LABEL_X, (LOCAL_DRAFTS_ROW_HEIGHT - BADGE_LABEL_HEIGHT) / 2 , BADGE_LABEL_WIDTH, BADGE_LABEL_HEIGHT);
		_badgeLabel = [[UILabel alloc] initWithFrame:frame];
		_badgeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		_badgeLabel.textColor = [UIColor lightGrayColor];
		_badgeLabel.textAlignment = UITextAlignmentRight;
		_badgeLabel.font = [UIFont boldSystemFontOfSize:BADGE_FONT_SIZE];
		
		[self.contentView addSubview:_badgeLabel];
    }
    
    return self;
}

@end
