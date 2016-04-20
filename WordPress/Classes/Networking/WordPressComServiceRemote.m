#import "WordPressComServiceRemote.h"
#import "NSString+Helpers.h"
#import "WordPressComApi.h"
#import "WordPressComApiCredentials.h"

NSString *const WordPressComApiErrorDomain = @"com.wordpress.api";
NSString *const WordPressComApiErrorMessageKey = @"WordPressComApiErrorMessageKey";
NSString *const WordPressComApiErrorCodeKey = @"WordPressComApiErrorCodeKey";

@implementation WordPressComServiceRemote

- (void)createWPComAccountWithEmail:(NSString *)email
                        andUsername:(NSString *)username
                        andPassword:(NSString *)password
                            success:(WordPressComServiceSuccessBlock)success
                            failure:(WordPressComServiceFailureBlock)failure
{
    NSParameterAssert([email isKindOfClass:[NSString class]]);
    NSParameterAssert([username isKindOfClass:[NSString class]]);
    NSParameterAssert([password isKindOfClass:[NSString class]]);
    
    [self createWPComAccountWithEmail:email
                          andUsername:username
                          andPassword:password
                             validate:NO
                              success:success
                              failure:failure];
}

- (void)createWPComAccountWithEmail:(NSString *)email
                        andUsername:(NSString *)username
                        andPassword:(NSString *)password
                           validate:(BOOL)validate
                            success:(WordPressComServiceSuccessBlock)success
                            failure:(WordPressComServiceFailureBlock)failure
{
    NSParameterAssert([email isKindOfClass:[NSString class]]);
    NSParameterAssert([username isKindOfClass:[NSString class]]);
    NSParameterAssert([password isKindOfClass:[NSString class]]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error){
        NSError *errorWithLocalizedMessage;
        // This endpoint is throttled, so check if we've sent too many requests and fill that error in as
        // when too many requests occur the API just spits out an html page.
        if ([error.userInfo objectForKey:WordPressComApiErrorCodeKey] == nil) {
            NSString *responseString = [operation responseString];
            if (responseString != nil && [responseString rangeOfString:@"Limit reached"].location != NSNotFound) {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:error.userInfo];
                [userInfo setValue:NSLocalizedString(@"Limit reached. You can try again in 1 minute. Trying again before that will only increase the time you have to wait before the ban is lifted. If you think this is in error, contact support.", @"") forKey:WordPressComApiErrorMessageKey];
                [userInfo setValue:@"too_many_requests" forKey:WordPressComApiErrorCodeKey];
                errorWithLocalizedMessage = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:userInfo];
            }
        } else {
            NSString *localizedErrorMessage = [self errorMessageForError:error];
            NSString *errorCode = [error.userInfo objectForKey:WordPressComApiErrorCodeKey];
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:error.userInfo];
            [userInfo setValue:errorCode forKey:WordPressComApiErrorCodeKey];
            [userInfo setValue:localizedErrorMessage forKey:WordPressComApiErrorMessageKey];
            errorWithLocalizedMessage = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:userInfo];
        }
        
        failure(errorWithLocalizedMessage);
    };
    
    NSDictionary *params = @{
                             @"email": email,
                             @"username" : username,
                             @"password" : password,
                             @"validate" : @(validate),
                             @"client_id" : [WordPressComApiCredentials client],
                             @"client_secret" : [WordPressComApiCredentials secret]
                             };
    
    NSString *requestUrl = [self pathForEndpoint:@"users/new"
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl parameters:params success:successBlock failure:failureBlock];
}

- (void)validateWPComBlogWithUrl:(NSString *)blogUrl
                    andBlogTitle:(NSString *)blogTitle
                   andLanguageId:(NSString *)languageId
                         success:(WordPressComServiceSuccessBlock)success
                         failure:(WordPressComServiceFailureBlock)failure
{
    [self createWPComBlogWithUrl:blogUrl
                    andBlogTitle:blogTitle
                   andLanguageId:languageId
               andBlogVisibility:WordPressComServiceBlogVisibilityPublic
                        validate:YES
                         success:success
                         failure:failure];
}

- (void)createWPComBlogWithUrl:(NSString *)blogUrl
                  andBlogTitle:(NSString *)blogTitle
                 andLanguageId:(NSString *)languageId
             andBlogVisibility:(WordPressComServiceBlogVisibility)visibility
                       success:(WordPressComServiceSuccessBlock)success
                       failure:(WordPressComServiceFailureBlock)failure
{
    [self createWPComBlogWithUrl:blogUrl
                    andBlogTitle:blogTitle
                   andLanguageId:languageId
               andBlogVisibility:visibility
                        validate:NO
                         success:success
                         failure:failure];
}

