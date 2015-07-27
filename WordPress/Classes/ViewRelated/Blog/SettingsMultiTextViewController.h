#import <UIKit/UIKit.h>

@interface SettingsMultiTextViewController : UITableViewController

@property (nonatomic, copy) void(^onValueChanged)(NSString *);
@property (nonatomic, copy) void(^onCancel)();

- (instancetype)initWithText:(NSString *)text
                 placeholder:(NSString *)placeholder
                        hint:(NSString *)hint
                  isPassword:(BOOL)isPassword;

@end
