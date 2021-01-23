CREATE TABLE [dbo].[Robot_Spy_Group_Message]
(
[RSPG_ROBO_RBID] [bigint] NULL,
[RSPG_GROP_CODE] [bigint] NULL,
[SRBT_SERV_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CHAT_ID] [bigint] NULL,
[MESG_TEXT] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_ID] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MESG_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MIME_TYPE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MESG_DATE] [datetime] NULL,
[MESG_ID] [bigint] NULL,
[CONT_FRST_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONT_LAST_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONT_PHON_NUMB] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONT_CHAT_ID] [bigint] NULL,
[CONT_USER_NAME] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LAT] [float] NULL,
[LON] [float] NULL,
[JOIN_LEFT] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CG$AINS_RSGM]
   ON  [dbo].[Robot_Spy_Group_Message]
   AFTER INSERT   
AS 
BEGIN
	DECLARE @Code BIGINT;
	SET @Code = dbo.GNRT_NVID_U();	
	
	MERGE dbo.Robot_Spy_Group_Message T
	USING (SELECT * FROM Inserted) S
	ON (T.CODE = S.CODE)
	WHEN MATCHED THEN
	   UPDATE SET
	      T.CODE = @Code;
   
   INSERT INTO dbo.Robot_Spy_Group_Message_Detail(RSGM_CODE, CODE, CHAT_TYPE, STAT)
   VALUES ( @Code ,dbo.GNRT_NVID_U() ,'001' ,'001')
         ,( @Code ,dbo.GNRT_NVID_U() ,'002' ,'001')
         ,( @Code ,dbo.GNRT_NVID_U() ,'003' ,'001')
         ,( @Code ,dbo.GNRT_NVID_U() ,'004' ,'001')
         ,( @Code ,dbo.GNRT_NVID_U() ,'005' ,'001')
         ,( @Code ,dbo.GNRT_NVID_U() ,'006' ,'001')
         ,( @Code ,dbo.GNRT_NVID_U() ,'007' ,'001');
End
GO
ALTER TABLE [dbo].[Robot_Spy_Group_Message] ADD CONSTRAINT [PK_RSGM] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Spy_Group_Message] ADD CONSTRAINT [FK_RSGM_ROBO] FOREIGN KEY ([RSPG_ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
ALTER TABLE [dbo].[Robot_Spy_Group_Message] ADD CONSTRAINT [FK_RSGM_RSPG] FOREIGN KEY ([RSPG_ROBO_RBID], [RSPG_GROP_CODE]) REFERENCES [dbo].[Robot_Spy_Group] ([ROBO_RBID], [GROP_CODE])
GO
ALTER TABLE [dbo].[Robot_Spy_Group_Message] ADD CONSTRAINT [FK_RSGM_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [RSPG_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'محتوای پیام', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Spy_Group_Message', 'COLUMN', N'CONT_TYPE'
GO
