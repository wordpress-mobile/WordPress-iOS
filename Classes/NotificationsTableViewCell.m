//
//  NotificationsTableViewCell.m
//  WordPress
//
//

#import "NotificationsTableViewCell.h"
#import "NSString+XMLExtensions.h"
#import "UIImageView+AFNetworking.h"
#import "UIColor+Helpers.h"

@interface NotificationsTableViewCell ()
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *unreadIndicator;
@end

const CGFloat NotificationsTableViewCellFontSize = 17.0f;

@implementation NotificationsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"cell_gradient_bg"] stretchableImageWithLeftCapWidth:0 topCapHeight:1]];
        self.backgroundView = imageView;
        self.textLabel.numberOfLines = 2;
        self.textLabel.font = [UIFont systemFontOfSize:NotificationsTableViewCellFontSize];
        self.textLabel.textColor = [UIColor UIColorFromHex:0x030303];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.imageView.frame = CGRectMake(0.f, 0.f, 47.f, 47.f);
        self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 16.f, 16.f)];
        self.detailTextLabel.numberOfLines = 2;
        self.detailTextLabel.font = [UIFont systemFontOfSize:NotificationsTableViewCellFontSize - 2.0f];
        self.detailTextLabel.textColor = [UIColor UIColorFromHex:0x323232];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.unreadIndicator = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 9.0f, 10.0f, 10.0f)];
        self.unreadIndicator.backgroundColor = [UIColor clearColor];
        self.unreadIndicator.font = [UIFont boldSystemFontOfSize:20.0f];
        self.unreadIndicator.textAlignment = NSTextAlignmentCenter;
        self.unreadIndicator.shadowColor = [UIColor whiteColor];
        self.unreadIndicator.shadowOffset = CGSizeMake(0.0f, 1.0f);
        self.unreadIndicator.text = @"•";
        self.unreadIndicator.textColor = [UIColor UIColorFromHex:0x008EBE];
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
    
    self.textLabel.text = [NSString decodeXMLCharactersIn:note.subject];
    
    self.detailTextLabel.text = [NSString decodeXMLCharactersIn: note.commentText];
    
    NSString *noteType = _note.type;
    if ([noteType rangeOfString:@"achievement"].location != NSNotFound)
        noteType = @"achievement";
    else if ([noteType rangeOfString:@"best"].location != NSNotFound)
        noteType = @"stats";
    
    UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:@"note_icon_%@", noteType]];
    if (iconImage) {
        self.iconImageView.hidden = NO;
        self.iconImageView.image = iconImage;
    }
    UIImage *highlightedIconImage = [UIImage imageNamed:[NSString stringWithFormat:@"note_icon_%@_highlighted", noteType]];
    if (highlightedIconImage)
        self.iconImageView.highlightedImage = highlightedIconImage;
    
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
        commentFrame.origin.y = CGRectGetMaxY(commentFrame);
        self.detailTextLabel.frame = commentFrame;
    }

    CGRect indicatorFrame = self.unreadIndicator.frame;
    indicatorFrame.origin.x = self.frame.size.width - 30.0f;
    self.unreadIndicator.frame = indicatorFrame;
}

@end
