#import <Foundation/Foundation.h>

/**
 Completion block for LocationService methods.
 */
typedef void(^LocationServiceCompletionBlock)(CLLocation *location, NSString *address, NSError *error);

/**
 LocationServiceSource Error Codes
 */
typedef NS_ENUM(NSUInteger, LocationServiceError) {
    LocationServiceErrorLocationsUnavailable,
    LocationServiceErrorLocationServiceTimedOut
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
 Check if location services are disabled.

 @return YES if services are disabled or restricted, or NO if the user has give permission, or has never been prompted for permission.
 */
- (BOOL)locationServicesDisabled;

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

@end
