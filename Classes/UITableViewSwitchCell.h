//
//  UITableViewSwitchCell.h
//  WordPress
//
//  Created by Chris Boyd on 7/25/10.
//

#import <UIKit/UIKit.h>


@interface UITableViewSwitchCell : UITableViewCell {
}

@property (nonatomic, strong) IBOutlet UILabel *textLabel;
@property (nonatomic, strong) IBOutlet UISwitch *cellSwitch;
@property (nonatomic, strong) IBOutlet UIView *viewForBackground;

@end
