//
//  PostMediaEditViewController.m
//  WordPress
//
//  Created by Chris Boyd on 8/31/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "PostMediaEditViewController.h"

@implementation PostMediaEditViewController
@synthesize mediaType, media, imageView, moviePlayer, buttons, table;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.table.backgroundColor = [UIColor clearColor];
	self.table.backgroundView = nil;
	
	buttons = [[NSArray alloc] initWithObjects:@"Resize", @"Upload", @"Insert", nil];
	
	switch (mediaType) {
		case kImage:
			self.navigationItem.title = @"Image";
			break;
		case kVideo:
			self.navigationItem.title = @"Video";
			break;
		default:
			break;
	}
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return buttons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.textAlignment = UITextAlignmentCenter;
	}
	
	NSString *mediaString = @"Image";
	if(mediaType == kVideo)
		mediaString = @"Video";
	
	cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [buttons objectAtIndex:indexPath.row], mediaString];
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
	return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 340, 230)] autorelease];
	UIView *fooLabel = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
	int foo = 0;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filepath = [documentsDirectory stringByAppendingPathComponent:media.filename];
	switch(section) {
		case 0:
			switch (mediaType) {
				case kImage:
					foo = 1;
					NSData *imageData = [NSData dataWithContentsOfFile:filepath];
					UIImage *contentImage = [[UIImage alloc] initWithData:imageData];
					contentImage = [contentImage resizedImage:CGSizeMake(200, 200) interpolationQuality:kCGInterpolationHigh];
					imageView = [[UIImageView alloc] initWithImage:contentImage];
					imageView.bounds = headerView.frame;
					[headerView addSubview:imageView];
					break;
				case kVideo:
					moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:filepath]];
					[headerView addSubview:moviePlayer.view];
					break;
				default:
					break;
			}
			break;
		default:
			[headerView addSubview:fooLabel];
			break;
	}
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	CGFloat height;
	switch(section) {
		case 0:
			height = 230.0;
			break;
		default:
			height = 2.0;
			break;
	}
	return height;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[table release];
	[buttons release];
	[media release];
	[imageView release];
	[moviePlayer release];
    [super dealloc];
}


@end
