CREATE TABLE [dbo].[Service_Robot_Message]
(
[SRBT_SERV_FILE_NO] [bigint] NOT NULL,
[SRBT_ROBO_RBID] [bigint] NOT NULL,
[RWNO] [bigint] NOT NULL CONSTRAINT [DF_Serive_Robot_Message_RWNO] DEFAULT ((0)),
[MESG_ID] [bigint] NULL,
[RECV_DATE] [datetime] NULL,
[MESG_TEXT] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHAT_ID] [bigint] NULL,
[USSD_CODE] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [BLOB] TEXTIMAGE_ON [PRIMARY]
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
CREATE TRIGGER [dbo].[CG$AINS_SRMG]
   ON  [dbo].[Service_Robot_Message]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   
   MERGE dbo.Service_Robot_Message T
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
            ,T.RECV_DATE = GETDATE()
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
CREATE TRIGGER [dbo].[CG$AUPD_SRMG]
   ON  [dbo].[Service_Robot_Message]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   
   MERGE dbo.Service_Robot_Message T
   USING (SELECT * FROM Inserted) S
   ON ( T.SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO AND
        T.SRBT_ROBO_RBID = S.SRBT_ROBO_RBID AND
        T.RWNO = S.RWNO
   )
   WHEN MATCHED THEN
      UPDATE 
         SET T.MDFY_BY = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Service_Robot_Message] ADD CONSTRAINT [PK_SRMG] PRIMARY KEY CLUSTERED  ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID], [RWNO]) ON [BLOB]
GO
ALTER TABLE [dbo].[Service_Robot_Message] ADD CONSTRAINT [FK_SRMG_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
