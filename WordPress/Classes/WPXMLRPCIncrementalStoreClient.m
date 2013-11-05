/*
 * WPXMLRPCIncrementalStoreClient.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "WPXMLRPCIncrementalStoreClient.h"
#import "BaseXMLRPCManagedObject.h"

@implementation WPXMLRPCIncrementalStoreClient

static WPXMLRPCIncrementalStoreClient *instance;

+ (instancetype)sharedClient {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WPXMLRPCIncrementalStoreClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://google.com"]];
    });
    return instance;
}

#pragma mark - Remote Representations

- (NSDictionary *)representationOfAttributes:(NSDictionary *)attributes ofManagedObject:(NSManagedObject *)managedObject {
    Class modelClass = NSClassFromString(managedObject.entity.name);
    if ([modelClass respondsToSelector:@selector(representationOfAttributes:ofManagedObject:)]) {
        return [modelClass representationOfAttributes:attributes ofManagedObject:managedObject];
    }
    return nil;
}

- (id)representationOrArrayOfRepresentationsOfEntity:(NSEntityDescription *)entity fromResponseObject:(id)responseObject requestOperation:(AFHTTPRequestOperation *)requestOperation {
    Class modelClass = NSClassFromString(entity.name);
    if ([modelClass respondsToSelector:@selector(representationOrArrayOfRepresentationsOfEntity:fromResponseObject:requestOperation:)]) {
        return [modelClass representationOrArrayOfRepresentationsOfEntity:entity fromResponseObject:responseObject requestOperation:requestOperation];
    }
    return nil;
}

- (NSDictionary *)representationsForRelationshipsFromRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity fromResponse:(NSHTTPURLResponse *)response {
    Class modelClass = NSClassFromString(entity.name);
    if ([modelClass respondsToSelector:@selector(representationsForRelationshipsFromRepresentation:ofEntity:fromResponse:)]) {
        return [modelClass representationsForRelationshipsFromRepresentation:representation ofEntity:entity fromResponse:response];
    }
    return nil;
}

- (NSDictionary *)attributesForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity fromResponse:(NSHTTPURLResponse *)response {
    Class modelClass = NSClassFromString(entity.name);
    if ([modelClass respondsToSelector:@selector(attributesForRepresentation:ofEntity:)]) {
        return [modelClass attributesForRepresentation:representation ofEntity:entity];
    }
    return nil;
}

- (NSString *)resourceIdentifierForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity fromResponse:(NSHTTPURLResponse *)response {
    Class modelClass = NSClassFromString(entity.name);
    if ([modelClass respondsToSelector:@selector(resourceIdentifierForRepresentation:ofEntity:fromResponse:)]) {
        return [modelClass resourceIdentifierForRepresentation:representation ofEntity:entity fromResponse:response];
    }
    return nil;
}

#pragma mark - Operations

- (NSMutableURLRequest *)requestForFetchRequest:(NSFetchRequest *)fetchRequest withContext:(NSManagedObjectContext *)context {
    Class modelClass = NSClassFromString(fetchRequest.entityName);
    if ([modelClass respondsToSelector:@selector(requestForFetchRequest:withContext:)]) {
        return [modelClass requestForFetchRequest:fetchRequest withContext:context];
    }
    return nil;
}

- (NSMutableURLRequest *)requestForInsertedObject:(NSManagedObject *)insertedObject {
    Class modelClass = NSClassFromString(insertedObject.entity.name);
    if ([modelClass respondsToSelector:@selector(requestForInsertedObject:)]) {
        return [modelClass requestForInsertedObject:insertedObject];
    }
    return nil;
}

- (NSMutableURLRequest *)requestForUpdatedObject:(NSManagedObject *)updatedObject {
    Class modelClass = NSClassFromString(updatedObject.entity.name);
    if ([modelClass respondsToSelector:@selector(requestForUpdatedObject:)]) {
        return [modelClass requestForUpdatedObject:updatedObject];
    }
    return nil;
}

- (NSMutableURLRequest *)requestForDeletedObject:(NSManagedObject *)deletedObject {
    Class modelClass = NSClassFromString(deletedObject.entity.name);
    if ([modelClass respondsToSelector:@selector(requestForDeletedObject:)]) {
        return [modelClass requestForDeletedObject:deletedObject];
    }
    return nil;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method pathForRelationship:(NSRelationshipDescription *)relationship forObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context {
    Class modelClass = NSClassFromString(objectID.entity.name);
    if ([modelClass respondsToSelector:@selector(requestWithMethod:pathForRelationship:forObjectWithID:withContext:)]) {
        return [modelClass requestWithMethod:method pathForRelationship:relationship forObjectWithID:objectID withContext:context];
    }
    return nil;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method pathForObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context {
    return nil;
}


#pragma mark - Fetch on faulted relationship

- (BOOL)shouldFetchRemoteValuesForRelationship:(NSRelationshipDescription *)relationship
                               forObjectWithID:(NSManagedObjectID *)objectID
                        inManagedObjectContext:(NSManagedObjectContext *)context {
    Class modelClass = NSClassFromString(relationship.entity.name);
    if ([modelClass respondsToSelector:@selector(shouldFetchRemoteValuesForRelationship:forObjectWithID:inManagedObjectContext:)]) {
        return [modelClass shouldFetchRemoteValuesForRelationship:relationship forObjectWithID:objectID inManagedObjectContext:context];
    }
    return NO;
}

- (BOOL)shouldFetchRemoteAttributeValuesForObjectWithID:(NSManagedObjectID *)objectID
                                 inManagedObjectContext:(NSManagedObjectContext *)context {
    Class modelClass = NSClassFromString(objectID.entity.name);
    if ([modelClass respondsToSelector:@selector(shouldFetchRemoteAttributeValuesForObjectWithID:inManagedObjectContext:)]) {
        return [modelClass shouldFetchRemoteAttributeValuesForObjectWithID:(NSManagedObjectID *)objectID
                                                    inManagedObjectContext:(NSManagedObjectContext *)context];
    }
    return NO;
}

@end
