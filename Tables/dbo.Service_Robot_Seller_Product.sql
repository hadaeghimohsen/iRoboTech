CREATE TABLE [dbo].[Service_Robot_Seller_Product]
(
[SRBS_CODE] [bigint] NULL,
[RBPR_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[TARF_CODE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DELV_DAY] [smallint] NULL,
[DELV_HOUR] [smallint] NULL,
[DELV_MINT] [smallint] NULL,
[MAKE_DAY] [smallint] NULL,
[MAKE_HOUR] [smallint] NULL,
[MAKE_MINT] [smallint] NULL,
[WREH_INVR_NUMB] [real] NULL,
[MAX_SALE_DAY_NUMB] [real] NULL,
[SALE_NUMB_DNRM] [real] NULL,
[CRNT_NUMB_DNRM] [real] NULL,
[SALE_CART_NUMB_DNRM] [real] NULL,
[ALRM_MIN_NUMB] [real] NULL,
[PROD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MIN_ORDR] [real] NULL,
[MADE_IN] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GRNT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GRNT_NUMB] [int] NULL,
[GRNT_TIME] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GRNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GRNT_DESC] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WRNT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WRNT_NUMB] [int] NULL,
[WRNT_TIME] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WRNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WRNT_DESC] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WEGH_AMNT] [real] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[CHAT_ID] [bigint] NULL
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
CREATE TRIGGER [dbo].[CG$AINS_SRSP]
   ON  [dbo].[Service_Robot_Seller_Product]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Seller_Product T
   USING (SELECT * FROM Inserted) S
   ON (t.SRBS_CODE = s.SRBS_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
       T.CRET_BY = UPPER(SUSER_NAME()),
       T.CRET_DATE = GETDATE(),
       T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
       T.RBPR_CODE = (
		    SELECT TOP 1 rp.CODE
		      FROM dbo.Robot_Product rp, dbo.Service_Robot_Seller sl
		     WHERE TARF_CODE = s.TARF_CODE
		       AND sl.CODE = s.SRBS_CODE
		       AND rp.ROBO_RBID = sl.SRBT_ROBO_RBID
       ),
       T.CHAT_ID = (
          SELECT srs.CHAT_ID
            FROM dbo.Service_Robot_Seller srs
           WHERE srs.CODE = s.SRBS_CODE
       );
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
CREATE TRIGGER [dbo].[CG$AUPD_SRSP]
   ON  [dbo].[Service_Robot_Seller_Product]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Seller_Product T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
       T.MDFY_BY = UPPER(SUSER_NAME()),
       T.MDFY_DATE = GETDATE(),
       T.WREH_INVR_NUMB = ISNULL(s.WREH_INVR_NUMB, 0),
       T.MAX_SALE_DAY_NUMB = ISNULL(s.MAX_SALE_DAY_NUMB, 0),       
       T.CRNT_NUMB_DNRM = ISNULL(S.CRNT_NUMB_DNRM, 0),
       T.ALRM_MIN_NUMB = ISNULL(S.ALRM_MIN_NUMB, 0),
       T.MIN_ORDR = ISNULL(s.MIN_ORDR, 1),
       t.MADE_IN = ISNULL(s.MADE_IN, '054'),
       T.GRNT_STAT = ISNULL(S.GRNT_STAT, '001'),
       T.GRNT_NUMB = ISNULL(S.GRNT_NUMB, 1),
       T.GRNT_TIME = ISNULL(S.GRNT_TIME, '003'),
       T.GRNT_TYPE = ISNULL(S.GRNT_TYPE, '001'),
       T.WRNT_STAT = ISNULL(S.WRNT_STAT, '001'),
       T.WRNT_NUMB = ISNULL(S.WRNT_NUMB, 1),
       T.WRNT_TIME = ISNULL(S.WRNT_TIME, '003'),
       T.WRNT_TYPE = ISNULL(S.WRNT_TYPE, '001'),
       T.SALE_NUMB_DNRM = CASE 
                           WHEN ISNULL(s.SALE_NUMB_DNRM, 0) = 0 THEN 
                           (
                              SELECT ISNULL(SUM(od.NUMB), 0)
                                FROM dbo.[Order] o, dbo.Order_Detail od
                               WHERE o.ORDR_TYPE = '004'
                                 AND EXISTS(SELECT * FROM dbo.Order_Step_History osh WHERE o.CODE = osh.ORDR_CODE AND osh.ORDR_STAT = '004')
                                 AND CAST(o.STRT_DATE AS DATE) = CAST(GETDATE() AS DATE)
                                 AND o.CODE = od.ORDR_CODE
                                 AND od.TARF_CODE = s.TARF_CODE
                           )
                           ELSE s.SALE_NUMB_DNRM
                          END,
       T.SALE_CART_NUMB_DNRM = (
         SELECT ISNULL(SUM(od.NUMB), 0)
           FROM dbo.[Order] o, dbo.Order_Detail od
          WHERE o.ORDR_TYPE = '004'
            AND o.ORDR_STAT = '001'
            AND CAST(o.STRT_DATE AS DATE) = CAST(GETDATE() AS DATE)
            AND o.CODE = od.ORDR_CODE
            AND od.TARF_CODE = s.TARF_CODE
       );
  
   -- بروزرسانی اطلاعات کالا در جدول ربات
   MERGE dbo.Robot_Product T
   USING ( SELECT srs.SRBT_ROBO_RBID AS ROBO_RBID, i.TARF_CODE, i.WREH_INVR_NUMB, i.MAX_SALE_DAY_NUMB, i.SALE_NUMB_DNRM, i.CRNT_NUMB_DNRM, 
                  p.SALE_CART_NUMB_DNRM, i.ALRM_MIN_NUMB, i.PROD_TYPE, i.MIN_ORDR, i.MADE_IN,
                  i.GRNT_STAT, i.GRNT_NUMB, i.GRNT_TIME, i.GRNT_TYPE, i.GRNT_DESC, i.WRNT_STAT, i.WRNT_NUMB, i.WRNT_TIME, i.WRNT_TYPE, i.WRNT_DESC, i.WEGH_AMNT,
                  i.DELV_DAY, i.DELV_HOUR, i.DELV_MINT, i.MAKE_DAY, i.MAKE_HOUR, i.MAKE_MINT
             FROM dbo.Service_Robot_Seller srs, Inserted i, dbo.Service_Robot_Seller_Product p
            WHERE srs.CODE = i.SRBS_CODE
              AND p.CODE = i.CODE ) S
   ON ( T.ROBO_RBID = S.ROBO_RBID AND
        T.TARF_CODE = S.TARF_CODE )
   WHEN MATCHED THEN 
      UPDATE SET
         T.WERH_INVR_NUMB_DNRM = ISNULL(s.WREH_INVR_NUMB, 0),
         T.MAX_SALE_DAY_NUMB_DNRM = ISNULL(s.MAX_SALE_DAY_NUMB, 0), 
         T.SALE_NUMB_DNRM = ISNULL(s.SALE_NUMB_DNRM, 0),
         T.CRNT_NUMB_DNRM = ISNULL(s.CRNT_NUMB_DNRM, 0),
         t.SALE_CART_NUMB_DNRM = ISNULL(s.SALE_CART_NUMB_DNRM, 0),
         t.ALRM_MIN_NUMB_DNRM = ISNULL(s.ALRM_MIN_NUMB, 0),
         t.PROD_TYPE_DNRM = ISNULL(s.PROD_TYPE, '002'),
         t.MIN_ORDR_DNRM = ISNULL(s.MIN_ORDR, 1),
         T.MADE_IN_DNRM = ISNULL(s.MADE_IN, '054'),
         T.DELV_DAY_DNRM = ISNULL(s.DELV_DAY, 0),
         T.DELV_HOUR_DNRM = ISNULL(s.DELV_HOUR, 0),
         T.DELV_MINT_DNRM = ISNULL(s.DELV_MINT, 0),
         T.MAKE_DAY_DNRM = ISNULL(s.MAKE_DAY, 0),
         T.MAKE_HOUR_DNRM = ISNULL(s.MAKE_HOUR, 0),
         T.MAKE_MINT_DNRM = ISNULL(s.MAKE_MINT, 0),
         T.GRNT_STAT_DNRM = ISNULL(s.GRNT_STAT, '002'),
         T.GRNT_NUMB_DNRM = ISNULL(s.GRNT_NUMB, 1),
         T.GRNT_TIME_DNRM = ISNULL(s.GRNT_TIME, '003'),
         T.GRNT_TYPE_DNRM = ISNULL(s.GRNT_TYPE, '001'),
         T.GRNT_DESC_DNRM = ISNULL(s.GRNT_DESC, N''),
         T.WRNT_STAT_DNRM = ISNULL(s.WRNT_STAT, '002'),
         T.WRNT_NUMB_DNRM = ISNULL(s.WRNT_NUMB, 1),
         T.WRNT_TIME_DNRM = ISNULL(s.WRNT_TIME, '003'),
         T.WRNT_TYPE_DNRM = ISNULL(s.WRNT_TYPE, '001'),
         T.WRNT_DESC_DNRM = ISNULL(s.WRNT_DESC, N''),
         T.WEGH_AMNT_DNRM = ISNULL(s.WEGH_AMNT, 1000);
	
END
GO
ALTER TABLE [dbo].[Service_Robot_Seller_Product] ADD CONSTRAINT [PK_SRSP] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Seller_Product] ADD CONSTRAINT [FK_SRSP_RBPR] FOREIGN KEY ([RBPR_CODE]) REFERENCES [dbo].[Robot_Product] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Seller_Product] ADD CONSTRAINT [FK_SRSP_SRBS] FOREIGN KEY ([SRBS_CODE]) REFERENCES [dbo].[Service_Robot_Seller] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداقل موجودی برای شارژ مجدد کالا', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'ALRM_MIN_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'موجودی فعلی', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'CRNT_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد روز تحویل', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'DELV_DAY'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد ساعت تحویل', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'DELV_HOUR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد دقیقه تحویل', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'DELV_MINT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد زمان گرانتی', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'GRNT_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ایا محصول دارای گارانتی می باشد یا خیر', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'GRNT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ماه یا سال', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'GRNT_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع ضمانت گارانتی', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'GRNT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کشور تولید کننده', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'MADE_IN'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد روز ساخت', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'MAKE_DAY'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد ساعت ساخت', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'MAKE_HOUR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد دقیقه ساخت', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'MAKE_MINT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداکثر فروش روزانه', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'MAX_SALE_DAY_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداقل سفارش', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'MIN_ORDR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع محصول * کالا یا خدمات', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'PROD_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد فروش درون سبد خرید', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'SALE_CART_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد فروش نهایی شده', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'SALE_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وزن کالا بر اساس واحد گرم', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'WEGH_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'موجودی انبار', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product', 'COLUMN', N'WREH_INVR_NUMB'
GO
