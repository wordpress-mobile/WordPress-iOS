//
//  UITableViewSwitchCell.h
//  WordPress
//
//  Created by Chris Boyd on 7/25/10.
//

#import <UIKit/UIKit.h>


@interface UITableViewSwitchCell : UITableViewCell {
}

@property (nonatomic, retain) IBOutlet UILabel *textLabel;
@property (nonatomic, retain) IBOutlet UISwitch *cellSwitch;
@property (nonatomic, retain) IBOutlet UIView *viewForBackground;

@end
