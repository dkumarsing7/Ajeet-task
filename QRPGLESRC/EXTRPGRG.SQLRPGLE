**FREE
// PROCEDURE LOG:
//----------------------------------------------------------------------------------//
// Procedure Name               | Procedure Description                             //
//------------------------------|---------------------------------------------------//
// chkEligibleType              | Verify member source type qualifies for extract   //
// chkExecutableLine            | Classify statement as executable or non-executable//
//----------------------------------------------------------------------------------//
// MODIFICATION LOG:
//----------------------------------------------------------------------------------//
// Date     | Mod_ID | Developer   | Case and Description                           //
//----------|--------|-------------|------------------------------------------------//
// 29/10/26 | 0001   | Antigravity | Implement Enterprise Standards and Metrics     //
//----------------------------------------------------------------------------------//

ctl-opt copyright('Programmers.io @ 2022');
ctl-opt option(*nodebugio: *srcstmt: *nounref);

// Program Interface
dcl-pi EXTRPGRG;
  upLib        char(10) const;
  upOutLib     char(10) const;
  upOutFile    char(10) const;
  upMbrCount   packed(10:0);
  upRecCount   packed(10:0);
  upStatus     char(10);
end-pi;

// Procedure Prototypes
dcl-pr chkEligibleType ind;
  upSourceType char(10) const;
end-pr;

dcl-pr chkExecutableLine ind;
  upSourceData varchar(256) const;
  upSourceType char(10)      const;
end-pr;

// Data Structure Declarations
dcl-ds udMbrDtl;
  usFile       char(10) inz;
  usName       char(10) inz;
  usType       char(10) inz;
end-ds;

// Character and Varchar Work Variables
dcl-s uwSourceData   varchar(256)  inz;
dcl-s uwSqlStmt      varchar(1000) inz;
dcl-s uwSqlAlias     varchar(500)  inz;
dcl-s uwSqlInsPf     varchar(1000) inz;
dcl-s uwSqlInsDtl    varchar(1000) inz;
dcl-s uwSqlInsSum    varchar(1000) inz;
dcl-s uwLastFile     char(10)      inz;

// Indicator Work Variables
dcl-s uwIsEligible   ind inz(*off);
dcl-s uwIsExecLine   ind inz(*off);

// Numeric and Packed Work Variables
dcl-s uwTotLines     packed(10:0) inz(0);
dcl-s uwExeLines     packed(10:0) inz(0);
dcl-s uwNonExeLines  packed(10:0) inz(0);
dcl-s uwLibObjCount  packed(10:0) inz(0);
dcl-s uwLibMbrCount  packed(10:0) inz(0);
dcl-s uwLibTotLines  packed(10:0) inz(0);
dcl-s uwLibExeLines  packed(10:0) inz(0);
dcl-s uwLibNonExe    packed(10:0) inz(0);

// Initialize return metrics
upMbrCount = 0;
upRecCount = 0;
upStatus   = '*OK';

// Configure embedded SQL environment
exec sql set option commit = *none,
                    datfmt = *iso,
                    closqlcsr = *endactgrp;

