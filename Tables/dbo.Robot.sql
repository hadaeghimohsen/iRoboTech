CREATE TABLE [dbo].[Robot]
(
[ORGN_OGID] [bigint] NOT NULL,
[ROBO_RBID] [bigint] NULL,
[RBID] [bigint] NOT NULL IDENTITY(1, 1),
[COPY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BOT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NAME] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TKON_CODE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CHCK_INTR] [int] NOT NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Robot_STAT] DEFAULT ('002'),
[BULD_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BULD_FILE_ID] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SPY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRTB_URL] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DOWN_LOAD_FILE_PATH] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UP_LOAD_FILE_PATH] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INVT_FRND] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SEND_SMS_INVT_CONT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HASH_TAG] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[POST_ADRS] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CORD_X] [float] NULL,
[CORD_Y] [float] NULL,
[CELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EMAL_ADRS] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WEB_SITE] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RUN_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AMNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CNCT_ACNT_APP] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACNT_APP_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PAGE_FECH_ROWS] [int] NULL,
[MIN_WITH_DRAW] [bigint] NULL,
[CONF_DURT_DAY] [int] NULL,
[AUTO_SHIP_CORI] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHOW_INVR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VIEW_INVR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FREE_SHIP_INCT_AMNT] [bigint] NULL,
[FREE_SHIP_OTCT_AMNT] [bigint] NULL,
[ORDR_EXPR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR_EXPR_TIME] [int] NULL,
[LOCL_SRVR_CONN_STRN] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WEB_SRVR_CONN_STRN] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXTR_SORC_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SLCT_SRVR_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NOTI_ORDR_SHIP_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NOTI_SOND_ORDR_SHIP_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NOTI_ORDR_RCPT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NOTI_SOND_ORDR_RCPT_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NOTI_ORDR_RECP_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NOTI_SOND_ORDR_RECP_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[CHCK_REGS_STRT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRNC_CALC_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RBCR_CODE] [bigint] NULL,
[CRNC_AMNT_DNRM] [bigint] NULL,
[CRNC_AUTO_UPDT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRNC_CYCL_AUTO_UPDT] [int] NULL,
[CRNC_HOW_UPDT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================  
-- Author:  <Author,,Name>  
-- Create date: <Create Date,,>  
-- Description: <Description,,>  
-- =============================================  
CREATE TRIGGER [dbo].[CG$AINS_ROBO]  
   ON  [dbo].[Robot]  
   AFTER insert 
AS   
BEGIN  
    -- SET NOCOUNT ON added to prevent extra result sets from  
    -- interfering with SELECT statements.  
    SET NOCOUNT ON;  
  
    -- Insert statements for trigger here  
    MERGE dbo.Robot T  
    USING (Select * FROM Inserted )s  
    ON (T.RBID = S.RBID)  
    WHEN MATCHED THEN  
     UPDATE  
      SET T.CRET_BY = UPPER(SUSER_NAME())
         ,T.CRET_DATE = GETDATE();  
  
    -- ثبت ردیف های شغلی به صورت پیش فرض برای ربات
    INSERT INTO dbo.Job (ROBO_RBID ,ORDR_TYPE ,JOB_DESC)
    SELECT i.ROBO_RBID, d.VALU, d.DOMN_DESC
      FROM Inserted i, dbo.[D$ORDT] d
     WHERE d.VALU NOT IN ('009', '013', '014', '015', '016', '021', '022');
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================  
-- Author:  <Author,,Name>  
-- Create date: <Create Date,,>  
-- Description: <Description,,>  
-- =============================================  
CREATE TRIGGER [dbo].[CG$AUPD_ROBO]  
   ON  [dbo].[Robot]  
   AFTER update
AS   
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for trigger here  
 MERGE dbo.Robot T  
 USING (Select * FROM Inserted )s  
 ON (T.RBID = S.RBID)  
 WHEN MATCHED THEN  
  UPDATE  
   SET T.Mdfy_BY = UPPER(SUSER_NAME())
      ,T.Mdfy_DATE = GETDATE()
      ,T.ACNT_APP_TYPE = CASE s.CNCT_ACNT_APP WHEN '001' THEN NULL ELSE s.ACNT_APP_TYPE END
      ,T.CHCK_REGS_STRT = ISNULL(s.CHCK_REGS_STRT, '001');
 
 -- 1399/10/30 * آن دسته از محصولاتی که نرخ آنها بر اساس نرخ ارز محاسبه میشود باید بروزرسانی شود
 IF EXISTS (
    SELECT * 
      FROM Inserted i , Deleted d
     WHERE i.RBID = d.RBID
       AND ISNULL(i.CRNC_CALC_STAT, '001') = '002'
       AND i.RBCR_CODE IS NOT NULL
       AND ISNULL(i.CRNC_AMNT_DNRM, 0) <> ISNULL(d.CRNC_AMNT_DNRM, 0)
 )
 BEGIN
   DECLARE @Rbid BIGINT,
           @CrncHowUpdtStat VARCHAR(3),
           @NewCrncAmnt BIGINT,
           @OldCrncAmnt BIGINT,
           @CrncAutoUpdtStat VARCHAR(3);
   
   SELECT @Rbid = i.RBID,
          @CrncHowUpdtStat = ISNULL(i.CRNC_HOW_UPDT_STAT, '000'),
          @CrncAutoUpdtStat = ISNULL(i.CRNC_AUTO_UPDT_STAT, '001'),
          @NewCrncAmnt = ISNULL(i.CRNC_AMNT_DNRM, 0),
          @OldCrncAmnt = ISNULL(d.CRNC_AMNT_DNRM, 0)
     FROM Inserted i , Deleted d
    WHERE i.RBID = d.RBID
      AND ISNULL(i.CRNC_CALC_STAT, '001') = '002'
      AND i.RBCR_CODE IS NOT NULL
      AND ISNULL(i.CRNC_AMNT_DNRM, 0) <> ISNULL(d.CRNC_AMNT_DNRM, 0);
   
   -- اگر بروزرسانی قیمت محصولات به صورت اتومات باشد
   IF @CrncAutoUpdtStat = '002'
   BEGIN
      IF (@CrncHowUpdtStat = '001' AND @NewCrncAmnt > @OldCrncAmnt) OR 
         (@CrncHowUpdtStat = '002' AND @NewCrncAmnt < @OldCrncAmnt) OR 
         (@CrncHowUpdtStat = '003')
      BEGIN
         --PRINT N'با افزایش نرخ ارز قیمت افزایش پیدا کند'
         --PRINT N'با کاهش نرخ ارز قیمت کاهش پیدا کند'
         --PRINT N'با افزایش نرخ قیمت افزایش با کاهش نرخ قیمت کاهش'
         DECLARE @CODE BIGINT,                          @ROBO_RBID BIGINT,                @TARF_CODE VARCHAR(100),
                 @EXPN_PRIC_DNRM BIGINT,                @EXTR_PRCT_DNRM BIGINT,           @BUY_PRIC BIGINT,
                 @UNIT_APBS_CODE BIGINT,                @PROD_FETR NVARCHAR(MAX),         @TARF_TEXT_DNRM NVARCHAR(250),
                 @TARF_ENGL_TEXT NVARCHAR(250),         @BRND_CODE_DNRM BIGINT,           @GROP_CODE_DNRM BIGINT,
                 @GROP_JOIN_DNRM VARCHAR(50),           @DELV_DAY_DNRM SMALLINT,          @DELV_HOUR_DNRM SMALLINT,
                 @DELV_MINT_DNRM SMALLINT,              @MAKE_DAY_DNRM SMALLINT,          @MAKE_HOUR_DNRM SMALLINT,
                 @MAKE_MINT_DNRM SMALLINT,              @RELS_TIME DATETIME,              @STAT VARCHAR(3),
                 @ALRM_MIN_NUMB_DNRM REAL,              @PROD_TYPE_DNRM VARCHAR(3),       @MIN_ORDR_DNRM REAL,
                 @MADE_IN_DNRM VARCHAR(3),              @GRNT_STAT_DNRM VARCHAR(3),       @GRNT_NUMB_DNRM INT,
                 @GRNT_TIME_DNRM VARCHAR(3),            @GRNT_TYPE_DNRM VARCHAR(3),       @GRNT_DESC_DNRM NVARCHAR(4000),
                 @WRNT_STAT_DNRM VARCHAR(3),            @WRNT_NUMB_DNRM INT,              @WRNT_TIME_DNRM VARCHAR(3),
                 @WRNT_TYPE_DNRM VARCHAR(3),            @WRNT_DESC_DNRM NVARCHAR(4000),   @WEGH_AMNT_DNRM REAL,
                 @NUMB_TYPE VARCHAR(3),                 @PROD_LIFE_STAT VARCHAR(3),       @PROD_SUPL_LOCT_STAT VARCHAR(3),
                 @PROD_SUPL_LOCT_DESC NVARCHAR(250),    @RESP_SHIP_COST_TYPE VARCHAR(3),  @APRX_SHIP_COST_AMNT BIGINT,
                 @CRNC_CALC_STAT VARCHAR(3),            @CRNC_EXPN_AMNT MONEY;
                 
         DECLARE C$ProdCC CURSOR FOR
            SELECT [CODE],[TARF_CODE],[EXPN_PRIC_DNRM],[EXTR_PRCT_DNRM],[BUY_PRIC],[UNIT_APBS_CODE]
                  ,[PROD_FETR],[TARF_TEXT_DNRM],[TARF_ENGL_TEXT],[BRND_CODE_DNRM],[GROP_CODE_DNRM]
                  ,[GROP_JOIN_DNRM],[DELV_DAY_DNRM],[DELV_HOUR_DNRM],[DELV_MINT_DNRM],[MAKE_DAY_DNRM],[MAKE_HOUR_DNRM],[MAKE_MINT_DNRM]
                  ,[RELS_TIME],[STAT],[ALRM_MIN_NUMB_DNRM],[PROD_TYPE_DNRM],[MIN_ORDR_DNRM],[MADE_IN_DNRM],[GRNT_STAT_DNRM]
                  ,[GRNT_NUMB_DNRM],[GRNT_TIME_DNRM],[GRNT_TYPE_DNRM],[GRNT_DESC_DNRM],[WRNT_STAT_DNRM],[WRNT_NUMB_DNRM]
                  ,[WRNT_TIME_DNRM],[WRNT_TYPE_DNRM],[WRNT_DESC_DNRM],[WEGH_AMNT_DNRM],[NUMB_TYPE],[PROD_LIFE_STAT]
                  ,[PROD_SUPL_LOCT_STAT],[PROD_SUPL_LOCT_DESC],[RESP_SHIP_COST_TYPE],[APRX_SHIP_COST_AMNT],[CRNC_CALC_STAT]
                  ,[CRNC_EXPN_AMNT]
              FROM dbo.Robot_Product rp
             WHERE rp.ROBO_RBID = @Rbid
               AND rp.CRNC_CALC_STAT = '002';
         
         OPEN [C$ProdCC];
         FETCH [C$ProdCC] INTO @CODE ,@TARF_CODE  ,@EXPN_PRIC_DNRM  ,@EXTR_PRCT_DNRM , @BUY_PRIC  ,@UNIT_APBS_CODE  ,
         @PROD_FETR  ,@TARF_TEXT_DNRM ,@TARF_ENGL_TEXT ,@BRND_CODE_DNRM  ,@GROP_CODE_DNRM  ,@GROP_JOIN_DNRM  ,
         @DELV_DAY_DNRM  ,@DELV_HOUR_DNRM  ,@DELV_MINT_DNRM  ,@MAKE_DAY_DNRM  ,@MAKE_HOUR_DNRM  ,@MAKE_MINT_DNRM  ,
         @RELS_TIME  ,@STAT  ,@ALRM_MIN_NUMB_DNRM  ,@PROD_TYPE_DNRM  ,@MIN_ORDR_DNRM  ,@MADE_IN_DNRM  ,
         @GRNT_STAT_DNRM  ,@GRNT_NUMB_DNRM  ,@GRNT_TIME_DNRM  ,@GRNT_TYPE_DNRM  ,@GRNT_DESC_DNRM  ,
         @WRNT_STAT_DNRM  ,@WRNT_NUMB_DNRM  ,@WRNT_TIME_DNRM  ,@WRNT_TYPE_DNRM  ,@WRNT_DESC_DNRM  ,
         @WEGH_AMNT_DNRM  ,@NUMB_TYPE , @PROD_LIFE_STAT, @PROD_SUPL_LOCT_STAT,
         @PROD_SUPL_LOCT_DESC, @RESP_SHIP_COST_TYPE, @APRX_SHIP_COST_AMNT, @CRNC_CALC_STAT, @CRNC_EXPN_AMNT ;
         
         SET @EXPN_PRIC_DNRM = @CRNC_EXPN_AMNT * @NewCrncAmnt;
               
         EXEC dbo.UPD_RBPR_P @CODE = @CODE, -- bigint
            @ROBO_RBID = @Rbid, -- bigint
            @TARF_CODE = @TARF_CODE, -- varchar(100)
            @EXPN_PRIC_DNRM = @EXPN_PRIC_DNRM, -- bigint  ** Update Column
            @EXTR_PRCT_DNRM = @EXTR_PRCT_DNRM, -- bigint
            @BUY_PRIC = @BUY_PRIC, -- bigint
            @UNIT_APBS_CODE = @UNIT_APBS_CODE, -- bigint
            @PROD_FETR = @PROD_FETR, -- nvarchar(max)
            @TARF_TEXT_DNRM = @TARF_TEXT_DNRM, -- nvarchar(250)
            @TARF_ENGL_TEXT = @TARF_ENGL_TEXT, -- nvarchar(250)
            @BRND_CODE_DNRM = @BRND_CODE_DNRM, -- bigint
            @GROP_CODE_DNRM = @GROP_CODE_DNRM, -- bigint
            @GROP_JOIN_DNRM = @GROP_JOIN_DNRM, -- varchar(50)
            @DELV_DAY_DNRM = @DELV_DAY_DNRM, -- smallint
            @DELV_HOUR_DNRM = @DELV_HOUR_DNRM, -- smallint
            @DELV_MINT_DNRM = @DELV_MINT_DNRM, -- smallint
            @MAKE_DAY_DNRM = @MAKE_DAY_DNRM, -- smallint
            @MAKE_HOUR_DNRM = @MAKE_HOUR_DNRM, -- smallint
            @MAKE_MINT_DNRM = @MAKE_MINT_DNRM, -- smallint
            @RELS_TIME = @RELS_TIME, -- datetime
            @STAT = @STAT, -- varchar(3)
            @ALRM_MIN_NUMB_DNRM = @ALRM_MIN_NUMB_DNRM, -- real
            @PROD_TYPE_DNRM = @PROD_TYPE_DNRM, -- varchar(3)
            @MIN_ORDR_DNRM = @MIN_ORDR_DNRM, -- real
            @MADE_IN_DNRM = @MADE_IN_DNRM, -- varchar(3)
            @GRNT_STAT_DNRM = @GRNT_STAT_DNRM, -- varchar(3)
            @GRNT_NUMB_DNRM = @GRNT_NUMB_DNRM, -- int
            @GRNT_TIME_DNRM = @GRNT_TIME_DNRM, -- varchar(3)
            @GRNT_TYPE_DNRM = @GRNT_TYPE_DNRM, -- varchar(3)
            @GRNT_DESC_DNRM = @GRNT_DESC_DNRM, -- nvarchar(4000)
            @WRNT_STAT_DNRM = @WRNT_STAT_DNRM, -- varchar(3)
            @WRNT_NUMB_DNRM = @WRNT_NUMB_DNRM, -- int
            @WRNT_TIME_DNRM = @WRNT_TIME_DNRM, -- varchar(3)
      @WRNT_TYPE_DNRM = @WRNT_TYPE_DNRM, -- varchar(3)
            @WRNT_DESC_DNRM = @WRNT_DESC_DNRM, -- nvarchar(4000)
            @WEGH_AMNT_DNRM = @WEGH_AMNT_DNRM, -- real
            @NUMB_TYPE = @NUMB_TYPE, -- varchar(3)
            @PROD_LIFE_STAT = @PROD_LIFE_STAT, -- varchar(3)
            @PROD_SUPL_LOCT_STAT = @PROD_SUPL_LOCT_STAT, -- varchar(3)
            @PROD_SUPL_LOCT_DESC = @PROD_SUPL_LOCT_DESC, -- nvarchar(250)
            @RESP_SHIP_COST_TYPE = @RESP_SHIP_COST_TYPE, -- varchar(3)
            @APRX_SHIP_COST_AMNT = @APRX_SHIP_COST_AMNT, -- bigint
            @CRNC_CALC_STAT = @CRNC_CALC_STAT, -- varchar(3)
            @CRNC_EXPN_AMNT = @CRNC_EXPN_AMNT -- money         
      END 
   END 
 END  
END
GO
ALTER TABLE [dbo].[Robot] ADD CONSTRAINT [PK_ROBO] PRIMARY KEY CLUSTERED  ([RBID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Robot_RBID] ON [dbo].[Robot] ([RBID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot] WITH NOCHECK ADD CONSTRAINT [FK_ROBO_ORGN] FOREIGN KEY ([ORGN_OGID]) REFERENCES [dbo].[Organ] ([OGID])
GO
ALTER TABLE [dbo].[Robot] ADD CONSTRAINT [FK_ROBO_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع نرم افزار حسابداری', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'ACNT_APP_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'واحد مالی', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'AMNT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Order Shipping Courier
وضعیت اتومات درخواست پیک برای ارسال سفارشات ثبت شده
اگر ربات به این صورت تنظیم شده باشد که به ازای هر ثبت سفارش سریعا برای ارسال سفیر انتخاب شود درخواست های ان سریع ثبت و به سفیران ارسال میشود در غیر این صورت فروشگاه می تواند سفارش ها را جمع آوری کرده و به یکباره ارسال کند', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'AUTO_SHIP_CORI'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Telegram Bot
Bale Bot
Rubika Bot
...', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'BOT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'در زمان ثبت نام چک شود که نیاز به ثبت نام داریم یا خیر', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'CHCK_REGS_STRT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اتصال به نرم افزار حسابداری', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'CNCT_ACNT_APP'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان تایید پورسانت', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'CONF_DURT_DAY'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ربات مستقل میباشد یا کاپی از ربات دیگر', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'COPY_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نحوه بروزرسانی مبلغ ارز
به صورت دستی یا اتومات', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'CRNC_AUTO_UPDT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان اجرای بروزرسانی نرخ ارز به صورت اتومات', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'CRNC_CYCL_AUTO_UPDT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نحوه تغییر نرخ محصولات بر اساس نرخ ارز منتخب
اگر نرخ افزایش پیدا کند قیمتها بروزشود؟
اگر نرخ کاهش پیدا کرد قیمتها بروزشود؟', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'CRNC_HOW_UPDT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آیا دسترسی به سرور بیرونی برای مشتری داریم یا خیر', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'EXTR_SORC_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان سبد خرید برای ارسال رایگان داخل شهری', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'FREE_SHIP_INCT_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان سبد خرید برای ارسال رایگان بیرون شهری', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'FREE_SHIP_OTCT_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Connection string local server
این گزینه برای نرم افزار های حسابداری هست که به صورت محلی کار میکنن', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'LOCL_SRVR_CONN_STRN'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداقل مبلغ برداشت وجه پورسانت', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'MIN_WITH_DRAW'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت اطلاع رسانی از رسیدهای پرداختی درخواست', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'NOTI_ORDR_RCPT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت اطلاع رسانی از سفارش های ثبت شده', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'NOTI_ORDR_RECP_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت اطلاع رسانی از ارسال بسته های درخواست', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'NOTI_ORDR_SHIP_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مسیر آدرس فایل وضعیت اطلاع رسانی از رسیدهای پرداختی درخواست', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'NOTI_SOND_ORDR_RCPT_PATH'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مسیر آدرس فایل وضعیت اطلاع رسانی از سفارش های ثبت شده', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'NOTI_SOND_ORDR_RECP_PATH'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مسیر آدرس فایل وضعیت اطلاع رسانی از ارسال بسته های درخواست', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'NOTI_SOND_ORDR_SHIP_PATH'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت انقضا برای سبد خرید مشتری', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'ORDR_EXPR_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان انقضای سبد خرید مشتری بر حسب دقیقه', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'ORDR_EXPR_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سیستم صفحه بندی برای خروجی اطلاعات از ربات', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'PAGE_FECH_ROWS'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مرجع ربات', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'ROBO_RBID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اجازه اجرا شدن ربات', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'RUN_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارسال پیام از طریق سامانه پیامکی', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'SEND_SMS_INVT_CONT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت نمایش موجودی کالاها', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'SHOW_INVR_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'انتخاب آدرس دسترسی به منبع بیرونی', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'SLCT_SRVR_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نمایش موجودی کالا', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'VIEW_INVR_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Connection string web server
این دسته از مشتریانی می باشد که نرم افزار فروشگاه انلاین دارند که با سیستم حسابداری خوب مرتبط کرده اند', 'SCHEMA', N'dbo', 'TABLE', N'Robot', 'COLUMN', N'WEB_SRVR_CONN_STRN'
GO
