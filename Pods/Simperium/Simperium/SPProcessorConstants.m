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

NSString * const ProcessorDidAddObjectsNotification             = @"ProcessorDidAddObjectsNotification";
NSString * const ProcessorDidChangeObjectNotification           = @"ProcessorDidChangeObjectNotification";
NSString * const ProcessorDidDeleteObjectKeysNotification       = @"ProcessorDidDeleteObjectKeysNotification";
NSString * const ProcessorDidAcknowledgeObjectsNotification     = @"ProcessorDidAcknowledgeObjectsNotification";
NSString * const ProcessorWillChangeObjectsNotification         = @"ProcessorWillChangeObjectsNotification";
NSString * const ProcessorDidAcknowledgeDeleteNotification      = @"ProcessorDidAcknowledgeDeleteNotification";
NSString * const ProcessorRequestsReindexingNotification        = @"ProcessorRequestsReindexingNotification";


#pragma mark ====================================================================================
#pragma mark Changeset Keys
#pragma mark ====================================================================================

NSString * const CH_KEY				= @"id";
NSString * const CH_ADD				= @"+";
NSString * const CH_REMOVE			= @"-";
NSString * const CH_MODIFY			= @"M";
NSString * const CH_OPERATION		= @"o";
NSString * const CH_VALUE			= @"v";
NSString * const CH_START_VERSION   = @"sv";
NSString * const CH_END_VERSION     = @"ev";
NSString * const CH_CHANGE_VERSION	= @"cv";
NSString * const CH_LOCAL_ID		= @"ccid";
NSString * const CH_CLIENT_ID		= @"clientid";
NSString * const CH_ERROR           = @"error";
NSString * const CH_DATA            = @"d";
NSString * const CH_EMPTY			= @"EMPTY";
