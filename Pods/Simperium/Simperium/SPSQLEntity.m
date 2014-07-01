//
//  MyClass.m
//  Simperium
//
//  Created by Michael Johnston on 11-04-18.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "SPSQLEntity.h"


@implementation SPSQLEntity

//static sqlite3_stmt *insert_statement = nil;
//static sqlite3_stmt *init_statement = nil;
//static sqlite3_stmt *delete_statement = nil;
//static sqlite3_stmt *hydrate_statement = nil;
//static sqlite3_stmt *dehydrate_statement = nil;
//
//// Creates a new empty record in the database. The primary key is returned, presumably to be used to alloc/init 
//// a new object. This method is a class method - it can be called without involving an instance of the class.
//+ (NSString *)insertIntoDatabase:(sqlite3 *)database {
//    // SQL statements are lazily loaded and kept around for optimization
//    if (insert_statement == nil) {
//		if ([members count] == 0) {
//			NSAssert1(0, @"Error: Simperium members not yet configured for %@ (need at least one)", entityName);
//		}
//		
//		NSMutableString *sqlStr = [NSMutableString stringWithFormat:@"INSERT INTO %@ (", entityName];
//		[sqlStr appendString: @"ghost, "];
//		// First construct the column names for each member
//		for (SPMember *member in members) {
//			[sqlStr appendString: [member keyName]];
//			if ([members lastObject] != member)
//				[sqlStr appendString: @", "];
//		}
//		[sqlStr appendString: @") VALUES("];
//		[sqlStr appendString: @"'', "];
//        
//		// Now add default values for each member
//		for (SPMember *member in members) {
//			[sqlStr appendString: [member defaultValueAsStringForSQL]];
//			if ([members lastObject] != member)
//				[sqlStr appendString: @", "];
//		}
//		[sqlStr appendString: @")"];
//        
//		// Finally, execute the statement to create the record
//        if (sqlite3_prepare_v2(database, [sqlStr UTF8String], -1, &insert_statement, NULL) != SQLITE_OK) {
//            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
//        }
//    }
//    int success = sqlite3_step(insert_statement);
//    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
//    sqlite3_reset(insert_statement);
//    if (success != SQLITE_ERROR) {
//        // SQLite provides a method which retrieves the value of the most recently auto-generated primary key sequence
//        // in the database. To access this functionality, the table should have a column declared of type 
//        // "INTEGER PRIMARY KEY"
//        //return sqlite3_last_insert_rowid(database);
//		return [[Simperium sharedManager] getUUID];
//    }
//    NSAssert1(0, @"Error: failed to insert into the database with message '%s'.", sqlite3_errmsg(database));
//    return @"";
//}
//
//// Finalize (delete) all of the SQLite compiled queries
//+ (void)finalizeStatements {
//    if (insert_statement) sqlite3_finalize(insert_statement);
//    if (init_statement) sqlite3_finalize(init_statement);
//    if (delete_statement) sqlite3_finalize(delete_statement);
//    if (hydrate_statement) sqlite3_finalize(hydrate_statement);
//    if (dehydrate_statement) sqlite3_finalize(dehydrate_statement);
//}
//
//// Initializes an instance and assigns defaults to it
//-(id)initWithPrimaryKey:(NSString *)pk database:(sqlite3 *)db {
//	primaryKey = [pk copy];
//	database = db;
//	// Compile the query for retrieving entity data if necessary
//	if (init_statement == nil) {			
//		// Dynamically construct the statement according to members in this entity
//		NSMutableString *sqlStr = [NSMutableString stringWithString:@"SELECT "];
//		[sqlStr appendString:@"ghost, "];
//		for (SPMember *member in members) {
//			[sqlStr appendString:[member keyName]];
//			if ([members lastObject] != member)
//				[sqlStr appendFormat:@", "];
//		}
//        
//		[sqlStr appendFormat:@" FROM %@ WHERE pk=?", entityName];
//		
//		if (sqlite3_prepare_v2(database, [sqlStr UTF8String], -1, &init_statement, NULL) != SQLITE_OK) {
//			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
//		}
//	}
//	// For this query, we bind the primary key to the first (and only) placeholder in the statement.
//	// Note that the parameters are numbered from 1, not from 0.
//	sqlite3_bind_text(init_statement, 1, [primaryKey UTF8String], -1, SQLITE_TRANSIENT);
//	if (sqlite3_step(init_statement) == SQLITE_ROW) {
//		// Found a row. Iterate through all members and initialize them according to some default rules.
//		char *str = (char *)sqlite3_column_text(init_statement, 0);
//		NSString *ghostStr = str == NULL ? @"" : [NSString stringWithUTF8String:str];	
//		self.ghost = ghostStr.length == 0 ? nil : [[SPGhost alloc] initFromDictionary:[ghostStr JSONValue]];
//		for (int memberIndex=0; memberIndex<[members count]; memberIndex++) {
//			SPMember *member = [members objectAtIndex:memberIndex];
//			id localData = [member sqlLoadWithStatement:init_statement queryPosition:memberIndex+1]; // +1 for ghost
//			[self setValue: localData forKey:[member keyName]];
//		}			
//	} else {
//		// Didn't find a row. Create a new instance and set default values for each of the members
//		// When does this happen?
//		self.ghost = nil;
//		for (int memberIndex=0; memberIndex<[members count]; memberIndex++) {
//			SPMember *member = [members objectAtIndex:memberIndex];
//			[self setValue:[member defaultValue] forKey:[member keyName]];
//		}
//	}
//	// Reset the statement for future reuse
//	sqlite3_reset(init_statement);
//	dirty = NO;
//    
//	return self;
//}
//
//- (void)deleteFromDatabase {
//    // Compile the delete statement if needed
//    if (delete_statement == nil) {
//		// Use the entity name to decide from which table to delete
//		NSString *sqlStr = [NSString stringWithFormat:@"DELETE FROM %@ WHERE pk=?", entityName];
//        if (sqlite3_prepare_v2(database, [sqlStr UTF8String], -1, &delete_statement, NULL) != SQLITE_OK) {
//            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
//        }
//    }
//    // Bind the primary key variable and execute the query
//    sqlite3_bind_text(delete_statement, 1, [primaryKey UTF8String], -1, SQLITE_TRANSIENT);
//    int success = sqlite3_step(delete_statement);
//    
//    // Reset the statement for future use
//    sqlite3_reset(delete_statement);
//    
//    if (success != SQLITE_DONE) {
//        NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
//    }
//}
//
//// Stores everything to the database
//// Currently doesn't do any flushing of data; see notes for hydration below
//- (void)dehydrate {
//    //if (dirty) {
//    // Write any changes to the database
//    // First, if needed, compile the dehydrate query
//    if (dehydrate_statement == nil) {
//        // Dynamically build the SQL UPDATE statement based on entity members
//        NSMutableString *sqlStr = [NSMutableString stringWithFormat:@"UPDATE %@ SET ", entityName];
//        [sqlStr appendString:@"ghost=?, "];
//        for (SPMember *member in members) {
//            [sqlStr appendFormat:@"%@=?",[member keyName]];
//            if ([members lastObject] != member)
//                [sqlStr appendFormat:@", "];
//        }
//        [sqlStr appendString:@" WHERE pk=?"];
//        
//        if (sqlite3_prepare_v2(database, [sqlStr UTF8String], -1, &dehydrate_statement, NULL) != SQLITE_OK) {
//            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
//        }
//    }
//    
//    // Bind the query variables for each member
//    NSString *ghostStr = [[ghost dictionary] JSONRepresentation];
//    sqlite3_bind_text(dehydrate_statement, 1, [ghostStr UTF8String], -1, SQLITE_TRANSIENT);	
//    for (int memberIndex=0; memberIndex<[members count]; memberIndex++) {
//        SPMember *member = [members objectAtIndex:memberIndex];
//        id localData = [self valueForKey:[member keyName]];
//        [member sqlBind: localData withStatement:dehydrate_statement queryPosition:memberIndex+2]; // +2 for ghost
//    }		
//    
//    // Lastly, bind the key and execute the query
//    sqlite3_bind_text(dehydrate_statement, [members count]+2, [primaryKey UTF8String], -1, SQLITE_TRANSIENT); // +2 for ghost
//    int success = sqlite3_step(dehydrate_statement);
//    
//    // Reset the query for the next use
//    sqlite3_reset(dehydrate_statement);
//    
//    if (success != SQLITE_DONE) {
//        NSAssert1(0, @"Error: failed to dehydrate with message '%s'.", sqlite3_errmsg(database));
//    }
//    // Update the entity state with respect to unwritten changes
//    //dirty = NO;
//    //}
//    // Update the entity state with respect to hydration
//    hydrated = NO;
//}
//
//// Hydration can be used to conserve memory if the object doesn't need all its contents loaded at all times.
//// Not sure if we'll need this yet.
//- (void)hydrate {
//	// Brings the rest of the object data into memory. If already in memory, no action is taken (harmless no-op).
//	
//	//    // Check if action is necessary.
//	//    if (hydrated) return;
//	//    // Compile the hydration statement, if needed.
//	//    if (hydrate_statement == nil) {
//	//        const char *sql = "SELECT creationDate FROM note WHERE pk=?";
//	//        if (sqlite3_prepare_v2(database, sql, -1, &hydrate_statement, NULL) != SQLITE_OK) {
//	//            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
//	//        }
//	//    }
//	//    // Bind the primary key variable.
//	//    sqlite3_bind_int(hydrate_statement, 1, primaryKey);
//	//    // Execute the query.
//	//    int success =sqlite3_step(hydrate_statement);
//	//    if (success == SQLITE_ROW) {
//	//        //char *str = (char *)sqlite3_column_text(hydrate_statement, 0);
//	//        //self.content = (str) ? [NSString stringWithUTF8String:str] : @"";
//	//        //self.creationDate = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(hydrate_statement, 0)];
//	//    } else {
//	//        // The query did not return 
//	//        //self.content = @"";
//	//		//self.creationDate = [NSDate date];
//	//    }
//	//    // Reset the query for the next use.
//	//    sqlite3_reset(hydrate_statement);
//	//    // Update object state with respect to hydration.
//    hydrated = YES;
//}

@end
