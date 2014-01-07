//
//  WPAddCategoryViewController.m
//  WordPress
//
//  Created by ? on ?
//  Copyright (c) 2014 WordPress. All rights reserved.
//
#import "WPAddCategoryViewController.h"
#import "Blog.h"
#import "Category.h"
#import "Constants.h"
#import "EditSiteViewController.h"
#import "WordPressAppDelegate.h"
#import "WPSegmentedSelectionTableViewController.h"

static void *const kParentCategoriesContext = ((void *)999);

NSString *const NewCategoryCreatedAndUpdatedInBlogNotification = @"NewCategoryCreatedAndUpdatedInBlogNotification";

@interface WPAddCategoryViewController ()

@property (nonatomic, strong) Category *parentCategory;
@property (nonatomic, strong) Blog *blog;

@property (nonatomic, strong) UITextField *createCatNameField;
@property (nonatomic, strong) UITextField *parentCatNameField;
@property (nonatomic, strong) UIBarButtonItem *saveButtonItem;

@end

@implementation WPAddCategoryViewController

- (id)initWithBlog:(Blog *)blog {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
    }
    return self;
}

- (void)viewDidLoad {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super viewDidLoad];
    
    self.tableView.sectionFooterHeight = 0.0f;

    self.saveButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"Save button label (saving content, ex: Post, Page, Comment, Category).")
                                                           style:[WPStyleGuide barButtonStyleForDone]
                                                          target:self
                                                          action:@selector(saveAddCategory:)];
    self.navigationItem.rightBarButtonItem = self.saveButtonItem;
    
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)didReceiveMemoryWarning {
    DDLogWarn(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


#pragma mark -
#pragma mark Instance Methods

- (void)clearUI {
    self.createCatNameField.text = @"";
    self.parentCatNameField.text = @"";
}

- (void)addProgressIndicator {
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
    [aiv startAnimating];
    
    self.navigationItem.rightBarButtonItem = activityButtonItem;
}

- (void)removeProgressIndicator {
	self.navigationItem.rightBarButtonItem = self.saveButtonItem;
}

- (void)dismiss {
    DDLogMethod();
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveAddCategory:(id)sender {
    NSString *catName = self.createCatNameField.text;
    
    if (!catName ||[catName length] == 0) {
        NSString *title = NSLocalizedString(@"Category title missing.", @"Error popup title to indicate that there was no category title filled in.");
        NSString *message = NSLocalizedString(@"Title for a category is mandatory.", @"Error popup message to indicate that there was no category title filled in.");
        [WPError showAlertWithTitle:title message:message withSupportButton:NO];

        return;
    }
    
    if ([Category existsName:catName forBlog:self.blog withParentId:self.parentCategory.categoryID]) {
        NSString *title = NSLocalizedString(@"Category name already exists.", @"Error popup title to show that a category already exists.");
        NSString *message = NSLocalizedString(@"There is another category with that name.", @"Error popup message to show that a category already exists.");
        [WPError showAlertWithTitle:title message:message withSupportButton:NO];
        return;
    }
    
    [self addProgressIndicator];
    
    [Category createCategory:catName parent:self.parentCategory forBlog:self.blog success:^(Category *category) {
        //re-syncs categories this is necessary because the server can change the name of the category!!!
		[self.blog syncCategoriesWithSuccess:nil failure:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:NewCategoryCreatedAndUpdatedInBlogNotification
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:category forKey:@"category"]];
        [self clearUI];
        [self removeProgressIndicator];
        [self dismiss];
    } failure:^(NSError *error) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		[self removeProgressIndicator];
		
		if ([error code] == 403) {
            [WPError showAlertWithTitle:NSLocalizedString(@"Couldn't Connect", @"") message:NSLocalizedString(@"The username or password stored in the app may be out of date. Please re-enter your password in the settings and try again.", @"") withSupportButton:NO];
			
			// bad login/pass combination
			EditSiteViewController *editSiteViewController = [[EditSiteViewController alloc] initWithBlog:self.blog];
			[self.navigationController pushViewController:editSiteViewController animated:YES];
			
		} else {
			[WPError showXMLRPCErrorAlert:error];
		}
    }];
}


#pragma mark - functional methods

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged {
    if (!isChanged) {
        [selctionController clean];
        return;
    }

    if (selContext == kParentCategoriesContext) {
        Category *curCat = [selectedObjects lastObject];

        if (self.parentCategory) {
            self.parentCategory = nil;
        }

        if (curCat) {
            self.parentCategory = curCat;
            self.parentCatNameField.text = curCat.categoryName;
            [self.tableView reloadData];
        }

    }

    [selctionController clean];
}

- (void)populateSelectionsControllerWithCategories {
    WPSegmentedSelectionTableViewController *selectionTableViewController = [[WPSegmentedSelectionTableViewController alloc] init];

    NSArray *selObjs = ((self.parentCategory == nil) ? [NSArray array] : [NSArray arrayWithObject:self.parentCategory]);
    
	NSArray *cats = [self.blog sortedCategories];
	
	[selectionTableViewController populateDataSource:cats
     havingContext:kParentCategoriesContext
     selectedObjects:selObjs
     selectionType:kRadio
     andDelegate:self];

    selectionTableViewController.title = NSLocalizedString(@"Parent Category", @"");

    [self.navigationController pushViewController:selectionTableViewController animated:YES];
}

#pragma mark - tableviewDelegates/datasources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WPTableViewCell *cell;
    if (indexPath.section == 0) {
        cell = [self cellForNewCategory];
    } else {
        cell = [self cellForParentCategory];
    }
    return cell;
}

