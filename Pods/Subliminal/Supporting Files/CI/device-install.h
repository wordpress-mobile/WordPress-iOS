//
//  device-install.h
//  
//	Copyright 2003 Inkling Systems, Inc.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy 
//	of this file and its contents (the "Header File"), to deal in the Header File 
//	without restriction, including without limitation the rights to use, copy, 
//	modify, merge, publish, distribute, sublicense, and/or sell copies of the 
//	Header File, and to permit persons to whom the Header File is furnished to 
//	do so, subject to the following conditions:
//  
//	The above copyright notice and this permission notice shall be included in 
//	all copies or substantial portions of the Header File.
//
//	THE HEADER FILE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
//	IN CONNECTION WITH THE HEADER FILE OR THE USE OR OTHER DEALINGS IN THE HEADER 
//	FILE.
//
//
//	This file is named `device-install.h` as it accompanies `device-install.m`, 
//  but what it defines is an interface to `MobileDevice.framework`.
//  This is by no means a complete interface, but only those structure definitions, 
//	typedefs, and function prototypes necessary to `device-install.m`. More 
//	information may be found online at http://theiphonewiki.com/wiki/MobileDevice_Library .
//
//	This file was produced with reference to several open-source projects.
//  We credit those sources below but do not believe the licenses used for those 
//	projects apply to this file, as this file does not rely on code from those 
//	projects. Although we have used certain structure definitions, typedefs and 
//	function prototypes from those projects, we do not believe that those elements 
//	are copyrightable. However, as with anything publicly available, it is up to 
//	you to determine whether the contents of this file and the licenses applicable 
//	to it are suitable for your use.
//


// Unless otherwise noted, the structure definitions, typedefs and function prototypes 
// below are reproduced from http://theiphonewiki.com/w/index.php?title=MobileDevice_Library&oldid=32928 .
// Documentation is reproduced from http://theiphonewiki.com/w/index.php?title=MobileDevice_Library&oldid=30093 .
//
// Where definitions have diverged between http://theiphonewiki.com/w/index.php?title=MobileDevice_Library&oldid=30093
// and http://theiphonewiki.com/w/index.php?title=MobileDevice_Library&oldid=32928 ,
// the documentation from http://theiphonewiki.com/w/index.php?title=MobileDevice_Library&oldid=30093
// has been updated by the author of this file (Inkling Systems, Inc.) to correspond 
// to the definitions of http://theiphonewiki.com/w/index.php?title=MobileDevice_Library&oldid=32928 .
#ifndef MOBILEDEVICE_H
#define MOBILEDEVICE_H

#ifndef __GNUC__
#pragma pack
#define __PACK
#else
#define __PACK __attribute__((__packed__))
#endif

#include <CoreFoundation/CoreFoundation.h>
#include <mach/error.h>

	/* Error codes */
#define MDERR_APPLE_MOBILE  (err_system(0x3a))
#define MDERR_IPHONE        (err_sub(0))

	/* Apple Mobile (AM*) errors */
#define MDERR_OK                ERR_SUCCESS
#define MDERR_SYSCALL           (ERR_MOBILE_DEVICE | 0x01)
#define MDERR_OUT_OF_MEMORY     (ERR_MOBILE_DEVICE | 0x03)
#define MDERR_QUERY_FAILED      (ERR_MOBILE_DEVICE | 0x04)
#define MDERR_INVALID_ARGUMENT  (ERR_MOBILE_DEVICE | 0x0b)
#define MDERR_DICT_NOT_LOADED   (ERR_MOBILE_DEVICE | 0x25)

	/* Messages passed to device notification callbacks: passed as part of
	 * AMDeviceNotificationCallbackInfo. */
#define ADNCI_MSG_CONNECTED     1
#define ADNCI_MSG_DISCONNECTED  2
#define ADNCI_MSG_UNSUBSCRIBED  3

#define AMD_IPHONE_PRODUCT_ID   0x1290
	//#define AMD_IPHONE_SERIAL       ""

	/* Services, found in /System/Library/Lockdown/Services.plist */
