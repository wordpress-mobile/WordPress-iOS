#import <Foundation/Foundation.h>

@protocol WPTableViewHandlerDelegate <NSObject>
- (NSManagedObjectContext *)managedObjectContext;
- (NSString *)entityName;
- (NSFetchRequest *)fetchRequest;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@optional
- (NSString *)sectionNameKeyPath;
- (NSString *)titleForHeaderInSection:(NSInteger)section;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)deletingSelectedRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@interface WPTableViewHandler : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) NSFetchedResultsController *resultsController;
@property (nonatomic, weak) id<WPTableViewHandlerDelegate> delegate;

- (instancetype)initWithTableView:(UITableView *)tableView;

@end
