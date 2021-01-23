CREATE TABLE [dbo].[Wallet_Detail]
(
[TXFE_TFID] [bigint] NULL,
[ORDR_CODE] [bigint] NULL,
[WLET_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [int] NULL,
[CHAT_ID] [bigint] NULL,
[AMNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AMNT] [bigint] NULL,
[AMNT_DATE] [datetime] NULL,
[AMNT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONF_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONF_DATE] [datetime] NULL,
[CONF_DESC] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRNT_WLET_AMNT_DNRM] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_WLDT]
   ON  [dbo].[Wallet_Detail]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   DECLARE C$WDINS CURSOR FOR
      SELECT i.CODE
        FROM Inserted i;
   
   DECLARE @Code BIGINT;
   
   OPEN [C$WDINS];
   L$Loop$C$WDINS:
   FETCH [C$WDINS] INTO @Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndLoop$C$WDINS;
      
   -- Insert statements for trigger here
   MERGE dbo.Wallet_Detail T
   USING (SELECT * FROM Inserted) S
   ON (t.WLET_CODE = s.WLET_CODE AND 
       t.CODE = s.CODE AND 
       t.CODE = @Code)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END,
         T.RWNO = (SELECT ISNULL(MAX(wd.RWNO), 0) + 1 FROM dbo.Wallet_Detail wd WHERE wd.WLET_CODE = s.WLET_CODE),
         T.CHAT_ID = (
            SELECT w.CHAT_ID
              FROM dbo.Wallet w
             WHERE w.CODE = s.WLET_CODE
         ),
         t.CRNT_WLET_AMNT_DNRM = CASE s.CONF_STAT 
                                      WHEN '002' THEN 
                                           CASE s.AMNT_STAT
                                                WHEN '001' THEN (SELECT ISNULL(w.AMNT_DNRM, 0) FROM dbo.Wallet w WHERE w.CODE = s.WLET_CODE) + ISNULL(s.AMNT, 0)
                                                WHEN '002' THEN (SELECT ISNULL(w.AMNT_DNRM, 0) FROM dbo.Wallet w WHERE w.CODE = s.WLET_CODE) - ISNULL(s.AMNT, 0)
                                           END 
                                      ELSE 0 
                                 END;
   
   GOTO L$Loop$C$WDINS;
   L$EndLoop$C$WDINS:
   CLOSE [C$WDINS];
   DEALLOCATE [C$WDINS];   
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
CREATE TRIGGER [dbo].[CG$AUPD_WLDT]
   ON  [dbo].[Wallet_Detail]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   --RETURN;
   -- Insert statements for trigger here
   MERGE dbo.Wallet_Detail T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
         /*T.CRNT_WLET_AMNT_DNRM = CASE s.CONF_STAT 
                                      WHEN '002' THEN 
                                           CASE s.AMNT_STAT
                                                WHEN '001' THEN (SELECT ISNULL(w.AMNT_DNRM, 0) FROM dbo.Wallet w WHERE w.CODE = s.WLET_CODE) + ISNULL(s.AMNT, 0)
                                                WHEN '002' THEN (SELECT ISNULL(w.AMNT_DNRM, 0) FROM dbo.Wallet w WHERE w.CODE = s.WLET_CODE) - ISNULL(s.AMNT, 0)
                                           END 
                                      ELSE 0 
                                 END;*/
   
   -- برورسانی تمامی پورسانت هایی که واریز به حساب کیف پول مشتریان بشود
   DECLARE C$WldtConf003 CURSOR FOR
      SELECT wd.CODE
        FROM dbo.Wallet_Detail wd
       WHERE wd.CONF_STAT = '003'
         AND wd.AMNT_STAT = '001'
         AND CAST(wd.CONF_DATE AS DATE) <= CAST(GETDATE() AS DATE)
       ORDER BY wd.RWNO;
   
   DECLARE @WldtCode BIGINT;
   
   OPEN [C$WldtConf003];
   L$WldtConf003Loop:
   FETCH [C$WldtConf003] INTO @WldtCode;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$WldtConf003EndLoop;
   
   UPDATE wd
      SET wd.CONF_STAT = '002',
          wd.CRNT_WLET_AMNT_DNRM = ISNULL(w.AMNT_DNRM, 0) + ISNULL(wd.AMNT, 0)
     FROM dbo.Wallet_Detail wd, dbo.Wallet w
    WHERE wd.WLET_CODE = w.CODE
      AND wd.CODE = @WldtCode
      AND wd.CONF_STAT = '003'
      AND wd.AMNT_STAT = '001' -- مبلغ های ورودی
      /*AND wd.CONF_DATE <= GETDATE() /* مبلغ های ورودی مدت دار که باید تایید شوند */
      */;   
   
   -- بروزرسانی کیف پول مشتری
   UPDATE w
      SET w.AMNT_DNRM = (SELECT SUM(CASE wd.AMNT_STAT WHEN '001' THEN wd.AMNT ELSE -wd.AMNT END) FROM dbo.Wallet_Detail wd WHERE w.CODE = wd.WLET_CODE AND wd.CONF_STAT = '002' AND ISNULL(wd.RWNO, 0) >= 1),
          w.LAST_IN_AMNT_DNRM = (SELECT wd.AMNT FROM dbo.Wallet_Detail wd WHERE wd.WLET_CODE = w.CODE AND wd.AMNT_STAT = '001' AND wd.CONF_STAT = '002' AND wd.RWNO = (SELECT MAX(wdt.RWNO) FROM dbo.Wallet_Detail wdt WHERE w.CODE = wdt.WLET_CODE AND wdt.AMNT_STAT = '001' AND wdt.CONF_STAT = '002')),
          w.LAST_IN_DATE_DNRM = (SELECT wd.AMNT_DATE FROM dbo.Wallet_Detail wd WHERE wd.WLET_CODE = w.CODE AND wd.AMNT_STAT = '001' AND wd.CONF_STAT = '002' AND wd.RWNO = (SELECT MAX(wdt.RWNO) FROM dbo.Wallet_Detail wdt WHERE w.CODE = wdt.WLET_CODE AND wdt.AMNT_STAT = '001' AND wdt.CONF_STAT = '002')),
          w.LAST_OUT_AMNT_DNRM = (SELECT wd.AMNT FROM dbo.Wallet_Detail wd WHERE wd.WLET_CODE = w.CODE AND wd.AMNT_STAT = '002' AND wd.CONF_STAT = '002' AND wd.RWNO = (SELECT MAX(wdt.RWNO) FROM dbo.Wallet_Detail wdt WHERE w.CODE = wdt.WLET_CODE AND wdt.AMNT_STAT = '002' AND wdt.CONF_STAT = '002')),
          w.LAST_OUT_DATE_DNRM = (SELECT wd.AMNT_DATE FROM dbo.Wallet_Detail wd WHERE wd.WLET_CODE = w.CODE AND wd.AMNT_STAT = '002' AND wd.CONF_STAT = '002' AND wd.RWNO = (SELECT MAX(wdt.RWNO) FROM dbo.Wallet_Detail wdt WHERE w.CODE = wdt.WLET_CODE AND wdt.AMNT_STAT = '002' AND wdt.CONF_STAT = '002'))
     FROM dbo.Wallet w, Inserted i
    WHERE w.CODE = i.WLET_CODE
      AND i.CODE = @WldtCode;
   
   GOTO L$WldtConf003Loop;
   L$WldtConf003EndLoop:
   CLOSE [C$WldtConf003];
   DEALLOCATE [C$WldtConf003];

   -- بروزرسانی کیف پول مشتری
   UPDATE w
      SET w.AMNT_DNRM = (SELECT SUM(CASE wd.AMNT_STAT WHEN '001' THEN wd.AMNT ELSE -wd.AMNT END) FROM dbo.Wallet_Detail wd WHERE w.CODE = wd.WLET_CODE AND wd.CONF_STAT = '002' AND ISNULL(wd.RWNO, 0) >= 1),
          w.LAST_IN_AMNT_DNRM = (SELECT wd.AMNT FROM dbo.Wallet_Detail wd WHERE wd.WLET_CODE = w.CODE AND wd.AMNT_STAT = '001' AND wd.CONF_STAT = '002' AND wd.RWNO = (SELECT MAX(wdt.RWNO) FROM dbo.Wallet_Detail wdt WHERE w.CODE = wdt.WLET_CODE AND wdt.AMNT_STAT = '001' AND wdt.CONF_STAT = '002')),
          w.LAST_IN_DATE_DNRM = (SELECT wd.AMNT_DATE FROM dbo.Wallet_Detail wd WHERE wd.WLET_CODE = w.CODE AND wd.AMNT_STAT = '001' AND wd.CONF_STAT = '002' AND wd.RWNO = (SELECT MAX(wdt.RWNO) FROM dbo.Wallet_Detail wdt WHERE w.CODE = wdt.WLET_CODE AND wdt.AMNT_STAT = '001' AND wdt.CONF_STAT = '002')),
          w.LAST_OUT_AMNT_DNRM = (SELECT wd.AMNT FROM dbo.Wallet_Detail wd WHERE wd.WLET_CODE = w.CODE AND wd.AMNT_STAT = '002' AND wd.CONF_STAT = '002' AND wd.RWNO = (SELECT MAX(wdt.RWNO) FROM dbo.Wallet_Detail wdt WHERE w.CODE = wdt.WLET_CODE AND wdt.AMNT_STAT = '002' AND wdt.CONF_STAT = '002')),
          w.LAST_OUT_DATE_DNRM = (SELECT wd.AMNT_DATE FROM dbo.Wallet_Detail wd WHERE wd.WLET_CODE = w.CODE AND wd.AMNT_STAT = '002' AND wd.CONF_STAT = '002' AND wd.RWNO = (SELECT MAX(wdt.RWNO) FROM dbo.Wallet_Detail wdt WHERE w.CODE = wdt.WLET_CODE AND wdt.AMNT_STAT = '002' AND wdt.CONF_STAT = '002'))
     FROM dbo.Wallet w, Inserted i
    WHERE w.CODE = i.WLET_CODE;
    

