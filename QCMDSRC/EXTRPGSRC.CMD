/* ========================================================================= */
/* Command Name : EXTRPGSRC                                                  */
/* Description  : Extract RPG-related Source & Sizing Metrics                */
/* Author       : IBM i Extraction Utility Team                              */
/* CPP          : EXTRPGCL                                                   */
/* VLDPGM       : CHKLIBS                                                    */
/* ========================================================================= */

             CMD        PROMPT('Extract RPG Source & Metrics')

             /* Target Libraries (1 to 10 entries allowed) */
             PARM       KWD(LIB) TYPE(*NAME) LEN(10) MIN(1) MAX(10) +
                          PROMPT('Libraries to extract')

             /* Output Library */
             PARM       KWD(OUTLIB) TYPE(*NAME) LEN(10) DFT(*CURLIB) +
                          SPCVAL((*CURLIB)) +
                          PROMPT('Output library')

             /* Output Consolidated Source Physical File */
             PARM       KWD(OUTFILE) TYPE(*NAME) LEN(10) DFT(IASRCRECP) +
                          PROMPT('Output physical file')

             /* Clear Existing Output Files Flag */
             PARM       KWD(CLEAR) TYPE(*CHAR) LEN(4) RSTD(*YES) +
                          VALUES(*YES *NO) DFT(*YES) +
                          PROMPT('Clear output files first')
