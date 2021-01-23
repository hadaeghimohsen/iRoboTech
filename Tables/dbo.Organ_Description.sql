CREATE TABLE [dbo].[Organ_Description]
(
[ODID] [bigint] NOT NULL IDENTITY(1, 1),
[ORGN_OGID] [bigint] NULL,
[ROBO_RBID] [bigint] NULL,
[ITEM_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ITEM_VALU] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR] [int] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Organ_Description_STAT] DEFAULT ('002'),
[SHOW_STRT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[USSD_CODE] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AINS_OGDC]
   ON  [dbo].[Organ_Description]
   AFTER INSERT
AS 
BEGIN
	MERGE dbo.Organ_Description T
	USING (
	   SELECT * 
	     FROM INSERTED I
	) S
	ON (T.ODID = S.ODID) 
	WHEN MATCHED THEN
	   UPDATE
	      SET ORGN_OGID = (SELECT ORGN_OGID FROM dbo.Robot WHERE RBID = S.ROBO_RBID)
	         ,T.CRET_BY = UPPER(SUSER_NAME())
	         ,T.CRET_DATE = GETDATE();

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AUPD_OGDC]
   ON  [dbo].[Organ_Description]
   AFTER UPDATE
AS 
BEGIN
	MERGE dbo.Organ_Description T
	USING (
	   SELECT * 
	     FROM INSERTED I
	) S
	ON (T.ODID = S.ODID AND S.ORGN_OGID IS NULL) 
	WHEN MATCHED THEN
	   UPDATE
	      SET ORGN_OGID = (SELECT ORGN_OGID FROM dbo.Robot WHERE RBID = S.ROBO_RBID)
	         ,T.MDFY_BY = UPPER(SUSER_NAME())
	         ,T.MDFY_DATE = GETDATE();

END
GO
ALTER TABLE [dbo].[Organ_Description] ADD CONSTRAINT [PK_Organ_Description] PRIMARY KEY CLUSTERED  ([ODID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Organ_Description] ADD CONSTRAINT [FK_OGDC_ORGN] FOREIGN KEY ([ORGN_OGID]) REFERENCES [dbo].[Organ] ([OGID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Organ_Description] ADD CONSTRAINT [FK_OGDC_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
