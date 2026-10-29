-- =================================================================
-- Table Name  : EXTRPGSUM (PF1)
-- Description : Library Summary Metrics Table (SQL DDL)
-- Author      : IBM i Extraction Utility Team
-- Columns     : Lib name / objcnt / mbrcnt / total lines / 
--               exec lines / non exec lines
-- =================================================================

CREATE OR REPLACE TABLE EXTRPGSUM (
    LIBNAME      CHAR(10)         NOT NULL DEFAULT '',
    OBJCNT       NUMERIC(10, 0)   NOT NULL DEFAULT 0,
    MBRCNT       NUMERIC(10, 0)   NOT NULL DEFAULT 0,
    TOTLINES     NUMERIC(10, 0)   NOT NULL DEFAULT 0,
    EXELINES     NUMERIC(10, 0)   NOT NULL DEFAULT 0,
    NONEXELIN    NUMERIC(10, 0)   NOT NULL DEFAULT 0
);

LABEL ON TABLE EXTRPGSUM IS 'Library Summary Metrics (PF1)';

LABEL ON COLUMN EXTRPGSUM (
    LIBNAME   TEXT IS 'Library Name',
    OBJCNT    TEXT IS 'Source Objects Count',
    MBRCNT    TEXT IS 'Eligible Members Count',
    TOTLINES  TEXT IS 'Total Source Lines',
    EXELINES  TEXT IS 'Executable Lines',
    NONEXELIN TEXT IS 'Non-Executable Lines'
);
