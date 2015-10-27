#import "MenusSelectionCell.h"

@interface MenusSelectionCell ()

@property (weak, nonatomic) IBOutlet UIView *redView;
@property (weak, nonatomic) IBOutlet UIView *blueView;

@end

@implementation MenusSelectionCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    //[self performSelector:@selector(testRemove) withObject:nil afterDelay:3.0];
}

- (void)testRemove
{
    [self.tableView beginUpdates];
    self.blueView.hidden = YES;
    [self.tableView endUpdates];
    
    [self performSelector:@selector(showBlue) withObject:nil afterDelay:3.0];
}

- (void)showBlue
{
    [self.tableView beginUpdates];
    self.blueView.hidden = NO;
    [self.tableView endUpdates];
}

@end
