#import "ShareBundleMediaPickerController.h"

enum {
  kFileName,
  kPreviewName,
  kExtension
};

@implementation ShareBundleMediaPickerController {
  // Array of media elements. Each element takes the form of {filename, previewname, extension}.
  NSArray *_mediaElements;
}

- (void)gppInit {
  _mediaElements = @[
    @[ @"samplemedia1", @"samplemedia1preview", @"mov" ],
    @[ @"samplemedia2", @"samplemedia2", @"png" ],
    @[ @"samplemedia3", @"samplemedia3", @"png" ]
  ];

  self.navigationItem.title = @"Select media";
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self gppInit];
  }
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [self gppInit];
  }
  return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_mediaElements count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"kCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:CellIdentifier];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.accessoryView = imageView;
  }

  cell.textLabel.text = [NSString stringWithFormat:@"%@.%@",
                                                   _mediaElements[indexPath.row][kFileName],
                                                   _mediaElements[indexPath.row][kExtension]];

  ((UIImageView *)cell.accessoryView).image =
      [UIImage imageNamed:_mediaElements[indexPath.row][kPreviewName]];

  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  // We have large cell heights to accommodate larger image thumbnails in the accessory view.
  return 60.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *fileName = _mediaElements[indexPath.row][kFileName];
  NSString *extension = _mediaElements[indexPath.row][kExtension];

  // Set media element as the attached element in the share view controller.
  if ([extension isEqualToString:@"png"]) {
    [self.delegate selectedImage:[UIImage imageNamed:fileName]];
  } else {
    NSURL *filePath = [[NSBundle mainBundle] URLForResource:fileName withExtension:extension];
    [self.delegate selectedVideo:filePath];
  }

  [self.navigationController popViewControllerAnimated:YES];
}

@end
