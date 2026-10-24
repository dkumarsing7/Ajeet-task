/* ========================================================================= */
/* Command Name : EXTRPGSRC                                                  */
/* Description  : Extract RPG-related Source to Consolidated PF              */
/* Author       : IBM i Extraction Utility Team                              */
/* CPP          : EXTRPGCL                                                   */
/* VLDPGM       : CHKLIBS                                                    */
/*                                                                           */
/* Parameter Specifications:                                                 */
/* 1. LIB     : List of 1 to 10 library names to extract source from.       */
/*              Enforced MIN(1) and MAX(10) by OS/400 Command Analyzer.     */
/* 2. OUTLIB  : Target library for consolidated physical file.               */
/* 3. OUTFILE : Target physical file name (Default: EXTRPGPF).               */
/* 4. CLEAR   : Clear output file before extraction (*YES/*NO).              */
/* ========================================================================= */

             CMD        PROMPT('Extract RPG Source to PF')

             /* ----------------------------------------------------------- */
             /* Parameter 1: Target Libraries (1 to 10 allowed)             */
             /* ----------------------------------------------------------- */
             PARM       KWD(LIB) TYPE(*NAME) LEN(10) MIN(1) MAX(10) +
                          PROMPT('Libraries to extract')

             /* ----------------------------------------------------------- */
             /* Parameter 2: Output Library                                 */
             /* ----------------------------------------------------------- */
             PARM       KWD(OUTLIB) TYPE(*NAME) LEN(10) DFT(*CURLIB) +
                          SPCVAL((*CURLIB)) +
                          PROMPT('Output library')

             /* ----------------------------------------------------------- */
             /* Parameter 3: Output Consolidated Physical File              */
             /* ----------------------------------------------------------- */
             PARM       KWD(OUTFILE) TYPE(*NAME) LEN(10) DFT(EXTRPGPF) +
                          PROMPT('Output physical file')

             /* ----------------------------------------------------------- */
             /* Parameter 4: Clear Existing Output File                     */
             /* ----------------------------------------------------------- */
             PARM       KWD(CLEAR) TYPE(*CHAR) LEN(4) RSTD(*YES) +
                          VALUES(*YES *NO) DFT(*YES) +
                          PROMPT('Clear output file first')
