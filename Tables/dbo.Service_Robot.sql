CREATE TABLE [dbo].[Service_Robot]
(
[SERV_FILE_NO] [bigint] NOT NULL,
[ROBO_RBID] [bigint] NOT NULL,
[GRPH_GHID] [bigint] NULL,
[SRPB_RWNO] [int] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Service_Robot_STAT] DEFAULT ('002'),
[CHAT_ID] [bigint] NULL,
[CELL_PHON] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CORD_X] [float] NULL,
[CORD_Y] [float] NULL,
[SERV_ADRS] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NATL_CODE] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NAME] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[JOIN_DATE] [date] NULL,
[REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RDUS_SRCH] [bigint] NULL,
[REF_SERV_FILE_NO] [bigint] NULL,
[REF_ROBO_RBID] [bigint] NULL,
[REF_CHAT_ID] [bigint] NULL,
[EXPR_DATE] [datetime] NULL,
[REAL_FRST_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REAL_LAST_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COMP_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OTHR_CELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OTHR_SERV_ADDR] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SRBT_DESC] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MRKT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[INST_USER_NAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CG$AINS_SRBT]
   ON  [dbo].[Service_Robot]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Service_Robot T
   USING (SELECT * FROM Inserted) S
   ON (T.SERV_FILE_NO = S.SERV_FILE_NO AND 
       T.ROBO_RBID = S.ROBO_RBID)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE();
   
   -- ایجاد کیف پول اعتباری برای مشتری
   INSERT INTO dbo.Wallet (SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,CODE ,CHAT_ID, WLET_TYPE)
   SELECT i.SERV_FILE_NO, i.ROBO_RBID, dbo.GNRT_NVID_U(), i.CHAT_ID, '001' /* نوع اعتباری */
     FROM Inserted i;   
   -- ایجاد کیف پول نقدینگی برای مشتری
   INSERT INTO dbo.Wallet (SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,CODE ,CHAT_ID, WLET_TYPE)
   SELECT i.SERV_FILE_NO, i.ROBO_RBID, dbo.GNRT_NVID_U(), i.CHAT_ID, '002' /* نوع نقدینگی */
     FROM Inserted i;
   
   -- ثبت اطلاعات مشتریان درون جدول پرسنل های ربات
   INSERT INTO dbo.Personal_Robot(SERV_FILE_NO ,ROBO_RBID ,STAT ,CHAT_ID ,NAME ,CELL_PHON ,DFLT_ACES )
   SELECT i.SERV_FILE_NO, i.ROBO_RBID, '002', i.CHAT_ID, i.NAME, i.CELL_PHON, '001'
     FROM Inserted i;
   
   -- ثبت پرسنل در گروه اعلام ها به صورت پیش فرض
   INSERT INTO dbo.Personal_Robot_Job(PRBT_SERV_FILE_NO ,PRBT_ROBO_RBID ,JOB_CODE ,STAT, BUSY_TYPE, SEQ_NUMB )
   SELECT i.SERV_FILE_NO, i.ROBO_RBID, j.CODE, '002', '002', 1
     FROM Inserted i, dbo.Personal_Robot pr, dbo.Job j
    WHERE i.SERV_FILE_NO = pr.SERV_FILE_NO
      AND i.ROBO_RBID = pr.ROBO_RBID
      AND i.CHAT_ID = pr.CHAT_ID
      AND j.ROBO_RBID = i.ROBO_RBID
      AND j.ORDR_TYPE IN ('012' /* اعلام ها */);
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
CREATE TRIGGER [dbo].[CG$AUPD_SRBT] ON [dbo].[Service_Robot]
    AFTER UPDATE
