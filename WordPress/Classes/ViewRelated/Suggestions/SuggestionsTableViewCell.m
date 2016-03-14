#import "SuggestionsTableViewCell.h"
#import "WPFontManager.h"

NSInteger const SuggestionsTableViewCellAvatarSize = 23;

@implementation SuggestionsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUsernameLabel];
        [self setupDisplayNameLabel];
        [self setupAvatarImageView];
        [self setupConstraints];
    }
    return self;
}

- (void)setupUsernameLabel
{
    _usernameLabel = [[UILabel alloc] init];
    [_usernameLabel setTextColor:[WPStyleGuide wordPressBlue]];
    [_usernameLabel setFont:[WPFontManager systemRegularFontOfSize:14.0]];
    [_usernameLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentView addSubview:_usernameLabel];
}

- (void)setupDisplayNameLabel
{
    _displayNameLabel = [[UILabel alloc] init];
    [_displayNameLabel setTextColor:[WPStyleGuide allTAllShadeGrey]];
    [_displayNameLabel setFont:[WPFontManager systemRegularFontOfSize:14.0]];
    [_displayNameLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    _displayNameLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:_displayNameLabel];
}

- (void)setupAvatarImageView
{
    _avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SuggestionsTableViewCellAvatarSize, SuggestionsTableViewCellAvatarSize)];
    _avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
    _avatarImageView.clipsToBounds = YES;
    _avatarImageView.image = [UIImage imageNamed:@"gravatar.png"];
    [_avatarImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentView addSubview:_avatarImageView];
}

- (void)setupConstraints
{
    NSDictionary *views = @{@"contentview": self.contentView,
                            @"username": _usernameLabel,
                            @"displayname": _displayNameLabel,
                            @"avatar": _avatarImageView };
        
    NSDictionary *metrics = @{@"avatarsize": @(SuggestionsTableViewCellAvatarSize) };
        
    // Horizontal spacing
    NSArray *horizConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[avatar(avatarsize)]-16-[username]-[displayname]-|"
                                                                        options:0
                                                                        metrics:metrics
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

@end
