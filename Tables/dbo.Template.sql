CREATE TABLE [dbo].[Template]
(
[ROBO_RBID] [bigint] NULL,
[TMID] [bigint] NOT NULL,
[TEMP_NAME] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEMP_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEMP_SUBJ] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEMP_TEXT] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_TMPL]
   ON  [dbo].[Template]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Template T
   USING (SELECT * FROM Inserted) S
   ON (t.ROBO_RBID = s.ROBO_RBID AND 
       t.TMID = s.TMID)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.TMID = CASE s.TMID WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.TMID END,
         T.STAT = ISNULL(S.STAT, '002');
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
CREATE TRIGGER [dbo].[CG$AUPD_TMPL]
   ON  [dbo].[Template]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Template T
   USING (SELECT * FROM Inserted) S
   ON (t.TMID = s.TMID)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Template] ADD CONSTRAINT [PK_TMPL] PRIMARY KEY CLUSTERED  ([TMID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Template] ADD CONSTRAINT [FK_TMPL_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'انواع قالب', 'SCHEMA', N'dbo', 'TABLE', N'Template', 'COLUMN', N'TEMP_TYPE'
GO
