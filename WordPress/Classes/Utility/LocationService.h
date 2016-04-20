#import <Foundation/Foundation.h>

/**
 Completion block for LocationService methods.
 */
typedef void(^LocationServiceCompletionBlock)(CLLocation *location, NSString *address, NSError *error);

typedef void(^LocationServicePlacemarksCompletionBlock)(NSArray<CLPlacemark *> *placemarks, NSError *error);
/**
 LocationServiceSource Error Codes
 */
typedef NS_ENUM(NSUInteger, LocationServiceError) {
    LocationServiceErrorPermissionDenied
};

extern NSString *const LocationServiceErrorDomain;

@interface LocationService : NSObject

/**
 Returns the singleton

 @return instance of LocationService
 */
+ (instancetype)sharedService;

/**
 Check if the location service is updating.

 @return YES if the service is currently updating location or looking up an address.
 */
@property (nonatomic, readonly) BOOL locationServiceRunning;

/**
 The last CLLocation reverse geocoded
 */
@property (nonatomic, strong, readonly) CLLocation *lastGeocodedLocation;

/**
 The last address reverse geocoded
 */
@property (nonatomic, strong, readonly) NSString *lastGeocodedAddress;

/**
 Check if location services are disabled system wide
 
 @return YES if location services are disable system wide
 */
- (BOOL)locationServicesDisabled;

/**
 Check if location services are denied or restricted.

 @return YES if services are denied or restricted, or NO if the user has give permission, or has never been prompted for permission.
 */
- (BOOL)locationServicesDenied;

/**
 Fetch the user's current location and do a reverse geolookup of its coordinates

 @param completionBlock The completion block to be executed when finished.
 */
- (void)getCurrentLocationAndAddress:(LocationServiceCompletionBlock)completionBlock;

/**
 Fetch the address for a location.

 @param location The location whose address needs to be found.
 @param completionBlock The completion block to be executed when finished.
 */
- (void)getAddressForLocation:(CLLocation *)location completion:(LocationServiceCompletionBlock)completionBlock;

/**
 Check if the lastGeocodedAddress is likely valid for the specified location.
 The lastGeocodedAddress is considered valid for the spcified location if the distance between the
 specified location and lastGeocodedLocation is within a short distance of each other.

 @param location The location whose address needs to be found.
 */
- (BOOL)hasAddressForLocation:(CLLocation *)location;

/**
 *  Search for placemarks that match the query for their name
 *
 *  @param query           the query string to use for search
 *  @param completionBlock a block to be invoked when results are found or an error occurs.
 */
- (void)searchPlacemarksWithQuery:(NSString *)query completion:(LocationServicePlacemarksCompletionBlock)completionBlock;

/**
 *  Shows an alert for an error resulting from a location request
 *
 *  @param error the error message to use for creating the alert
 */
- (void)showAlertForLocationError:(NSError *)error;

/**
 *  Show an alert for when location services are disabled
 */
- (void)showAlertForLocationServicesDisabled;

@end
