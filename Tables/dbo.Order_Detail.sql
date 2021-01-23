CREATE TABLE [dbo].[Order_Detail]
(
[ORDR_CODE] [bigint] NOT NULL,
[RWNO] [bigint] NOT NULL IDENTITY(1, 1),
[ELMN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR_DESC] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BUY_PRIC_DNRM] [bigint] NULL,
[EXPN_PRIC] [bigint] NULL,
[EXTR_PRCT] [bigint] NULL,
[PRFT_PRIC_DNRM] [bigint] NULL,
[SUM_EXPN_PRIC_DNRM] [bigint] NULL,
[SUM_PRFT_PRIC_DNRM] [bigint] NULL,
[TAX_PRCT] [int] NULL,
[OFF_PRCT] [real] NULL,
[OFF_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OFF_KIND] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DSCN_AMNT_DNRM] [bigint] NULL,
[NUMB] [real] NULL,
[BASE_USSD_CODE] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUB_USSD_CODE] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR_CMNT] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR_IMAG] [image] NULL,
[IMAG_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MIME_TYPE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_EXT] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GHIT_CODE] [bigint] NULL,
[GHIT_MIN_DATE] [datetime] NULL,
[GHIT_MAX_DATE] [datetime] NULL,
[SEND_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TARF_CODE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UNIT_APBS_CODE_DNRM] [bigint] NULL,
[UNIT_DESC_DNRM] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TARF_DATE] [date] NULL,
[RQTP_CODE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SRBS_CODE_DNRM] [bigint] NULL,
[DELV_TIME_DNRM] [datetime] NULL,
[MAKE_TIME_DNRM] [datetime] NULL,
[INLN_KEYB_DNRM] [xml] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[SRSP_CODE] [bigint] NULL
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
CREATE TRIGGER [dbo].[CG$ADEL_ORDT]
   ON  [dbo].[Order_Detail]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   UPDATE p
      SET p.SALE_CART_NUMB_DNRM = NULL
     FROM dbo.[Order] o, dbo.Order_Detail od, Deleted d, dbo.Service_Robot_Seller_Product p
    WHERE od.ORDR_CODE = d.ORDR_CODE
      AND od.TARF_CODE = d.TARF_CODE
      AND od.TARF_CODE = p.TARF_CODE
      AND od.ORDR_CODE = o.CODE
      AND o.ORDR_TYPE IN ('004');
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
CREATE TRIGGER [dbo].[CG$AINS_ORDT]
   ON  [dbo].[Order_Detail]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
    -- Insert statements for trigger here
   MERGE dbo.Order_Detail T
   USING (SELECT Inserted.ORDR_CODE, Inserted.RWNO FROM Inserted) S
   ON (t.ORDR_CODE = s.ORDR_CODE AND 
       t.RWNO = s.RWNO)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,T.DELV_TIME_DNRM = 0;
   
   -- بروز رسانی اطلاعات محصول از فروشندگان و تعداد روز تحویل کالا
   UPDATE a
      SET a.MAKE_TIME_DNRM = DATEADD(MINUTE, ISNULL(b.MAKE_MINT, 0) + ISNULL(b.MAKE_HOUR, 0) * 60 + ISNULL(b.MAKE_DAY, 0) * 24 * 60 , GETDATE()),
          a.DELV_TIME_DNRM = DATEADD(MINUTE, ISNULL(b.DELV_MINT, 0) + ISNULL(b.DELV_HOUR, 0) * 60 + ISNULL(b.DELV_DAY, 0) * 24 * 60 , GETDATE()),
          a.SRBS_CODE_DNRM = b.SRBS_CODE,
          a.UNIT_APBS_CODE_DNRM = rp.UNIT_APBS_CODE,
          a.UNIT_DESC_DNRM = rp.UNIT_DESC_DNRM,
          a.BUY_PRIC_DNRM = CASE ISNULL(a.BUY_PRIC_DNRM, 0) WHEN 0 THEN ISNULL(rp.BUY_PRIC, 0) ELSE a.BUY_PRIC_DNRM END,
          a.PRFT_PRIC_DNRM = CASE ISNULL(a.PRFT_PRIC_DNRM, 0) WHEN 0 THEN ISNULL(rp.PRFT_PRIC_DNRM, 0) ELSE a.PRFT_PRIC_DNRM END
     FROM dbo.Order_Detail a, dbo.Service_Robot_Seller_Product b, Inserted i, dbo.Robot_Product rp
    WHERE a.ORDR_CODE = i.ORDR_CODE
      AND a.TARF_CODE = b.TARF_CODE
      AND b.RBPR_CODE = rp.CODE;
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
CREATE TRIGGER [dbo].[CG$AUPD_ORDT]
   ON  [dbo].[Order_Detail]
   AFTER UPDATE  
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
    -- Insert statements for trigger here
   MERGE dbo.Order_Detail T
   USING (SELECT i.ORDR_CODE, i.RWNO, i.TARF_CODE, 
                 ISNULL(i.EXPN_PRIC, 0) EXPN_PRIC, 
                 ISNULL(i.EXTR_PRCT, 0) EXTR_PRCT, 
                 ISNULL(i.NUMB, 0) NUMB, 
                 ISNULL(i.OFF_PRCT, 0) OFF_PRCT, 
                 ISNULL(i.TAX_PRCT, 0) TAX_PRCT                 
            FROM Inserted i) S
   ON (t.ORDR_CODE = s.ORDR_CODE AND 
       t.RWNO = s.RWNO)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE()        
        ,T.SEND_STAT = ISNULL(T.SEND_STAT, '001')
        ,t.DSCN_AMNT_DNRM = CASE WHEN s.OFF_PRCT > 0 THEN (s.EXPN_PRIC * s.OFF_PRCT) * S.NUMB / 100 ELSE 0 END 
        ,T.EXTR_PRCT = CASE WHEN s.OFF_PRCT > 0 THEN (s.EXPN_PRIC - (s.EXPN_PRIC * s.OFF_PRCT / 100)) * S.TAX_PRCT / 100 ELSE s.EXPN_PRIC * s.TAX_PRCT / 100 END
        ,T.SUM_EXPN_PRIC_DNRM = (S.EXPN_PRIC + S.EXTR_PRCT) * S.NUMB
        ,T.SUM_PRFT_PRIC_DNRM = T.PRFT_PRIC_DNRM * S.NUMB;
   
   UPDATE p
      SET p.SALE_CART_NUMB_DNRM = NULL
     FROM dbo.[Order] o, dbo.Order_Detail od, Inserted d, dbo.Service_Robot_Seller_Product p
    WHERE od.ORDR_CODE = d.ORDR_CODE
      AND od.TARF_CODE = d.TARF_CODE
      AND od.TARF_CODE = p.TARF_CODE
      AND od.ORDR_CODE = o.CODE
      AND o.ORDR_TYPE IN ('004');
