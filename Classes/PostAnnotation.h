//
//  PostAnnotation.h
//  WordPress
//
//  Created by Christopher Boyd on 3/8/10.
//  
//

#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@interface PostAnnotation : NSObject<MKAnnotation>

- (id)initWithCoordinate:(CLLocationCoordinate2D)c;

@end
