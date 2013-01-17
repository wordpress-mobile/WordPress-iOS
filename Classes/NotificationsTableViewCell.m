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
@property (nonatomic, strong) UILabel *commentLabel;
@property (nonatomic, strong) UIImageView *unreadIndicator;
@end

@implementation NotificationsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.textLabel.numberOfLines = 2;
        self.textLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.imageView.frame = CGRectMake(0.f, 0.f, 47.f, 47.f);
        self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 19.f, 19.f)];
        self.commentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.commentLabel.numberOfLines = 2;
        self.commentLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        self.commentLabel.textColor = [UIColor darkGrayColor];
        self.unreadIndicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"note_unread_indicator"]];
        [self addSubview:self.commentLabel];
        [self addSubview:self.iconImageView];
        [self addSubview:self.unreadIndicator];
    }
    return self;
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
        self.textLabel.text = [NSString stringWithFormat:@"     %@", [NSString decodeXMLCharactersIn: note.subject]];
    } else {
        self.iconImageView.hidden = YES;
        self.textLabel.text = [NSString decodeXMLCharactersIn:note.subject];
    }
    
    self.commentLabel.text = [NSString decodeXMLCharactersIn: note.commentText];
    
    self.unreadIndicator.hidden = [note isRead];
    if (![self.note isComment] || ![self.note isLike])
        self.commentLabel.hidden = YES;

}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(7.f, 7.f, 47.f, 47.f);
    [self.textLabel sizeToFit];
    CGRect labelFrame = self.textLabel.frame;
    labelFrame.origin.x = CGRectGetMaxX(self.imageView.frame) + 8.f;
    labelFrame.origin.y = 8.f;
    labelFrame.size.width = self.bounds.size.width - 40.f - CGRectGetMaxX(self.imageView.frame);
    self.textLabel.frame = labelFrame;
    CGRect iconFrame = self.iconImageView.frame;
    iconFrame.origin.x = CGRectGetMaxX(self.imageView.frame) + 8.f;
    iconFrame.origin.y = 10.f;
    self.iconImageView.frame = iconFrame;
    
    if ([self.note isComment]) {
        CGRect commentFrame = self.textLabel.frame;
        commentFrame.origin.y = CGRectGetMaxY(commentFrame) + 5.f;
        self.commentLabel.frame = commentFrame;
        
    }
    
    CGRect indicatorFrame = self.unreadIndicator.frame;
    indicatorFrame.origin.x = CGRectGetMaxX(self.bounds) - indicatorFrame.size.width;
    self.unreadIndicator.frame = indicatorFrame;

    
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
