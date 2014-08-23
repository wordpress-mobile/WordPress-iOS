#import "DataPickerState.h"
#import "DataPickerViewController.h"

@implementation DataPickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
            dataState:(DataPickerState *)dataState {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _dataState = dataState;
  }
  return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return [self.dataState.cellLabels count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * const kCellIdentifier = @"Cell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];

  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:kCellIdentifier];
  }

  cell.textLabel.text = self.dataState.cellLabels[indexPath.row];
  // If the cell is selected, mark it as checked
  if ([self.dataState.selectedCells containsObject:cell.textLabel.text]) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
  NSString *label = selectedCell.textLabel.text;

  if (self.dataState.multipleSelectEnabled) {
    // If multiple selections are allowed, then toggle the state
    // of the selected cell
    if ([self.dataState.selectedCells containsObject:label]) {
      [self.dataState.selectedCells removeObject:label];
      selectedCell.accessoryType = UITableViewCellAccessoryNone;
    } else {
      [self.dataState.selectedCells addObject:label];
      selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
  } else {
    // Set all cells to unchecked except for the one that was just selected
    [self.dataState.selectedCells removeAllObjects];
    [self.dataState.selectedCells addObject:label];

    for (NSIndexPath *curPath in [self.tableView indexPathsForVisibleRows]) {
      UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:curPath];
      if (curPath.row == indexPath.row) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
      } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
      }
    }
  }
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
