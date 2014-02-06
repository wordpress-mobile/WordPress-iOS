DTFoundation Core
=================

This part of DTFoundation contains enhancements for Apple frameworks and classes which are usable on Mac and iOS.

## Functions

### DTBlockFunctions

Block Utility Methods for performing blocks synchronously on main thread.

### DTCoreGraphicsUtils

Various CoreGraphics-related utility functions

### DTLog

Replacement for `NSLog` which can be configured to output certain log levels at run time.

### DTWeakSupport

Useful defines for building code the compiles with zeroing weak references if the deployment target allows it

## Utility Classes

### DTAsyncFileDeleter

This class deletes large amounts of files asynchronously.

### DTBase64Coding

Utility class for encoding and decoding data in base64 format.

### DTExtendedFileAttributes

This class provides read/write access to extended file attributes of a file or folder.

### DTFolderMonitor

Class for monitoring changes on a folder.

### DTVersion

Class that represents a version number comprised of major, minor and maintenance number separated by dots.

## Foundation Enhancements

### NSArray (DTError)

A collection of useful additions for `NSArray` to deal with Property Lists and also to get error handling for malformed data.

### NSData (DTCrypto)

Useful cryptography methods.

### NSDictionary (DTError)

A collection of useful additions for `NSDictionary` to deal with Property Lists and also to get error handling for malformed data.

### NSFileWrapper (DTCopying)

Methods for copying file wrappers.

### NSMutableArray (DTMoving)

Methods that add convenient moving methods to `NSMutableArray`

### NSString (DTFormatNumbers)

A collection of category extensions for `NSString` dealing with the formatting of numbers in special contexts. 

### NSString (DTPaths)

A collection of useful additions for `NSString` to deal with paths.

### NSString (DTURLEncoding)

A collection of useful additions for `NSString` to deal with URL encoding.

### NSString (DTUtilities)

A collection of utility additions for `NSString`.

### NSURL (DTComparing)

Category for comparing URLs.

### NSURL (DTUnshorten)

Method for getting the full length URL for a shortened one.
