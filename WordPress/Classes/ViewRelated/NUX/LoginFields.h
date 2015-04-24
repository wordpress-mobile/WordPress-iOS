#import <Foundation/Foundation.h>

/**
 *  This class is a wrapper for the fields needed for logging into a WordPress site.
 */
@interface LoginFields : NSObject

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *siteUrl;
@property (nonatomic, copy) NSString *multifactorCode;
@property (nonatomic, assign) BOOL userIsDotCom;
@property (nonatomic, assign) BOOL shouldDisplayMultifactor;

/**
 *  Helper method to initialize this class
 *
 *  @param username                 username
 *  @param password                 password
 *  @param siteUrl                  siteUrl (not required for WordPress.com)
 *  @param multifactorCode          the multifactor code if the user is attempting to login to a site that requires one
 *  @param userIsDotCom             whether this is a WordPress.com login
 *  @param shouldDisplayMultifactor whether or not to display the fields that allow the user to input a 2fa code
 *
 *  @return an initialized `LoginFields` class
 */
+ (instancetype)loginFieldsWithUsername:(NSString *)username
                               password:(NSString *)password
                                siteUrl:(NSString *)siteUrl
                        multifactorCode:(NSString *)multifactorCode
                           userIsDotCom:(BOOL)userIsDotCom
               shouldDisplayMultiFactor:(BOOL)shouldDisplayMultifactor;

@end

