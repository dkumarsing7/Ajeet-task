-- PROCEDURE LOG:
-- ----------------------------------------------------------------------------------
-- Procedure Name               | Procedure Description
-- -----------------------------|----------------------------------------------------
-- No Procedure                 | DDL Table Definition for Source Records Repository
-- ----------------------------------------------------------------------------------
-- MODIFICATION LOG:
-- ----------------------------------------------------------------------------------
-- Date     | Mod_ID | Developer   | Case and Description
-- ---------|--------|-------------|-------------------------------------------------
-- 29/10/26 | 0001   | Antigravity | Create Consolidated Source Records Table
-- ----------------------------------------------------------------------------------

Create Or Replace Table Source_Extraction_Records (
    Source_Library         FOR COLUMN IASRCLIB    CHAR(10)       NOT NULL WITH DEFAULT ' ',
    Source_File            FOR COLUMN IASRCFIL    CHAR(10)       NOT NULL WITH DEFAULT ' ',
    Member_Name            FOR COLUMN IASRCMBR    CHAR(10)       NOT NULL WITH DEFAULT ' ',
    Member_Type            FOR COLUMN IASRCTYP    CHAR(10)       NOT NULL WITH DEFAULT ' ',
    Source_Sequence        FOR COLUMN IASRCSEQ    DECIMAL(6, 2)  NOT NULL WITH DEFAULT 0.00,
    Source_Date            FOR COLUMN IASRCDAT    NUMERIC(6, 0)  NOT NULL WITH DEFAULT 0,
    Source_Data            FOR COLUMN IASRCDTA    VARCHAR(256)   NOT NULL WITH DEFAULT ' '
);

Rename Table Source_Extraction_Records To System Name IASRCRECP;

Label On Table Source_Extraction_Records Is 'Consolidated Source Records Repository';

Label On Column Source_Extraction_Records (
    IASRCLIB    IS 'Source              Library',
    IASRCFIL    IS 'Source              File',
    IASRCMBR    IS 'Member              Name',
    IASRCTYP    IS 'Member              Type',
    IASRCSEQ    IS 'Source              Sequence',
    IASRCDAT    IS 'Source              Date',
    IASRCDTA    IS 'Source              Data'
);

Create Index IASRCRECP_IDX1 On Source_Extraction_Records (IASRCLIB, IASRCFIL, IASRCMBR, IASRCSEQ);
