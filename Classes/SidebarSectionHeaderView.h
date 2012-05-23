/*
 Custom header view for sidebar panel
 Based on example app from Apple at: 
 http://developer.apple.com/library/ios/#samplecode/TableViewUpdates/Introduction/Intro.html
*/

#import <Foundation/Foundation.h>
#import "Blog.h"

@protocol SidebarSectionHeaderViewDelegate;


@interface SidebarSectionHeaderView : UIView 

@property (nonatomic, assign) UILabel *titleLabel;
@property (nonatomic, assign) UIButton *disclosureButton;
@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) id <SidebarSectionHeaderViewDelegate> delegate;

-(id)initWithFrame:(CGRect)frame blog:(Blog*)blog section:(NSInteger)sectionNumber delegate:(id <SidebarSectionHeaderViewDelegate>)delegate;
-(void)toggleOpenWithUserAction:(BOOL)userAction;

@end


/*
 Protocol to be adopted by the section header's delegate; the section header tells its delegate when the section should be opened and closed.
 */
@protocol SidebarSectionHeaderViewDelegate <NSObject>

@optional
-(void)sectionHeaderView:(SidebarSectionHeaderView*)sectionHeaderView sectionOpened:(NSInteger)section;
-(void)sectionHeaderView:(SidebarSectionHeaderView*)sectionHeaderView sectionClosed:(NSInteger)section;

@end

