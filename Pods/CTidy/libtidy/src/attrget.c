/* attrget.c -- Locate attribute value by type

  (c) 1998-2006 (W3C) MIT, ERCIM, Keio University
  See tidy.h for the copyright notice.
  
  CVS Info:
    $Author: arnaud02 $ 
    $Date: 2006/09/12 15:14:44 $ 
    $Revision: 1.6 $ 

*/

#include "tidy-int.h"
#include "tags.h"
#include "attrs.h"
#include "tidy.h"

TidyAttr TIDY_CALL ig_tidyAttrGetById( TidyNode tnod, TidyAttrId attId )
{
    Node* nimp = tidyNodeToImpl(tnod);
    return tidyImplToAttr( TY_(AttrGetById)( nimp, attId ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetHREF( TidyNode tnod )
{
    return tidyImplToAttr( attrGetHREF( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetSRC( TidyNode tnod )
{
    return tidyImplToAttr( attrGetSRC( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetID( TidyNode tnod )
{
    return tidyImplToAttr( attrGetID( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetNAME( TidyNode tnod )
{
    return tidyImplToAttr( attrGetNAME( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetSUMMARY( TidyNode tnod )
{
    return tidyImplToAttr( attrGetSUMMARY( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetALT( TidyNode tnod )
{
    return tidyImplToAttr( attrGetALT( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetLONGDESC( TidyNode tnod )
{
    return tidyImplToAttr( attrGetLONGDESC( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetUSEMAP( TidyNode tnod )
{
    return tidyImplToAttr( attrGetUSEMAP( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetISMAP( TidyNode tnod )
{
    return tidyImplToAttr( attrGetISMAP( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetLANGUAGE( TidyNode tnod )
{
    return tidyImplToAttr( attrGetLANGUAGE( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetTYPE( TidyNode tnod )
{
    return tidyImplToAttr( attrGetTYPE( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetVALUE( TidyNode tnod )
{
    return tidyImplToAttr( attrGetVALUE( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetCONTENT( TidyNode tnod )
{
    return tidyImplToAttr( attrGetCONTENT( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetTITLE( TidyNode tnod )
{
    return tidyImplToAttr( attrGetTITLE( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetXMLNS( TidyNode tnod )
{
    return tidyImplToAttr( attrGetXMLNS( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetDATAFLD( TidyNode tnod )
{
    return tidyImplToAttr( attrGetDATAFLD( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetWIDTH( TidyNode tnod )
{
    return tidyImplToAttr( attrGetWIDTH( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetHEIGHT( TidyNode tnod )
{
    return tidyImplToAttr( attrGetHEIGHT( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetFOR( TidyNode tnod )
{
    return tidyImplToAttr( attrGetFOR( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetSELECTED( TidyNode tnod )
{
    return tidyImplToAttr( attrGetSELECTED( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetCHECKED( TidyNode tnod )
{
    return tidyImplToAttr( attrGetCHECKED( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetLANG( TidyNode tnod )
{
    return tidyImplToAttr( attrGetLANG( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetTARGET( TidyNode tnod )
{
    return tidyImplToAttr( attrGetTARGET( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetHTTP_EQUIV( TidyNode tnod )
{
    return tidyImplToAttr( attrGetHTTP_EQUIV( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetREL( TidyNode tnod )
{
    return tidyImplToAttr( attrGetREL( tidyNodeToImpl(tnod) ) );
}

TidyAttr TIDY_CALL ig_tidyAttrGetOnMOUSEMOVE( TidyNode tnod )
{
    return tidyImplToAttr( attrGetOnMOUSEMOVE( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetOnMOUSEDOWN( TidyNode tnod )
{
    return tidyImplToAttr( attrGetOnMOUSEDOWN( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetOnMOUSEUP( TidyNode tnod )
{
    return tidyImplToAttr( attrGetOnMOUSEUP( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetOnCLICK( TidyNode tnod )
{
    return tidyImplToAttr( attrGetOnCLICK( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetOnMOUSEOVER( TidyNode tnod )
{
    return tidyImplToAttr( attrGetOnMOUSEOVER( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetOnMOUSEOUT( TidyNode tnod )
{
    return tidyImplToAttr( attrGetOnMOUSEOUT( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetOnKEYDOWN( TidyNode tnod )
{
    return tidyImplToAttr( attrGetOnKEYDOWN( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetOnKEYUP( TidyNode tnod )
{
    return tidyImplToAttr( attrGetOnKEYUP( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetOnKEYPRESS( TidyNode tnod )
{
    return tidyImplToAttr( attrGetOnKEYPRESS( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetOnFOCUS( TidyNode tnod )
{
    return tidyImplToAttr( attrGetOnFOCUS( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetOnBLUR( TidyNode tnod )
{
    return tidyImplToAttr( attrGetOnBLUR( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetBGCOLOR( TidyNode tnod )
{
    return tidyImplToAttr( attrGetBGCOLOR( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetLINK( TidyNode tnod )
{
    return tidyImplToAttr( attrGetLINK( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetALINK( TidyNode tnod )
{
    return tidyImplToAttr( attrGetALINK( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetVLINK( TidyNode tnod )
{
    return tidyImplToAttr( attrGetVLINK( tidyNodeToImpl(tnod) ) );
}

TidyAttr TIDY_CALL ig_tidyAttrGetTEXT( TidyNode tnod )
{
    return tidyImplToAttr( attrGetTEXT( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetSTYLE( TidyNode tnod )
{
    return tidyImplToAttr( attrGetSTYLE( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetABBR( TidyNode tnod )
{
    return tidyImplToAttr( attrGetABBR( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetCOLSPAN( TidyNode tnod )
{
    return tidyImplToAttr( attrGetCOLSPAN( tidyNodeToImpl(tnod) ) );
}
TidyAttr TIDY_CALL ig_tidyAttrGetROWSPAN( TidyNode tnod )
{
    return tidyImplToAttr( attrGetROWSPAN( tidyNodeToImpl(tnod) ) );
}

/*
 * local variables:
 * mode: c
 * indent-tabs-mode: nil
 * c-basic-offset: 4
 * eval: (c-set-offset 'substatement-open 0)
 * end:
 */
