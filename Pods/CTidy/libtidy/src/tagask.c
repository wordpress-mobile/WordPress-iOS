/* tagask.c -- Interrogate node type

  (c) 1998-2006 (W3C) MIT, ERCIM, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: arnaud02 $ 
    $Date: 2006/09/12 15:14:44 $ 
    $Revision: 1.6 $ 

*/

#include "tidy-int.h"
#include "tags.h"
#include "tidy.h"

Bool TIDY_CALL ig_tidyNodeIsText( TidyNode tnod )
{ return TY_(nodeIsText)( tidyNodeToImpl(tnod) );
}
Bool tidyNodeCMIsBlock( TidyNode tnod ); /* not exported yet */
Bool tidyNodeCMIsBlock( TidyNode tnod )
{ return TY_(nodeCMIsBlock)( tidyNodeToImpl(tnod) );
}
Bool tidyNodeCMIsInline( TidyNode tnod ); /* not exported yet */
Bool tidyNodeCMIsInline( TidyNode tnod )
{ return TY_(nodeCMIsInline)( tidyNodeToImpl(tnod) );
}
Bool tidyNodeCMIsEmpty( TidyNode tnod ); /* not exported yet */
Bool tidyNodeCMIsEmpty( TidyNode tnod )
{ return TY_(nodeCMIsEmpty)( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsHeader( TidyNode tnod )
{ return TY_(nodeIsHeader)( tidyNodeToImpl(tnod) );
}

Bool TIDY_CALL ig_tidyNodeIsHTML( TidyNode tnod )
{ return nodeIsHTML( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsHEAD( TidyNode tnod )
{ return nodeIsHEAD( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsTITLE( TidyNode tnod )
{ return nodeIsTITLE( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsBASE( TidyNode tnod )
{ return nodeIsBASE( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsMETA( TidyNode tnod )
{ return nodeIsMETA( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsBODY( TidyNode tnod )
{ return nodeIsBODY( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsFRAMESET( TidyNode tnod )
{ return nodeIsFRAMESET( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsFRAME( TidyNode tnod )
{ return nodeIsFRAME( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsIFRAME( TidyNode tnod )
{ return nodeIsIFRAME( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsNOFRAMES( TidyNode tnod )
{ return nodeIsNOFRAMES( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsHR( TidyNode tnod )
{ return nodeIsHR( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsH1( TidyNode tnod )
{ return nodeIsH1( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsH2( TidyNode tnod )
{ return nodeIsH2( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsPRE( TidyNode tnod )
{ return nodeIsPRE( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsLISTING( TidyNode tnod )
{ return nodeIsLISTING( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsP( TidyNode tnod )
{ return nodeIsP( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsUL( TidyNode tnod )
{ return nodeIsUL( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsOL( TidyNode tnod )
{ return nodeIsOL( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsDL( TidyNode tnod )
{ return nodeIsDL( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsDIR( TidyNode tnod )
{ return nodeIsDIR( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsLI( TidyNode tnod )
{ return nodeIsLI( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsDT( TidyNode tnod )
{ return nodeIsDT( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsDD( TidyNode tnod )
{ return nodeIsDD( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsTABLE( TidyNode tnod )
{ return nodeIsTABLE( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsCAPTION( TidyNode tnod )
{ return nodeIsCAPTION( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsTD( TidyNode tnod )
{ return nodeIsTD( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsTH( TidyNode tnod )
{ return nodeIsTH( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsTR( TidyNode tnod )
{ return nodeIsTR( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsCOL( TidyNode tnod )
{ return nodeIsCOL( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsCOLGROUP( TidyNode tnod )
{ return nodeIsCOLGROUP( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsBR( TidyNode tnod )
{ return nodeIsBR( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsA( TidyNode tnod )
{ return nodeIsA( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsLINK( TidyNode tnod )
{ return nodeIsLINK( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsB( TidyNode tnod )
{ return nodeIsB( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsI( TidyNode tnod )
{ return nodeIsI( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsSTRONG( TidyNode tnod )
{ return nodeIsSTRONG( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsEM( TidyNode tnod )
{ return nodeIsEM( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsBIG( TidyNode tnod )
{ return nodeIsBIG( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsSMALL( TidyNode tnod )
{ return nodeIsSMALL( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsPARAM( TidyNode tnod )
{ return nodeIsPARAM( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsOPTION( TidyNode tnod )
{ return nodeIsOPTION( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsOPTGROUP( TidyNode tnod )
{ return nodeIsOPTGROUP( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsIMG( TidyNode tnod )
{ return nodeIsIMG( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsMAP( TidyNode tnod )
{ return nodeIsMAP( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsAREA( TidyNode tnod )
{ return nodeIsAREA( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsNOBR( TidyNode tnod )
{ return nodeIsNOBR( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsWBR( TidyNode tnod )
{ return nodeIsWBR( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsFONT( TidyNode tnod )
{ return nodeIsFONT( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsLAYER( TidyNode tnod )
{ return nodeIsLAYER( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsSPACER( TidyNode tnod )
{ return nodeIsSPACER( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsCENTER( TidyNode tnod )
{ return nodeIsCENTER( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsSTYLE( TidyNode tnod )
{ return nodeIsSTYLE( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsSCRIPT( TidyNode tnod )
{ return nodeIsSCRIPT( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsNOSCRIPT( TidyNode tnod )
{ return nodeIsNOSCRIPT( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsFORM( TidyNode tnod )
{ return nodeIsFORM( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsTEXTAREA( TidyNode tnod )
{ return nodeIsTEXTAREA( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsBLOCKQUOTE( TidyNode tnod )
{ return nodeIsBLOCKQUOTE( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsAPPLET( TidyNode tnod )
{ return nodeIsAPPLET( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsOBJECT( TidyNode tnod )
{ return nodeIsOBJECT( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsDIV( TidyNode tnod )
{ return nodeIsDIV( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsSPAN( TidyNode tnod )
{ return nodeIsSPAN( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsINPUT( TidyNode tnod )
{ return nodeIsINPUT( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsQ( TidyNode tnod )
{ return nodeIsQ( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsLABEL( TidyNode tnod )
{ return nodeIsLABEL( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsH3( TidyNode tnod )
{ return nodeIsH3( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsH4( TidyNode tnod )
{ return nodeIsH4( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsH5( TidyNode tnod )
{ return nodeIsH5( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsH6( TidyNode tnod )
{ return nodeIsH6( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsADDRESS( TidyNode tnod )
{ return nodeIsADDRESS( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsXMP( TidyNode tnod )
{ return nodeIsXMP( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsSELECT( TidyNode tnod )
{ return nodeIsSELECT( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsBLINK( TidyNode tnod )
{ return nodeIsBLINK( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsMARQUEE( TidyNode tnod )
{ return nodeIsMARQUEE( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsEMBED( TidyNode tnod )
{ return nodeIsEMBED( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsBASEFONT( TidyNode tnod )
{ return nodeIsBASEFONT( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsISINDEX( TidyNode tnod )
{ return nodeIsISINDEX( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsS( TidyNode tnod )
{ return nodeIsS( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsSTRIKE( TidyNode tnod )
{ return nodeIsSTRIKE( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsU( TidyNode tnod )
{ return nodeIsU( tidyNodeToImpl(tnod) );
}
Bool TIDY_CALL ig_tidyNodeIsMENU( TidyNode tnod )
{ return nodeIsMENU( tidyNodeToImpl(tnod) );
}


/*
 * local variables:
 * mode: c
 * indent-tabs-mode: nil
 * c-basic-offset: 4
 * eval: (c-set-offset 'substatement-open 0)
 * end:
 */
