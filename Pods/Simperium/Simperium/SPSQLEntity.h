//
//  MyClass.h
//  Simperium
//
//  Created by Michael Johnston on 11-04-18.
//  Copyright 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SPSQLEntity : NSObject  {
    
    // Opaque reference to the underlying database.
    sqlite3 *database;
    NSString *primaryKey;
    
    // Internal state variables. Hydrated tracks whether attribute data is in the object or the database.
    BOOL hydrated;
    BOOL dirty;
}

//-(id)initWithPrimaryKey:(NSString *)pk database:(sqlite3 *)db;
//+(NSString *)insertIntoDatabase:(sqlite3 *)database;
//+(void)finalizeStatements;
//-(void)hydrate;
//-(void)dehydrate;
//-(void)deleteFromDatabase;

@end
