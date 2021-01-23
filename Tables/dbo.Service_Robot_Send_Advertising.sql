CREATE TABLE [dbo].[Service_Robot_Send_Advertising]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[SDAD_ID] [bigint] NULL,
[RWNO] [bigint] NOT NULL IDENTITY(1, 1),
[CHAT_ID] [bigint] NULL,
[SEND_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VIST_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LIKE_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RTNG_NUM] [smallint] NULL,
[AMNT] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SRSA]
   ON  [dbo].[Service_Robot_Send_Advertising]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Send_Advertising T
   USING (SELECT * FROM Inserted) S
   ON (T.SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO
   AND T.SRBT_ROBO_RBID = S.SRBT_ROBO_RBID
   AND T.SDAD_ID = S.SDAD_ID
   AND T.RWNO = s.RWNO)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,T.CHAT_ID = (
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
CREATE TRIGGER [dbo].[CG$AUPD_SRSA]
   ON  [dbo].[Service_Robot_Send_Advertising]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Send_Advertising T
   USING (SELECT * FROM Inserted) S
   ON (T.SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO
   AND T.SRBT_ROBO_RBID = S.SRBT_ROBO_RBID
   AND T.SDAD_ID = S.SDAD_ID
   AND T.RWNO = s.RWNO)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE();

END
GO
ALTER TABLE [dbo].[Service_Robot_Send_Advertising] ADD CONSTRAINT [PK_SRSA] PRIMARY KEY CLUSTERED  ([RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Send_Advertising] ADD CONSTRAINT [FK_SRSA_SADA] FOREIGN KEY ([SDAD_ID]) REFERENCES [dbo].[Send_Advertising] ([ID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Send_Advertising] ADD CONSTRAINT [FK_SRSA_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ تبلیغات', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Send_Advertising', 'COLUMN', N'AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'خوشم اومد', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Send_Advertising', 'COLUMN', N'LIKE_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'امتیاز به پیام', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Send_Advertising', 'COLUMN', N'RTNG_NUM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'رویت کرده یا خیر', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Send_Advertising', 'COLUMN', N'VIST_STAT'
GO
