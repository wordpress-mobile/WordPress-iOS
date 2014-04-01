#import "NotificationsFollowTableViewCell.h"
#import "FollowButton.h"

@implementation NotificationsFollowTableViewCell

@synthesize actionButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [actionButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [actionButton setFrame:CGRectMake(100.0f, 20.0f, 80.0f, 30.0f)];
        [actionButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 6.0f, 0.0f, 0.0f)];
        [actionButton.titleLabel setFont:[WPStyleGuide tableviewSectionHeaderFont]];
        [actionButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 9.0f, 0.0f, 2.0f)];
        [actionButton.imageView setContentMode:UIViewContentModeLeft];
        [actionButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
        [actionButton.titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        [actionButton.titleLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
        [self addSubview:actionButton];
        
        [self.textLabel setBackgroundColor:[UIColor clearColor]];
        [self.textLabel setTextColor:[WPStyleGuide littleEddieGrey]];
        [self.textLabel setFont:[WPStyleGuide postTitleFont]];
        
        [self.detailTextLabel setFont:[WPStyleGuide subtitleFont]];
        [self.detailTextLabel setTextColor:[WPStyleGuide baseDarkerBlue]];
        [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
        [self.detailTextLabel setNumberOfLines:1];
        [self.detailTextLabel setAdjustsFontSizeToFitWidth:NO];
        [self.detailTextLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        
        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    }
    return self;
}

- (void)setFollowing:(BOOL)isFollowing {
    if (isFollowing) {
        [actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [actionButton setImage:[UIImage imageNamed:@"note_button_icon_following"] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateHighlighted];
        [actionButton.titleLabel setShadowColor:[UIColor blackColor]];
    } else {
        [actionButton setTitleColor:[UIColor UIColorFromHex:0x1A1A1A] forState:UIControlStateNormal];
        [actionButton setImage:[UIImage imageNamed:@"note_button_icon_follow"] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[[UIImage imageNamed:@"navbar_button_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[[UIImage imageNamed:@"navbar_button_bg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateHighlighted];
        [actionButton.titleLabel setShadowColor:[UIColor whiteColor]];
    }
    CGSize textSize = [[actionButton.titleLabel text] sizeWithAttributes:@{NSFontAttributeName:[actionButton.titleLabel font]}];
    CGFloat buttonWidth = textSize.width + 40.0f;
    if (buttonWidth > 180.0f)
        buttonWidth = 180.0f;
    [actionButton setFrame:CGRectMake(actionButton.frame.origin.x, actionButton.frame.origin.y, buttonWidth, 30.0f)];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.imageView setFrame:CGRectMake(10.0f, 10.0f, 80.0f, 80.0f)];
    [self.textLabel setFrame:CGRectMake(100.0f, 20.0f, 180.0f, 30.0f)];
    [self.detailTextLabel setFrame:CGRectMake(100.0f, 55.0f, self.frame.size.width - 140.0f, 30.0f)];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    actionButton.highlighted = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    actionButton.highlighted = NO;
}

@end
