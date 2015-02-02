#import <UIKit/UIKit.h>
#import "ReaderHeaderView.h"

@interface ReaderPostHeaderView : ReaderHeaderView

/**
 A ReaderPostHeaderCallback block to be executed whenever the user pressed this view.
 */
typedef void (^ReaderPostHeaderCallback)(void);
@property (nonatomic, copy) ReaderPostHeaderCallback onClick;

/**
 A BOOL indicating whether if this view should display a disclosure indicator, or not.
 */
@property (nonatomic, assign) BOOL showsDisclosureIndicator;

@end
