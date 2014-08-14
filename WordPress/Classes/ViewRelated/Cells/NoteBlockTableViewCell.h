#import <Foundation/Foundation.h>
#import "WPTableViewCell.h"



typedef void (^NotificationUrlHandler)(NSURL *url);

@interface NoteBlockTableViewCell : WPTableViewCell

- (CGFloat)heightForWidth:(CGFloat)width;

+ (NSString *)reuseIdentifier;

@end
