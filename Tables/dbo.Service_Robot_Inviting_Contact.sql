CREATE TABLE [dbo].[Service_Robot_Inviting_Contact]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CHAT_ID] [bigint] NULL,
[CONT_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONT_CELL_PHON] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONT_CHAT_ID] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SRIC]
   ON  [dbo].[Service_Robot_Inviting_Contact]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Inviting_Contact T
   USING (SELECT * FROM Inserted) S
   ON (t.SRBT_SERV_FILE_NO = s.SRBT_SERV_FILE_NO AND 
       t.SRBT_ROBO_RBID = s.SRBT_ROBO_RBID AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END,
         T.CHAT_ID = ( SELECT sr.CHAT_ID
                         FROM dbo.Service_Robot sr
                        WHERE sr.SERV_FILE_NO = s.SRBT_SERV_FILE_NO
                          AND sr.ROBO_RBID = s.SRBT_ROBO_RBID);
   
   -- اگر ربات سامانه ارسال پیام از طریق سامانه پیامکی خود را فعال کرده باشد   
   IF EXISTS(SELECT * FROM dbo.Robot r, Inserted i WHERE r.RBID = i.SRBT_ROBO_RBID AND r.SEND_SMS_INVT_CONT = '002')
   BEGIN 
      INSERT INTO iProject.Msgb.Sms_Message_Box ( SUB_SYS ,LINE_TYPE ,ACTN_DATE ,PHON_NUMB ,MSGB_TEXT ,STAT, SEND_TYPE )
      SELECT 12, '001', GETDATE(), i.CONT_CELL_PHON, sr.NAME + CHAR(10) + N'بله را نصب کنید، من از آن برای پیام رسانی، خرید از فروشگاه های انلاین، پرداخت پول و ... استفاده می کنم.آن را به صورت رایگان در https://bale.ai/#download دریافت کنید', '001', '002'
        FROM Inserted i, dbo.Service_Robot sr
       WHERE sr.SERV_FILE_NO = i.SRBT_SERV_FILE_NO
         AND sr.ROBO_RBID = i.SRBT_ROBO_RBID;
   END 
   ELSE 
   BEGIN
      PRINT 'ارسال پیامی به صورت متنی و ایموجی برای مخاطب ارسال گردد که آن را برای شبکه های اجتماعی که خود از آن آگاه هست ارسال کند';
   END 
   
   DECLARE @Xtemp XML;
   
   
   -- 1399/08/15 * اگر سیستم پاداشی بابت اینکار برای مشتری در نظر گرفته باشد
   IF EXISTS (
      SELECT *
        FROM Inserted a, dbo.Robot_Tariff b, dbo.Transaction_Fee c
       WHERE a.SRBT_ROBO_RBID = b.ROBO_RBID
         AND b.TARF_TYPE = '001' -- Invited Contact
         AND b.STAT = '002' -- فعال
         AND c.TXFE_TYPE = '008' -- پاداش معرفی و ذخیره شماره جدید
         AND c.STAT = '002' -- فعال
   )
   BEGIN
      -- ثبت پاداش معرفی برای مشتری
      INSERT INTO dbo.Wallet_Detail (WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC)
      SELECT w.CODE, 0, r.AMNT_TYPE, t.TXFE_AMNT, GETDATE(), '001', '002', GETDATE(), N'افزایش مبلغ نقدینگی مشتری بابت ارسال شماره جدید مشتری'
        FROM dbo.Wallet w, dbo.Robot r, Inserted i, dbo.Transaction_Fee t
       WHERE w.SRBT_SERV_FILE_NO = i.SRBT_SERV_FILE_NO
         AND w.SRBT_ROBO_RBID = i.SRBT_ROBO_RBID
         AND w.SRBT_ROBO_RBID = r.RBID
         AND t.TXFE_TYPE = '008'
         AND t.STAT = '002'
         AND w.WLET_TYPE = '002'; -- کیف پول نقدینگی
      
      -- ثبت سند حسابداری درون سیستم
      SELECT @xTemp = (
         SELECT 5 AS '@subsys'
               ,'108' AS '@cmndcode' -- عملیات جامع ذخیره سازی
               ,12 AS '@refsubsys' -- محل ارجاعی
               ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
               ,sr.CHAT_ID AS '@refcode'
               ,sr.CHAT_ID AS '@refnumb' -- تعداد شماره درخواست ثبت شده
               ,GETDATE() AS '@strtdate'
               ,sr.CHAT_ID AS '@chatid'
               ,r.AMNT_TYPE AS '@amnttype'
               ,'001' AS '@pymtmtod'
               ,GETDATE() AS '@pymtdate'
               ,t.TXFE_AMNT AS '@amnt'
               ,i.CONT_CELL_PHON AS '@txid'
           FROM Inserted i, dbo.Service_Robot sr, dbo.Robot r, dbo.Transaction_Fee t
          WHERE i.SRBT_ROBO_RBID = r.RBID
            AND i.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
            AND i.SRBT_ROBO_RBID = sr.ROBO_RBID
            AND t.TXFE_TYPE = '008'
            AND t.STAT = '002'
            FOR XML PATH('Router_Command')
      );
      INSERT INTO dbo.logs
               ( x )
      VALUES   ( @Xtemp )
      L$StrtCalling1:
      EXEC dbo.RouterdbCommand @X = @xTemp, @xRet = @XTemp OUTPUT -- xml      
      --IF @XTemp.query('//Router_Command').value('(Router_Command/@needrecall)[1]', 'VARCHAR(3)') = '002'
      --BEGIN
      --   GOTO L$StrtCalling1;
      --END
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
CREATE TRIGGER [dbo].[CG$AUPD_SRIC]
   ON  [dbo].[Service_Robot_Inviting_Contact]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Inviting_Contact T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Service_Robot_Inviting_Contact] ADD CONSTRAINT [PK_Service_Robot_Inviting_Contact] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Inviting_Contact] ADD CONSTRAINT [FK_Service_Robot_Inviting_Contact_Service_Robot] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
