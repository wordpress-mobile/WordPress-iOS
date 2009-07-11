#import <UIKit/UIKit.h>

typedef enum _SelectionType {
    kRadio,
    kCheckbox
} WPSelectionType;

@interface WPSelectionTableViewController : UIViewController {
    IBOutlet UITableView *tableView;

    NSArray *objects;
    NSMutableArray *selectionStatusOfObjects, *originalSelObjects;
    id selectionDelegate;
    void *curContext;

    int selectionType;
    BOOL autoReturnInRadioSelectMode;
    BOOL flag;
}

@property (nonatomic, assign) BOOL autoReturnInRadioSelectMode;
@property (nonatomic, retain) NSArray *objects;
@property (nonatomic, retain) NSMutableArray *selectionStatusOfObjects;
@property (nonatomic, retain) NSMutableArray *originalSelObjects;

- (void)populateDataSource:(NSArray *)sourceObjects havingContext:(void *)context selectedObjects:(NSArray *)selObjects selectionType:(WPSelectionType)aType andDelegate:(id)delegate;

- (NSArray *)selectedObjects;
- (void *)curContext;
- (BOOL)haveChanges;

- (void)clean;

@end
