/*
 Custom header view for sidebar panel
 Based on example app from Apple at: 
 http://developer.apple.com/library/ios/#samplecode/TableViewUpdates/Introduction/Intro.html
*/

#import <Foundation/Foundation.h>
#import "Blog.h"
#import "SectionInfo.h"

@protocol SidebarSectionHeaderViewDelegate;


@interface SidebarSectionHeaderView : UIView {
    float startingFrameWidth;
    UIImageView *background;
    UIImageView *blavatarView;
}

@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UIButton *disclosureButton;
@property (nonatomic, weak) SectionInfo *sectionInfo;
@property (nonatomic, weak) id <SidebarSectionHeaderViewDelegate> delegate;
@property (nonatomic, weak) UIImageView *numberOfCommentsImageView;
@property (nonatomic, weak) UILabel *numberOfcommentsLabel;
@property (nonatomic, weak) Blog *blog;

-(id)initWithFrame:(CGRect)frame blog:(Blog*)blog sectionInfo:(SectionInfo *)sectionInfo delegate:(id <SidebarSectionHeaderViewDelegate>)delegate;
-(void)toggleOpenWithUserAction:(BOOL)userAction;

@end


/*
 Protocol to be adopted by the section header's delegate; the section header tells its delegate when the section should be opened and closed.
 */
@protocol SidebarSectionHeaderViewDelegate <NSObject>

@optional
-(void)sectionHeaderView:(SidebarSectionHeaderView*)sectionHeaderView sectionOpened:(SectionInfo *)sectionInfo;
-(void)sectionHeaderView:(SidebarSectionHeaderView*)sectionHeaderView sectionClosed:(SectionInfo *)sectionInfo;

@end

