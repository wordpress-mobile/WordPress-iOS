#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

@interface SwitchSettingTableViewCell : WPTableViewCell

- (instancetype)initWithLabel:(NSString *)label
                       target:(id)target
                       action:(SEL)action
              reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, assign) BOOL switchValue;

@end