- (void)createWPComBlogWithUrl:(NSString *)blogUrl
                  andBlogTitle:(NSString *)blogTitle
                 andLanguageId:(NSString *)languageId
             andBlogVisibility:(WordPressComServiceBlogVisibility)visibility
                      validate:(BOOL)validate
                       success:(WordPressComServiceSuccessBlock)success
                       failure:(WordPressComServiceFailureBlock)failure
{
    NSParameterAssert([blogUrl isKindOfClass:[NSString class]]);
    NSParameterAssert([languageId isKindOfClass:[NSString class]]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = responseObject;
        if ([response count] == 0) {
            // There was an error creating the blog as a successful call yields a dictionary back.
            NSString *localizedErrorMessage = NSLocalizedString(@"Unknown error", nil);
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
            [userInfo setValue:localizedErrorMessage forKey:WordPressComApiErrorMessageKey];
            NSError *errorWithLocalizedMessage = [[NSError alloc] initWithDomain:WordPressComApiErrorDomain code:0 userInfo:userInfo];
            
            failure(errorWithLocalizedMessage);
        } else {
            success(responseObject);
        }
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error){
        NSError *errorWithLocalizedMessage;
        
        if ([error.userInfo objectForKey:WordPressComApiErrorCodeKey] == nil) {
            NSString *responseString = [operation responseString];
            if (responseString != nil && [responseString rangeOfString:@"Limit reached"].location != NSNotFound) {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:error.userInfo];
                [userInfo setValue:NSLocalizedString(@"Limit reached. You can try again in 1 minute. Trying again before that will only increase the time you have to wait before the ban is lifted. If you think this is in error, contact support.", @"") forKey:WordPressComApiErrorMessageKey];
                [userInfo setValue:@"too_many_requests" forKey:WordPressComApiErrorCodeKey];
                errorWithLocalizedMessage = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:userInfo];
            }
        }
        else {
            NSString *errorCode = [error.userInfo objectForKey:WordPressComApiErrorCodeKey];
            NSString *localizedErrorMessage = [self errorMessageForError:error];
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:error.userInfo];
            [userInfo setValue:errorCode forKey:WordPressComApiErrorCodeKey];
            [userInfo setValue:localizedErrorMessage forKey:WordPressComApiErrorMessageKey];
            errorWithLocalizedMessage = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:userInfo];
        }
        failure(errorWithLocalizedMessage);
    };
    
    if (blogTitle == nil) {
        blogTitle = @"";
    }
    
    int blogVisibility = 1;
    if (visibility == WordPressComServiceBlogVisibilityPublic) {
        blogVisibility = 1;
    } else if (visibility == WordPressComServiceBlogVisibilityPrivate) {
        blogVisibility = -1;
    } else {
        // Hidden
        blogVisibility = 0;
    }
    
    NSDictionary *params = @{
                             @"blog_name": blogUrl,
                             @"blog_title": blogTitle,
                             @"lang_id": languageId,
                             @"public": @(blogVisibility),
                             @"validate": @(validate),
                             @"client_id": [WordPressComApiCredentials client],
                             @"client_secret": [WordPressComApiCredentials secret]
                             };
    
    
    NSString *requestUrl = [self pathForEndpoint:@"sites/new"
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl parameters:params success:successBlock failure:failureBlock];
}

#pragma mark - Error localization


