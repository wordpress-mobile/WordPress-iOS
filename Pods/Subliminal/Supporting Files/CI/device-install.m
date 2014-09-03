/*/../bin/ls > /dev/null
# This comment is a shell script to self-compile this `.m` file.
# It allows the file to be directly invoked with arguments.
# Thanks to http://bou.io/HowToWriteASelfCompilingObjectiveCFile.html for explanation.


#  For details and documentation:
#  http://github.com/inkling/Subliminal
#
#  Copyright 2013-2014 Inkling Systems, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#


# `device-install` installs and uninstalls applications onto/from devices.
#
# `device-install` is modeled after the [`mobiledevice`](https://github.com/imkira/mobiledevice) and
# [`fruitstrap`](https://github.com/ghughes/fruitstrap) libraries. It differs from those projects primarily
# in its focus: it is not meant to serve as a general device manager that supports debugging, tunneling, etc.,
# or even to provide utilities like reporting a device's identifier or installed applications, but 
# solely to install and uninstall applications.
#
# Execute `device-install.m` with no arguments to print usage.


COMPILED=${0%.*}
clang "$0" -fobjc-arc -framework Foundation -framework MobileDevice -F/System/Library/PrivateFrameworks -o "$COMPILED"
if [ $? -eq 0 ]; then
    "$COMPILED" "$@"; EXIT_STATUS=$?; rm "$COMPILED"
    exit $EXIT_STATUS
else
    exit 1
fi
*/


#import <Foundation/Foundation.h>
#import <getopt.h>
#import "device-install.h"


#pragma mark - Usage

void printUsage(const char *app) {
    const char *usage = ""
    "usage: %s -i/--hw_id <udid> -a/--app <app> [-t/--timeout <timeout>] <command>\n"
    "\n"
    "   arguments:\n"
    "       -i/--hw_id <udid>       The UDID of the device on which to install, or from which to uninstall,\n"
    "                               an application. `device-install` will wait for this device to connect,\n"
    "                               if it is not already connected, for a duration determined by `timeout`.\n"
    "\n"
    "       -a/--app <app>          The full path to the application that is to be installed on, or uninstalled\n"
    "                               from, the device. This application must be built for an iOS device (as opposed\n"
    "                               to the simulator) and must be code-signed with a valid identity.\n"
    "                               (If you have set such an identity in your project's settings, Xcode will\n"
    "                               sign the application when it builds it for device.)\n"
    "\n"
    "       -t/--timeout <timeout>  The maximum duration for which to wait, in seconds, for the specified device\n"
    "                               to connect before aborting. This value is optional; if not specified,\n"
    "                               `device-install will wait indefinitely.\n"
    "\n"
    "   commands:\n"
    "       install                 Installs the specified application on the specified device.\n"
    "                               If the application is already installed, it will be updated (just like\n"
    "                               repeatedly building and running on device from Xcode.)\n"
    "\n"
    "       uninstall               Uninstalls the specified application from the specified device.\n"
    "                               More specifically, the application with bundle ID matching that of the\n"
    "                               specified application (if any) will be uninstalled.\n"
    "\n"
    "                               Note that this command will print log messages as if such an application\n"
    "                               is being uninstalled, even if none was actually installed prior to\n"
    "                               `device-install being invoked.\n"
    "\n";
    fprintf(stderr, usage, app);
}


#pragma mark - Definitions

#define DIAssert(condition, ...)\
do {\
    if (!(condition)) {\
        fprintf(stderr, __VA_ARGS__);\
        unregisterForDeviceNotifications();\
        exit(1);\
    }\
} while (0)

typedef NS_ENUM(NSUInteger, CommandType) {
    InstallApp,
    UninstallApp
};

struct {
    CommandType command;
    const char *deviceId;
    const char *appPath;
    double timeout;

    AMDeviceNotificationRef notification;
    BOOL foundDevice;
} __run;


#pragma mark - Functions

#pragma mark -Utility functions

// This must be declared at top so it can be called by DIAssert
void unregisterForDeviceNotifications() {
    AMDeviceNotificationUnsubscribe(__run.notification);
}

void withDeviceConnected(AMDeviceRef device, void(^connectionHandler)(BOOL didConnect, AMDeviceRef device)) {
    BOOL errorOccurred = AMDeviceConnect(device);

    errorOccurred = errorOccurred || !AMDeviceIsPaired(device); // unlike the other functions, this returns 1 on success
    errorOccurred = errorOccurred || AMDeviceValidatePairing(device);
    errorOccurred = errorOccurred || AMDeviceStartSession(device);

    connectionHandler(!errorOccurred, device);
    if (errorOccurred) return;

    DIAssert(AMDeviceStopSession(device) == 0, "Could not stop session.\n");
    DIAssert(AMDeviceDisconnect(device) == 0, "Could not disconnect from device.\n");
}

