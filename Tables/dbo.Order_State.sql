CREATE TABLE [dbo].[Order_State]
(
[ORDR_CODE] [bigint] NULL,
[APBS_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[DISC_DCID] [bigint] NULL,
[GIFC_GCID] [bigint] NULL,
[WLDT_CODE] [bigint] NULL,
[STAT_DATE] [datetime] NULL,
[STAT_DESC] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AMNT] [bigint] NULL,
[AMNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RCPT_MTOD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SORC_CARD_NUMB] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEST_CARD_NUMB] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TXID] [varchar] (266) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TXFE_PRCT] [smallint] NULL,
[TXFE_CALC_AMNT] [bigint] NULL,
[TXFE_AMNT] [bigint] NULL,
[FILE_ID] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONF_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONF_DATE] [datetime] NULL,
[CONF_DESC] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_ODST]
   ON  [dbo].[Order_State]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- بررسی اینکه رسید های پرداختی تایید شده اطلاعات کامل را وارد کرده اند یا خیر   
   --IF EXISTS(
   --   SELECT *
   --     FROM Inserted i
   --    WHERE i.AMNT_TYPE = '005' -- رسید پرداخت
   --      AND i.CONF_STAT = '002' -- وضعیت تایید
   --      AND (
   --            ISNULL(i.AMNT, 0) = 0 OR
   --            LEN(i.TXID) = 0 
   --          )
   --)
   --BEGIN
   --   RAISERROR(N'لطفا برای تایید رسید های پرداخت فیلد های مبلغ و شماره پیگیری را وارد نمایید', 16, 1);
   --   RETURN;
   --END 
   
   -- Insert statements for trigger here
   --MERGE dbo.Order_State T
   --USING (SELECT * FROM Inserted) S
   --ON (t.CODE = s.CODE)
   --WHEN MATCHED THEN
   --   UPDATE SET 
   --      t.MDFY_BY = UPPER(SUSER_NAME())
   --     ,t.MDFY_DATE = GETDATE();
        
   
   -- 1396/07/25 * بروز کردن ستون های درآمد ، تخفیف و هزینه سفارش   
   --UPDATE o
   --   SET o.PYMT_AMNT_DNRM = (SELECT SUM(ISNULL(os.AMNT, 0)) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.CODE AND os.AMNT_TYPE = '001')
   --      ,o.DSCN_AMNT_DNRM = (SELECT SUM(ISNULL(os.AMNT, 0)) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.CODE AND os.AMNT_TYPE = '002')
   --      ,o.COST_AMNT_DNRM = (SELECT SUM(ISNULL(os.AMNT, 0)) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.CODE AND os.AMNT_TYPE = '003')         
   --      --,o.TXFE_PRCT_DNRM = s.TXFE_PRCT
   --      --,o.TXFE_CALC_AMNT_DNRM = (s.AMNT * ISNULL(s.TXFE_PRCT, 0) / 100)
   --  FROM dbo.[Order] o, Inserted s
   -- WHERE o.CODE = s.ORDR_CODE;
   
   UPDATE o
	   SET o.Expn_Amnt = (SELECT SUM(od.EXPN_PRIC * od.NUMB) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE)
	      ,o.EXTR_PRCT = (SELECT SUM(od.EXTR_PRCT * od.NUMB) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE)	      
	      ,o.PYMT_AMNT_DNRM = (SELECT SUM(os.AMNT) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.code AND os.AMNT_TYPE IN ('001', '005', '006') AND os.CONF_STAT = '002')
	      ,o.DSCN_AMNT_DNRM = (SELECT SUM(((od.EXPN_PRIC + od.EXTR_PRCT) * od.NUMB) * ISNULL(od.OFF_PRCT, 0) / 100 ) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE) + 
	                          (SELECT ISNULL(SUM(os.AMNT), 0) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.CODE AND os.AMNT_TYPE = '002' /* تخفیفات سفارش */)
         ,o.COST_AMNT_DNRM = (SELECT SUM(ISNULL(os.AMNT, 0)) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.CODE AND os.AMNT_TYPE = '003')         	                          
	  FROM dbo.[Order] o, Deleted s
    WHERE o.CODE = s.ORDR_CODE;
         
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
CREATE TRIGGER [dbo].[CG$AINS_ODST]
   ON  [dbo].[Order_State]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Order_State T
   USING (SELECT * FROM Inserted) S
   ON (t.ORDR_CODE = s.ORDR_CODE AND 
       ISNULL(t.APBS_CODE, 0) = ISNULL(s.APBS_CODE, 0) AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         t.CRET_BY = UPPER(SUSER_NAME())
        ,t.CRET_DATE = GETDATE()
        ,t.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END
        /*,T.TXFE_PRCT = (
            SELECT TXFE_PRCT 
              FROM dbo.Transaction_Fee 
             WHERE TXFE_TYPE = '001' 
               AND CALC_TYPE = '001' 
               AND STAT = '002'
               AND EXISTS(
                   SELECT *
                     FROM dbo.[Order] o
                    WHERE o.CODE = s.ORDR_CODE
                      AND o.ORDR_TYPE = '004'
               )
         )*/;
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
CREATE TRIGGER [dbo].[CG$AUPD_ODST]
   ON  [dbo].[Order_State]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- بررسی اینکه رسید های پرداختی تایید شده اطلاعات کامل را وارد کرده اند یا خیر   
   IF EXISTS(
      SELECT *
        FROM Inserted i
       WHERE i.AMNT_TYPE = '005' -- رسید پرداخت
         AND i.CONF_STAT = '002' -- وضعیت تایید
         AND (
               ISNULL(i.AMNT, 0) = 0 OR
               LEN(i.TXID) = 0 
             )
   )
   BEGIN
      RAISERROR(N'لطفا برای تایید رسید های پرداخت فیلد های مبلغ و شماره پیگیری را وارد نمایید', 16, 1);
      RETURN;
   END 
   
   -- Insert statements for trigger here
   MERGE dbo.Order_State T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         t.MDFY_BY = UPPER(SUSER_NAME())
        ,t.MDFY_DATE = GETDATE();
        
   
   -- 1396/07/25 * بروز کردن ستون های درآمد ، تخفیف و هزینه سفارش   
   --UPDATE o
   --   SET o.PYMT_AMNT_DNRM = (SELECT SUM(ISNULL(os.AMNT, 0)) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.CODE AND os.AMNT_TYPE = '001')
   --      ,o.DSCN_AMNT_DNRM = (SELECT SUM(ISNULL(os.AMNT, 0)) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.CODE AND os.AMNT_TYPE = '002')
   --      ,o.COST_AMNT_DNRM = (SELECT SUM(ISNULL(os.AMNT, 0)) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.CODE AND os.AMNT_TYPE = '003')         
   --      --,o.TXFE_PRCT_DNRM = s.TXFE_PRCT
   --      --,o.TXFE_CALC_AMNT_DNRM = (s.AMNT * ISNULL(s.TXFE_PRCT, 0) / 100)
   --  FROM dbo.[Order] o, Inserted s
   -- WHERE o.CODE = s.ORDR_CODE;
   
   UPDATE o
	   SET o.Expn_Amnt = (SELECT SUM(od.EXPN_PRIC * od.NUMB) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE)
	      ,o.EXTR_PRCT = (SELECT SUM(od.EXTR_PRCT * od.NUMB) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE)	      
	      ,o.PYMT_AMNT_DNRM = (SELECT SUM(os.AMNT) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.code AND os.AMNT_TYPE IN ('001', '005', '006') AND os.CONF_STAT = '002')
	      ,o.DSCN_AMNT_DNRM = (SELECT SUM(((od.EXPN_PRIC + od.EXTR_PRCT) * od.NUMB) * ISNULL(od.OFF_PRCT, 0) / 100 ) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE) + 
	                          (SELECT ISNULL(SUM(os.AMNT), 0) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.CODE AND os.AMNT_TYPE = '002' /* تخفیفات سفارش */)
         ,o.COST_AMNT_DNRM = (SELECT SUM(ISNULL(os.AMNT, 0)) FROM dbo.Order_State os WHERE os.ORDR_CODE = o.CODE AND os.AMNT_TYPE = '003')         	                          
	  FROM dbo.[Order] o, Inserted s
    WHERE o.CODE = s.ORDR_CODE;
         
END
GO
ALTER TABLE [dbo].[Order_State] ADD CONSTRAINT [PK_ODST] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Order_State] ADD CONSTRAINT [FK_ODST_APBS] FOREIGN KEY ([APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Order_State] ADD CONSTRAINT [FK_ODST_ORDR] FOREIGN KEY ([ORDR_CODE]) REFERENCES [dbo].[Order] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Order_State] ADD CONSTRAINT [FK_ODST_SRDC] FOREIGN KEY ([DISC_DCID]) REFERENCES [dbo].[Service_Robot_Discount_Card] ([DCID])
GO
ALTER TABLE [dbo].[Order_State] ADD CONSTRAINT [FK_ODST_SRGC] FOREIGN KEY ([GIFC_GCID]) REFERENCES [dbo].[Service_Robot_Gift_Card] ([GCID])
GO
ALTER TABLE [dbo].[Order_State] ADD CONSTRAINT [FK_ODST_WLDT] FOREIGN KEY ([WLDT_CODE]) REFERENCES [dbo].[Wallet_Detail] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ', 'SCHEMA', N'dbo', 'TABLE', N'Order_State', 'COLUMN', N'AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'هزینه یا درآمد', 'SCHEMA', N'dbo', 'TABLE', N'Order_State', 'COLUMN', N'AMNT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت ردیف ارسالی این گزینه در حال حاظر برای رسید های پرداخت شده مورد استفاده قرار میگیرد', 'SCHEMA', N'dbo', 'TABLE', N'Order_State', 'COLUMN', N'CONF_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد تخفیف اعلام شده درون سفارش', 'SCHEMA', N'dbo', 'TABLE', N'Order_State', 'COLUMN', N'DISC_DCID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'عکس رسید ارسال شده سمت مشتری', 'SCHEMA', N'dbo', 'TABLE', N'Order_State', 'COLUMN', N'FILE_ID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع فایل ارسال شده', 'SCHEMA', N'dbo', 'TABLE', N'Order_State', 'COLUMN', N'FILE_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد کارت هدیه استفاده شده درون سفارش', 'SCHEMA', N'dbo', 'TABLE', N'Order_State', 'COLUMN', N'GIFC_GCID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع پرداخت توسط کارت به کارت کردن یا درگاه پرداخت بانک ملی یا کد 
Ussd iNoti', 'SCHEMA', N'dbo', 'TABLE', N'Order_State', 'COLUMN', N'RCPT_MTOD'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ کارمزد مشتری', 'SCHEMA', N'dbo', 'TABLE', N'Order_State', 'COLUMN', N'TXFE_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ محاسبه شده کارمزد کارفرما', 'SCHEMA', N'dbo', 'TABLE', N'Order_State', 'COLUMN', N'TXFE_CALC_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درصد کارمزد کارفرما', 'SCHEMA', N'dbo', 'TABLE', N'Order_State', 'COLUMN', N'TXFE_PRCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کسر مبلغ پرداختی از اعتبار کیف پول', 'SCHEMA', N'dbo', 'TABLE', N'Order_State', 'COLUMN', N'WLDT_CODE'
GO