#define AMSVC_AFC                   CFSTR("com.apple.afc")
#define AMSVC_BACKUP                CFSTR("com.apple.mobilebackup")
#define AMSVC_CRASH_REPORT_COPY     CFSTR("com.apple.crashreportcopy")
#define AMSVC_DEBUG_IMAGE_MOUNT     CFSTR("com.apple.mobile.debug_image_mount")
#define AMSVC_NOTIFICATION_PROXY    CFSTR("com.apple.mobile.notification_proxy")
#define AMSVC_PURPLE_TEST           CFSTR("com.apple.purpletestr")
#define AMSVC_SOFTWARE_UPDATE       CFSTR("com.apple.mobile.software_update")
#define AMSVC_SYNC                  CFSTR("com.apple.mobilesync")
#define AMSVC_SCREENSHOT            CFSTR("com.apple.screenshotr")
#define AMSVC_SYSLOG_RELAY          CFSTR("com.apple.syslog_relay")
#define AMSVC_SYSTEM_PROFILER       CFSTR("com.apple.mobile.system_profiler")

	/* Structure that contains internal data used by AMDevice... functions. Never try
     * to access its members directly! Use AMDeviceCopyDeviceIdentifier,
     * AMDeviceGetConnectionID, AMDeviceRetain, AMDeviceRelease instead. */
    struct AMDevice {
        CFUUIDBytes _uuid;          /* 0 - Unique Device Identifier */
        UInt32 _deviceID;           /* 16 */
        UInt32 _productID;          /* 20 - set to AMD_IPHONE_PRODUCT_ID */
        CFStringRef _serial;        /* 24 - serial string of device */
        UInt32 _unknown0;           /* 28 */
        UInt32 _unknown1;           /* 32 - reference counter, increased by AMDeviceRetain, decreased by AMDeviceRelease */
        UInt32 _lockdownConnection; /* 36 */
        UInt8 _unknown2[8];         /* 40 */
#if (__ITUNES_VER > 740)
        UInt32 _unknown3;           /* 48 - used to store CriticalSection Handle*/
#if (__ITUNES_VER >= 800)
        UInt8 _unknown4[24];        /* 52 */
#endif
#endif
    } __PACK;
    typedef struct __AMDevice AMDevice;
    typedef const AMDevice *AMDeviceRef;

    struct __AMDeviceNotificationCallbackInfo;
    typedef void (*AMDeviceNotificationCallback)(struct __AMDeviceNotificationCallbackInfo *, int _cookie);

    struct __AMDeviceNotification {
        UInt32 _unknown0;                       /* 0  */
        UInt32 _unknown1;                       /* 4  */
        UInt32 _unknown2;                       /* 8  */
        AMDeviceNotificationCallback _callback; /* 12 */
        UInt32 _cookie;                         /* 16 */
    } __PACK;
    typedef struct __AMDeviceNotification AMDeviceNotification;
    typedef const AMDeviceNotification *AMDeviceNotificationRef;

    struct __AMDeviceNotificationCallbackInfo {
        AMDeviceRef _device;                    /* 0 - device */
        UInt32 _message;                        /* 4 - one of ADNCI_MSG_* */
        AMDeviceNotificationRef _subscription;  /* 8 */
    } __PACK;
    typedef struct __AMDeviceNotificationCallbackInfo AMDeviceNotificationCallbackInfo;
    typedef AMDeviceNotificationCallbackInfo *AMDeviceNotificationCallbackInfoRef;

	/*  Registers a notification with the current run loop. The callback gets
	 *  copied into the notification struct, as well as being registered with the
	 *  current run loop. Cookie gets copied into cookie in the same.
	 *  (Cookie is a user info parameter that gets passed as an arg to
	 *  the callback) unused0 and unused1 are both 0 when iTunes calls this.
	 *
	 *  Never try to access directly or copy contents of dev and subscription fields
	 *  in AMDeviceNotificationCallbackInfo. Treat them as abstract handles.
	 *  When done with connection use AMDeviceRelease to free resources allocated for am_device.
	 *
	 *  Returns:
	 *      MDERR_OK            if successful
	 *      MDERR_SYSCALL       if CFRunLoopAddSource() failed
	 *      MDERR_OUT_OF_MEMORY if we ran out of memory
	 */
	mach_error_t AMDeviceNotificationSubscribe(AMDeviceNotificationCallback callback,
                                                           unsigned int unused0, unsigned int unused1,
                                                           unsigned int cookie,
                                                           AMDeviceNotificationRef *subscription);


    /* Unregisters notifications. Buggy (iTunes 8.2): if you subscribe, unsubscribe and subscribe again, arriving
     notifications will contain cookie and subscription from 1st call to subscribe, not the 2nd one. iTunes
     calls this function only once on exit.
     */
	mach_error_t AMDeviceNotificationUnsubscribe(AMDeviceNotificationRef subscription);

	/*  Returns serial field of AMDevice structure
	 */
	CFStringRef AMDeviceCopyDeviceIdentifier(AMDeviceRef device);

	/*  Connects to the iPhone. Pass in the AMDeviceRef that the
	 *  notification callback will give to you.
	 *
	 *  Returns:
	 *      MDERR_OK                if successfully connected
	 *      MDERR_SYSCALL           if setsockopt() failed
	 *      MDERR_QUERY_FAILED      if the daemon query failed
	 *      MDERR_INVALID_ARGUMENT  if USBMuxConnectByPort returned 0xffffffff
	 */
	mach_error_t AMDeviceConnect(AMDeviceRef device);

    mach_error_t AMDeviceDisconnect(AMDeviceRef device);

	/*  Calls PairingRecordPath() on the given device, than tests whether the path
	 *  which that function returns exists. During the initial connect, the path
	 *  returned by that function is '/', and so this returns 1.
	 *
	 *  Returns:
	 *      0   if the path did not exist
	 *      1   if it did
	 */
	mach_error_t AMDeviceIsPaired(AMDeviceRef device);
	mach_error_t AMDevicePair(AMDeviceRef device);

	/*  iTunes calls this function immediately after testing whether the device is
	 *  paired. It creates a pairing file and establishes a Lockdown connection.
	 *
	 *  Returns:
	 *      MDERR_OK                if successful
	 *      MDERR_INVALID_ARGUMENT  if the supplied device is null
	 *      MDERR_DICT_NOT_LOADED   if the load_dict() call failed
	 */
	mach_error_t AMDeviceValidatePairing(AMDeviceRef device);

	/*  Creates a Lockdown session and adjusts the device structure appropriately
	 *  to indicate that the session has been started. iTunes calls this function
	 *  after validating pairing.
	 *
	 *  Returns:
	 *      MDERR_OK                if successful
	 *      MDERR_INVALID_ARGUMENT  if the Lockdown conn has not been established
	 *      MDERR_DICT_NOT_LOADED   if the load_dict() call failed
	 */
	mach_error_t AMDeviceStartSession(AMDeviceRef device);


	/* Starts a service and returns a socket file descriptor that can be used in order to further
	 * access the service. You should stop the session and disconnect before using
	 * the service. iTunes calls this function after starting a session. It starts
	 * the service and the SSL connection. service_name should be one of the AMSVC_*
	 * constants.
	 *
	 * Returns:
	 *      MDERR_OK                if successful
	 *      MDERR_SYSCALL           if the setsockopt() call failed
	 *      MDERR_INVALID_ARGUMENT  if the Lockdown conn has not been established
	 */
	mach_error_t AMDeviceStartService(AMDeviceRef device, CFStringRef
                                                  service_name, int *socket_fd);

	/* Stops a session. You should do this before accessing services.
	 *
	 * Returns:
	 *      MDERR_OK                if successful
	 *      MDERR_INVALID_ARGUMENT  if the Lockdown conn has not been established
	 */
	mach_error_t AMDeviceStopSession(AMDeviceRef device);

	/* Decrements reference counter and, if nothing left, releases resources hold
	 * by connection, invalidates  pointer to device
	 */
	void AMDeviceRelease(AMDeviceRef device);

	/* Increments reference counter
	 */
	void AMDeviceRetain(AMDeviceRef device);


// The following function prototype is reproduced from https://github.com/imkira/mobiledevice/blob/master/mobiledevice.h .
    int AMDeviceSecureUninstallApplication(int unknown0, AMDeviceRef device, CFStringRef bundle_id,
                                           int unknown1, void *callback, int callback_arg);


// The following function prototypes are inferred from those functions' usage
// in https://github.com/ghughes/fruitstrap/blob/master/fruitstrap.c .
// Comments are by Inkling Systems, Inc.
    /* `socket_fd` is the file descriptor returned (by reference) by `AMDeviceStartService` called with `AMSVC_AFC` for `service_name` */
    int AMDeviceTransferApplication(int socket_fd, CFStringRef path,
                                    CFDictionaryRef options, void *callback, int callback_arg);
    /* `socket_fd` is the file descriptor returned (by reference) by `AMDeviceStartService` called with `CFSTR("com.apple.mobile.installation_proxy")` for `service_name` */
    int AMDeviceInstallApplication(int socket_fd, CFStringRef path,
                                   CFDictionaryRef options, void *callback, int callback_arg);

#endif
