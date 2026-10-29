-- =================================================================
-- Table Name  : EXTRPGDTL (PF2)
-- Description : Member Detail Metrics Table (SQL DDL)
-- Author      : IBM i Extraction Utility Team
-- Columns     : Library / Source File / Member name / Member type /
--               total lines / exec lines / non exec lines
-- =================================================================

CREATE OR REPLACE TABLE EXTRPGDTL (
    SRCLIB       CHAR(10)         NOT NULL DEFAULT '',
    SRCFILE      CHAR(10)         NOT NULL DEFAULT '',
    SRCMBR       CHAR(10)         NOT NULL DEFAULT '',
    SRCTYPE      CHAR(10)         NOT NULL DEFAULT '',
    TOTLINES     NUMERIC(10, 0)   NOT NULL DEFAULT 0,
    EXELINES     NUMERIC(10, 0)   NOT NULL DEFAULT 0,
    NONEXELIN    NUMERIC(10, 0)   NOT NULL DEFAULT 0
);

LABEL ON TABLE EXTRPGDTL IS 'Member Detail Metrics (PF2)';

LABEL ON COLUMN EXTRPGDTL (
    SRCLIB    TEXT IS 'Source Library',
    SRCFILE   TEXT IS 'Source File',
    SRCMBR    TEXT IS 'Member Name',
    SRCTYPE   TEXT IS 'Member Type',
    TOTLINES  TEXT IS 'Total Source Lines',
    EXELINES  TEXT IS 'Executable Lines',
    NONEXELIN TEXT IS 'Non-Executable Lines'
);

CREATE INDEX EXTRPGDTL_IDX1 ON EXTRPGDTL (SRCLIB, SRCFILE, SRCMBR);
