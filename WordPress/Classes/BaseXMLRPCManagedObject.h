/*
 * BaseXMLRPCManagedObject.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

@class Blog;

typedef NS_ENUM(NSUInteger, XMLRPCCRUDOperation) {
    XMLRPCInsertOperation,
    XMLRPCDeleteOperation,
    XMLRPCUpdateOperation,
    XMLRPCFetchOperation
};

@interface BaseXMLRPCManagedObject : NSManagedObject

/// Populated for objects such as Post/Page
/// Required for XMLPRC URL
@property (nonatomic, retain) Blog *blog;

+ (NSMutableURLRequest *)requestForInsertedObject:(NSManagedObject *)object;
+ (NSMutableURLRequest *)requestForUpdatedObject:(NSManagedObject *)object;
+ (NSMutableURLRequest *)requestForDeletedObject:(NSManagedObject *)object;

///-------------------------------
///@name Required subclass methods
///-------------------------------

/*
 Define the method name for the XML RPC call for the given operation
 
 @param the CRUD operation type
 @return an XML RPC method name
 */
+ (NSString *)methodNameForCRUDOperation:(XMLRPCCRUDOperation)op;

/* 
 Return the unique identifier for a remote representation. 
 Used to determine distinct objects in AFIncrementalStore.
 
 @param remote representation
 @param entity description to apply to the representation
 @param the server response
 
 @return a string representation of the remote unique identifier
 */
+ (NSString *)resourceIdentifierForRepresentation:(NSDictionary *)representation
                                         ofEntity:(NSEntityDescription *)entity
                                     fromResponse:(NSHTTPURLResponse *)response;

/*
 Construct the remote representation of the local managed object
 
 @param attributes to compose
 @param the managed object to obtain the values
 @return a dictionary of the remote representation for the given managed object
 */
+ (NSDictionary *)representationOfAttributes:(NSDictionary *)attributes
                             ofManagedObject:(NSManagedObject *)managedObject;

/*
 Construct the local managed object's attributes of the remote representation
 
 @param remote representation
 @param entity
 @return a dictionary of the local keys and remote values
 */
+ (NSDictionary *)attributesForRepresentation:(NSDictionary *)representation
                                     ofEntity:(NSEntityDescription *)entity;

/*
 Construct a suitable URL request for a fetch request
 
 @param the fetch request
 @param a NSManagedObjectContext
 
 @return nil or a request suitable for the fetch request
 */
+ (NSMutableURLRequest *)requestForFetchRequest:(NSFetchRequest *)fetchRequest
                                    withContext:(NSManagedObjectContext *)context;

/*
 Construct a suitable URL request for an HTTP method and relationship
 
 @param the HTTP method
 @param relationship requested
 @param object ID for the object holding the relationship
 @param NSManagedObjectContext
 
 @return URL request representing the request required to obtain
         remote representations for the relationship
 */
+ (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                       pathForRelationship:(NSRelationshipDescription *)relationship
                           forObjectWithID:(NSManagedObjectID *)objectID
                               withContext:(NSManagedObjectContext *)context;

/*
 Return a dictionary containing the remote representations for each named relationship,
 keyed by the local relationship name
 
 @discussion If a post has a relationship called 'categories', then if the post:
 
 {
   postid: 1,
   title: "test post"
   remoteCategories: ["Uncategorized", "Some Category"],
   remoteComments: [<comment>, <comment>]
 }
 
 then:
 
 return @{'categories': ["Uncategorized", "Some Category"],
          'comments': [<comment>, <comment>]}
 
 @param a remote representation of an entity
 @param the entity
 @param HTTP URL response for the request
 
 @return a dictionary that contains
 */
+ (NSDictionary *)representationsForRelationshipsFromRepresentation:(NSDictionary *)representation
                                                           ofEntity:(NSEntityDescription *)entity
                                                       fromResponse:(NSHTTPURLResponse *)response;


///------------------------
///@name Optional Overrides
///------------------------

/*
 Return the params for the XML RPC request
 
 @param the CRUD operation type
 
 @return an array of params for the XML RPC call,
 additional to the blogID, username, and password.
 */
+ (NSArray *)additionalParamsForCRUDOperation:(XMLRPCCRUDOperation)op;

/*
 Optional override
 
 Default implementation returns the decoded responseObject
 
 @return the parsed XML
 */
+ (id)representationOrArrayOfRepresentationsOfEntity:(NSEntityDescription *)entity fromResponseObject:(id)responseObject
                                    requestOperation:(AFHTTPRequestOperation *)requestOperation;

/*
 Should fetch relationship objects on fault
 
 Default is NO
 
 @return BOOL
 */
+ (BOOL)shouldFetchRemoteValuesForRelationship:(NSRelationshipDescription *)relationship
                               forObjectWithID:(NSManagedObjectID *)objectID
                        inManagedObjectContext:(NSManagedObjectContext *)context;

/*
 Should fetch attributes on fault for individual object
 
 Default is NO
 
 @return BOOL
 */
+ (BOOL)shouldFetchRemoteAttributeValuesForObjectWithID:(NSManagedObjectID *)objectID
                                 inManagedObjectContext:(NSManagedObjectContext *)context;

@end
