-- PROCEDURE LOG:
-- ----------------------------------------------------------------------------------
-- Procedure Name               | Procedure Description
-- -----------------------------|----------------------------------------------------
-- No Procedure                 | DDL Table Definition for Library Summary Metrics
-- ----------------------------------------------------------------------------------
-- MODIFICATION LOG:
-- ----------------------------------------------------------------------------------
-- Date     | Mod_ID | Developer   | Case and Description
-- ---------|--------|-------------|-------------------------------------------------
-- 29/10/26 | 0001   | Antigravity | Create Library Summary Metrics Table (PF1)
-- ----------------------------------------------------------------------------------

Create Or Replace Table Library_Summary_Metrics (
    Library_Name           FOR COLUMN IALIBNAM    CHAR(10)       NOT NULL WITH DEFAULT ' ',
    Object_Count           FOR COLUMN IAOBJCNT    NUMERIC(10, 0) NOT NULL WITH DEFAULT 0,
    Member_Count           FOR COLUMN IAMBRCNT    NUMERIC(10, 0) NOT NULL WITH DEFAULT 0,
    Total_Lines            FOR COLUMN IATOTLIN    NUMERIC(10, 0) NOT NULL WITH DEFAULT 0,
    Executable_Lines       FOR COLUMN IAEXELIN    NUMERIC(10, 0) NOT NULL WITH DEFAULT 0,
    Non_Executable_Lines   FOR COLUMN IANOEXEL    NUMERIC(10, 0) NOT NULL WITH DEFAULT 0
);

Rename Table Library_Summary_Metrics To System Name IASUMMETP;

Label On Table Library_Summary_Metrics Is 'Library Summary Sizing Metrics (PF1)';

Label On Column Library_Summary_Metrics (
    IALIBNAM    IS 'Library             Name',
    IAOBJCNT    IS 'Source Object       Count',
    IAMBRCNT    IS 'Eligible Member     Count',
    IATOTLIN    IS 'Total Source        Lines',
    IAEXELIN    IS 'Executable          Lines',
    IANOEXEL    IS 'Non-Executable      Lines'
);
