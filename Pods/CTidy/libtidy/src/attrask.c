/* attrask.c -- Interrogate attribute type

  (c) 1998-2006 (W3C) MIT, ERCIM, Keio University
  See tidy.h for the copyright notice.
  
  CVS Info:
    $Author: arnaud02 $ 
    $Date: 2006/09/12 15:14:44 $ 
    $Revision: 1.5 $ 

*/

#include "tidy-int.h"
#include "tidy.h"
#include "attrs.h"

Bool TIDY_CALL ig_tidyAttrIsHREF( TidyAttr tattr )
{
    return attrIsHREF( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsSRC( TidyAttr tattr )
{
    return attrIsSRC( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsID( TidyAttr tattr )
{
    return attrIsID( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsNAME( TidyAttr tattr )
{
    return attrIsNAME( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsSUMMARY( TidyAttr tattr )
{
    return attrIsSUMMARY( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsALT( TidyAttr tattr )
{
    return attrIsALT( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsLONGDESC( TidyAttr tattr )
{
    return attrIsLONGDESC( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsUSEMAP( TidyAttr tattr )
{
    return attrIsUSEMAP( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsISMAP( TidyAttr tattr )
{
    return attrIsISMAP( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsLANGUAGE( TidyAttr tattr )
{
    return attrIsLANGUAGE( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsTYPE( TidyAttr tattr )
{
    return attrIsTYPE( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsVALUE( TidyAttr tattr )
{
    return attrIsVALUE( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsCONTENT( TidyAttr tattr )
{
    return attrIsCONTENT( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsTITLE( TidyAttr tattr )
{
    return attrIsTITLE( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsXMLNS( TidyAttr tattr )
{
    return attrIsXMLNS( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsDATAFLD( TidyAttr tattr )
{
    return attrIsDATAFLD( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsWIDTH( TidyAttr tattr )
{
    return attrIsWIDTH( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsHEIGHT( TidyAttr tattr )
{
    return attrIsHEIGHT( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsFOR( TidyAttr tattr )
{
    return attrIsFOR( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsSELECTED( TidyAttr tattr )
{
    return attrIsSELECTED( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsCHECKED( TidyAttr tattr )
{
    return attrIsCHECKED( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsLANG( TidyAttr tattr )
{
    return attrIsLANG( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsTARGET( TidyAttr tattr )
{
    return attrIsTARGET( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsHTTP_EQUIV( TidyAttr tattr )
{
    return attrIsHTTP_EQUIV( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsREL( TidyAttr tattr )
{
    return attrIsREL( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsEvent( TidyAttr tattr )
{
    return TY_(attrIsEvent)( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsOnMOUSEMOVE( TidyAttr tattr )
{
    return attrIsOnMOUSEMOVE( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsOnMOUSEDOWN( TidyAttr tattr )
{
    return attrIsOnMOUSEDOWN( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsOnMOUSEUP( TidyAttr tattr )
{
    return attrIsOnMOUSEUP( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsOnCLICK( TidyAttr tattr )
{
    return attrIsOnCLICK( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsOnMOUSEOVER( TidyAttr tattr )
{
    return attrIsOnMOUSEOVER( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsOnMOUSEOUT( TidyAttr tattr )
{
    return attrIsOnMOUSEOUT( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsOnKEYDOWN( TidyAttr tattr )
{
    return attrIsOnKEYDOWN( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsOnKEYUP( TidyAttr tattr )
{
    return attrIsOnKEYUP( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsOnKEYPRESS( TidyAttr tattr )
{
    return attrIsOnKEYPRESS( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsOnFOCUS( TidyAttr tattr )
{
    return attrIsOnFOCUS( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsOnBLUR( TidyAttr tattr )
{
    return attrIsOnBLUR( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsBGCOLOR( TidyAttr tattr )
{
    return attrIsBGCOLOR( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsLINK( TidyAttr tattr )
{
    return attrIsLINK( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsALINK( TidyAttr tattr )
{
    return attrIsALINK( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsVLINK( TidyAttr tattr )
{
    return attrIsVLINK( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsTEXT( TidyAttr tattr )
{
    return attrIsTEXT( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsSTYLE( TidyAttr tattr )
{
    return attrIsSTYLE( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsABBR( TidyAttr tattr )
{
    return attrIsABBR( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsCOLSPAN( TidyAttr tattr )
{
    return attrIsCOLSPAN( tidyAttrToImpl(tattr) );
}
Bool TIDY_CALL ig_tidyAttrIsROWSPAN( TidyAttr tattr )
{
    return attrIsROWSPAN( tidyAttrToImpl(tattr) );
}

/*
 * local variables:
 * mode: c
 * indent-tabs-mode: nil
 * c-basic-offset: 4
 * eval: (c-set-offset 'substatement-open 0)
 * end:
 */
