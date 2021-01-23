CREATE TABLE [dbo].[Service_Robot_Replay_Message]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[SRMG_RWNO] [bigint] NULL,
[SRMG_MESG_ID_DNRM] [bigint] NULL,
[ORDT_ORDR_CODE] [bigint] NULL,
[ORDT_RWNO] [bigint] NULL,
[RWNO] [bigint] NOT NULL CONSTRAINT [DF_Service_Robot_Replay_Message_RWNO] DEFAULT ((0)),
[RPLY_DATE] [datetime] NULL,
[MESG_TEXT] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SEND_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHAT_ID] [bigint] NULL,
[FILE_ID] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_PATH] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MESG_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LAT] [float] NULL,
[LON] [float] NULL,
[CONT_CELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VIST_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WHO_SEND] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SNDR_CHAT_ID] [bigint] NULL,
[HEDR_CODE] [bigint] NULL,
[HEDR_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONF_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONF_DATE] [datetime] NULL,
[INLN_KEYB_DNRM] [xml] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SRRM]
   ON  [dbo].[Service_Robot_Replay_Message]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   
   MERGE dbo.Service_Robot_Replay_Message T
   USING (SELECT * FROM Inserted) S
   ON ( T.SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO AND
        T.SRBT_ROBO_RBID = S.SRBT_ROBO_RBID AND
        T.RWNO = S.RWNO
   )
   WHEN MATCHED THEN
      UPDATE 
         SET T.CRET_BY = UPPER(SUSER_NAME())
            ,T.CRET_DATE = GETDATE()
            ,T.RWNO = dbo.GNRT_NVID_U()
            ,T.RPLY_DATE = GETDATE()
            ,T.MESG_TYPE = ISNULL(s.MESG_TYPE, '001')
            ,T.SEND_STAT = ISNULL(S.SEND_STAT, '002')
            ,T.VIST_STAT = ISNULL(s.VIST_STAT, '001')
            ,t.CHAT_ID = (SELECT CHAT_ID FROM dbo.Service_Robot WHERE SERV_FILE_NO = S.SRBT_SERV_FILE_NO AND ROBO_RBID = S.SRBT_ROBO_RBID);
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
CREATE TRIGGER [dbo].[CG$AUPD_SRRM]
   ON  [dbo].[Service_Robot_Replay_Message]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   
   MERGE dbo.Service_Robot_Replay_Message T
   USING (SELECT * FROM Inserted) S
   ON ( T.SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO AND
        T.SRBT_ROBO_RBID = S.SRBT_ROBO_RBID AND
        T.RWNO = S.RWNO
   )
   WHEN MATCHED THEN
      UPDATE 
         SET T.MDFY_BY = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE()
            ,T.SRMG_MESG_ID_DNRM = (SELECT MESG_ID FROM dbo.Service_Robot_Message WHERE SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO AND SRBT_ROBO_RBID = s.SRBT_ROBO_RBID AND RWNO = s.SRMG_RWNO);
END
GO
ALTER TABLE [dbo].[Service_Robot_Replay_Message] ADD CONSTRAINT [PK_SRRM] PRIMARY KEY CLUSTERED  ([RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Replay_Message] ADD CONSTRAINT [FK_SRRM_ORDT] FOREIGN KEY ([ORDT_ORDR_CODE], [ORDT_RWNO]) REFERENCES [dbo].[Order_Detail] ([ORDR_CODE], [RWNO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Replay_Message] ADD CONSTRAINT [FK_SRRM_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Replay_Message] ADD CONSTRAINT [FK_SRRM_SRMG] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID], [SRMG_RWNO]) REFERENCES [dbo].[Service_Robot_Message] ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID], [RWNO])
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ تایید', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Replay_Message', 'COLUMN', N'CONF_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاییدیه پیام های تبلیغاتی برای مشتریان', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Replay_Message', 'COLUMN', N'CONF_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اگر پیام برای چند نفر قرارباشد ارسال شود با این گزینه می توانیم مدیریت کنیم', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Replay_Message', 'COLUMN', N'HEDR_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'محتوای پیام برای چه بخشی است', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Replay_Message', 'COLUMN', N'HEDR_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'منوی پیام', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Replay_Message', 'COLUMN', N'INLN_KEYB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارسال کننده پیام', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Replay_Message', 'COLUMN', N'SNDR_CHAT_ID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'پاسخ به پیام دریافت شده از مشترک', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Replay_Message', 'COLUMN', N'SRMG_MESG_ID_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'رویت کرده یا خیر', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Replay_Message', 'COLUMN', N'VIST_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارسال کننده پیام', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Replay_Message', 'COLUMN', N'WHO_SEND'
GO
