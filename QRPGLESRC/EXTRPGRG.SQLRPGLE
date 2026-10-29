**FREE
// =========================================================================
// Program Name : EXTRPGRG
// Description  : RPG Source Extraction & Sizing Metrics Engine
// Language     : Fully Free-Form ILE RPG with Embedded SQL (SQLRPGLE)
// Author       : IBM i Extraction Utility Team
//
// Key Capabilities:
// 1. Reads member catalog from &OUTLIB/&peLib (permanent table named after
//    the library being processed, e.g., OUTLIB/ERP).
// 2. Evaluates member eligibility based on source type (MLSEU2).
// 3. Dynamically aliases each eligible member via DB2 ALIAS in QTEMP.
// 4. Inserts full source records into consolidated PF (EXTRPGPF).
// 5. Analyzes each source line to classify as Executable vs Non-Executable:
//    - C-specs and free-form operational statements -> Executable
//    - Comments (* or //), blank lines, H/F/D/I/O specs -> Non-Executable
// 6. Writes member metrics into PF2 (EXTRPGDTL):
//    SRCLIB, SRCFILE, SRCMBR, SRCTYPE, TOTLINES, EXELINES, NONEXELIN
// 7. Writes library summary metrics into PF1 (EXTRPGSUM):
//    LIBNAME, OBJCNT, MBRCNT, TOTLINES, EXELINES, NONEXELIN
// =========================================================================

ctl-opt dftactgrp(*no) actgrp(*caller) option(*srcstmt:*nodebugio);

// -------------------------------------------------------------------------
// Program Interface (PI)
// -------------------------------------------------------------------------
dcl-pi EXTRPGRG;
  peLib      char(10) const;
  peOutLib   char(10) const;
  peOutFile  char(10) const;
  peMbrCount int(10);
  peRecCount int(10);
  peStatus   char(10);
end-pi;

// -------------------------------------------------------------------------
// Internal Prototypes
// -------------------------------------------------------------------------
dcl-pr isEligibleType ind;
  pSourceType char(10) const;
end-pr;

dcl-pr isExecutableLine ind;
  pSrcDta  varchar(256) const;
  pSrcType char(10)     const;
end-pr;

// -------------------------------------------------------------------------
// Working Variables
// -------------------------------------------------------------------------
dcl-s srcFile         char(10);
dcl-s srcMbr          char(10);
dcl-s srcType         char(10);
dcl-s srcDta          varchar(256);
dcl-s lastFile        char(10) value('');

// Member-level counters (for PF2: EXTRPGDTL)
dcl-s mbrTotLines     int(10);
dcl-s mbrExeLines     int(10);
dcl-s mbrNonExeLines  int(10);

// Library-level counters (for PF1: EXTRPGSUM)
dcl-s libObjCount     int(10) value(0);
dcl-s libMbrCount     int(10) value(0);
dcl-s libTotLines     int(10) value(0);
dcl-s libExeLines     int(10) value(0);
dcl-s libNonExeLines  int(10) value(0);

// Dynamic SQL statements
dcl-s sqlMbrStmt      varchar(512);
dcl-s sqlCreate       varchar(512);
dcl-s sqlInsertPf     varchar(1024);
dcl-s sqlInsertDtl    varchar(1024);
dcl-s sqlInsertSum    varchar(1024);

// Initialize return values
peMbrCount = 0;
peRecCount = 0;
peStatus   = '*OK';

// Configure SQL session
exec sql set option commit = *none,
                    datfmt = *iso,
                    closqlcsr = *endactgrp;