END
GO
ALTER TABLE [dbo].[Order_Detail] ADD CONSTRAINT [PK_ORDT] PRIMARY KEY CLUSTERED  ([ORDR_CODE], [RWNO]) ON [BLOB]
GO
ALTER TABLE [dbo].[Order_Detail] ADD CONSTRAINT [FK_ORDT_GHIT] FOREIGN KEY ([GHIT_CODE]) REFERENCES [dbo].[Group_Header_Item] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Order_Detail] ADD CONSTRAINT [FK_ORDT_ORDR] FOREIGN KEY ([ORDR_CODE]) REFERENCES [dbo].[Order] ([CODE]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Order_Detail] ADD CONSTRAINT [FK_ORDT_SRBS] FOREIGN KEY ([SRBS_CODE_DNRM]) REFERENCES [dbo].[Service_Robot_Seller] ([CODE])
GO
ALTER TABLE [dbo].[Order_Detail] ADD CONSTRAINT [FK_ORDT_SRSPR] FOREIGN KEY ([SRSP_CODE]) REFERENCES [dbo].[Service_Robot_Seller_Partner] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'قیمت خرید', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'BUY_PRIC_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان تحویل کالا', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'DELV_TIME_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ تخفیف محاسبه شده', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'DSCN_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درصد تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'OFF_PRCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'OFF_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سود فروش', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'PRFT_PRIC_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع فرآیند زیر سیستم', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'RQTP_CODE_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'این گزینه برای این می باشد که بتوانیم در هر لحظه پیام جدیدی که لازم هست به درخواست اضافه کنیم اضافه شود و پیام های جدید ارسال  کنیم و نیاز به ثبت درخواست جدید نباشد', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'SEND_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'فروشنده محصول', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'SRBS_CODE_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد نرخ قیمت همکار', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'SRSP_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ فروش با محاسبه تعداد فروش', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'SUM_EXPN_PRIC_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سود فروش با محاسبه تعداد فروش', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'SUM_PRFT_PRIC_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'این گزینه برای زیر سیستم های زیر مانند نرم افزار مدیرتی ارتا مورد استفاده قرار میگیرد که مشتری با وارد کردن این کد تعرفه می تواند خود را در گروهی تمدید کند', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'TARF_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ اعلام تعرفه در زیر سیستم', 'SCHEMA', N'dbo', 'TABLE', N'Order_Detail', 'COLUMN', N'TARF_DATE'
GO
