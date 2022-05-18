#import "ContextManager.h"
#import <XCTest/XCTest.h>


NS_ASSUME_NONNULL_BEGIN

/**
 *  @class      ContextManagerMock
 *  @brief      This class overrides standard ContextManager functionality, for testing purposes.
 *  @details    The SQLite-Backed PSC is replaced by an InMemory store. This allows us to easily reset
 *              the contents of the database, without even hitting the filesystem.
 */
@interface ContextManagerMock : ContextManager

@end

NS_ASSUME_NONNULL_END
