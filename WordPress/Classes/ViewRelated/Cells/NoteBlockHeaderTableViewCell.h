#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"
#import "NoteBlockTableViewCell.h"



@interface NoteBlockHeaderTableViewCell : WPTableViewCell <NoteBlockTableViewCell>

@property (nonatomic, strong) NSString              *noticon;
@property (nonatomic, strong) NSAttributedString    *attributedText;

@end
