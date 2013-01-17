//
//  NotificationsTableViewCell.m
//  WordPress
//
//

#import "NotificationsTableViewCell.h"
#import "NSString+XMLExtensions.h"
#import "UIImageView+AFNetworking.h"

@interface NotificationsTableViewCell ()
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *unreadIndicator;
@end

const CGFloat NotificationsTableViewCellFontSize = 15;

@implementation NotificationsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"cell_gradient_bg"] stretchableImageWithLeftCapWidth:0 topCapHeight:1]];
        self.backgroundView = imageView;
        self.textLabel.numberOfLines = 3;
        self.textLabel.font = [UIFont systemFontOfSize:NotificationsTableViewCellFontSize];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.imageView.frame = CGRectMake(0.f, 0.f, 47.f, 47.f);
        self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 16.f, 16.f)];
        self.detailTextLabel.numberOfLines = 3;
        self.detailTextLabel.font = [UIFont systemFontOfSize:NotificationsTableViewCellFontSize];
        self.detailTextLabel.textColor = [UIColor darkGrayColor];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.unreadIndicator = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 14.0f, 10.0f, 10.0f)];
        self.unreadIndicator.backgroundColor = [UIColor clearColor];
        self.unreadIndicator.font = [UIFont boldSystemFontOfSize:24.0f];
        self.unreadIndicator.textAlignment = NSTextAlignmentCenter;
        self.unreadIndicator.shadowColor = [UIColor whiteColor];
        self.unreadIndicator.shadowOffset = CGSizeMake(0.0f, 1.0f);
        self.unreadIndicator.text = @"•";
        self.unreadIndicator.textColor = [UIColor UIColorFromHex:0x2EA2CC];
        [self addSubview:self.detailTextLabel];
        [self addSubview:self.iconImageView];
        [self addSubview:self.unreadIndicator];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.detailTextLabel.hidden = YES;
    self.unreadIndicator.hidden = YES;
    self.iconImageView.hidden = YES;
    self.iconImageView.image = nil;
}

/*
 * Setting the note will update all of the necessary views in the cell
 */
- (void)setNote:(Note *)note {
    
    if ( _note != note) {
        _note = note;
    }

    [self.imageView setImageWithURL:[NSURL URLWithString:self.note.icon]
                   placeholderImage:[UIImage imageNamed:@"note_icon_placeholder"]];
    // make room for the icon
    
    UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:@"note_icon_%@", note.type]];
    if (iconImage != nil) {
        self.iconImageView.hidden = NO;
        self.iconImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"note_icon_%@", note.type]];
        self.textLabel.text = [NSString decodeXMLCharactersIn:note.subject];
    } else {
        self.textLabel.text = [NSString decodeXMLCharactersIn:note.subject];
    }
    
    self.textLabel.text = [NSString decodeXMLCharactersIn:note.subject];
    
    if (![note isRead])
        self.textLabel.text = [NSString stringWithFormat:@"   %@", self.textLabel.text];
    
    self.detailTextLabel.text = [NSString decodeXMLCharactersIn: note.commentText];
    
    self.unreadIndicator.hidden = [note isRead];
    if ([self.note isComment])
        self.detailTextLabel.hidden = NO;

}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(7.f, 7.f, 47.f, 47.f);

    CGRect labelFrame = self.textLabel.frame;
    labelFrame.origin.x = CGRectGetMaxX(self.imageView.frame) + 8.f;
    labelFrame.origin.y = 8.f;
    labelFrame.size.width = self.bounds.size.width - 40.f - CGRectGetMaxX(self.imageView.frame);
    self.textLabel.frame = labelFrame;

    CGRect iconFrame = self.iconImageView.frame;
    iconFrame.origin.x = self.frame.size.width - 22.0f;
    iconFrame.origin.y = 5.0f;
    self.iconImageView.frame = iconFrame;
    
    if ([self.note isComment]) {
        CGRect commentFrame = self.textLabel.frame;
        commentFrame.origin.y = CGRectGetMaxY(commentFrame) + 5.f;
        self.detailTextLabel.frame = commentFrame;
    }

    CGRect indicatorFrame = self.unreadIndicator.frame;
    indicatorFrame.origin.x = CGRectGetMaxX(self.imageView.frame) + 8.f;
    self.unreadIndicator.frame = indicatorFrame;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