- (WPTableViewCell *)cellForNewCategory {
    WPTableViewCell *cell;
    
    static NSString *newCategoryCellIdentifier = @"newCategoryCellIdentifier";
    cell = (WPTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:newCategoryCellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:newCategoryCellIdentifier];
        self.createCatNameField = [[UITextField alloc] initWithFrame:CGRectZero];
        self.createCatNameField.borderStyle = UITextBorderStyleNone;
        self.createCatNameField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.createCatNameField.font = [UIFont fontWithName:@"OpenSans" size:17];
        self.createCatNameField.placeholder = NSLocalizedString(@"Title", @"Title of the new Category being created.");
    }

    CGRect frame = self.createCatNameField.frame;
    frame.origin.x = 15.0f;
    frame.size.width = cell.contentView.frame.size.width - 30.0f;
    frame.size.height = cell.contentView.frame.size.height;
    self.createCatNameField.frame = frame;
    [cell.contentView addSubview:self.createCatNameField];
    
    return cell;
}

- (WPTableViewCell *)cellForParentCategory {
    WPTableViewCell *cell;
    static NSString *parentCategoryCellIdentifier = @"parentCategoryCellIdentifier";
    cell = (WPTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:parentCategoryCellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:parentCategoryCellIdentifier];
        cell.textLabel.font = [WPStyleGuide tableviewSectionHeaderFont];
        cell.textLabel.textColor = [WPStyleGuide whisperGrey];
        cell.textLabel.text = NSLocalizedString(@"Parent Category", @"Placeholder to set a parent category for a new category.");
        
        cell.detailTextLabel.font = [WPStyleGuide tableviewTextFont];
    }
    NSString *parentCategoryName;
    if (self.parentCategory == nil ) {
        parentCategoryName = NSLocalizedString(@"Optional", @"Placeholder to indicate that filling out the field is optional.");
        cell.detailTextLabel.textColor = [WPStyleGuide textFieldPlaceholderGrey];
    } else {
        parentCategoryName = self.parentCategory.categoryName;
        cell.detailTextLabel.textColor = [WPStyleGuide whisperGrey];
    }
    cell.detailTextLabel.text = parentCategoryName;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

    if (indexPath.section == 1) {
        [self populateSelectionsControllerWithCategories];
    }
}

#pragma mark textfied deletage

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
