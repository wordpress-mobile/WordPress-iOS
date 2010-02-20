//
//  PostLocationViewController.h
//  WordPress
//
//  Created by Christopher Boyd on 2/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "LocationController.h"

@interface PostLocationViewController : UIViewController <LocationControllerDelegate> {
	IBOutlet MKMapView *map;
	IBOutlet UIBarButtonItem *buttonClose;
	LocationController *locationController;
	CLLocation *initialLocation;
}

@property (nonatomic, retain) IBOutlet MKMapView *map;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonClose;
@property (nonatomic, retain) LocationController *locationController;
@property (nonatomic, retain) CLLocation *initialLocation;

- (void)locationUpdate:(CLLocation *)location;
- (void)locationError:(NSError *)error;
- (void)centerMapOn:(CLLocation *)location;
- (IBAction)dismiss:(id)sender;

@end
