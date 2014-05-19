#import <UIKit/UIKit.h>

@class Media;

@protocol MediaBrowserCellMultiSelectDelegate <NSObject>

- (void)mediaCellSelected:(Media *)media;
- (void)mediaCellDeselected:(Media *)media;

@end

@interface MediaBrowserCell : UICollectionViewCell

@property (nonatomic, strong) Media *media;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) BOOL hideCheckbox;
@property (nonatomic, weak) id<MediaBrowserCellMultiSelectDelegate> delegate;

- (void)loadThumbnail;

@end
