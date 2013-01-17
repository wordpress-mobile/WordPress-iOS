//
//  FollowButton.m
//  WordPress
//
//  Created by Beau Collins on 12/5/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "FollowButton.h"
#import "DTCoreText.h"
#import "NSString+XMLExtensions.h"

NSString *const FollowButtonFollowedEvent = @"FollowButtonFollowed";
NSString *const FollowButtonUnfollowedEvent = @"FollowButtonUnfollowed";

@interface FollowButton ()
@property (nonatomic, strong) UIButton *button;
@end

@implementation FollowButton

+ (FollowButton*)buttonWithLabel:(NSString *)label andApi:(WordPressComApi *)user andSiteID:(NSNumber *)siteID andFollowing:(FollowButtonState)following{
    FollowButton  *button = [[FollowButton alloc] initWithLabel:label andApi:user andSiteID:siteID andFollowing:following];
    return button;
}

+ (FollowButton *)buttonFromAction:(NSDictionary *)action withApi:(WordPressComApi *)user {
    NSLog(@"Follow button for action: %@", action);
    NSString *label = [action valueForKeyPath:@"params.blog_title"];
    NSNumber *siteId = [action valueForKeyPath:@"params.blog_id"];
    FollowButtonState state = [[action valueForKeyPath:@"params.is_following"] intValue];
    FollowButton *button = [FollowButton buttonWithLabel:label andApi:user andSiteID:siteId andFollowing:state];
    return button;
}

- (id)initWithLabel:(NSString *)label andApi:(WordPressComApi *)user andSiteID:(NSNumber *)siteId andFollowing:(FollowButtonState)following {
    
    self = [super initWithFrame:CGRectMake(0.f, 0.f, 80.0f, 30.0f)];
    if (self) {
        // Initialization code
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.button addTarget:self action:@selector(toggleFollowState:) forControlEvents:UIControlEventTouchUpInside];
        
        [self setupButton:self.button];
        
        
        [self addSubview:self.button];
        if (label == nil) {
            label = @"Hello World";
        }
        self.label = label;
        self.user = user;
        self.siteID = siteId;
        
        self.maxButtonWidth = 180.f;
        
        self.followState = following;
        
        [self resizeButton];
    }
    return self;
    
}

- (void)setupButton:(UIButton *)button {
    
    button.frame = self.bounds;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleEdgeInsets = UIEdgeInsetsMake(0.f, 10.f, 0.f, 0.f);
    button.titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    button.titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    button.imageEdgeInsets = UIEdgeInsetsMake(0.f, 5.f, 0.f, 0.f);

}

- (void)toggleFollowState:(id)sender {
    switch (self.followState) {
        case FollowButtonStateFollowing:
        {
            self.followState = FollowButtonStateNotFollowing;
            [self.user postPath:self.unfollowURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self postEvent:FollowButtonUnfollowedEvent];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error){
                self.followState = FollowButtonStateFollowing;
            }];
            break;
        }
        case FollowButtonStateNotFollowing:
        {
            self.followState = FollowButtonStateFollowing;
            [self.user postPath:self.followURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self postEvent:FollowButtonFollowedEvent];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error){
                self.followState = FollowButtonStateNotFollowing;
            }];
            break;
        }
    }
    
}

- (void)postEvent:(NSString *)eventName {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:eventName
     object:self
     userInfo:@{
        @"siteID": self.siteID
     }];
}

- (NSString *)followURL {
    return [NSString stringWithFormat:@"sites/%@/follows/new", self.siteID];
}

- (NSString *)unfollowURL {
    return [NSString stringWithFormat:@"sites/%@/follows/mine/delete", self.siteID];
}

- (void)setFollowState:(FollowButtonState)followState {
    if (_followState != followState) {
        _followState = followState;
    }
    UIButton *actionButton = self.button;
    switch (self.followState) {
        case FollowButtonStateFollowing:
            [actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [actionButton setImage:[UIImage imageNamed:@"note_button_icon_following"] forState:UIControlStateNormal];
            [actionButton setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateNormal];
            [actionButton setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateHighlighted];
            [actionButton.titleLabel setShadowColor:[UIColor blackColor]];
            break;
        case FollowButtonStateNotFollowing:
            [actionButton setTitleColor:[UIColor UIColorFromHex:0x1A1A1A] forState:UIControlStateNormal];
            [actionButton setImage:[UIImage imageNamed:@"note_button_icon_follow"] forState:UIControlStateNormal];
            [actionButton setBackgroundImage:[[UIImage imageNamed:@"navbar_button_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateNormal];
            [actionButton setBackgroundImage:[[UIImage imageNamed:@"navbar_button_bg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateHighlighted];
            [actionButton.titleLabel setShadowColor:[UIColor whiteColor]];
            break;
    }
    [self resizeButton];
}



- (void)setMaxButtonWidth:(CGFloat)maxButtonWidth {
    if (maxButtonWidth != _maxButtonWidth) {
        _maxButtonWidth = maxButtonWidth;
        [self resizeButton];
    }
}

- (NSString *)label {
    return [self.button titleForState:UIControlStateNormal];
}

- (void)setLabel:(NSString *)label {
    [self.button setTitle:[label stringByDecodingXMLCharacters] forState:UIControlStateNormal];
    [self resizeButton];
}

- (void)resizeButton {
    [self resizeButtonWithMaxWidth:self.maxButtonWidth];
}

- (void)resizeButtonWithMaxWidth:(CGFloat)maxSize {
    CGSize textSize = [self.label sizeWithFont:[self.button.titleLabel font]];
    CGFloat buttonWidth = textSize.width + 40.0f;
    if (buttonWidth > maxSize)
        buttonWidth = maxSize;
    CGRect frame = self.button.frame;
    frame.size.height = 30.f;
    frame.size.width = buttonWidth;
    self.button.frame = frame;
    NSLog(@"Resized the button: %@", self.button);
    CGRect viewFrame = self.frame;
    viewFrame.size = frame.size;
    self.frame = viewFrame;
}


@end