#pragma mark -Uninstallation

void uninstallCallback(CFDictionaryRef cfInfo, int arg) {
    // begin a new autorelease pool because this is a callback
    @autoreleasepool {
        NSDictionary *info = (__bridge NSDictionary *)cfInfo;

        // only print the "removing application" status (at ~50%) because there's only two others,
        // one at 0%--and we already print a 0% message--and one at 90% that's not very informative
        NSString *status = info[@"Status"];
        if ([status isEqualToString:@"RemovingApplication"]) {
            int percent = [info[@"PercentComplete"] intValue];
            printf("[%3d%%] %s\n", percent, "Removing the application");
        }
    }
}

void uninstallApp(AMDeviceRef device) {
    NSString *infoPlistPath = [@(__run.appPath) stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
    DIAssert(infoPlist, "App at path '%s' does not appear to be valid: 'Info.plist' is missing.\n", __run.appPath);
    NSString *bundleId = infoPlist[@"CFBundleIdentifier"];

    printf("[  0%%] Uninstalling app (%s) with bundle ID %s\n", __run.appPath, [bundleId UTF8String]);

    withDeviceConnected(device, ^(BOOL didConnect, AMDeviceRef dev) {
        DIAssert(didConnect, "Could not connect to device.\n");

        // in contrast to installation, it seems that uninstallation requires being connected
        // plus we're not using a service. perhaps there is one that would let us uninstall unconnected
        DIAssert(AMDeviceSecureUninstallApplication(0, dev, (__bridge CFStringRef)bundleId, 0, &uninstallCallback, 0) == 0, "Could not uninstall application.\n");
    });

    printf("[100%%] Uninstalled %s\n", __run.appPath);
    unregisterForDeviceNotifications();
    exit(0);
}

#pragma mark -Installation

void transferCallback(CFDictionaryRef cfInfo, int arg) {
    // begin a new autorelease pool because this is a callback
    @autoreleasepool {
        NSDictionary *info = (__bridge NSDictionary *)cfInfo;

        int percent = [info[@"PercentComplete"] intValue];
        int scaledPercent = percent / 2;    // transfer is only half the installation process

        // only print statuses about copying files
        // because the other ones are just "PreflightingTransfer" at 0%--and we already print a 0% message--
        // and "TransferringPackage" at the same percentage as the first file copied
        NSString *status = info[@"Status"];
        if ([status isEqualToString:@"CopyingFile"]) {
            NSString *path = info[@"Path"];
            // we may receive multiple callbacks while copying big files
            // but we only want to print one update per file
            static NSString *__lastPath = nil;
            if (!__lastPath || ![path isEqualToString:__lastPath]) {
                printf("[%3d%%] Copying %s to device\n", scaledPercent, [path UTF8String]);
            }
            __lastPath = path;
        }
    }
}

void installCallback(CFDictionaryRef cfInfo, int arg) {
    // begin a new autorelease pool because this is a callback
    @autoreleasepool {
        NSDictionary *info = (__bridge NSDictionary *)cfInfo;

        int percent = [info[@"PercentComplete"] intValue];
        int scaledPercent = percent / 2 + 50;    // this is the second half of the installation process
        printf("[%3d%%] %s\n", scaledPercent, [info[@"Status"] UTF8String]);
    }
}

void installApp(AMDeviceRef device) {
    printf("[  0%%] Installing %s\n", __run.appPath);

    CFStringRef appPath = (__bridge CFStringRef)@(__run.appPath);

    // copy app to device
    __block int afcFd;
    withDeviceConnected(device, ^(BOOL didConnect, AMDeviceRef dev) {
        DIAssert(didConnect, "Could not connect to device.\n");

        AMDeviceStartService(dev, AMSVC_AFC, &afcFd);

        // documentation on `AMDeviceStartService` says that we should disconnect before using the service
        // (in the transfer); also the transfer works without being connected
    });
    DIAssert(AMDeviceTransferApplication(afcFd, appPath, NULL, &transferCallback, 0) == 0, "Could not copy the app to the device.\n");
    close(afcFd);

    // install the app on the device
    __block int installFd;
    withDeviceConnected(device, ^(BOOL didConnect, AMDeviceRef dev) {
        DIAssert(didConnect, "Could not connect to device.\n");
        
        // There's no AMSVC value defined for the installation proxy
        AMDeviceStartService(dev, CFSTR("com.apple.mobile.installation_proxy"), &installFd);

        // documentation on `AMDeviceStartService` says that we should disconnect before using the service
        // (in the installation); also the installation works without being connected
    });
    NSDictionary *installOptions = @{ @"PackageType": @"Developer" };
    DIAssert(AMDeviceInstallApplication(installFd, appPath, (__bridge CFDictionaryRef)installOptions, &installCallback, 0) == 0, "Could not install application.\n");
    close(installFd);

    printf("[100%%] Installed %s\n", __run.appPath);
    unregisterForDeviceNotifications();
    exit(0);
}

#pragma mark -Startup

void handleDeviceConnection(AMDeviceRef device) {
    // ignore devices other than that specified by the user
    NSString *udid = CFBridgingRelease(AMDeviceCopyDeviceIdentifier(device));
    if (![udid isEqualToString:@(__run.deviceId)]) return;
    __run.foundDevice = YES;

    switch (__run.command) {
        case InstallApp:
            installApp(device);
            break;
        case UninstallApp:
            uninstallApp(device);
            break;
    }
}

void deviceNotificationCallback(AMDeviceNotificationCallbackInfoRef info, int cookie) {
    // begin a new autoreleasepool because this is a callback
    @autoreleasepool {
        switch (info->_message) {
            case ADNCI_MSG_CONNECTED:
                handleDeviceConnection(info->_device);
                break;
            default:
                break;
        }
    }
}

void registerForDeviceNotifications() {
    const char *timeoutDescription = "";
    if (__run.timeout > 0) {
        timeoutDescription = [[NSString stringWithFormat:@"up to %g seconds ", __run.timeout] UTF8String];
    }
    printf("[....] Waiting %sfor device %s to connect...\n", timeoutDescription, __run.deviceId);

    AMDeviceNotificationSubscribe(&deviceNotificationCallback, 0, 0, 0, &__run.notification);

    // wait for a device to connect (or for us to receive a notification of an already-connected device)
    if (__run.timeout > 0) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, __run.timeout, false);
        DIAssert(__run.foundDevice, "Timed out waiting for device to connect.\n");
    } else {
        // wait indefinitely
        CFRunLoopRun();
    }
}