END
GO
ALTER TABLE [dbo].[Wallet_Detail] ADD CONSTRAINT [PK_WLDT] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Wallet_Detail] ADD CONSTRAINT [FK_WLDT_ORDR] FOREIGN KEY ([ORDR_CODE]) REFERENCES [dbo].[Order] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Wallet_Detail] ADD CONSTRAINT [FK_WLDT_TXFE] FOREIGN KEY ([TXFE_TFID]) REFERENCES [dbo].[Transaction_Fee] ([TFID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Wallet_Detail] ADD CONSTRAINT [FK_WLDT_WLET] FOREIGN KEY ([WLET_CODE]) REFERENCES [dbo].[Wallet] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'ورودی یا خروجی', 'SCHEMA', N'dbo', 'TABLE', N'Wallet_Detail', 'COLUMN', N'AMNT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'واحد ریالی یا تومانی', 'SCHEMA', N'dbo', 'TABLE', N'Wallet_Detail', 'COLUMN', N'AMNT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ تایید
این گزینه را برای این گذاشته ایم که مشتریانی که به واسطه فروشی یا هر گزینه ی دیگری که انجام میشود و مبلغی به عنوان ورودی بخواهیم برایشان ثبت کنیم شاید در همان لحظه نتوان مبلغ را ذخیره کرد باید برای مدتی این مبلغ در وضعیت تایید نشده قرار بگیرد که سیستم آن را به صورت تایید شده ذخیره کند', 'SCHEMA', N'dbo', 'TABLE', N'Wallet_Detail', 'COLUMN', N'CONF_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'دلیل تاییدیه یا عدم تاییدیه', 'SCHEMA', N'dbo', 'TABLE', N'Wallet_Detail', 'COLUMN', N'CONF_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آیا پول تایید شده یا خیر', 'SCHEMA', N'dbo', 'TABLE', N'Wallet_Detail', 'COLUMN', N'CONF_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'موجودی کیف پول زمانی که ردیف جاری تایید میشود', 'SCHEMA', N'dbo', 'TABLE', N'Wallet_Detail', 'COLUMN', N'CRNT_WLET_AMNT_DNRM'
GO
