#import "SuggestionsTableViewCell.h"

NSInteger const SuggestionsTableViewCellAvatarSize = 32;

@implementation SuggestionsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _usernameLabel = [[UILabel alloc] init];
        [_usernameLabel setTextColor:[WPStyleGuide wordPressBlue]];
        [_usernameLabel setFont:[WPStyleGuide regularTextFont]];
        [_usernameLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.contentView addSubview:_usernameLabel];
        
        _displayNameLabel = [[UILabel alloc] init];
        [_displayNameLabel setTextColor:[WPStyleGuide readGrey]];
        [_displayNameLabel setFont:[WPStyleGuide regularTextFont]];
        [_displayNameLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        _displayNameLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_displayNameLabel];
        
        _avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SuggestionsTableViewCellAvatarSize, SuggestionsTableViewCellAvatarSize)];
        _avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
        _avatarImageView.clipsToBounds = YES;
        _avatarImageView.image = [UIImage imageNamed:@"gravatar.png"];
        [_avatarImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.contentView addSubview:_avatarImageView];
        
        NSDictionary *views = @{@"contentview": self.contentView,
                                @"username": _usernameLabel,
                                @"displayname": _displayNameLabel,
                                @"avatar": _avatarImageView };
        
        // Horizontal spacing
        NSArray *horizConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[avatar(32)]-16-[username]-[displayname]-|"
                                                                            options:0
                                                                            metrics:nil
                                                                              views:views];
        [self.contentView addConstraints:horizConstraints];
                
        // Vertically constrain centers of each element
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_usernameLabel
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:0]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_displayNameLabel
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:0]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_avatarImageView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:0]];
        
    }
    return self;
}

@end