AS
 BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
   SET NOCOUNT ON;

   IF EXISTS ( SELECT  *
              FROM    dbo.Service_Robot t ,
                      Inserted s
              WHERE   t.SERV_FILE_NO != s.SERV_FILE_NO
                      AND t.ROBO_RBID = s.ROBO_RBID 
                      AND t.OTHR_CELL_PHON IS NOT NULL
                      AND LEN(t.OTHR_CELL_PHON) > 10
                      AND s.OTHR_CELL_PHON IS NOT NULL
                      AND LEN(s.OTHR_CELL_PHON) > 10
                      AND t.OTHR_CELL_PHON = s.OTHR_CELL_PHON)
   BEGIN
   RAISERROR (N'شما قادر به ذخیره کردن یک شماره برای چند مشترک نیستید', 16, 1);
   RETURN;
   END;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot T
   USING ( SELECT * FROM Inserted ) S
   ON ( T.SERV_FILE_NO = S.SERV_FILE_NO
        AND T.ROBO_RBID = S.ROBO_RBID )
   WHEN MATCHED THEN
       UPDATE SET
          T.MDFY_BY = UPPER(SUSER_NAME()) ,
          T.MDFY_DATE = GETDATE();
   
   -- اگر این مشتری توسط شخص دیگری دعوت شده باشد باید به صورت اتومات درون لیست فروش آن مشتری قرار بگیرد
   UPDATE sr
      SET sr.REF_CHAT_ID = sric.CHAT_ID,
          sr.REF_SERV_FILE_NO = sric.SRBT_SERV_FILE_NO,
          sr.REF_ROBO_RBID = sric.SRBT_ROBO_RBID
     FROM Service_Robot sr, Inserted i, Deleted d, dbo.Service_Robot_Inviting_Contact sric
    WHERE sr.SERV_FILE_NO = i.SERV_FILE_NO
      AND sr.ROBO_RBID = i.ROBO_RBID
      AND i.SERV_FILE_NO = d.SERV_FILE_NO
      AND i.ROBO_RBID = d.ROBO_RBID
      AND ISNULL(i.CELL_PHON, 'no mobile') != ISNULL(d.CELL_PHON, 'no mobile')
      AND dbo.CHK_MOBL_U(sr.CELL_PHON) = 1
      AND sr.CELL_PHON = sric.CONT_CELL_PHON;
   
   UPDATE sric
      SET sric.CONT_CHAT_ID = sr.CHAT_ID
     FROM Service_Robot sr, Inserted i, Deleted d, dbo.Service_Robot_Inviting_Contact sric
    WHERE sr.SERV_FILE_NO = i.SERV_FILE_NO
      AND sr.ROBO_RBID = i.ROBO_RBID
      AND i.SERV_FILE_NO = d.SERV_FILE_NO
      AND i.ROBO_RBID = d.ROBO_RBID
      AND ISNULL(i.CELL_PHON, 'no mobile') != ISNULL(d.CELL_PHON, 'no mobile')
      AND dbo.CHK_MOBL_U(sr.CELL_PHON) = 1
      AND sr.CELL_PHON = sric.CONT_CELL_PHON
      AND sric.CONT_CHAT_ID IS NULL;
 END;
GO
ALTER TABLE [dbo].[Service_Robot] ADD CONSTRAINT [PK_SRBT] PRIMARY KEY CLUSTERED  ([SERV_FILE_NO], [ROBO_RBID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot] ADD CONSTRAINT [FK_Service_Robot_Service_Robot] FOREIGN KEY ([REF_SERV_FILE_NO], [REF_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID])
GO
ALTER TABLE [dbo].[Service_Robot] ADD CONSTRAINT [FK_SRBT_GRPH] FOREIGN KEY ([GRPH_GHID]) REFERENCES [dbo].[Group_Header] ([GHID])
GO
ALTER TABLE [dbo].[Service_Robot] ADD CONSTRAINT [FK_ُSRBT_REGN] FOREIGN KEY ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE])
GO
ALTER TABLE [dbo].[Service_Robot] ADD CONSTRAINT [SRBT_ROBO_FK] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
ALTER TABLE [dbo].[Service_Robot] ADD CONSTRAINT [SRBT_SERV_FK] FOREIGN KEY ([SERV_FILE_NO]) REFERENCES [dbo].[Service] ([FILE_NO])
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان انقضا', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot', 'COLUMN', N'EXPR_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نام کاربری اینستاگرام', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot', 'COLUMN', N'INST_USER_NAME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'بازاریاب ربات فروشگاه انلاین', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot', 'COLUMN', N'MRKT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'معرف * کسی که این فرد رو به ربات دعوت کرده', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot', 'COLUMN', N'REF_CHAT_ID'
GO
