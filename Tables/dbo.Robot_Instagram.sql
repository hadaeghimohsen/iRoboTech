CREATE TABLE [dbo].[Robot_Instagram]
(
[ROBO_RBID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[PAGE_OWNR_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INST_PKID] [bigint] NULL,
[USER_NAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PASS_WORD] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FULL_NAME] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WEB_LINK] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PAGE_LINK] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NAME] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GNDR_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EMAL_ADRS] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[URL] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CELL_PHON] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BIOG_DESC] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CTGY_DESC] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IMAG_PROF_PATH] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BUSN_LOCT_ID] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BUSN_LOCT_NAME] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BUSN_PHON] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BUSN_CONT_MTOD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BUSN_POST_ADRS] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BUSN_ZIP_CODE] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CYCL_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CYCL_INTR] [int] NULL,
[CYCL_SEND_MESG_NUMB] [int] NULL,
[CYCL_NEW_FOLW_NUMB] [int] NULL,
[CYCL_NFLW_TMPL_TMID] [bigint] NULL,
[CYCL_ACTN_SLEP] [int] NULL,
[CYCL_HOST_MANG] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RINS]
   ON  [dbo].[Robot_Instagram]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Instagram T
   USING (SELECT * FROM Inserted) S
   ON (t.ROBO_RBID = s.ROBO_RBID AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
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
CREATE TRIGGER [dbo].[CG$AUPD_RINS]
   ON  [dbo].[Robot_Instagram]
   AFTER UPDATE   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   MERGE dbo.Robot_Instagram T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Robot_Instagram] ADD CONSTRAINT [PK_RINS] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Instagram] ADD CONSTRAINT [FK_RINS_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'بیوگرافی پیج', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'BIOG_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره تلفن', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'CELL_PHON'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان استراحت بین هر عمل', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'CYCL_ACTN_SLEP'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سیستم مدت زمان ارسال پیام به اینستاگرام', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'CYCL_INTR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد فالو های یک دوره', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'CYCL_NEW_FOLW_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'پیام ارسال بعد از فالو کردن', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'CYCL_NFLW_TMPL_TMID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد پیام های ارسالی در هر دوره ارسال', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'CYCL_SEND_MESG_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت ارسال پیام به اینستاگرام', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'CYCL_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آدرس ایمیل', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'EMAL_ADRS'
GO
EXEC sp_addextendedproperty N'MS_Description', N'جنسیت', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'GNDR_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آدرس فایل ذخیره سازی عکس پروفابل پیج', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'IMAG_PROF_PATH'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نام', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'NAME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'پیج اینستاگرام', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'PAGE_LINK'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مالکیت پیج', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'PAGE_OWNR_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'رمز عبور', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'PASS_WORD'
GO
EXEC sp_addextendedproperty N'MS_Description', N'URL', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'URL'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نام کاربری اینستاگرام', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'USER_NAME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آدرس اینترنتی پیج اینستاگرام', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Instagram', 'COLUMN', N'WEB_LINK'
GO
