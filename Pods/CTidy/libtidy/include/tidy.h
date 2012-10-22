#ifndef __TIDY_H__
#define __TIDY_H__

/** @file tidy.h - Defines HTML Tidy API implemented by tidy library.

  Public interface is const-correct and doesn't explicitly depend
  on any globals.  Thus, thread-safety may be introduced w/out
  changing the interface.

  Looking ahead to a C++ wrapper, C functions always pass 
  this-equivalent as 1st arg.


  Copyright (c) 1998-2008 World Wide Web Consortium
  (Massachusetts Institute of Technology, European Research 
  Consortium for Informatics and Mathematics, Keio University).
  All Rights Reserved.

  CVS Info :

    $Author: arnaud02 $ 
    $Date: 2008/04/22 11:00:42 $ 
    $Revision: 1.22 $ 

  Contributing Author(s):

     Dave Raggett <dsr@w3.org>

  The contributing author(s) would like to thank all those who
  helped with testing, bug fixes and suggestions for improvements. 
  This wouldn't have been possible without your help.

  COPYRIGHT NOTICE:
 
  This software and documentation is provided "as is," and
  the copyright holders and contributing author(s) make no
  representations or warranties, express or implied, including
  but not limited to, warranties of merchantability or fitness
  for any particular purpose or that the use of the software or
  documentation will not infringe any third party patents,
  copyrights, trademarks or other rights. 

  The copyright holders and contributing author(s) will not be held
  liable for any direct, indirect, special or consequential damages
  arising out of any use of the software or documentation, even if
  advised of the possibility of such damage.

  Permission is hereby granted to use, copy, modify, and distribute
  this source code, or portions hereof, documentation and executables,
  for any purpose, without fee, subject to the following restrictions:

  1. The origin of this source code must not be misrepresented.
  2. Altered versions must be plainly marked as such and must
     not be misrepresented as being the original source.
  3. This Copyright notice may not be removed or altered from any
     source or altered source distribution.
 
  The copyright holders and contributing author(s) specifically
  permit, without fee, and encourage the use of this source code
  as a component for supporting the Hypertext Markup Language in
  commercial products. If you use this source code in a product,
  acknowledgment is not required but would be appreciated.


  Created 2001-05-20 by Charles Reitzel
  Updated 2002-07-01 by Charles Reitzel - 1st Implementation

*/

#include "platform.h"
#include "tidyenum.h"

