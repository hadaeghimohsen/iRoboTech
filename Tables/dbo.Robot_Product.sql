CREATE TABLE [dbo].[Robot_Product]
(
[ROBO_RBID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[TARF_CODE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPN_PRIC_DNRM] [bigint] NULL,
[EXTR_PRCT_DNRM] [bigint] NULL,
[BUY_PRIC] [bigint] NULL,
[PRFT_PRIC_DNRM] [bigint] NULL,
[UNIT_APBS_CODE] [bigint] NULL,
[UNIT_DESC_DNRM] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RTNG_NUMB_DNRM] [real] NULL,
[RTNG_CONT_DNRM] [int] NULL,
[PROD_FETR] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TARF_TEXT_DNRM] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TARF_ENGL_TEXT] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REVW_CONT_DNRM] [int] NULL,
[BRND_TEXT_DNRM] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BRND_CODE_DNRM] [bigint] NULL,
[GROP_TEXT_DNRM] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GROP_CODE_DNRM] [bigint] NULL,
[ROOT_GROP_CODE_DNRM] [bigint] NULL,
[ROOT_GROP_DESC_DNRM] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GROP_JOIN_DNRM] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR_CONT_DNRM] [bigint] NULL,
[VIST_CONT_DNRM] [bigint] NULL,
[LIKE_CONT_DNRM] [bigint] NULL,
[BEST_SLNG_CONT_DNRM] [bigint] NULL,
[DELV_DAY_DNRM] [smallint] NULL,
[DELV_HOUR_DNRM] [smallint] NULL,
[DELV_MINT_DNRM] [smallint] NULL,
[MAKE_DAY_DNRM] [smallint] NULL,
[MAKE_HOUR_DNRM] [smallint] NULL,
[MAKE_MINT_DNRM] [smallint] NULL,
[RELS_TIME] [datetime] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WERH_INVR_NUMB_DNRM] [real] NULL,
[MAX_SALE_DAY_NUMB_DNRM] [real] NULL,
[SALE_NUMB_DNRM] [real] NULL,
[CRNT_NUMB_DNRM] [real] NULL,
[SALE_CART_NUMB_DNRM] [real] NULL,
[ALRM_MIN_NUMB_DNRM] [real] NULL,
[PROD_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MIN_ORDR_DNRM] [real] NULL,
[MADE_IN_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GRNT_STAT_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GRNT_NUMB_DNRM] [int] NULL,
[GRNT_TIME_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GRNT_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GRNT_DESC_DNRM] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WRNT_STAT_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WRNT_NUMB_DNRM] [int] NULL,
[WRNT_TIME_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WRNT_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WRNT_DESC_DNRM] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WEGH_AMNT_DNRM] [real] NULL,
[NUMB_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[PROD_LIFE_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PROD_SUPL_LOCT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PROD_SUPL_LOCT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RESP_SHIP_COST_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[APRX_SHIP_COST_AMNT] [bigint] NULL,
[CRNC_CALC_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRNC_EXPN_AMNT] [money] NULL,
[BAR_CODE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CG$ADEL_RBPR]
   ON  [dbo].[Robot_Product]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   IF EXISTS (SELECT name FROM sys.databases WHERE name = N'iScsc')
	BEGIN
	   DELETE iScsc.dbo.Expense_Item
	    WHERE CODE IN (
	          SELECT et.EPIT_CODE
	            FROM iScsc.dbo.Expense_Type et, iScsc.dbo.Expense e, Deleted d
	           WHERE et.CODE = e.EXTP_CODE
	             AND e.ORDR_ITEM = d.TARF_CODE
	    );
	   
	   DELETE iScsc.dbo.Expense_Type
	    WHERE CODE IN (
	          SELECT e.EXTP_CODE
	            FROM iScsc.dbo.Expense e, Deleted d
	           WHERE e.ORDR_ITEM = d.TARF_CODE
	    );
	   
	   DELETE iScsc.dbo.Expense 
	    WHERE ORDR_ITEM IN (
	          SELECT d.TARF_CODE
	            FROM Deleted d
	    );
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
CREATE TRIGGER [dbo].[CG$AINS_RBPR]
   ON  [dbo].[Robot_Product]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Product T
   USING (SELECT * FROM Inserted) S
   ON (t.ROBO_RBID = s.ROBO_RBID AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
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
CREATE TRIGGER [dbo].[CG$AUPD_RBPR]
   ON  [dbo].[Robot_Product]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
   -- Insert statements for trigger here
   MERGE dbo.Robot_Product T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE()
        ,T.RTNG_NUMB_DNRM = (SELECT ISNULL(AVG(srpr.RATE_NUMB), 0) FROM dbo.Service_Robot_Product_Rating srpr WHERE s.CODE = srpr.RBPR_CODE)
        ,T.RTNG_CONT_DNRM = (SELECT COUNT(srpr.CODE) FROM dbo.Service_Robot_Product_Rating srpr WHERE s.CODE = srpr.RBPR_CODE)
        ,T.REVW_CONT_DNRM = (SELECT COUNT(srpr.CODE) FROM dbo.Service_Robot_Product_Rating srpr WHERE s.CODE = srpr.RBPR_CODE AND (srpr.TITL_TEXT IS NOT NULL OR srpr.RATE_TEXT IS NOT NULL))
        ,T.UNIT_DESC_DNRM = (SELECT TITL_DESC FROM dbo.App_Base_Define WHERE CODE = s.UNIT_APBS_CODE)
        ,T.BUY_PRIC = ISNULL(s.BUY_PRIC, 0)
        ,T.PRFT_PRIC_DNRM = (s.EXPN_PRIC_DNRM + s.EXTR_PRCT_DNRM) - ISNULL(s.BUY_PRIC, 0);
   
   DECLARE @CnctAcntApp VARCHAR(3), @AcntTypeApp VARCHAR(3);
   SELECT TOP 1 @CnctAcntApp = r.CNCT_ACNT_APP, @AcntTypeApp = r.ACNT_APP_TYPE
     FROM dbo.Robot r, Inserted i
    WHERE r.RBID = i.ROBO_RBID;
   
   DECLARE C$Rbpr CURSOR FOR
      SELECT i.CODE, i.TARF_CODE, i.TARF_TEXT_DNRM, i.TARF_ENGL_TEXT, i.BRND_TEXT_DNRM, i.GROP_TEXT_DNRM, i.GROP_JOIN_DNRM, i.EXPN_PRIC_DNRM, i.EXTR_PRCT_DNRM, i.ROOT_GROP_DESC_DNRM
        FROM Inserted i;
   
   DECLARE @Code BIGINT, @TarfCode VARCHAR(100),
           @TarfTextDnrm NVARCHAR(250), @TarfEnglText NVARCHAR(250),
           @BrndTextDnrm NVARCHAR(250), @GropTextDnrm NVARCHAR(250),
           @BrndCodeDnrm BIGINT, @GropCodeDnrm BIGINT, @GropJoinDnrm VARCHAR(50),
           @ExpnPric BIGINT, @ExtrPrct BIGINT, @RootGropCodeDnrm BIGINT, @RootGropDescDnrm NVARCHAR(250);
   
   OPEN [C$Rbpr];
   L$Loop1:
   FETCH [C$Rbpr] INTO @Code, @TarfCode, @TarfTextDnrm, @TarfEnglText, @BrndTextDnrm, @GropTextDnrm, @GropJoinDnrm, @ExpnPric, @ExtrPrct, @RootGropDescDnrm;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndLoop1;
   
   IF @CnctAcntApp = '002' -- آیا ربات به نرم افزار حسابداری متصل می باشد
   BEGIN
      IF @AcntTypeApp = '001' -- نرم افزار مدیریتی ارتا
      BEGIN
         -- گزینه هایی که ما از آنها برای نرم افزار خودمان اطلاعاتی داریم         
         IF @TarfTextDnrm IS NULL OR @GropTextDnrm IS NULL OR 
            @BrndTextDnrm IS NULL OR @TarfTextDnrm = '' OR 
            @GropTextDnrm = '' OR @BrndTextDnrm = '' OR
            @GropJoinDnrm = '' OR 
            @ExpnPric IS NULL OR @ExtrPrct IS NULL OR
            @RootGropDescDnrm = ''
         BEGIN
            SELECT @TarfTextDnrm = e.EXPN_DESC, @GropTextDnrm = ge.GROP_DESC, @BrndTextDnrm = be.GROP_DESC,
                   @BrndCodeDnrm = be.CODE, @GropCodeDnrm = ge.CODE, @GropJoinDnrm = e.RELY_CMND,
                   @ExpnPric = e.PRIC, @ExtrPrct = e.EXTR_PRCT,
                   @RootGropDescDnrm = iScsc.dbo.GET_GEXP_U(ge.Code), @RootGropCodeDnrm = iScsc.dbo.GETC_GEXP_U(ge.CODE)
              FROM iScsc.dbo.Expense e INNER JOIN 
                   iScsc.dbo.Expense_Type et ON e.EXTP_CODE = et.CODE INNER JOIN
                   iScsc.dbo.Request_Requester rr ON rr.CODE = et.RQRQ_CODE INNER JOIN                   
                   iScsc.dbo.Regulation rg ON rg.YEAR = rr.REGL_YEAR AND rg.CODE = rr.REGL_CODE 
                   LEFT OUTER JOIN iScsc.dbo.Group_Expense ge ON e.GROP_CODE = ge.CODE AND ge.GROP_TYPE = '001' -- گروه بندی کالا
                   LEFT OUTER JOIN iScsc.dbo.Group_Expense be ON e.BRND_CODE = be.CODE AND be.GROP_TYPE = '002' -- برند کالا                                                    
             WHERE e.ORDR_ITEM = @TarfCode
               AND e.EXTP_CODE = et.CODE
               AND et.RQRQ_CODE = rr.CODE
               AND rr.REGL_YEAR = rg.YEAR
               AND rr.REGL_CODE = rg.CODE
               AND rg.REGL_STAT = '002'
               AND rg.[TYPE] = '001'
               AND rr.RQTP_CODE = '016';
            
            UPDATE dbo.Robot_Product
               SET TARF_TEXT_DNRM = @TarfTextDnrm
                  ,GROP_TEXT_DNRM = @GropTextDnrm
                  ,BRND_TEXT_DNRM = @BrndTextDnrm
                  ,GROP_CODE_DNRM = @GropCodeDnrm
                  ,BRND_CODE_DNRM = @BrndCodeDnrm
                  ,GROP_JOIN_DNRM = @GropJoinDnrm
                  ,ROOT_GROP_CODE_DNRM = @RootGropCodeDnrm
                  ,ROOT_GROP_DESC_DNRM = @RootGropDescDnrm
                  ,EXPN_PRIC_DNRM = @ExpnPric
                  ,EXTR_PRCT_DNRM = @ExtrPrct
             WHERE CODE = @Code;
         END 
      END 
   END 
   
   GOTO L$Loop1;   
   L$EndLoop1:
   CLOSE [C$Rbpr];
   DEALLOCATE [C$Rbpr];	
END
GO
ALTER TABLE [dbo].[Robot_Product] ADD CONSTRAINT [PK_RBPR] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Product] ADD CONSTRAINT [FK_RBPR_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Robot_Product] ADD CONSTRAINT [FK_Robot_Product_App_Base_Define] FOREIGN KEY ([UNIT_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'آگاهی جهت حداقل رسیدن موجودی کالاها', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'ALRM_MIN_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ هزینه باربری و حمل و نقل', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'APRX_SHIP_COST_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'پر فروش ترین', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'BEST_SLNG_CONT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'عنوان برند', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'BRND_TEXT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'قیمت خرید', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'BUY_PRIC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'محاسبه مبلغ محصول بر اساس نرخ ارز', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'CRNC_CALC_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'قیمت محصول به نرخ ارز مورد نظر', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'CRNC_EXPN_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'موجودی فعلی قفسه فروش', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'CRNT_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد روز تحویل', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'DELV_DAY_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد ساعت تحویل', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'DELV_HOUR_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد دقیقه تحویل', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'DELV_MINT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ کالا', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'EXPN_PRIC_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارزش افزوده کالا', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'EXTR_PRCT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'گروه سرپرستی که بتوان چندین کالا را بهم مرتبط کرد
مثلا کالای کفش نایک با رنگ های مختلف
در این قسمت ما رنگ زرد، قرمز، ، آبی را داریم که هر سه یک کالا را در نظر داریم ولی با رنگ های مختلف از هم جدا میشوند و با این کد می تواند کالا های مرتبط را پیدا کرد', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'GROP_JOIN_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'عنوان گروه', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'GROP_TEXT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد محبوبیت', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'LIKE_CONT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کشور تولید کننده', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'MADE_IN_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد روز تولید', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'MAKE_DAY_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد ساعت تولید', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'MAKE_HOUR_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد دقیقه تولید', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'MAKE_MINT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداکثر فروش روزانه', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'MAX_SALE_DAY_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع تعداد فروش', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'NUMB_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد فروش', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'ORDR_CONT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سود فروش محصول', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'PRFT_PRIC_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ویژگی های محصول', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'PROD_FETR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت دستگاه
دامنه D$PROT', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'PROD_LIFE_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نمایش محل تامین و ارسال کالا', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'PROD_SUPL_LOCT_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت نمایش محل تامین و ارسال کالا', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'PROD_SUPL_LOCT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع محصول * کالا یا خدمات', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'PROD_TYPE_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان انتشار', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'RELS_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'عهده دار هزینه باربری و حمل و نقل', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'RESP_SHIP_COST_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد دیدگاه کاربران', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'REVW_CONT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد امتیاز دهندگان', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'RTNG_CONT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'امتیاز بندی کالا توسط کاربران', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'RTNG_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'موجودی سبد خرید مشتریان', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'SALE_CART_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد کالای فروخته شده', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'SALE_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت محصول', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'عنوان لاتین', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'TARF_ENGL_TEXT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'عنوان فارسی', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'TARF_TEXT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'واحد کالا', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'UNIT_APBS_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد بازدید', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'VIST_CONT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وزن کالا بر اساس گرم', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'WEGH_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'موجودی انبار', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product', 'COLUMN', N'WERH_INVR_NUMB_DNRM'
GO