monitor;

  // Prepare dynamic SQL to read member catalog from OUTLIB named after upLib
  uwSqlStmt = 'SELECT MLFILE, MLNAME, MLSEU2 ' +
              'FROM ' + %trim(upOutLib) + '/' + %trim(upLib) + ' ' +
              'WHERE MLFTYP = ''S'' ' +
              'ORDER BY MLFILE, MLNAME';

  exec sql prepare sMbrCatalog from :uwSqlStmt;
  if (sqlcode < 0);
    upStatus = '*ERR_PREP';
    return;
  endif;

  exec sql declare cMbrCatalog cursor for sMbrCatalog;
  exec sql open cMbrCatalog;

  if (sqlcode < 0);
    upStatus = '*ERR_OPEN';
    return;
  endif;

  // Process each discovered member from catalog
  dow (1 = 1);

    exec sql fetch next from cMbrCatalog into :udMbrDtl;

    if (sqlcode <> 0);
      leave;
    endif;

    // Verify if source type is eligible RPG member
    uwIsEligible = chkEligibleType(usType);
    if (not uwIsEligible);
      iter;
    endif;

    // Increment object count on new file boundary
    if (usFile <> uwLastFile);
      uwLibObjCount += 1;
      uwLastFile = usFile;
    endif;

    // Reset member-level counters
    uwTotLines    = 0;
    uwExeLines    = 0;
    uwNonExeLines = 0;

    // Create dynamic SQL alias in QTEMP for member
    uwSqlAlias = 'CREATE OR REPLACE ALIAS QTEMP.CURSRCMBR FOR "' +
                 %trim(upLib) + '"."' +
                 %trim(usFile) + '" ("' +
                 %trim(usName) + '")';

    exec sql execute immediate :uwSqlAlias;
    if (sqlcode < 0);
      iter;
    endif;

    // Insert source lines into consolidated repository
    uwSqlInsPf = 'INSERT INTO ' + %trim(upOutLib) + '/' + %trim(upOutFile) +
                 ' (IASRCLIB, IASRCFIL, IASRCMBR, IASRCTYP, ' +
                 '  IASRCSEQ, IASRCDAT, IASRCDTA) ' +
                 'SELECT ''' + %trim(upLib) + ''', ''' +
                               %trim(usFile) + ''', ''' +
                               %trim(usName) + ''', ''' +
                               %trim(usType) + ''', ' +
                 'SRCSEQ, SRCDAT, SRCDTA ' +
                 'FROM QTEMP.CURSRCMBR';

    exec sql execute immediate :uwSqlInsPf;

    // Fetch and analyze each source line for sizing metrics
    exec sql declare cSrcLines cursor for
      select SRCDTA from QTEMP.CURSRCMBR;

    exec sql open cSrcLines;

    if (sqlcode = 0);
      dow (1 = 1);
        exec sql fetch next from cSrcLines into :uwSourceData;
        if (sqlcode <> 0);
          leave;
        endif;

        uwTotLines += 1;

        uwIsExecLine = chkExecutableLine(uwSourceData: usType);
        if (uwIsExecLine);
          uwExeLines += 1;
        else;
          uwNonExeLines += 1;
        endif;
      enddo;
      exec sql close cSrcLines;
    endif;

    // Write row into PF2 Member Detail Metrics
    uwSqlInsDtl = 'INSERT INTO ' + %trim(upOutLib) + '/IADTLMETP ' +
                  '(IASRCLIB, IASRCFIL, IASRCMBR, IASRCTYP, ' +
                  ' IATOTLIN, IAEXELIN, IANOEXEL) ' +
                  'VALUES (''' + %trim(upLib) + ''', ''' +
                                %trim(usFile) + ''', ''' +
                                %trim(usName) + ''', ''' +
                                %trim(usType) + ''', ' +
                                %char(uwTotLines) + ', ' +
                                %char(uwExeLines) + ', ' +
                                %char(uwNonExeLines) + ')';

    exec sql execute immediate :uwSqlInsDtl;

    // Clean up temporary alias
    exec sql drop alias QTEMP.CURSRCMBR;

    // Accumulate library-level totals
    uwLibMbrCount += 1;
    uwLibTotLines += uwTotLines;
    uwLibExeLines += uwExeLines;
    uwLibNonExe   += uwNonExeLines;

  enddo;

  exec sql close cMbrCatalog;

  // Write row into PF1 Library Summary Metrics
  if (uwLibMbrCount > 0 or uwLibObjCount > 0);
    uwSqlInsSum = 'INSERT INTO ' + %trim(upOutLib) + '/IASUMMETP ' +
                  '(IALIBNAM, IAOBJCNT, IAMBRCNT, ' +
                  ' IATOTLIN, IAEXELIN, IANOEXEL) ' +
                  'VALUES (''' + %trim(upLib) + ''', ' +
                                %char(uwLibObjCount) + ', ' +
                                %char(uwLibMbrCount) + ', ' +
                                %char(uwLibTotLines) + ', ' +
                                %char(uwLibExeLines) + ', ' +
                                %char(uwLibNonExe) + ')';

    exec sql execute immediate :uwSqlInsSum;
  endif;

  // Pass totals back to caller
  upMbrCount = uwLibMbrCount;
  upRecCount = uwLibTotLines;
  upStatus   = '*OK';

on-error;
  upStatus = '*SYS_ERR';
  return;
endmon;

*inlr = *on;
return;

// Procedure: chkEligibleType
dcl-proc chkEligibleType;
  dcl-pi chkEligibleType ind;
    upSourceType char(10) const;
  end-pi;

  dcl-s urEligTypes char(10) dim(6) ctdata;
  dcl-s uiEligType  packed(4:0)     inz;
  dcl-s uwCleanType varchar(10)     inz;

  uwCleanType = %trim(upSourceType);

  for uiEligType = 1 to %elem(urEligTypes);
    if (uwCleanType = %trim(urEligTypes(uiEligType)));
      return *on;
    endif;
  endfor;

  return *off;
end-proc;

// Procedure: chkExecutableLine
dcl-proc chkExecutableLine;
  dcl-pi chkExecutableLine ind;
    upSourceData varchar(256) const;
    upSourceType char(10)      const;
  end-pi;

  dcl-s uwTrimmed varchar(256) inz;
  dcl-s uwCol6    char(1)      inz;
  dcl-s uwCol7    char(1)      inz;

  uwTrimmed = %trim(upSourceData);

  // Use versatile SELECT block instead of nested IF
  select;

    // Blank line is non-executable
    when (uwTrimmed = '');
      return *off;

    // Free-form comment line
    when (%len(uwTrimmed) >= 2 and %subst(uwTrimmed: 1: 2) = '//');
      return *off;

    // Compiler directive
    when (%len(uwTrimmed) >= 1 and %subst(uwTrimmed: 1: 1) = '/');
      return *off;

    // Fully free-form header tag
    when (%len(uwTrimmed) >= 6 and %upper(%subst(uwTrimmed: 1: 6)) = '**FREE');
      return *off;

    // Free-form declaration statement
    when (%len(uwTrimmed) >= 4 and
          (%lower(%subst(uwTrimmed: 1: 4)) = 'dcl-' or
           %lower(%subst(uwTrimmed: 1: 4)) = 'end-' or
           (%len(uwTrimmed) >= 7 and %lower(%subst(uwTrimmed: 1: 7)) = 'ctl-opt')));
      return *off;

    // Fixed-form comment line (asterisk in column 7)
    when (%len(upSourceData) >= 7 and %subst(upSourceData: 7: 1) = '*');
      return *off;

    // Fixed-form declarative specifications (H, F, D, I, O in column 6)
    when (%len(upSourceData) >= 6 and
          (%upper(%subst(upSourceData: 6: 1)) = 'H' or
           %upper(%subst(upSourceData: 6: 1)) = 'F' or
           %upper(%subst(upSourceData: 6: 1)) = 'D' or
           %upper(%subst(upSourceData: 6: 1)) = 'I' or
           %upper(%subst(upSourceData: 6: 1)) = 'O'));
      return *off;

    // Fixed-form calculation specification (C in column 6)
    when (%len(upSourceData) >= 6 and %upper(%subst(upSourceData: 6: 1)) = 'C');
      return *on;

    // Default: Free-form operational code (executable)
    other;
      return *on;

  endsl;

end-proc;

**CTDATA urEligTypes
RPGLE
SQLRPGLE
RPG
SQLRPG
RPG38
RPGP
