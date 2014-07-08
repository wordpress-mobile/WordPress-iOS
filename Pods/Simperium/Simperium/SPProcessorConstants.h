//
//  SPProcessorConstants.h
//  Simperium
//
//  Created by Michael Johnston on 9/9/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//


#pragma mark ====================================================================================
#pragma mark Notifications
#pragma mark ====================================================================================

extern NSString * const ProcessorDidAddObjectsNotification;
extern NSString * const ProcessorDidChangeObjectNotification;
extern NSString * const ProcessorDidDeleteObjectKeysNotification;
extern NSString * const ProcessorDidAcknowledgeObjectsNotification;
extern NSString * const ProcessorWillChangeObjectsNotification;
extern NSString * const ProcessorDidAcknowledgeDeleteNotification;
extern NSString * const ProcessorRequestsReindexingNotification;


#pragma mark ====================================================================================
#pragma mark Changeset Keys
#pragma mark ====================================================================================

extern NSString * const CH_KEY;
extern NSString * const CH_ADD;
extern NSString * const CH_REMOVE;
extern NSString * const CH_MODIFY;
extern NSString * const CH_OPERATION;
extern NSString * const CH_VALUE;
extern NSString * const CH_START_VERSION;
extern NSString * const CH_END_VERSION;
extern NSString * const CH_CHANGE_VERSION;
extern NSString * const CH_LOCAL_ID;
extern NSString * const CH_CLIENT_ID;
extern NSString * const CH_ERROR;
extern NSString * const CH_DATA;
extern NSString * const CH_EMPTY;


#pragma mark ====================================================================================
#pragma mark Changeset Errors
#pragma mark ====================================================================================

typedef NS_ENUM(NSUInteger, CH_ERRORS) {
    CH_ERRORS_INVALID_SCHEMA        = 400,
    CH_ERRORS_INVALID_PERMISSION    = 401,
    CH_ERRORS_NOT_FOUND             = 404,
	CH_ERRORS_BAD_VERSION           = 405,
	CH_ERRORS_DUPLICATE             = 409,
    CH_ERRORS_EMPTY_CHANGE          = 412,
    CH_ERRORS_DOCUMENT_TOO_lARGE    = 413,
	CH_ERRORS_EXPECTATION_FAILED	= 417,		// (e.g. foreign key doesn't exist just yet)
    CH_ERRORS_INVALID_DIFF			= 440,
	CH_ERRORS_THRESHOLD				= 503
};

// Internal Server Errors: [500-599]
static NSRange const CH_SERVER_ERROR_RANGE = {500, 99};
