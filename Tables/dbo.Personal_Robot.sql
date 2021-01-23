CREATE TABLE [dbo].[Personal_Robot]
(
[SERV_FILE_NO] [bigint] NOT NULL,
[ROBO_RBID] [bigint] NOT NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_PRBT_STAT] DEFAULT ('002'),
[CHAT_ID] [bigint] NULL,
[NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CELL_PHON] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TELL_PHON] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[USER_NAME] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DFLT_ACES] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_PRBT]
   ON  [dbo].[Personal_Robot]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Personal_Robot T
   USING(SELECT * FROM inserted) S
   ON (T.SERV_FILE_NO = S.Serv_File_No AND
       T.ROBO_RBID = S.Robo_Rbid)
   WHEN MATCHED THEN
      UPDATE         
         SET T.CRET_BY = UPPER(SUSER_NAME())
            ,T.CRET_DATE = GETDATE()
            ,T.STAT = ISNULL(s.STAT, '002')
            ,T.DFLT_ACES = ISNULL(s.DFLT_ACES, '002')
            ,T.Chat_Id = (SELECT CHAT_ID FROM dbo.Service_Robot X WHERE X.SERV_FILE_NO = S.Serv_File_No AND X.ROBO_RBID = S.Robo_Rbid)
            ,T.NAME = (SELECT X.NAME FROM dbo.Service_Robot X WHERE X.SERV_FILE_NO = S.Serv_File_No AND X.ROBO_RBID = S.Robo_Rbid)
            ,T.CELL_PHON = (SELECT X.CELL_PHON FROM dbo.Service_Robot X WHERE X.SERV_FILE_NO = S.Serv_File_No AND X.ROBO_RBID = S.Robo_Rbid);

   
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
CREATE TRIGGER [dbo].[CG$AUPD_PRBT]
   ON  [dbo].[Personal_Robot]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Personal_Robot T
   USING(SELECT * FROM inserted) S
   ON (T.SERV_FILE_NO = S.Serv_File_No AND
       T.ROBO_RBID = S.Robo_Rbid)
   WHEN MATCHED THEN
      UPDATE         
         SET T.MDFY_BY = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE();
   
END
GO
ALTER TABLE [dbo].[Personal_Robot] ADD CONSTRAINT [PK_PRBT] PRIMARY KEY CLUSTERED  ([SERV_FILE_NO], [ROBO_RBID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Personal_Robot] ADD CONSTRAINT [PRBT_ROBO_FK] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
ALTER TABLE [dbo].[Personal_Robot] WITH NOCHECK ADD CONSTRAINT [PRBT_SERV_FK] FOREIGN KEY ([SERV_FILE_NO]) REFERENCES [dbo].[Service] ([FILE_NO]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'دسترسی به صورت پیش فرض داده شود', 'SCHEMA', N'dbo', 'TABLE', N'Personal_Robot', 'COLUMN', N'DFLT_ACES'
GO
