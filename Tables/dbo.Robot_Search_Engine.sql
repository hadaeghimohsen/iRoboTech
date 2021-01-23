CREATE TABLE [dbo].[Robot_Search_Engine]
(
[ROBO_RBID] [bigint] NULL,
[SGID] [bigint] NOT NULL,
[SRCH_ENGN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WEB_SITE] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR] [int] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[NAME] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CG$AINS_ROSE]
   ON  [dbo].[Robot_Search_Engine]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Search_Engine T
   USING (SELECT * FROM Inserted) S
   ON (t.ROBO_RBID = s.ROBO_RBID AND 
       t.SGID = s.SGID)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.SGID = CASE S.SGID WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.SGID END,
         T.STAT = ISNULL(S.STAT, '002'),
         T.ORDR = (SELECT ISNULL(MAX(se.ORDR), 0) + 1 FROM dbo.Robot_Search_Engine se WHERE se.ROBO_RBID = s.ROBO_RBID);
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
CREATE TRIGGER [dbo].[CG$AUPD_ROSE]
   ON  [dbo].[Robot_Search_Engine]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Search_Engine T
   USING (SELECT * FROM Inserted) S
   ON (t.ROBO_RBID = s.ROBO_RBID AND 
       t.SGID = s.SGID)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Robot_Search_Engine] ADD CONSTRAINT [PK_ROSE] PRIMARY KEY CLUSTERED  ([SGID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Search_Engine] ADD CONSTRAINT [FK_ROSE_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
