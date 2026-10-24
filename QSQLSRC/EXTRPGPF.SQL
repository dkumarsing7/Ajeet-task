-- =================================================================
-- Table Name  : EXTRPGPF
-- Description : Consolidated RPG Extracted Source Records (SQL DDL)
-- Author      : IBM i Extraction Utility Team
-- Execution   : RUNSQLSTM SRCFILE(QSQLSRC) SRCMBR(EXTRPGPF) COMMIT(*NONE)
-- =================================================================

CREATE OR REPLACE TABLE EXTRPGPF (
    SRCLIB     CHAR(10)         NOT NULL DEFAULT '',
    SRCFILE    CHAR(10)         NOT NULL DEFAULT '',
    SRCMBR     CHAR(10)         NOT NULL DEFAULT '',
    SRCTYPE    CHAR(10)         NOT NULL DEFAULT '',
    SRCSEQ     DECIMAL(6, 2)    NOT NULL DEFAULT 0.00,
    SRCDAT     NUMERIC(6, 0)    NOT NULL DEFAULT 0,
    SRCDTA     VARCHAR(256)     NOT NULL DEFAULT '',
    EXTRTIME   TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP
);

LABEL ON TABLE EXTRPGPF IS 'Consolidated RPG Extracted Source Records';

LABEL ON COLUMN EXTRPGPF (
    SRCLIB   TEXT IS 'Source Library',
    SRCFILE  TEXT IS 'Source File',
    SRCMBR   TEXT IS 'Source Member',
    SRCTYPE  TEXT IS 'Source Type',
    SRCSEQ   TEXT IS 'Source Sequence',
    SRCDAT   TEXT IS 'Source Date',
    SRCDTA   TEXT IS 'Source Data',
    EXTRTIME TEXT IS 'Extraction Timestamp'
);

-- Optional Performance Index for Querying Extracted Records
CREATE INDEX EXTRPGPF_IDX1 ON EXTRPGPF (SRCLIB, SRCFILE, SRCMBR, SRCSEQ);
