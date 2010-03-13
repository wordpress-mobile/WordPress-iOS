//
//  PostLocationViewController.h
//  WordPress
//
//  Created by Christopher Boyd on 2/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "BlogDataManager.h"
#import "LocationController.h"
#import "PostAnnotation.h"

@interface PostLocationViewController : UIViewController <LocationControllerDelegate> {
	IBOutlet MKMapView *map;
	IBOutlet UIBarButtonItem *buttonClose, *buttonAction;
	IBOutlet UIToolbar *toolbar;
	LocationController *locationController;
}

@property (nonatomic, retain) IBOutlet MKMapView *map;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonClose, *buttonAction;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) LocationController *locationController;

- (void)locationUpdate:(CLLocation *)location;
- (void)locationError:(NSError *)error;
- (void)centerMapOn:(CLLocation *)location;
- (IBAction)dismiss:(id)sender;
- (IBAction)buttonActionPressed:(id)sender;
- (void)addLocation;
- (void)removeLocation;
- (BOOL)isPostGeotagged;
- (CLLocation *)getPostLocation;

@end
