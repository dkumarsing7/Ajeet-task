-- PROCEDURE LOG:
-- ----------------------------------------------------------------------------------
-- Procedure Name               | Procedure Description
-- -----------------------------|----------------------------------------------------
-- No Procedure                 | DDL Table Definition for Member Detail Metrics
-- ----------------------------------------------------------------------------------
-- MODIFICATION LOG:
-- ----------------------------------------------------------------------------------
-- Date     | Mod_ID | Developer   | Case and Description
-- ---------|--------|-------------|-------------------------------------------------
-- 29/10/26 | 0001   | Antigravity | Create Member Detail Metrics Table (PF2)
-- ----------------------------------------------------------------------------------

Create Or Replace Table Member_Detail_Metrics (
    Source_Library         FOR COLUMN IASRCLIB    CHAR(10)       NOT NULL WITH DEFAULT ' ',
    Source_File            FOR COLUMN IASRCFIL    CHAR(10)       NOT NULL WITH DEFAULT ' ',
    Member_Name            FOR COLUMN IASRCMBR    CHAR(10)       NOT NULL WITH DEFAULT ' ',
    Member_Type            FOR COLUMN IASRCTYP    CHAR(10)       NOT NULL WITH DEFAULT ' ',
    Total_Lines            FOR COLUMN IATOTLIN    NUMERIC(10, 0) NOT NULL WITH DEFAULT 0,
    Executable_Lines       FOR COLUMN IAEXELIN    NUMERIC(10, 0) NOT NULL WITH DEFAULT 0,
    Non_Executable_Lines   FOR COLUMN IANOEXEL    NUMERIC(10, 0) NOT NULL WITH DEFAULT 0
);

Rename Table Member_Detail_Metrics To System Name IADTLMETP;

Label On Table Member_Detail_Metrics Is 'Member Detail Sizing Metrics (PF2)';

Label On Column Member_Detail_Metrics (
    IASRCLIB    IS 'Source              Library',
    IASRCFIL    IS 'Source              File',
    IASRCMBR    IS 'Member              Name',
    IASRCTYP    IS 'Member              Type',
    IATOTLIN    IS 'Total Source        Lines',
    IAEXELIN    IS 'Executable          Lines',
    IANOEXEL    IS 'Non-Executable      Lines'
);

Create Index IADTLMETP_IDX1 On Member_Detail_Metrics (IASRCLIB, IASRCFIL, IASRCMBR);
