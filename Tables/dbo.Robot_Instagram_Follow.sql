CREATE TABLE [dbo].[Robot_Instagram_Follow]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[RINS_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[INST_PKID] [bigint] NOT NULL,
[USER_NAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BIOG_DESC] [nvarchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FULL_NAME] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[URL] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CTGY_DESC] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EMAL_ADRS] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHAT_ID] [bigint] NULL,
[FOLW_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RINF]
   ON  [dbo].[Robot_Instagram_Follow]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Instagram_Follow T
   USING (SELECT * FROM Inserted) S
   ON (T.RINS_CODE = S.RINS_CODE AND 
       t.INST_PKID = s.INST_PKID AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END,
         t.CHAT_ID = (
            SELECT sr.CHAT_ID
              FROM dbo.Service_Robot sr
             WHERE sr.SERV_FILE_NO = s.SRBT_SERV_FILE_NO
               AND sr.ROBO_RBID = s.SRBT_ROBO_RBID
         );
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
CREATE TRIGGER [dbo].[CG$AUPD_RINF]
   ON  [dbo].[Robot_Instagram_Follow]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Instagram_Follow T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Robot_Instagram_Follow] ADD CONSTRAINT [PK_RINF] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Instagram_Follow] ADD CONSTRAINT [FK_RINF_RINS] FOREIGN KEY ([RINS_CODE]) REFERENCES [dbo].[Robot_Instagram] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Robot_Instagram_Follow] ADD CONSTRAINT [FK_RINF_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع اعضا
Follower
Folllowing', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram_Follow', 'COLUMN', N'FOLW_TYPE'
GO
