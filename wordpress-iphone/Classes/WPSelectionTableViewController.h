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
	void* curContext;
	
	int selectionType;
	BOOL autoReturnInRadioSelectMode;//default is true;
	BOOL flag;
}

//default is true;
@property (nonatomic, assign) BOOL autoReturnInRadioSelectMode;

//strings
- (void)populateDataSource:(NSArray *)sourceObjects havingContext:(void*)context selectedObjects:(NSArray *)selObjects selectionType:(WPSelectionType)aType andDelegate:(id)delegate;

- (NSArray *)selectedObjects;
- (void *)curContext;
- (BOOL)haveChanges;


- (void)clean;

@end