monitor;

  // -----------------------------------------------------------------------
  // 1. Declare and Open Cursor Over &OUTLIB/peLib (Table named after peLib)
  //    Selects only Source physical files (MLFTYP = 'S')
  // -----------------------------------------------------------------------
  sqlMbrStmt = 'SELECT MLFILE, MLNAME, MLSEU2 ' +
               'FROM ' + %trim(peOutLib) + '/' + %trim(peLib) + ' ' +
               'WHERE MLFTYP = ''S'' ' +
               'ORDER BY MLFILE, MLNAME';

  exec sql prepare sMbrStmt from :sqlMbrStmt;
  if (sqlcode < 0);
    peStatus = '*ERR_PREP';
    return;
  endif;

  exec sql declare cMbrCatalog cursor for sMbrStmt;
  exec sql open cMbrCatalog;

  if (sqlcode < 0);
    peStatus = '*ERR_OPEN';
    return;
  endif;

  // -----------------------------------------------------------------------
  // 2. Fetch and Process Each Discovered Member
  // -----------------------------------------------------------------------
  dow (1 = 1);

    exec sql fetch next from cMbrCatalog
      into :srcFile, :srcMbr, :srcType;

    if (sqlcode <> 0);
      leave; // EOF or error
    endif;

    // Filter for eligible RPG types (RPGLE, SQLRPGLE, RPG, SQLRPG, RPG38, RPGP)
    if not isEligibleType(srcType);
      iter; // Skip non-RPG types (e.g., CLP, CLLE, DDS, TXT, CBL)
    endif;

    // Track distinct source physical files (objects) processed
    if (srcFile <> lastFile);
      libObjCount += 1;
      lastFile = srcFile;
    endif;

    // Reset member-level counters
    mbrTotLines    = 0;
    mbrExeLines    = 0;
    mbrNonExeLines = 0;

    // ---------------------------------------------------------------------
    // 3. Create Dynamic SQL Alias in QTEMP for Member
    // ---------------------------------------------------------------------
    sqlCreate = 'CREATE OR REPLACE ALIAS QTEMP.CURSRCMBR FOR "' +
                %trim(peLib) + '"."' +
                %trim(srcFile) + '" ("' +
                %trim(srcMbr) + '")';

    exec sql execute immediate :sqlCreate;
    if (sqlcode < 0);
      iter; // Skip member if locked or inaccessible
    endif;

    // ---------------------------------------------------------------------
    // 4. Insert Source Lines into Consolidated Repository (EXTRPGPF)
    // ---------------------------------------------------------------------
    sqlInsertPf = 'INSERT INTO ' + %trim(peOutLib) + '/' + %trim(peOutFile) +
                  ' (SRCLIB, SRCFILE, SRCMBR, SRCTYPE, SRCSEQ, SRCDAT, SRCDTA) ' +
                  'SELECT ''' + %trim(peLib) + ''', ''' +
                                %trim(srcFile) + ''', ''' +
                                %trim(srcMbr) + ''', ''' +
                                %trim(srcType) + ''', ' +
                  'SRCSEQ, SRCDAT, SRCDTA ' +
                  'FROM QTEMP.CURSRCMBR';

    exec sql execute immediate :sqlInsertPf;

    // ---------------------------------------------------------------------
    // 5. Line-by-Line Sizing Analysis: Executable vs Non-Executable
    // ---------------------------------------------------------------------
    exec sql declare cSrcLines cursor for
      select SRCDTA from QTEMP.CURSRCMBR;

    exec sql open cSrcLines;

    if (sqlcode = 0);
      dow (1 = 1);
        exec sql fetch next from cSrcLines into :srcDta;
        if (sqlcode <> 0);
          leave;
        endif;

        mbrTotLines += 1;

        if isExecutableLine(srcDta: srcType);
          mbrExeLines += 1;
        else;
          mbrNonExeLines += 1;
        endif;
      enddo;
      exec sql close cSrcLines;
    endif;

    // ---------------------------------------------------------------------
    // 6. Insert Row into Detail Metrics PF2 (EXTRPGDTL)
    //    Columns: Library / Source File / Member name / Member type /
    //             total lines / exec lines / non exec lines
    // ---------------------------------------------------------------------
    sqlInsertDtl = 'INSERT INTO ' + %trim(peOutLib) + '/EXTRPGDTL ' +
                   '(SRCLIB, SRCFILE, SRCMBR, SRCTYPE, TOTLINES, EXELINES, NONEXELIN) ' +
                   'VALUES (''' + %trim(peLib) + ''', ''' +
                                 %trim(srcFile) + ''', ''' +
                                 %trim(srcMbr) + ''', ''' +
                                 %trim(srcType) + ''', ' +
                                 %char(mbrTotLines) + ', ' +
                                 %char(mbrExeLines) + ', ' +
                                 %char(mbrNonExeLines) + ')';

    exec sql execute immediate :sqlInsertDtl;

    // Drop temporary alias
    exec sql drop alias QTEMP.CURSRCMBR;

    // Accumulate library-level totals
    libMbrCount    += 1;
    libTotLines    += mbrTotLines;
    libExeLines    += mbrExeLines;
    libNonExeLines += mbrNonExeLines;

  enddo;

  exec sql close cMbrCatalog;

  // -----------------------------------------------------------------------
  // 7. Insert Row into Library Summary Metrics PF1 (EXTRPGSUM)
  //    Columns: Lib name / objcnt / mbrcnt / total lines /
  //             exec lines / non exec lines
  // -----------------------------------------------------------------------
  if (libMbrCount > 0 or libObjCount > 0);
    sqlInsertSum = 'INSERT INTO ' + %trim(peOutLib) + '/EXTRPGSUM ' +
                   '(LIBNAME, OBJCNT, MBRCNT, TOTLINES, EXELINES, NONEXELIN) ' +
                   'VALUES (''' + %trim(peLib) + ''', ' +
                                 %char(libObjCount) + ', ' +
                                 %char(libMbrCount) + ', ' +
                                 %char(libTotLines) + ', ' +
                                 %char(libExeLines) + ', ' +
                                 %char(libNonExeLines) + ')';

    exec sql execute immediate :sqlInsertSum;
  endif;

  // Return totals to caller
  peMbrCount = libMbrCount;
  peRecCount = libTotLines;
  peStatus   = '*OK';

on-error;
  peStatus = '*SYS_ERR';
  return;
endmon;

*inlr = *on;
return;

// =========================================================================
// Procedure   : isEligibleType
// Description : Determines if source type qualifies for RPG extraction.
// =========================================================================
dcl-proc isEligibleType;
  dcl-pi isEligibleType ind;
    pSourceType char(10) const;
  end-pi;

  dcl-s cleanType  varchar(10);
  dcl-s i          int(10);
  dcl-c ELIG_COUNT const(6);
  dcl-s typeList   char(10) dim(ELIG_COUNT) ctdata;

  cleanType = %trim(pSourceType);

  for i = 1 to ELIG_COUNT;
    if (cleanType = %trim(typeList(i)));
      return *on;
    endif;
  endfor;

  return *off;
end-proc;

// =========================================================================
// Procedure   : isExecutableLine
// Description : Evaluates whether a source record represents an executable
//               statement (C-spec or free-form statement) or non-executable
//               (comment, blank, directive, or declaration spec).
// =========================================================================
dcl-proc isExecutableLine;
  dcl-pi isExecutableLine ind;
    pSrcDta  varchar(256) const;
    pSrcType char(10)     const;
  end-pi;

  dcl-s trimmed varchar(256);
  dcl-s col6    char(1);
  dcl-s col7    char(1);

  trimmed = %trim(pSrcDta);

  // 1. Blank line -> Non-executable
  if (trimmed = '');
    return *off;
  endif;

  // 2. Free-form / Directive comment markers
  // Line starting with '//' -> Comment
  if (%len(trimmed) >= 2 and %subst(trimmed: 1: 2) = '//');
    return *off;
  endif;

  // Compiler directives (/copy, /include, /free, /end-free, /if, /endif, etc.)
  if (%len(trimmed) >= 1 and %subst(trimmed: 1: 1) = '/');
    return *off;
  endif;

  // Free-form tag line **FREE
  if (%len(trimmed) >= 6 and %upper(%subst(trimmed: 1: 6)) = '**FREE');
    return *off;
  endif;

  // 3. Fixed-Form RPG Evaluation (based on standard column positions)
  if (%len(pSrcDta) >= 7);
    col6 = %upper(%subst(pSrcDta: 6: 1));
    col7 = %subst(pSrcDta: 7: 1);

    // Fixed-form comment has asterisk in column 7
    if (col7 = '*');
      return *off;
    endif;

    // Fixed-form Declarative Specs:
    // H = Header, F = File, D = Data Def, I = Input, O = Output
    if (col6 = 'H' or col6 = 'F' or col6 = 'D' or col6 = 'I' or col6 = 'O');
      return *off;
    endif;

    // Fixed-form Calculation Spec:
    // Column 6 = 'C' and column 7 is not '*' -> Executable Calculation Line!
    if (col6 = 'C');
      return *on;
    endif;
  endif;

  // 4. Free-form RPG Declarations:
  // dcl-s, dcl-c, dcl-ds, dcl-pr, dcl-pi, dcl-f, ctl-opt, end-ds, end-pr, end-pi
  if (%len(trimmed) >= 4);
    if (%lower(%subst(trimmed: 1: 4)) = 'dcl-' or
        %lower(%subst(trimmed: 1: 4)) = 'end-' or
        (%len(trimmed) >= 7 and %lower(%subst(trimmed: 1: 7)) = 'ctl-opt'));
      return *off;
    endif;
  endif;

  // 5. Default: Free-form operational code (eval, if, dow, exec sql, chain, etc.)
  return *on;
end-proc;

**CTDATA typeList
RPGLE
SQLRPGLE
RPG
SQLRPG
RPG38
RPGP