#ifdef __cplusplus
extern "C" {
#endif

/** @defgroup Opaque Opaque Types
**
** Cast to implementation types within lib.
** Reduces inter-dependencies/conflicts w/ application code.
** @{
*/

/** @struct TidyDoc
**  Opaque document datatype
*/
opaque_type( TidyDoc );

/** @struct TidyOption
**  Opaque option datatype
*/
opaque_type( TidyOption );

/** @struct TidyNode
**  Opaque node datatype
*/
opaque_type( TidyNode );

/** @struct TidyAttr
**  Opaque attribute datatype
*/
opaque_type( TidyAttr );

/** @} end Opaque group */

TIDY_STRUCT struct _TidyBuffer;
typedef struct _TidyBuffer TidyBuffer;


/** @defgroup Memory  Memory Allocation
**
** Tidy uses a user provided allocator for all
** memory allocations.  If this allocator is
** not provided, then a default allocator is
** used which simply wraps standard C malloc/free
** calls.  These wrappers call the panic function
** upon any failure.  The default panic function
** prints an out of memory message to stderr, and
** calls exit(2).
**
** For applications in which it is unacceptable to
** abort in the case of memory allocation, then the
** panic function can be replaced with one which
** longjmps() out of the tidy code.  For this to
** clean up completely, you should be careful not
** to use any tidy methods that open files as these
** will not be closed before panic() is called.
**
** TODO: associate file handles with tidyDoc and
** ensure that tidyDocRelease() can close them all.
**
** Calling the withAllocator() family (
** tidyCreateWithAllocator, tidyBufInitWithAllocator,
** tidyBufAllocWithAllocator) allow settings custom
** allocators).
**
** All parts of the document use the same allocator.
** Calls that require a user provided buffer can
** optionally use a different allocator.
**
** For reference in designing a plug-in allocator,
** most allocations made by tidy are less than 100
** bytes, corresponding to attribute names/values, etc.
**
** There is also an additional class of much larger
** allocations which are where most of the data from
** the lexer is stored.  (It is not currently possible
** to use a separate allocator for the lexer, this
** would be a useful extension).
**
** In general, approximately 1/3rd of the memory
** used by tidy is freed during the parse, so if
** memory usage is an issue then an allocator that 
** can reuse this memory is a good idea.
**
** @{
*/

/** Prototype for the allocator's function table */
struct _TidyAllocatorVtbl;
/** The allocators function table */
typedef struct _TidyAllocatorVtbl TidyAllocatorVtbl;

/** Prototype for the allocator */
struct _TidyAllocator;
/** The allocator **/
typedef struct _TidyAllocator TidyAllocator;

/** An allocator's function table.  All functions here must
    be provided.
 */
struct _TidyAllocatorVtbl {
    /** Called to allocate a block of nBytes of memory */
    void* (TIDY_CALL *alloc)( TidyAllocator *self, size_t nBytes );
    /** Called to resize (grow, in general) a block of memory.
        Must support being called with NULL.
    */
    void* (TIDY_CALL *realloc)( TidyAllocator *self, void *block, size_t nBytes );
    /** Called to free a previously allocated block of memory */
    void (TIDY_CALL *free)( TidyAllocator *self, void *block);
    /** Called when a panic condition is detected.  Must support
        block == NULL.  This function is not called if either alloc 
        or realloc fails; it is up to the allocator to do this.
        Currently this function can only be called if an error is
        detected in the tree integrity via the internal function
        CheckNodeIntegrity().  This is a situation that can
        only arise in the case of a programming error in tidylib.
        You can turn off node integrity checking by defining
        the constant NO_NODE_INTEGRITY_CHECK during the build.
    **/
    void (TIDY_CALL *panic)( TidyAllocator *self, ctmbstr msg );
};

/** An allocator.  To create your own allocator, do something like
    the following:
    
    typedef struct _MyAllocator {
       TidyAllocator base;
       ...other custom allocator state...
    } MyAllocator;
    
    void* MyAllocator_alloc(TidyAllocator *base, void *block, size_t nBytes)
    {
        MyAllocator *self = (MyAllocator*)base;
        ...
    }
    (etc)

    static const TidyAllocatorVtbl MyAllocatorVtbl = {
        MyAllocator_alloc,
        MyAllocator_realloc,
        MyAllocator_free,
        MyAllocator_panic
    };

    myAllocator allocator;
    TidyDoc doc;

    allocator.base.vtbl = &amp;MyAllocatorVtbl;
    ...initialise allocator specific state...
    doc = tidyCreateWithAllocator(&allocator);
    ...

    Although this looks slightly long winded, the advantage is that to create
    a custom allocator you simply need to set the vtbl pointer correctly.
    The vtbl itself can reside in static/global data, and hence does not
    need to be initialised each time an allocator is created, and furthermore
    the memory is shared amongst all created allocators.
*/
struct _TidyAllocator {
    const TidyAllocatorVtbl *vtbl;
};

/** Callback for "malloc" replacement */
typedef void* (TIDY_CALL *TidyMalloc)( size_t len );
/** Callback for "realloc" replacement */
typedef void* (TIDY_CALL *TidyRealloc)( void* buf, size_t len );
/** Callback for "free" replacement */
typedef void  (TIDY_CALL *TidyFree)( void* buf );
/** Callback for "out of memory" panic state */
typedef void  (TIDY_CALL *TidyPanic)( ctmbstr mssg );


/** Give Tidy a malloc() replacement */
TIDY_EXPORT Bool TIDY_CALL ig_tidySetMallocCall( TidyMalloc fmalloc );
/** Give Tidy a realloc() replacement */
TIDY_EXPORT Bool TIDY_CALL ig_tidySetReallocCall( TidyRealloc frealloc );
/** Give Tidy a free() replacement */
TIDY_EXPORT Bool TIDY_CALL ig_tidySetFreeCall( TidyFree ffree );
/** Give Tidy an "out of memory" handler */
TIDY_EXPORT Bool TIDY_CALL ig_tidySetPanicCall( TidyPanic fpanic );

/** @} end Memory group */

/** @defgroup Basic Basic Operations
**
** Tidy public interface
**
** Several functions return an integer document status:
**
** <pre>
** 0    -> SUCCESS
** >0   -> 1 == TIDY WARNING, 2 == TIDY ERROR
** <0   -> SEVERE ERROR
** </pre>
** 
The following is a short example program.

<pre>
#include &lt;tidy.h&gt;
#include &lt;buffio.h&gt;
#include &lt;stdio.h&gt;
#include &lt;errno.h&gt;


int main(int argc, char **argv )
{
  const char* input = "&lt;title&gt;Foo&lt;/title&gt;&lt;p&gt;Foo!";
  TidyBuffer output;
  TidyBuffer errbuf;
  int rc = -1;
  Bool ok;

  TidyDoc tdoc = tidyCreate();                     // Initialize "document"
  tidyBufInit( &amp;output );
  tidyBufInit( &amp;errbuf );
  printf( "Tidying:\t\%s\\n", input );

  ok = tidyOptSetBool( tdoc, TidyXhtmlOut, yes );  // Convert to XHTML
  if ( ok )
    rc = tidySetErrorBuffer( tdoc, &amp;errbuf );      // Capture diagnostics
  if ( rc &gt;= 0 )
    rc = tidyParseString( tdoc, input );           // Parse the input
  if ( rc &gt;= 0 )
    rc = tidyCleanAndRepair( tdoc );               // Tidy it up!
  if ( rc &gt;= 0 )
    rc = tidyRunDiagnostics( tdoc );               // Kvetch
  if ( rc &gt; 1 )                                    // If error, force output.
    rc = ( tidyOptSetBool(tdoc, TidyForceOutput, yes) ? rc : -1 );
  if ( rc &gt;= 0 )
    rc = tidySaveBuffer( tdoc, &amp;output );          // Pretty Print

  if ( rc &gt;= 0 )
  {
    if ( rc &gt; 0 )
      printf( "\\nDiagnostics:\\n\\n\%s", errbuf.bp );
    printf( "\\nAnd here is the result:\\n\\n\%s", output.bp );
  }
  else
    printf( "A severe error (\%d) occurred.\\n", rc );

  tidyBufFree( &amp;output );
  tidyBufFree( &amp;errbuf );
  tidyRelease( tdoc );
  return rc;
}
</pre>
** @{
*/

TIDY_EXPORT TidyDoc TIDY_CALL     ig_tidyCreate(void);
TIDY_EXPORT TidyDoc TIDY_CALL     ig_tidyCreateWithAllocator( TidyAllocator *allocator );
TIDY_EXPORT void TIDY_CALL        ig_tidyRelease( TidyDoc tdoc );

/** Let application store a chunk of data w/ each Tidy instance.
**  Useful for callbacks.
*/
TIDY_EXPORT void TIDY_CALL        ig_tidySetAppData( TidyDoc tdoc, void* appData );

/** Get application data set previously */
TIDY_EXPORT void* TIDY_CALL       ig_tidyGetAppData( TidyDoc tdoc );

/** Get release date (version) for current library */
TIDY_EXPORT ctmbstr TIDY_CALL     ig_tidyReleaseDate(void);

/* Diagnostics and Repair
*/

/** Get status of current document. */
TIDY_EXPORT int TIDY_CALL         ig_tidyStatus( TidyDoc tdoc );

/** Detected HTML version: 0, 2, 3 or 4 */
TIDY_EXPORT int TIDY_CALL         ig_tidyDetectedHtmlVersion( TidyDoc tdoc );

/** Input is XHTML? */
TIDY_EXPORT Bool TIDY_CALL        ig_tidyDetectedXhtml( TidyDoc tdoc );

/** Input is generic XML (not HTML or XHTML)? */
TIDY_EXPORT Bool TIDY_CALL        ig_tidyDetectedGenericXml( TidyDoc tdoc );

/** Number of Tidy errors encountered.  If > 0, output is suppressed
**  unless TidyForceOutput is set.
*/
TIDY_EXPORT uint TIDY_CALL        ig_tidyErrorCount( TidyDoc tdoc );

/** Number of Tidy warnings encountered. */
TIDY_EXPORT uint TIDY_CALL        ig_tidyWarningCount( TidyDoc tdoc );

/** Number of Tidy accessibility warnings encountered. */
TIDY_EXPORT uint TIDY_CALL        ig_tidyAccessWarningCount( TidyDoc tdoc );

/** Number of Tidy configuration errors encountered. */
TIDY_EXPORT uint TIDY_CALL        ig_tidyConfigErrorCount( TidyDoc tdoc );

/* Get/Set configuration options
*/
/** Load an ASCII Tidy configuration file */
TIDY_EXPORT int TIDY_CALL         ig_tidyLoadConfig( TidyDoc tdoc, ctmbstr configFile );

/** Load a Tidy configuration file with the specified character encoding */
TIDY_EXPORT int TIDY_CALL         ig_tidyLoadConfigEnc( TidyDoc tdoc, ctmbstr configFile,
                                                     ctmbstr charenc );

TIDY_EXPORT Bool TIDY_CALL        ig_tidyFileExists( TidyDoc tdoc, ctmbstr filename );


/** Set the input/output character encoding for parsing markup.
**  Values include: ascii, latin1, raw, utf8, iso2022, mac,
**  win1252, utf16le, utf16be, utf16, big5 and shiftjis.  Case in-sensitive.
*/
TIDY_EXPORT int TIDY_CALL         ig_tidySetCharEncoding( TidyDoc tdoc, ctmbstr encnam );

/** Set the input encoding for parsing markup.
** As for tidySetCharEncoding but only affects the input encoding
**/
TIDY_EXPORT int TIDY_CALL         ig_tidySetInCharEncoding( TidyDoc tdoc, ctmbstr encnam );

/** Set the output encoding.
**/
TIDY_EXPORT int TIDY_CALL         ig_tidySetOutCharEncoding( TidyDoc tdoc, ctmbstr encnam );

/** @} end Basic group */


/** @defgroup Configuration Configuration Options
**
** Functions for getting and setting Tidy configuration options.
** @{
*/

/** Applications using TidyLib may want to augment command-line and
**  configuration file options.  Setting this callback allows an application 
**  developer to examine command-line and configuration file options after
**  TidyLib has examined them and failed to recognize them.
**/

typedef Bool (TIDY_CALL *TidyOptCallback)( ctmbstr option, ctmbstr value );

TIDY_EXPORT Bool TIDY_CALL          ig_tidySetOptionCallback( TidyDoc tdoc, TidyOptCallback pOptCallback );

/** Get option ID by name */
TIDY_EXPORT TidyOptionId TIDY_CALL  ig_tidyOptGetIdForName( ctmbstr optnam );

/** Get iterator for list of option */
/** 
Example:
<pre>
TidyIterator itOpt = tidyGetOptionList( tdoc );
while ( itOpt )
{
  TidyOption opt = tidyGetNextOption( tdoc, &itOpt );
  .. get/set option values ..
}
</pre>
*/

TIDY_EXPORT TidyIterator TIDY_CALL  ig_tidyGetOptionList( TidyDoc tdoc );
/** Get next Option */
TIDY_EXPORT TidyOption TIDY_CALL    ig_tidyGetNextOption( TidyDoc tdoc, TidyIterator* pos );

/** Lookup option by ID */
TIDY_EXPORT TidyOption TIDY_CALL    ig_tidyGetOption( TidyDoc tdoc, TidyOptionId optId );
/** Lookup option by name */
TIDY_EXPORT TidyOption TIDY_CALL    ig_tidyGetOptionByName( TidyDoc tdoc, ctmbstr optnam );

/** Get ID of given Option */
TIDY_EXPORT TidyOptionId TIDY_CALL  ig_tidyOptGetId( TidyOption opt );

/** Get name of given Option */
TIDY_EXPORT ctmbstr TIDY_CALL       ig_tidyOptGetName( TidyOption opt );

/** Get datatype of given Option */
TIDY_EXPORT TidyOptionType TIDY_CALL ig_tidyOptGetType( TidyOption opt );

/** Is Option read-only? */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptIsReadOnly( TidyOption opt );

/** Get category of given Option */
TIDY_EXPORT TidyConfigCategory TIDY_CALL ig_tidyOptGetCategory( TidyOption opt );

/** Get default value of given Option as a string */
TIDY_EXPORT ctmbstr TIDY_CALL       ig_tidyOptGetDefault( TidyOption opt );

/** Get default value of given Option as an unsigned integer */
TIDY_EXPORT ulong TIDY_CALL         ig_tidyOptGetDefaultInt( TidyOption opt );

/** Get default value of given Option as a Boolean value */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptGetDefaultBool( TidyOption opt );

/** Iterate over Option "pick list" */
TIDY_EXPORT TidyIterator TIDY_CALL  ig_tidyOptGetPickList( TidyOption opt );
/** Get next string value of Option "pick list" */
TIDY_EXPORT ctmbstr TIDY_CALL       ig_tidyOptGetNextPick( TidyOption opt, TidyIterator* pos );

/** Get current Option value as a string */
TIDY_EXPORT ctmbstr TIDY_CALL       ig_tidyOptGetValue( TidyDoc tdoc, TidyOptionId optId );
/** Set Option value as a string */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptSetValue( TidyDoc tdoc, TidyOptionId optId, ctmbstr val );
/** Set named Option value as a string.  Good if not sure of type. */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptParseValue( TidyDoc tdoc, ctmbstr optnam, ctmbstr val );

/** Get current Option value as an integer */
TIDY_EXPORT ulong TIDY_CALL         ig_tidyOptGetInt( TidyDoc tdoc, TidyOptionId optId );
/** Set Option value as an integer */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptSetInt( TidyDoc tdoc, TidyOptionId optId, ulong val );

/** Get current Option value as a Boolean flag */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptGetBool( TidyDoc tdoc, TidyOptionId optId );
/** Set Option value as a Boolean flag */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptSetBool( TidyDoc tdoc, TidyOptionId optId, Bool val );

/** Reset option to default value by ID */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptResetToDefault( TidyDoc tdoc, TidyOptionId opt );
/** Reset all options to their default values */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptResetAllToDefault( TidyDoc tdoc );

/** Take a snapshot of current config settings */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptSnapshot( TidyDoc tdoc );
/** Reset config settings to snapshot (after document processing) */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptResetToSnapshot( TidyDoc tdoc );

/** Any settings different than default? */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptDiffThanDefault( TidyDoc tdoc );
/** Any settings different than snapshot? */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptDiffThanSnapshot( TidyDoc tdoc );

/** Copy current configuration settings from one document to another */
TIDY_EXPORT Bool TIDY_CALL          ig_tidyOptCopyConfig( TidyDoc tdocTo, TidyDoc tdocFrom );

/** Get character encoding name.  Used with TidyCharEncoding,
**  TidyOutCharEncoding, TidyInCharEncoding */
TIDY_EXPORT ctmbstr TIDY_CALL       ig_tidyOptGetEncName( TidyDoc tdoc, TidyOptionId optId );

/** Get current pick list value for option by ID.  Useful for enum types. */
TIDY_EXPORT ctmbstr TIDY_CALL       ig_tidyOptGetCurrPick( TidyDoc tdoc, TidyOptionId optId);

/** Iterate over user declared tags */
TIDY_EXPORT TidyIterator TIDY_CALL  ig_tidyOptGetDeclTagList( TidyDoc tdoc );
/** Get next declared tag of specified type: TidyInlineTags, TidyBlockTags,
**  TidyEmptyTags, TidyPreTags */
TIDY_EXPORT ctmbstr TIDY_CALL       ig_tidyOptGetNextDeclTag( TidyDoc tdoc, 
                                                          TidyOptionId optId,
                                                          TidyIterator* iter );
/** Get option description */
TIDY_EXPORT ctmbstr TIDY_CALL       ig_tidyOptGetDoc( TidyDoc tdoc, TidyOption opt );

/** Iterate over a list of related options */
TIDY_EXPORT TidyIterator TIDY_CALL  ig_tidyOptGetDocLinksList( TidyDoc tdoc,
                                                  TidyOption opt );
/** Get next related option */
TIDY_EXPORT TidyOption TIDY_CALL    ig_tidyOptGetNextDocLinks( TidyDoc tdoc,
                                                  TidyIterator* pos );

/** @} end Configuration group */

/** @defgroup IO  I/O and Messages
**
** By default, Tidy will define, create and use 
** instances of input and output handlers for 
** standard C buffered I/O (i.e. FILE* stdin,
** FILE* stdout and FILE* stderr for content
** input, content output and diagnostic output,
** respectively.  A FILE* cfgFile input handler
** will be used for config files.  Command line
** options will just be set directly.
**
** @{
*/

/*****************
   Input Source
*****************/
/** Input Callback: get next byte of input */
typedef int  (TIDY_CALL *TidyGetByteFunc)( void* sourceData );

/** Input Callback: unget a byte of input */
typedef void (TIDY_CALL *TidyUngetByteFunc)( void* sourceData, byte bt );

/** Input Callback: is end of input? */
typedef Bool (TIDY_CALL *TidyEOFFunc)( void* sourceData );

/** End of input "character" */
#define EndOfStream (~0u)

/** TidyInputSource - Delivers raw bytes of input
*/
TIDY_STRUCT
typedef struct _TidyInputSource
{
  /* Instance data */
  void*               sourceData;  /**< Input context.  Passed to callbacks */

  /* Methods */
  TidyGetByteFunc     getByte;     /**< Pointer to "get byte" callback */
  TidyUngetByteFunc   ungetByte;   /**< Pointer to "unget" callback */
  TidyEOFFunc         eof;         /**< Pointer to "eof" callback */
} TidyInputSource;

/** Facilitates user defined source by providing
**  an entry point to marshal pointers-to-functions.
**  Needed by .NET and possibly other language bindings.
*/
TIDY_EXPORT Bool TIDY_CALL ig_tidyInitSource( TidyInputSource*  source,
                                          void*             srcData,
                                          TidyGetByteFunc   gbFunc,
                                          TidyUngetByteFunc ugbFunc,
                                          TidyEOFFunc       endFunc );

/** Helper: get next byte from input source */
TIDY_EXPORT uint TIDY_CALL ig_tidyGetByte( TidyInputSource* source );

/** Helper: unget byte back to input source */
TIDY_EXPORT void TIDY_CALL ig_tidyUngetByte( TidyInputSource* source, uint byteValue );

/** Helper: check if input source at end */
TIDY_EXPORT Bool TIDY_CALL ig_tidyIsEOF( TidyInputSource* source );


/****************
   Output Sink
****************/
/** Output callback: send a byte to output */
typedef void (TIDY_CALL *TidyPutByteFunc)( void* sinkData, byte bt );


/** TidyOutputSink - accepts raw bytes of output
*/
TIDY_STRUCT
typedef struct _TidyOutputSink
{
  /* Instance data */
  void*               sinkData;  /**< Output context.  Passed to callbacks */

  /* Methods */
  TidyPutByteFunc     putByte;   /**< Pointer to "put byte" callback */
} TidyOutputSink;

/** Facilitates user defined sinks by providing
**  an entry point to marshal pointers-to-functions.
**  Needed by .NET and possibly other language bindings.
*/
TIDY_EXPORT Bool TIDY_CALL ig_tidyInitSink( TidyOutputSink* sink, 
                                        void*           snkData,
                                        TidyPutByteFunc pbFunc );

/** Helper: send a byte to output */
TIDY_EXPORT void TIDY_CALL ig_tidyPutByte( TidyOutputSink* sink, uint byteValue );


/** Callback to filter messages by diagnostic level:
**  info, warning, etc.  Just set diagnostic output 
**  handler to redirect all diagnostics output.  Return true
**  to proceed with output, false to cancel.
*/
typedef Bool (TIDY_CALL *TidyReportFilter)( TidyDoc tdoc, TidyReportLevel lvl,
                                           uint line, uint col, ctmbstr mssg );

/** Give Tidy a filter callback to use */
TIDY_EXPORT Bool TIDY_CALL    ig_tidySetReportFilter( TidyDoc tdoc,
                                                  TidyReportFilter filtCallback );

/** Set error sink to named file */
TIDY_EXPORT FILE* TIDY_CALL   ig_tidySetErrorFile( TidyDoc tdoc, ctmbstr errfilnam );
/** Set error sink to given buffer */
TIDY_EXPORT int TIDY_CALL     ig_tidySetErrorBuffer( TidyDoc tdoc, TidyBuffer* errbuf );
/** Set error sink to given generic sink */
TIDY_EXPORT int TIDY_CALL     ig_tidySetErrorSink( TidyDoc tdoc, TidyOutputSink* sink );

/** @} end IO group */

/* TODO: Catalog all messages for easy translation
TIDY_EXPORT ctmbstr     tidyLookupMessage( int errorNo );
*/



/** @defgroup Parse Document Parse
**
** Parse markup from a given input source.  String and filename 
** functions added for convenience.  HTML/XHTML version determined
** from input.
** @{
*/

/** Parse markup in named file */
TIDY_EXPORT int TIDY_CALL         ig_tidyParseFile( TidyDoc tdoc, ctmbstr filename );

/** Parse markup from the standard input */
TIDY_EXPORT int TIDY_CALL         ig_tidyParseStdin( TidyDoc tdoc );

/** Parse markup in given string */
TIDY_EXPORT int TIDY_CALL         ig_tidyParseString( TidyDoc tdoc, ctmbstr content );

/** Parse markup in given buffer */
TIDY_EXPORT int TIDY_CALL         ig_tidyParseBuffer( TidyDoc tdoc, TidyBuffer* buf );

/** Parse markup in given generic input source */
TIDY_EXPORT int TIDY_CALL         ig_tidyParseSource( TidyDoc tdoc, TidyInputSource* source);

/** @} End Parse group */


/** @defgroup Clean Diagnostics and Repair
**
** @{
*/
/** Execute configured cleanup and repair operations on parsed markup */
TIDY_EXPORT int TIDY_CALL         ig_tidyCleanAndRepair( TidyDoc tdoc );

/** Run configured diagnostics on parsed and repaired markup. 
**  Must call tidyCleanAndRepair() first.
*/
TIDY_EXPORT int TIDY_CALL         ig_tidyRunDiagnostics( TidyDoc tdoc );

/** @} end Clean group */


/** @defgroup Save Document Save Functions
**
** Save currently parsed document to the given output sink.  File name
** and string/buffer functions provided for convenience.
** @{
*/

/** Save to named file */
TIDY_EXPORT int TIDY_CALL         ig_tidySaveFile( TidyDoc tdoc, ctmbstr filename );

/** Save to standard output (FILE*) */
TIDY_EXPORT int TIDY_CALL         ig_tidySaveStdout( TidyDoc tdoc );

/** Save to given TidyBuffer object */
TIDY_EXPORT int TIDY_CALL         ig_tidySaveBuffer( TidyDoc tdoc, TidyBuffer* buf );

/** Save document to application buffer.  If buffer is not big enough,
**  ENOMEM will be returned and the necessary buffer size will be placed
**  in *buflen.
*/
TIDY_EXPORT int TIDY_CALL         ig_tidySaveString( TidyDoc tdoc,
                                                 tmbstr buffer, uint* buflen );

/** Save to given generic output sink */
TIDY_EXPORT int TIDY_CALL         ig_tidySaveSink( TidyDoc tdoc, TidyOutputSink* sink );

/** @} end Save group */


/** @addtogroup Basic
** @{
*/
/** Save current settings to named file.
    Only non-default values are written. */
TIDY_EXPORT int TIDY_CALL         ig_tidyOptSaveFile( TidyDoc tdoc, ctmbstr cfgfil );

/** Save current settings to given output sink.
    Only non-default values are written. */
TIDY_EXPORT int TIDY_CALL         ig_tidyOptSaveSink( TidyDoc tdoc, TidyOutputSink* sink );


/* Error reporting functions 
*/

/** Write more complete information about errors to current error sink. */
TIDY_EXPORT void TIDY_CALL        ig_tidyErrorSummary( TidyDoc tdoc );

/** Write more general information about markup to current error sink. */
TIDY_EXPORT void TIDY_CALL        ig_tidyGeneralInfo( TidyDoc tdoc );

/** @} end Basic group (again) */


/** @defgroup Tree Document Tree
**
** A parsed and, optionally, repaired document is
** represented by Tidy as a Tree, much like a W3C DOM.
** This tree may be traversed using these functions.
** The following snippet gives a basic idea how these
** functions can be used.
**
<pre>
void dumpNode( TidyNode tnod, int indent )
{
  TidyNode child;

  for ( child = tidyGetChild(tnod); child; child = tidyGetNext(child) )
  {
    ctmbstr name;
    switch ( tidyNodeGetType(child) )
    {
    case TidyNode_Root:       name = "Root";                    break;
    case TidyNode_DocType:    name = "DOCTYPE";                 break;
    case TidyNode_Comment:    name = "Comment";                 break;
    case TidyNode_ProcIns:    name = "Processing Instruction";  break;
    case TidyNode_Text:       name = "Text";                    break;
    case TidyNode_CDATA:      name = "CDATA";                   break;
    case TidyNode_Section:    name = "XML Section";             break;
    case TidyNode_Asp:        name = "ASP";                     break;
    case TidyNode_Jste:       name = "JSTE";                    break;
    case TidyNode_Php:        name = "PHP";                     break;
    case TidyNode_XmlDecl:    name = "XML Declaration";         break;

    case TidyNode_Start:
    case TidyNode_End:
    case TidyNode_StartEnd:
    default:
      name = tidyNodeGetName( child );
      break;
    }
    assert( name != NULL );
    printf( "\%*.*sNode: \%s\\n", indent, indent, " ", name );
    dumpNode( child, indent + 4 );
  }
}

void dumpDoc( TidyDoc tdoc )
{
  dumpNode( tidyGetRoot(tdoc), 0 );
}

void dumpBody( TidyDoc tdoc )
{
  dumpNode( tidyGetBody(tdoc), 0 );
}
</pre>

@{

*/

TIDY_EXPORT TidyNode TIDY_CALL    ig_tidyGetRoot( TidyDoc tdoc );
TIDY_EXPORT TidyNode TIDY_CALL    ig_tidyGetHtml( TidyDoc tdoc );
TIDY_EXPORT TidyNode TIDY_CALL    ig_tidyGetHead( TidyDoc tdoc );
TIDY_EXPORT TidyNode TIDY_CALL    ig_tidyGetBody( TidyDoc tdoc );

/* parent / child */
TIDY_EXPORT TidyNode TIDY_CALL    ig_tidyGetParent( TidyNode tnod );
TIDY_EXPORT TidyNode TIDY_CALL    ig_tidyGetChild( TidyNode tnod );

/* siblings */
TIDY_EXPORT TidyNode TIDY_CALL    ig_tidyGetNext( TidyNode tnod );
TIDY_EXPORT TidyNode TIDY_CALL    ig_tidyGetPrev( TidyNode tnod );

/* Null for non-element nodes and all pure HTML
TIDY_EXPORT ctmbstr     tidyNodeNsLocal( TidyNode tnod );
TIDY_EXPORT ctmbstr     tidyNodeNsPrefix( TidyNode tnod );
TIDY_EXPORT ctmbstr     tidyNodeNsUri( TidyNode tnod );
*/

/* Iterate over attribute values */
TIDY_EXPORT TidyAttr TIDY_CALL    ig_tidyAttrFirst( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL    ig_tidyAttrNext( TidyAttr tattr );

TIDY_EXPORT ctmbstr TIDY_CALL     ig_tidyAttrName( TidyAttr tattr );
TIDY_EXPORT ctmbstr TIDY_CALL     ig_tidyAttrValue( TidyAttr tattr );

/* Null for pure HTML
TIDY_EXPORT ctmbstr     tidyAttrNsLocal( TidyAttr tattr );
TIDY_EXPORT ctmbstr     tidyAttrNsPrefix( TidyAttr tattr );
TIDY_EXPORT ctmbstr     tidyAttrNsUri( TidyAttr tattr );
*/

/** @} end Tree group */


/** @defgroup NodeAsk Node Interrogation
**
** Get information about any givent node.
** @{
*/

/* Node info */
TIDY_EXPORT TidyNodeType TIDY_CALL ig_tidyNodeGetType( TidyNode tnod );
TIDY_EXPORT ctmbstr TIDY_CALL     ig_tidyNodeGetName( TidyNode tnod );

TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsText( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsProp( TidyDoc tdoc, TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsHeader( TidyNode tnod ); /* h1, h2, ... */

TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeHasText( TidyDoc tdoc, TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeGetText( TidyDoc tdoc, TidyNode tnod, TidyBuffer* buf );

/* Copy the unescaped value of this node into the given TidyBuffer as UTF-8 */
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeGetValue( TidyDoc tdoc, TidyNode tnod, TidyBuffer* buf );

TIDY_EXPORT TidyTagId TIDY_CALL ig_tidyNodeGetId( TidyNode tnod );

TIDY_EXPORT uint TIDY_CALL ig_tidyNodeLine( TidyNode tnod );
TIDY_EXPORT uint TIDY_CALL ig_tidyNodeColumn( TidyNode tnod );

/** @defgroup NodeIsElementName Deprecated node interrogation per TagId
**
** @deprecated The functions tidyNodeIs{ElementName} are deprecated and 
** should be replaced by tidyNodeGetId.
** @{
*/
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsHTML( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsHEAD( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsTITLE( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsBASE( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsMETA( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsBODY( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsFRAMESET( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsFRAME( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsIFRAME( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsNOFRAMES( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsHR( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsH1( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsH2( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsPRE( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsLISTING( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsP( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsUL( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsOL( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsDL( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsDIR( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsLI( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsDT( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsDD( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsTABLE( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsCAPTION( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsTD( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsTH( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsTR( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsCOL( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsCOLGROUP( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsBR( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsA( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsLINK( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsB( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsI( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsSTRONG( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsEM( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsBIG( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsSMALL( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsPARAM( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsOPTION( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsOPTGROUP( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsIMG( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsMAP( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsAREA( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsNOBR( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsWBR( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsFONT( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsLAYER( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsSPACER( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsCENTER( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsSTYLE( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsSCRIPT( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsNOSCRIPT( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsFORM( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsTEXTAREA( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsBLOCKQUOTE( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsAPPLET( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsOBJECT( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsDIV( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsSPAN( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsINPUT( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsQ( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsLABEL( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsH3( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsH4( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsH5( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsH6( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsADDRESS( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsXMP( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsSELECT( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsBLINK( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsMARQUEE( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsEMBED( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsBASEFONT( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsISINDEX( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsS( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsSTRIKE( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsU( TidyNode tnod );
TIDY_EXPORT Bool TIDY_CALL ig_tidyNodeIsMENU( TidyNode tnod );

/** @} End NodeIsElementName group */

/** @} End NodeAsk group */


/** @defgroup Attribute Attribute Interrogation
**
** Get information about any given attribute.
** @{
*/

TIDY_EXPORT TidyAttrId TIDY_CALL ig_tidyAttrGetId( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsEvent( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsProp( TidyAttr tattr );

/** @defgroup AttrIsAttributeName Deprecated attribute interrogation per AttrId
**
** @deprecated The functions  tidyAttrIs{AttributeName} are deprecated and 
** should be replaced by tidyAttrGetId.
** @{
*/
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsHREF( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsSRC( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsID( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsNAME( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsSUMMARY( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsALT( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsLONGDESC( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsUSEMAP( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsISMAP( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsLANGUAGE( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsTYPE( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsVALUE( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsCONTENT( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsTITLE( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsXMLNS( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsDATAFLD( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsWIDTH( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsHEIGHT( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsFOR( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsSELECTED( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsCHECKED( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsLANG( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsTARGET( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsHTTP_EQUIV( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsREL( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsOnMOUSEMOVE( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsOnMOUSEDOWN( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsOnMOUSEUP( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsOnCLICK( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsOnMOUSEOVER( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsOnMOUSEOUT( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsOnKEYDOWN( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsOnKEYUP( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsOnKEYPRESS( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsOnFOCUS( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsOnBLUR( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsBGCOLOR( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsLINK( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsALINK( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsVLINK( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsTEXT( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsSTYLE( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsABBR( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsCOLSPAN( TidyAttr tattr );
TIDY_EXPORT Bool TIDY_CALL ig_tidyAttrIsROWSPAN( TidyAttr tattr );

/** @} End AttrIsAttributeName group */

/** @} end AttrAsk group */


/** @defgroup AttrGet Attribute Retrieval
**
** Lookup an attribute from a given node
** @{
*/

TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetById( TidyNode tnod, TidyAttrId attId );

/** @defgroup AttrGetAttributeName Deprecated attribute retrieval per AttrId
**
** @deprecated The functions tidyAttrGet{AttributeName} are deprecated and 
** should be replaced by tidyAttrGetById.
** For instance, tidyAttrGetID( TidyNode tnod ) can be replaced by 
** tidyAttrGetById( TidyNode tnod, TidyAttr_ID ). This avoids a potential
** name clash with tidyAttrGetId for case-insensitive languages.
** @{
*/
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetHREF( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetSRC( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetID( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetNAME( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetSUMMARY( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetALT( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetLONGDESC( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetUSEMAP( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetISMAP( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetLANGUAGE( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetTYPE( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetVALUE( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetCONTENT( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetTITLE( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetXMLNS( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetDATAFLD( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetWIDTH( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetHEIGHT( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetFOR( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetSELECTED( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetCHECKED( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetLANG( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetTARGET( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetHTTP_EQUIV( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetREL( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetOnMOUSEMOVE( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetOnMOUSEDOWN( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetOnMOUSEUP( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetOnCLICK( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetOnMOUSEOVER( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetOnMOUSEOUT( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetOnKEYDOWN( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetOnKEYUP( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetOnKEYPRESS( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetOnFOCUS( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetOnBLUR( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetBGCOLOR( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetLINK( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetALINK( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetVLINK( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetTEXT( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetSTYLE( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetABBR( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetCOLSPAN( TidyNode tnod );
TIDY_EXPORT TidyAttr TIDY_CALL ig_tidyAttrGetROWSPAN( TidyNode tnod );

/** @} End AttrGetAttributeName group */

/** @} end AttrGet group */

#ifdef __cplusplus
}  /* extern "C" */
#endif
#endif /* __TIDY_H__ */

/*
 * local variables:
 * mode: c
 * indent-tabs-mode: nil
 * c-basic-offset: 4
 * eval: (c-set-offset 'substatement-open 0)
 * end:
 */