int main(int argc, char *argv[])
{
    #define DIAssertUsage(condition, ...)\
    do {\
        if (!(condition)) {\
            fprintf(stderr, __VA_ARGS__);\
            printUsage(argv[0]);\
            exit(1);\
        }\
    } while (0)

    @autoreleasepool
    {
        // If the script was invoked with no arguments, print usage and die
        DIAssertUsage(argc > 1, "");

        // Parse options and command
        const struct option longopts[] = {
            { "hw_id",  required_argument, NULL, 'i' },
            { "app",    required_argument, NULL, 'a' },
            { "timeout",required_argument, NULL, 't' },
            { NULL, 0, NULL, 0 }
        };

        char ch;
        while ((ch = getopt_long(argc, argv, "i:a:t:", longopts, NULL)) != -1) {
            switch (ch) {
                case 'i':
                    __run.deviceId = optarg;
                    break;
                case 'a': {
                    NSString *appPath = [@(optarg) stringByStandardizingPath];
                    DIAssertUsage([[NSFileManager defaultManager] fileExistsAtPath:appPath], "App does not exist at specified path.\n");
                    __run.appPath = [appPath UTF8String];
                }   break;
                case 't':
                    __run.timeout = atof(optarg);
                    break;
                default:
                    // getopt_long will log an error for us
                    DIAssertUsage(NO, "");
                    break;
            }
        }

        // assert that the user specified the required arguments
        DIAssertUsage(__run.deviceId && __run.appPath, "You must specify a UDID and app path.\n");

        DIAssertUsage(optind < argc, "%s requires a command\n", argv[0]);
        NSString *commandType = @(argv[optind]);
        if ([commandType isEqualToString:@"install"]) {
            __run.command = InstallApp;
        } else if ([commandType isEqualToString:@"uninstall"]) {
            __run.command = UninstallApp;
        } else {
            DIAssertUsage(NO, "Unrecognized command: %s\n", [commandType UTF8String]);
        }

        // Wait for device to connect
        registerForDeviceNotifications();
    }
    return 0;
}
