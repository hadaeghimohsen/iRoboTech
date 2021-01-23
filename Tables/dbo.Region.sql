CREATE TABLE [dbo].[Region]
(
[PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Region_PRVN_CNTY_CODE] DEFAULT ('001'),
[PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Region_PRVN_CODE] DEFAULT ('001'),
[CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LTIN_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Region_STAT] DEFAULT ('002'),
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_REGN]
   ON  [dbo].[Region]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Region T
   USING (SELECT * FROM INSERTED) S
   ON (T.PRVN_CNTY_CODE = S.PRVN_CNTY_CODE AND
       T.PRVN_CODE      = S.PRVN_CODE      AND
       T.CODE           = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE();
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_REGN]
   ON  [dbo].[Region]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Region T
   USING (SELECT * FROM INSERTED) S
   ON (T.PRVN_CNTY_CODE = S.PRVN_CNTY_CODE AND
       T.PRVN_CODE      = S.PRVN_CODE      AND
       T.CODE           = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;
GO
ALTER TABLE [dbo].[Region] ADD CONSTRAINT [PK_REGN] PRIMARY KEY CLUSTERED  ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Region] ADD CONSTRAINT [FK_REGN_PRVN] FOREIGN KEY ([PRVN_CNTY_CODE], [PRVN_CODE]) REFERENCES [dbo].[Province] ([CNTY_CODE], [CODE]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Region] ADD CONSTRAINT [FK_REGN_REGN] FOREIGN KEY ([PRVN_CNTY_CODE], [PRVN_CODE], [REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE])
GO
