CREATE TABLE [dbo].[User_RobotListener_Log]
(
[URLF_FGA_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[ACTN_DATE] [datetime] NULL,
[USER_NAME_DNRM] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HOST_NAME_DNRM] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACTN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RSLT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RSLT_DESC] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_URLL]
   ON  [dbo].[User_RobotListener_Log]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.User_RobotListener_Log T
   USING(SELECT * FROM Inserted) S
   ON (T.URLF_FGA_CODE = S.URLF_FGA_CODE 
   AND T.Code = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET T.CRET_BY = UPPER(SUSER_NAME())
            ,T.CRET_DATE = GETDATE()
            ,T.CODE = dbo.GNRT_NVID_U()
            ,T.ACTN_DATE = GETDATE();
   
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
CREATE TRIGGER [dbo].[CG$AUPD_URLL]
   ON  [dbo].[User_RobotListener_Log]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.User_RobotListener_Log T
   USING(SELECT * FROM Inserted) S
   ON (T.URLF_FGA_CODE = S.URLF_FGA_CODE 
   AND T.Code = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET T.MDFY_BY = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE()
            ,T.USER_NAME_DNRM = (SELECT [USER_NAME] FROM dbo.User_RobotListener_Fgac WHERE FGA_CODE = s.URLF_FGA_CODE)
            ,t.HOST_NAME_DNRM = (SELECT [HOST_NAME] FROM dbo.User_RobotListener_Fgac WHERE FGA_CODE = s.URLF_FGA_CODE);
END
GO
ALTER TABLE [dbo].[User_RobotListener_Log] ADD CONSTRAINT [PK_URLL] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[User_RobotListener_Log] ADD CONSTRAINT [FK_URLL_URLF] FOREIGN KEY ([URLF_FGA_CODE]) REFERENCES [dbo].[User_RobotListener_Fgac] ([FGA_CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع رکورد کاری
1 - ایجاد کردن پل ارتباطی
2 - استارت کردن ربات', 'SCHEMA', N'dbo', 'TABLE', N'User_RobotListener_Log', 'COLUMN', N'ACTN_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ایا کاری که برای آن رکورد در نظر گرفته شده آیا موفقیت آمیز بوده یا خیر؟', 'SCHEMA', N'dbo', 'TABLE', N'User_RobotListener_Log', 'COLUMN', N'RSLT_TYPE'
GO
