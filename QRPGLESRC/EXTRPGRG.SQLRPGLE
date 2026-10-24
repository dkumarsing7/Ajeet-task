**FREE
// =========================================================================
// Program Name : EXTRPGRG
// Description  : RPG Source Extraction Engine
// Language     : Fully Free-Form ILE RPG with Embedded SQL (SQLRPGLE)
// Author       : IBM i Extraction Utility Team
//
// Purpose:
// 1. Reads member catalog from QTEMP/QAFDMBL (populated by DSPFD).
// 2. Evaluates member eligibility based on source type (MLSEU2),
//    ignoring source physical file naming conventions.
// 3. Dynamically aliases each eligible member using DB2 for i ALIAS in QTEMP.
// 4. Performs set-based block INSERT into the consolidated output PF.
//    Sidesteps Record Format Level Checks (CPF4131) and variable widths.
// 5. Preserves exact sequence numbers (SRCSEQ), modification dates (SRCDAT),
//    and source text (SRCDTA).
// 6. Returns extracted member count and total records to caller.
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

// -------------------------------------------------------------------------
// Working Variables
// -------------------------------------------------------------------------
dcl-s srcFile       char(10);
dcl-s srcMbr        char(10);
dcl-s srcType       char(10);
dcl-s fileType      char(1);

dcl-s sqlCreate     varchar(512);
dcl-s sqlInsert     varchar(1024);
dcl-s insertedRows  int(10);

// Initialize return values
peMbrCount = 0;
peRecCount = 0;
peStatus   = '*OK';

// Set SQL run options
exec sql set option commit = *none,
                    datfmt = *iso,
                    closqlcsr = *endactgrp;

monitor;

  // -----------------------------------------------------------------------
  // 1. Declare and Open Cursor Over Member Catalog in QTEMP/QAFDMBL
  //    MLFTYP = 'S' guarantees we only examine Source physical files,
  //    preventing accidental scans of data physical files.
  // -----------------------------------------------------------------------
  exec sql declare cMbrCatalog cursor for
    select MLFILE, MLNAME, MLSEU2
    from QTEMP/QAFDMBL
    where MLFTYP = 'S'
    order by MLFILE, MLNAME;

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
      leave; // EOF (100) or error
    endif;

    // Check if member source type is an eligible RPG language type
    if not isEligibleType(srcType);
      iter; // Skip non-RPG types (e.g., CLP, CLLE, DDS, TXT, CBL)
    endif;

    // ---------------------------------------------------------------------
    // 3. Create or Replace Dynamic SQL Alias in QTEMP
    //    Format: CREATE OR REPLACE ALIAS QTEMP.CURSRCMBR FOR "LIB"."FILE" ("MBR")
    // ---------------------------------------------------------------------
    sqlCreate = 'CREATE OR REPLACE ALIAS QTEMP.CURSRCMBR FOR "' +
                %trim(peLib) + '"."' +
                %trim(srcFile) + '" ("' +
                %trim(srcMbr) + '")';

    exec sql execute immediate :sqlCreate;

    if (sqlcode < 0);
      // Member might be locked, damaged, or inaccessible; skip to next
      iter;
    endif;

    // ---------------------------------------------------------------------
    // 4. Perform High-Speed Set-Based Transfer to Consolidated PF
    //    DB2 automatically promotes/maps SRCSEQ, SRCDAT, and SRCDTA
    //    regardless of source file record length (80, 100, 112, 132, 240).
    // ---------------------------------------------------------------------
    sqlInsert = 'INSERT INTO ' + %trim(peOutLib) + '/' + %trim(peOutFile) +
                ' (SRCLIB, SRCFILE, SRCMBR, SRCTYPE, SRCSEQ, SRCDAT, SRCDTA) ' +
                'SELECT ''' + %trim(peLib) + ''', ''' +
                              %trim(srcFile) + ''', ''' +
                              %trim(srcMbr) + ''', ''' +
                              %trim(srcType) + ''', ' +
                'SRCSEQ, SRCDAT, SRCDTA ' +
                'FROM QTEMP.CURSRCMBR';

    exec sql execute immediate :sqlInsert;

    if (sqlcode = 0);
      // Success: retrieve number of rows inserted
      exec sql get diagnostics :insertedRows = ROW_COUNT;
      peMbrCount += 1;
      peRecCount += insertedRows;
    elseif (sqlcode = 100);
      // Empty member (0 source lines inserted)
      peMbrCount += 1;
    endif;

    // ---------------------------------------------------------------------
    // 5. Clean Up Temporary Alias for Current Member
    // ---------------------------------------------------------------------
    exec sql drop alias QTEMP.CURSRCMBR;

  enddo;

  exec sql close cMbrCatalog;

on-error;
  peStatus = '*SYS_ERR';
  return;
endmon;

*inlr = *on;
return;

// =========================================================================
// Procedure   : isEligibleType
// Description : Determines if source type qualifies for RPG extraction.
//               Centralized, maintainable eligibility lookup.
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

**CTDATA typeList
RPGLE
SQLRPGLE
RPG
SQLRPG
RPG38
RPGP
