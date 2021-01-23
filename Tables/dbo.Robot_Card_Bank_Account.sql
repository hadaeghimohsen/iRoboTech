CREATE TABLE [dbo].[Robot_Card_Bank_Account]
(
[ROBO_RBID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CARD_NUMB] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CARD_NUMB_DNRM] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHBA_NUMB] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHBA_NUMB_DNRM] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BANK_NAME] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACNT_OWNR] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACNT_DESC] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACNT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[IDPY_ADRS] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CG$AINS_RCBA]
   ON  [dbo].[Robot_Card_Bank_Account]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Card_Bank_Account T
   USING (SELECT * FROM Inserted) S
   ON (
      T.ROBO_RBID = s.ROBO_RBID AND
      T.CODE = s.CODE
   )
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
   
   -- 1399/09/03 * اگر حساب فروشنده باشد
   IF EXISTS (SELECT * FROM Inserted i WHERE i.ACNT_TYPE = '002')
   BEGIN
      INSERT INTO dbo.Service_Robot_Card_Bank ( SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,RCBA_CODE ,CODE )
      SELECT sr.SERV_FILE_NO, sr.ROBO_RBID, a.CODE, dbo.GNRT_NVID_U()
        FROM Inserted i, dbo.Service_Robot sr, dbo.Service_Robot_Group srg, dbo.Robot_Card_Bank_Account a
       WHERE i.ROBO_RBID = sr.ROBO_RBID
         AND sr.SERV_FILE_NO = srg.SRBT_SERV_FILE_NO
         AND sr.ROBO_RBID = srg.SRBT_ROBO_RBID
         AND i.ROBO_RBID = a.ROBO_RBID
         AND i.CARD_NUMB = a.CARD_NUMB
         AND i.ACNT_TYPE = a.ACNT_TYPE
         AND i.ORDR_TYPE = a.ORDR_TYPE
         AND srg.GROP_GPID IN (131 /* گروه مدیریان فروشگاه */)
         AND srg.STAT = '002'
   END 
   
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
CREATE TRIGGER [dbo].[CG$AUPD_RCBA]
   ON  [dbo].[Robot_Card_Bank_Account]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Card_Bank_Account T
   USING (SELECT * FROM Inserted) S
   ON (      
      T.CODE = s.CODE
   )
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE()
        ,T.CARD_NUMB_DNRM = 
            CASE
               WHEN S.CARD_NUMB IS NULL OR LEN(S.CARD_NUMB) != 16 THEN NULL
               ELSE SUBSTRING(s.CARD_NUMB, 1, 4) + '-' + 
                    SUBSTRING(s.CARD_NUMB, 5, 4) + '-' +
                    SUBSTRING(s.CARD_NUMB, 9, 4) + '-' +
                    SUBSTRING(s.CARD_NUMB, 13, 4) 
            END,
         T.SHBA_NUMB_DNRM = 
            CASE
               WHEN S.SHBA_NUMB IS NULL OR LEN(S.SHBA_NUMB) != 26 THEN NULL
               ELSE SUBSTRING(s.SHBA_NUMB, 1, 4) + ' ' + 
                    SUBSTRING(s.SHBA_NUMB, 5, 4) + ' ' +
                    SUBSTRING(s.SHBA_NUMB, 9, 4) + ' ' +
                    SUBSTRING(s.SHBA_NUMB, 13, 4) + ' ' + 
                    SUBSTRING(s.SHBA_NUMB, 17, 4) + ' ' + 
                    SUBSTRING(s.SHBA_NUMB, 21, 4) + ' ' +
                    SUBSTRING(s.SHBA_NUMB, 25, 4)                     
            END
        ,T.BANK_NAME = 
            CASE 
               WHEN S.CARD_NUMB IS NULL OR LEN(S.CARD_NUMB) != 16 THEN NULL               
               ELSE CASE SUBSTRING(s.CARD_NUMB, 1, 6)
                         WHEN '603799' THEN N'بانک ملی ایران' -- 1
                         WHEN '589210' THEN N'بانک سپه' -- 2
                         WHEN '627648' THEN N'بانک توسعه صاردات' -- 3
                         WHEN '207177' THEN N'بانک توسعه صاردات' -- 3
                         WHEN '627961' THEN N'بانک صنعت معدن' -- 4
                         WHEN '603770' THEN N'بانک کشاورزی' -- 5
                         WHEN '639217' THEN N'بانک کشاورزی' -- 5
                         WHEN '628023' THEN N'بانک مسکن' -- 6
                         WHEN '627760' THEN N'پست بانک ایران' -- 7
                         WHEN '502908' THEN N'بانک توسعه تعاون' -- 8
                         WHEN '627412' THEN N'بانک اقتصاد نوین' -- 9
                         WHEN '622106' THEN N'بانک پارسیان' -- 10
                         WHEN '639194' THEN N'بانک پارسیان' -- 10
                         WHEN '627884' THEN N'بانک پارسیان' -- 10                        
                         WHEN '639347' THEN N'بانک پاسارگاد' -- 11
                         WHEN '502229' THEN N'بانک پاسارگاد' -- 11
                         WHEN '627488' THEN N'بانک کار آفرین' -- 12
                         WHEN '502910' THEN N'بانک کار آفرین' -- 12
                         WHEN '621986' THEN N'بانک سامان' -- 13
                         WHEN '639346' THEN N'بانک سینا' -- 14
                         WHEN '639607' THEN N'بانک سرمایه' -- 15
                         WHEN '636214' THEN N'بانک تات' -- 16
                         WHEN '502806' THEN N'بانک شهر' -- 17
                         WHEN '504706' THEN N'بانک شهر' -- 17
                         WHEN '502938' THEN N'بانک دی' -- 18
                         WHEN '603769' THEN N'بانک صادرات' -- 19
                         WHEN '610433' THEN N'بانک ملت' -- 20
                         WHEN '991975' THEN N'بانک ملت' -- 20
                         WHEN '585983' THEN N'بانک تجارت' -- 21
                         WHEN '627353' THEN N'بانک تجارت' -- 21
                         WHEN '589463' THEN N'بانک رفاه' -- 22
                         WHEN '627381' THEN N'بانک انصار' -- 23
                         WHEN '505785' THEN N'بانک ایران زمین' -- 24
                         WHEN '636795' THEN N'بانک مرکزی' -- 25
                         WHEN '636949' THEN N'بانک حکمت ایرانیان' -- 26
                         WHEN '505416' THEN N'بانک گردشگری' -- 27
                         WHEN '606373' THEN N'بانک قرض الحسنه مهر ایران' -- 28
                         WHEN '628157' THEN N'موسسه اعتباری توسعه' -- 29
                         WHEN '505801' THEN N'موسسه مالی اعتباری کوثر' -- 30
                         WHEN '639370' THEN N'موسسه مالی اعتباری مهر' -- 31
                         WHEN '639599' THEN N'بانک قوامین' -- 32
                         WHEN '504172' THEN N'بانک رسالت' -- 33
                    END 
            END ;
   
   -- 1399/09/03
   MERGE dbo.Service_Robot_Card_Bank T
   USING (SELECT * FROM Inserted) S
   ON (T.RCBA_CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CARD_NUMB_DNRM = s.CARD_NUMB;
END
GO
ALTER TABLE [dbo].[Robot_Card_Bank_Account] ADD CONSTRAINT [PK_RCBA] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Card_Bank_Account] ADD CONSTRAINT [FK_RCBA_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'توضیحات', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Card_Bank_Account', 'COLUMN', N'ACNT_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'صاحب حساب', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Card_Bank_Account', 'COLUMN', N'ACNT_OWNR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت حساب', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Card_Bank_Account', 'COLUMN', N'ACNT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اعداد با خروجی 4 رقمی', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Card_Bank_Account', 'COLUMN', N'CARD_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شناسه درگاه آی دی پی', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Card_Bank_Account', 'COLUMN', N'IDPY_ADRS'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع درخواست
سفارش
هزینه کارمزد پرداخت
هزینه شارژ خدمات شبکه های اجتماعی
هزینه پشتیبانی سالیانه', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Card_Bank_Account', 'COLUMN', N'ORDR_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره شبا', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Card_Bank_Account', 'COLUMN', N'SHBA_NUMB'
GO
