/*
 * BaseXMLRPCManagedObject.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "BaseXMLRPCManagedObject.h"
#import "Blog.h"
#import <wpxmlrpc/WPXMLRPCDecoder.h>
#import <wpxmlrpc/WPXMLRPCEncoder.h>

@implementation BaseXMLRPCManagedObject

@dynamic blog;

+ (NSMutableURLRequest *)requestForInsertedObject:(NSManagedObject *)object {
    NSString *methodName = [self methodNameForCRUDOperation:XMLRPCInsertOperation];
    NSArray *params = [self additionalParamsForCRUDOperation:XMLRPCInsertOperation];
    return [self requestForCRUDWithObject:object forMethod:methodName andParams:params];
}

+ (NSMutableURLRequest *)requestForDeletedObject:(NSManagedObject *)object {
    NSString *methodName = [self methodNameForCRUDOperation:XMLRPCDeleteOperation];
    NSArray *params = [self additionalParamsForCRUDOperation:XMLRPCDeleteOperation];
    return [self requestForCRUDWithObject:object forMethod:methodName andParams:params];
}

+ (NSMutableURLRequest *)requestForUpdatedObject:(NSManagedObject *)object {
    NSString *methodName = [self methodNameForCRUDOperation:XMLRPCUpdateOperation];
    NSArray *params = [self additionalParamsForCRUDOperation:XMLRPCUpdateOperation];
    return [self requestForCRUDWithObject:object forMethod:methodName andParams:params];
}

+ (NSMutableURLRequest *)requestForCRUDWithObject:(NSManagedObject *)object forMethod:(NSString *)methodName andParams:(NSArray *)params {
    Blog *blog;
    if ([object isKindOfClass:[Blog class]]) {
        blog = (Blog *)object;
    } else {
        blog = ((BaseXMLRPCManagedObject *)object).blog;
    }
    
    params = [params arrayByAddingObjectsFromArray:@[blog.blogID, blog.username, blog.password]];
    
    WPXMLRPCEncoder *encoder = [[WPXMLRPCEncoder alloc] initWithMethod:methodName andParameters:params];
    
    NSMutableURLRequest *request;
    if ([object respondsToSelector:@selector(blog)]) {
        request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:blog.xmlrpc]];
        request.HTTPBody = encoder.body;
        request.HTTPMethod = @"POST";
        [request addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    }
    
    return request;
}

+ (id)representationOrArrayOfRepresentationsOfEntity:(NSEntityDescription *)entity fromResponseObject:(id)responseObject requestOperation:(AFHTTPRequestOperation *)requestOperation {
    WPXMLRPCDecoder *decoder = [[WPXMLRPCDecoder alloc] initWithData:responseObject];
    return decoder.object;
}

#pragma mark - Optional Overrides

+ (BOOL)shouldFetchRemoteValuesForRelationship:(NSRelationshipDescription *)relationship
                               forObjectWithID:(NSManagedObjectID *)objectID
                        inManagedObjectContext:(NSManagedObjectContext *)context {
    return NO;
}

+ (BOOL)shouldFetchRemoteAttributeValuesForObjectWithID:(NSManagedObjectID *)objectID
                                 inManagedObjectContext:(NSManagedObjectContext *)context {
    return NO;
}

+ (NSArray *)additionalParamsForCRUDOperation:(XMLRPCCRUDOperation)op {
    return nil;
}

#pragma mark - Required Overrides

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreturn-type"

+ (NSString *)methodNameForCRUDOperation:(XMLRPCCRUDOperation)op {
    AssertSubclassMethod();
}

+ (NSDictionary *)representationOfAttributes:(NSDictionary *)attributes ofManagedObject:(NSManagedObject *)managedObject {
    AssertSubclassMethod();
}

+ (NSDictionary *)attributesForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity {
    AssertSubclassMethod();
}

+ (NSMutableURLRequest *)requestForFetchRequest:(NSFetchRequest *)fetchRequest withContext:(NSManagedObjectContext *)context {
    AssertSubclassMethod();
}

+ (NSString *)resourceIdentifierForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity fromResponse:(NSHTTPURLResponse *)response {
    AssertSubclassMethod();
}

+ (NSDictionary *)representationsForRelationshipsFromRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity fromResponse:(NSHTTPURLResponse *)response {
    AssertSubclassMethod();
}

+ (NSMutableURLRequest *)requestWithMethod:(NSString *)method pathForRelationship:(NSRelationshipDescription *)relationship forObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context {
    AssertSubclassMethod();
}

#pragma clang diagnostic pop

@end
