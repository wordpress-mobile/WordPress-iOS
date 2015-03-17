#import <Foundation/Foundation.h>

@interface LoginFields : NSObject

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *siteUrl;
@property (nonatomic, copy) NSString *multifactorCode;
@property (nonatomic, assign) BOOL userIsDotCom;
@property (nonatomic, assign) BOOL shouldDisplayMultifactor;


+ (instancetype)loginFieldsWithUsername:(NSString *)username password:(NSString *)password siteUrl:(NSString *)siteUrl multifactorCode:(NSString *)multifactorCode userIsDotCom:(BOOL)userIsDotCom shouldDisplayMultiFactor:(BOOL)shouldDisplayMultifactor;

@end