- (NSString *)errorMessageForError:(NSError *)error
{
    NSString *errorCode = [error.userInfo stringForKey:WordPressComApiErrorCodeKey];
    NSString *errorMessage = [[error.userInfo stringForKey:NSLocalizedDescriptionKey] stringByStrippingHTML];
    
    if ([errorCode isEqualToString:@"username_only_lowercase_letters_and_numbers"]) {
        return NSLocalizedString(@"Sorry, usernames can only contain lowercase letters (a-z) and numbers.", nil);
    } else if ([errorCode isEqualToString:@"username_required"]) {
        return NSLocalizedString(@"Please enter a username.", nil);
    } else if ([errorCode isEqualToString:@"username_not_allowed"]) {
        return NSLocalizedString(@"That username is not allowed.", nil);
    } else if ([errorCode isEqualToString:@"email_cant_be_used_to_signup"]) {
        return NSLocalizedString(@"You cannot use that email address to signup. We are having problems with them blocking some of our email. Please use another email provider.", nil);
    } else if ([errorCode isEqualToString:@"username_must_be_at_least_four_characters"]) {
        return NSLocalizedString(@"Username must be at least 4 characters.", nil);
    } else if ([errorCode isEqualToString:@"username_contains_invalid_characters"]) {
        return NSLocalizedString(@"Sorry, usernames may not contain the character &#8220;_&#8221;!", nil);
    } else if ([errorCode isEqualToString:@"username_must_include_letters"]) {
        return NSLocalizedString(@"Sorry, usernames must have letters (a-z) too!", nil);
    } else if ([errorCode isEqualToString:@"email_not_allowed"]) {
        return NSLocalizedString(@"Sorry, that email address is not allowed!", nil);
    } else if ([errorCode isEqualToString:@"username_exists"]) {
        return NSLocalizedString(@"Sorry, that username already exists!", nil);
    } else if ([errorCode isEqualToString:@"email_exists"]) {
        return NSLocalizedString(@"Sorry, that email address is already being used!", nil);
    } else if ([errorCode isEqualToString:@"username_reserved_but_may_be_available"]) {
        return NSLocalizedString(@"That username is currently reserved but may be available in a couple of days.", nil);
    } else if ([errorCode isEqualToString:@"username_unavailable"]) {
        return NSLocalizedString(@"Sorry, that username is unavailable.", nil);
    } else if ([errorCode isEqualToString:@"email_reserved"]) {
        return NSLocalizedString(@"That email address has already been used. Please check your inbox for an activation email. If you don't activate you can try again in a few days.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_required"]) {
        return NSLocalizedString(@"Please enter a site address.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_not_allowed"]) {
        return NSLocalizedString(@"That site address is not allowed.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_must_be_at_least_four_characters"]) {
        return NSLocalizedString(@"Site address must be at least 4 characters.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_must_be_less_than_sixty_four_characters"]) {
        return NSLocalizedString(@"The site address must be shorter than 64 characters.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_contains_invalid_characters"]) {
        return NSLocalizedString(@"Sorry, site addresses may not contain the character &#8220;_&#8221;!", nil);
    } else if ([errorCode isEqualToString:@"blog_name_cant_be_used"]) {
        return NSLocalizedString(@"Sorry, you may not use that site address.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_only_lowercase_letters_and_numbers"]) {
        return NSLocalizedString(@"Sorry, site addresses can only contain lowercase letters (a-z) and numbers.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_must_include_letters"]) {
        return NSLocalizedString(@"Sorry, site addresses must have letters too!", nil);
    } else if ([errorCode isEqualToString:@"blog_name_exists"]) {
        return NSLocalizedString(@"Sorry, that site already exists!", nil);
    } else if ([errorCode isEqualToString:@"blog_name_reserved"]) {
        return NSLocalizedString(@"Sorry, that site is reserved!", nil);
    } else if ([errorCode isEqualToString:@"blog_name_reserved_but_may_be_available"]) {
        return NSLocalizedString(@"That site is currently reserved but may be available in a couple days.", nil);
    } else if ([errorCode isEqualToString:@"password_invalid"]) {
        return NSLocalizedString(@"Sorry, that password does not meet our security guidelines. Please choose a password with a mix of uppercase letters, lowercase letters, numbers and symbols.", @"This error message occurs when a user tries to create an account with a weak password.");
    } else if ([errorCode isEqualToString:@"blog_title_invalid"]) {
        return NSLocalizedString(@"Invalid Site Title", @"");
    } else if ([errorCode isEqualToString:@"username_illegal_wpcom"]) {
        // Try to extract the illegal phrase
        NSError *error;
        NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"\"([^\"].*)\"" options:NSRegularExpressionCaseInsensitive error:&error];
        NSArray *matches = [regEx matchesInString:errorMessage options:0 range:NSMakeRange(0, [errorMessage length])];
        NSString *invalidPhrase = @"";
        for (NSTextCheckingResult *result in matches) {
            if ([result numberOfRanges] < 2)
                continue;
            NSRange invalidTextRange = [result rangeAtIndex:1];
            invalidPhrase = [NSString stringWithFormat:@" (\"%@\")", [errorMessage substringWithRange:invalidTextRange]];
        }
        
        return [NSString stringWithFormat:NSLocalizedString(@"Sorry, but your username contains an invalid phrase%@.", @"This error message occurs when a user tries to create a username that contains an invalid phrase for WordPress.com. The %@ may include the phrase in question if it was sent down by the API"), invalidPhrase];
    }
    
    // We have a few ambiguous errors that come back from the api, they sometimes have error messages included so
    // attempt to return that if possible. If not fall back to a generic error.
    NSDictionary *ambiguousErrors = @{
                                      @"email_invalid": NSLocalizedString(@"Please enter a valid email address.", nil),
                                      @"blog_name_invalid" : NSLocalizedString(@"Invalid Site Address", @""),
                                      @"username_invalid" : NSLocalizedString(@"Invalid username", @"")
                                      };
    if ([ambiguousErrors.allKeys containsObject:errorCode]) {
        if (errorMessage != nil) {
            return errorMessage;
        }
        
        return [ambiguousErrors objectForKey:errorCode];
    }
    
    // Return an error message if there's one included rather than the unhelpful "Unknown Error"
    if (errorMessage != nil) {
        return errorMessage;
    }
    
    return NSLocalizedString(@"Unknown error", nil);
}

@end
