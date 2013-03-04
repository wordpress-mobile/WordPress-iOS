# WordPress API for iOS

WordPress API for iOS is a library for iOS designed to make sharing on your WordPress blog easy.

It's not meant to provide access to the full feature set of the WordPress XML-RPC API.

# Disclaimer

**Warning:** This API is a work in progress, and much of the basic functionality is not implemented yet.

# Installation

WordPress API uses [CocoaPods](http://cocoapods.org/) for easy
dependency management.

Until we are ready for a 1.0 release, you can add this to your Podfile:

	pod 'WordPressApi', :podspec => 'https://raw.github.com/koke/WordPressApi/master/WordPressApi.podspec'

Another option, if you don't use CocoaPods, is to copy the `WordPressApi`
folder to your project.

# Example usage

## Posting a picture

A hypothetical camera app called Cameramattic wants to add an option to share its pictures on WordPress

    NSURL *xmlrpcURL = [NSURL URLWithString:@"https://aphotoblog.wordpress.com"];
    NSString *username = "aUsername";
    NSString *password = "thePassword";
    NSString *title = "My cat";
    NSString *content = "She likes to sleep like that";
    UIImage *image = ... // The image to upload

    WordPressAPI *wp = [[WordPressAPI alloc] initWithXMLRPCEndpoint:xmlrpcURL username:username password:password];
    [wp publishPostWithImage:(UIImage *)image
                 description:(NSString *)content
                       title:(NSString *)title
                     success:^(NSUInteger postId, NSURL *permalink) {
                         NSLog(@"Image post successful with ID %d at %@", postId, permalink);
                     }
                     failure:^(NSError *error) {
                         NSLog(@"Post upload failed: %@", [error localizedDescription])
                     }];
