CREATE TABLE [dbo].[Order]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[SRBT_SRPB_RWNO] [int] NULL,
[PROB_SERV_FILE_NO] [bigint] NULL,
[PROB_ROBO_RBID] [bigint] NULL,
[CHAT_ID] [bigint] NULL,
[SUB_SYS] [int] NULL,
[ORDR_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Order_CODE] DEFAULT ((0)),
[ORDR_NUMB] [bigint] NULL,
[ORDR_TYPE_NUMB] [bigint] NULL,
[SERV_ORDR_RWNO] [bigint] NULL,
[OWNR_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STRT_DATE] [datetime] NULL,
[END_DATE] [datetime] NULL,
[ORDR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HOW_SHIP] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CORD_X] [float] NULL,
[CORD_Y] [float] NULL,
[CELL_PHON] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SERV_ADRS] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ARCH_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Order_ARCH_STAT] DEFAULT ('001'),
[SERV_JOB_APBS_CODE] [bigint] NULL,
[SERV_INTR_APBS_CODE] [bigint] NULL,
[CRTB_SEND_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRTB_MAIL_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRTB_MAIL_SUBJ] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[APBS_CODE] [bigint] NULL,
[EXPN_AMNT] [bigint] NULL,
[EXTR_PRCT] [bigint] NULL,
[SUM_EXPN_AMNT_DNRM] [bigint] NULL,
[AMNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DSCN_AMNT_DNRM] [bigint] NULL,
[PYMT_AMNT_DNRM] [bigint] NULL,
[COST_AMNT_DNRM] [bigint] NULL,
[DEBT_DNRM] [bigint] NULL,
[PYMT_MTOD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SORC_CARD_NUMB_DNRM] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEST_CARD_NUMB_DNRM] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TXID_DNRM] [varchar] (266) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TXFE_PRCT_DNRM] [smallint] NULL,
[TXFE_CALC_AMNT_DNRM] [bigint] NULL,
[TXFE_AMNT_DNRM] [bigint] NULL,
[SUM_FEE_AMNT_DNRM] [bigint] NULL,
[SORC_CORD_X] [float] NULL,
[SORC_CORD_Y] [float] NULL,
[SORC_POST_ADRS] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SORC_CELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SORC_TELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SORC_EMAL_ADRS] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SORC_WEB_SITE] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DELV_TIME_DNRM] [smallint] NULL,
[ORDR_DESC] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[SCDL_PTNT_DATE] [datetime] NULL
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
CREATE TRIGGER [dbo].[CG$AINS_ORDR]
   ON  [dbo].[Order]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   MERGE dbo.[Order] T
   USING(SELECT i.CODE, i.SUB_SYS, i.STRT_DATE, i.MDFR_STAT, i.CHAT_ID, i.ORDR_NUMB, i.SRBT_SERV_FILE_NO, i.SRBT_ROBO_RBID, 
                r.CORD_X AS SORC_CORD_X , r.CORD_Y AS SORC_CORD_Y, r.POST_ADRS AS SORC_POST_ADRS, r.CELL_PHON AS SORC_CELL_PHON, 
                r.TELL_PHON AS SORC_TELL_PHON, r.EMAL_ADRS AS SORC_EMAL_ADRS, r.WEB_SITE AS SORC_WEB_SITE, i.HOW_SHIP, i.ORDR_TYPE,
                sr.SRPB_RWNO, sr.CORD_X, sr.CORD_Y, sr.SERV_ADRS, sr.CELL_PHON, sr.NAME, i.ARCH_STAT, i.ORDR_STAT
           FROM Inserted i, dbo.Robot r, dbo.Service_Robot sr 
          WHERE i.SRBT_ROBO_RBID = r.RBID AND i.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO AND i.SRBT_ROBO_RBID = sr.ROBO_RBID) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,T.CODE = CASE WHEN s.CODE = 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END
        ,T.STRT_DATE = ISNULL(s.STRT_DATE, GETDATE())
        ,T.MDFR_STAT = ISNULL( s.MDFR_STAT , '001' )
        ,T.CHAT_ID = CASE WHEN s.CHAT_ID IS NOT NULL THEN s.CHAT_ID ELSE (SELECT Sr.CHAT_ID FROM dbo.Service_Robot sr WHERE s.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO AND s.SRBT_ROBO_RBID = sr.ROBO_RBID) END
        ,T.ORDR_NUMB = CASE WHEN s.ORDR_NUMB IS NOT NULL AND s.ORDR_NUMB != 0 THEN s.ORDR_NUMB ELSE (SELECT COUNT(o.CODE) FROM dbo.[Order] o WHERE o.SRBT_ROBO_RBID = s.SRBT_ROBO_RBID) END 
        ,t.ORDR_TYPE_NUMB = (SELECT ISNULL(MAX(o.ORDR_TYPE_NUMB), 0) + 1 FROM dbo.[Order] o WHERE s.SRBT_ROBO_RBID = o.SRBT_ROBO_RBID AND s.SRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO AND s.ORDR_TYPE = o.ORDR_TYPE)
        ,T.SERV_ORDR_RWNO = (SELECT COUNT(o.CODE) FROM dbo.[Order] o WHERE o.SRBT_SERV_FILE_NO = s.SRBT_SERV_FILE_NO)
        ,t.CORD_X = s.CORD_X
        ,t.CORD_Y = s.CORD_Y
        ,t.SERV_ADRS = s.SERV_ADRS
        ,t.CELL_PHON = s.CELL_PHON
        ,t.SRBT_SRPB_RWNO = s.SRPB_RWNO
        ,T.OWNR_NAME = s.NAME--(SELECT sr.NAME FROM dbo.Service_Robot sr WHERE sr.SERV_FILE_NO = s.SRBT_SERV_FILE_NO AND sr.ROBO_RBID = s.SRBT_ROBO_RBID)
        ,T.SORC_CORD_X = s.SORC_CORD_X
        ,T.SORC_CORD_Y = s.SORC_CORD_Y
        ,T.SORC_POST_ADRS = s.SORC_POST_ADRS
        ,T.SORC_CELL_PHON = s.SORC_CELL_PHON
        ,T.SORC_TELL_PHON = s.SORC_TELL_PHON
        ,T.SORC_EMAL_ADRS = s.SORC_EMAL_ADRS
        ,T.SORC_WEB_SITE = s.SORC_WEB_SITE
        ,T.SUB_SYS = ISNULL(S.SUB_SYS, 12)
        ,T.HOW_SHIP = ISNULL(s.HOW_SHIP, '000')
        ,T.ARCH_STAT = ISNULL(s.ARCH_STAT, '001')
        ,T.ORDR_STAT = ISNULL(s.ORDR_STAT, '001');
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
CREATE TRIGGER [dbo].[CG$AUPD_ORDR]
   ON  [dbo].[Order]
   AFTER UPDATE   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   MERGE dbo.[Order] T
   USING(SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE()
        ,T.TELL_PHON = CASE WHEN LEN(ISNULL(S.TELL_PHON, '')) = 0 THEN NULL ELSE s.TELL_PHON END
        ,T.CELL_PHON = CASE WHEN LEN(ISNULL(S.CELL_PHON, '')) = 0 THEN NULL ELSE s.CELL_PHON END
        ,T.SORC_TELL_PHON = CASE WHEN LEN(ISNULL(S.SORC_TELL_PHON, '')) = 0 THEN NULL ELSE s.SORC_TELL_PHON END
        ,T.SORC_CELL_PHON = CASE WHEN LEN(ISNULL(S.SORC_CELL_PHON, '')) = 0 THEN NULL ELSE s.SORC_CELL_PHON END
        ,T.AMNT_TYPE = (SELECT AMNT_TYPE FROM dbo.Robot where RBID = s.SRBT_ROBO_RBID)
        ,t.SERV_ADRS = CASE s.HOW_SHIP 
                            WHEN '000' THEN N'نحوه تحویل نامشخص'
                            WHEN '001' THEN N'تحویل از فروشگاه'
                            ELSE s.SERV_ADRS
                       END                                
        ,T.TXFE_AMNT_DNRM = (
            SELECT TOP 1 CASE s.ORDR_TYPE WHEN '024' THEN tf.TXFE_AMNT * 2 ELSE tf.TXFE_AMNT END
              FROM dbo.Transaction_Fee tf
             WHERE tf.TXFE_TYPE = '002'
               AND tf.CALC_TYPE = '002'
               AND tf.STAT = CASE s.ORDR_TYPE WHEN '024' /* اگر درخواست انتقال وجه باشه کارمزد انتقال از خوده مشتری کسر میشه */ THEN '001' ELSE '002' END 
               AND s.EXPN_AMNT != 0
               AND (s.EXPN_AMNT + ISNULL(s.EXTR_PRCT , 0)) >= tf.FROM_AMNT AND (s.EXPN_AMNT + ISNULL(s.EXTR_PRCT , 0)) < tf.TO_AMNT
               AND s.ORDR_TYPE NOT IN ('013', '014', '015', '023')
        )
        ,T.DEST_CARD_NUMB_DNRM = 
            dbo.GET_RBCN_U(
               (SELECT s.SRBT_ROBO_RBID AS '@rbid'
                      ,s.ORDR_TYPE AS '@type'
                      ,s.CODE AS '@code'
                      ,s.DEST_CARD_NUMB_DNRM AS '@cardnumb'
                  FOR XML PATH('Order'), TYPE)
            )
        ,T.PYMT_MTOD = 
            CASE S.AMNT_TYPE
               WHEN '001' THEN 
                  CASE 
                     WHEN (s.EXPN_AMNT + ISNULL(s.EXTR_PRCT, 0) + ISNULL(s.TXFE_AMNT_DNRM, 0)) > 50000000 THEN '011' 
                     ELSE '009' 
                  END
               WHEN '002' THEN
                  CASE 
                     WHEN (s.EXPN_AMNT + ISNULL(s.EXTR_PRCT, 0) + ISNULL(s.TXFE_AMNT_DNRM, 0)) > 50000000 THEN '011' 
                     ELSE '009' 
                  END
            END ;
   
   -- 1396/07/25 * بروز کردن میزان بدهی سفارش
   UPDATE o
      SET o.DEBT_DNRM = (ISNULL(o.EXPN_AMNT, 0) + ISNULL(o.EXTR_PRCT, 0) - 
                        (CASE WHEN EXISTS(SELECT * FROM dbo.Order_Step_History os WHERE os.ORDR_CODE = o.CODE AND os.ORDR_STAT = '004') THEN 0 
                              ELSE ISNULL(o.TXFE_AMNT_DNRM, 0) 
                         END)) - (ISNULL(o.DSCN_AMNT_DNRM, 0) + ISNULL(o.PYMT_AMNT_DNRM, 0))
         ,o.SUM_EXPN_AMNT_DNRM = o.EXPN_AMNT + ISNULL(o.EXTR_PRCT, 0) - ISNULL(o.TXFE_AMNT_DNRM, 0) - ISNULL(o.DSCN_AMNT_DNRM, 0)
         ,o.SUM_FEE_AMNT_DNRM = ISNULL(o.TXFE_CALC_AMNT_DNRM, 0) + ISNULL(o.TXFE_AMNT_DNRM, 0)
     FROM dbo.[Order] o, Inserted s
    WHERE o.CODE = s.CODE;  
   
   DECLARE @ChatId BIGINT,
           @ServFileNo BIGINT,
           @Rbid BIGINT;
   
   -- اگ درخواست انصراف بخورد باید اطلاعات کارت اعتباری و کیف پول به حساب مشتری برگردد
   IF EXISTS(SELECT * FROM Inserted i, Deleted d WHERE i.CODE = d.CODE AND d.ORDR_STAT != '003' AND i.ORDR_STAT = '003' AND i.ORDR_TYPE IN ( '004' , '023', '024' ))
   BEGIN
      -- بازگشت مبلغ کارت اعتباری به حساب کیف پول مشتری
      UPDATE g 
         SET g.TEMP_AMNT_USE = 0
        FROM dbo.Service_Robot_Gift_Card g, dbo.Order_State os, Inserted i
       WHERE g.GCID = os.GIFC_GCID
         AND os.ORDR_CODE = i.CODE;
      
      -- برگشت مبلغ کسر شده از کیف پول
      UPDATE w
         SET w.TEMP_AMNT_USE = 0
        FROM dbo.Wallet w, dbo.Wallet_Detail wd
       WHERE w.CODE = wd.WLET_CODE
         AND wd.ORDR_CODE IN (
             SELECT i.CODE
               FROM Inserted i, Deleted d 
              WHERE i.CODE = d.CODE 
                AND d.ORDR_STAT != '003' 
                AND i.ORDR_STAT = '003' 
                AND i.ORDR_TYPE = '004'
             );
         
      DELETE dbo.Wallet_Detail
       WHERE ORDR_CODE IN (
             SELECT i.CODE
               FROM Inserted i, Deleted d 
              WHERE i.CODE = d.CODE 
                AND d.ORDR_STAT != '003' 
                AND i.ORDR_STAT = '003' 
                AND i.ORDR_TYPE = '004'
             )
         AND CONF_STAT = '003';
      
      -- 1399/04/19
      -- بروزرسانی موجودی جدول کالاها	
      -- بارشگت محصول به قفسه کالا
      UPDATE p
         SET p.CRNT_NUMB_DNRM = WREH_INVR_NUMB - (SALE_NUMB_DNRM + (SALE_CART_NUMB_DNRM - od.NUMB))
             --p.SALE_CART_NUMB_DNRM += @n
        FROM dbo.Service_Robot_Seller_Product p, dbo.Order_Detail od, Inserted i
       WHERE i.CODE = od.ORDR_CODE
         AND od.TARF_CODE = p.TARF_CODE
         AND p.PROD_TYPE = '002';         
   END 
   -- اگر درخواست پایانی شود
   ELSE IF EXISTS(SELECT * FROM Inserted i, Deleted d WHERE i.CODE = d.CODE AND d.ORDR_STAT != '004' AND i.ORDR_STAT = '004' AND i.ORDR_TYPE IN ( '004', '023', '024' ))
   BEGIN
      -- بروزرسانی کد تخفیف و خارج شدن از لیست تخفیفات مشتری
      UPDATE d
         SET d.VALD_TYPE = '001'
        FROM dbo.Service_Robot_Discount_Card d, dbo.Order_State os, Inserted i
       WHERE d.DCID = os.DISC_DCID
         AND os.ORDR_CODE = i.CODE
         -- 1399/08/15 * کارت تخفیف هایی غیر فعال میشوند که تخفیف همکار نباشد
         AND d.OFF_TYPE != '008'
         AND d.OFF_KIND != '004';
      
      -- بروزرسانی کارت هدیه اعتباری بعد از پرداخت سفارش
      UPDATE g
         SET g.BLNC_AMNT_DNRM -= g.TEMP_AMNT_USE,
             g.TEMP_AMNT_USE = 0,
             g.VALD_TYPE = CASE g.BLNC_AMNT_DNRM - g.TEMP_AMNT_USE WHEN 0 THEN '001' ELSE '002' END 
        FROM dbo.Service_Robot_Gift_Card g, dbo.Order_State os, Inserted i
       WHERE g.GCID = os.GIFC_GCID
         AND os.ORDR_CODE = i.CODE;
      
      -- بروزرسانی کیف پول
      UPDATE wd
         SET wd.CONF_STAT = '002',
             wd.CONF_DATE = GETDATE(),
             wd.CONF_DESC = CASE i.ORDR_TYPE 
                                 WHEN '004' THEN N'مبلغ برداشت برای خرید سفارش ' + CAST(i.ORDR_TYPE_NUMB AS VARCHAR(30))
                                 WHEN '023' THEN N'مبلغ برداشت بابت پرداخت هزینه ارسال سفارش' + CAST(i.ORDR_TYPE_NUMB AS VARCHAR(30))
                                 WHEN '024' THEN wd.CONF_DESC + CAST(i.ORDR_TYPE_NUMB AS VARCHAR(30))
                            END,
             wd.CRNT_WLET_AMNT_DNRM = CASE wd.AMNT_STAT
                                                WHEN '001' THEN (SELECT ISNULL(w.AMNT_DNRM, 0) FROM dbo.Wallet w WHERE w.CODE = wd.WLET_CODE) + ISNULL(wd.AMNT, 0)
                                                WHEN '002' THEN (SELECT ISNULL(w.AMNT_DNRM, 0) FROM dbo.Wallet w WHERE w.CODE = wd.WLET_CODE) - ISNULL(wd.AMNT, 0)
                                      END 
        FROM dbo.Wallet_Detail wd, dbo.Order_State os, Inserted i
       WHERE wd.CODE = os.WLDT_CODE
         AND os.ORDR_CODE = i.CODE;
      
      UPDATE w
         SET w.TEMP_AMNT_USE = 0
        FROM dbo.Wallet w, dbo.Wallet_Detail wd, dbo.Order_State os, Inserted i
       WHERE w.CODE = wd.WLET_CODE
         AND wd.CODE = os.WLDT_CODE
         AND os.ORDR_CODE = i.CODE;
      
      ---- بروزرسانی میزان فروش کالا و خدمات جدول کالا ها
      --UPDATE rp
      --   SET rp.SALE_NUMB_DNRM = ISNULL(rp.SALE_NUMB_DNRM, 0) + 1
      --  FROM dbo.Robot r, dbo.Robot_Product rp, dbo.[Order] o, dbo.Order_Detail od, Inserted i
      -- WHERE r.RBID = rp.ROBO_RBID
      --   AND rp.ROBO_RBID = o.SRBT_ROBO_RBID
      --   AND o.CODE = i.CODE
      --   AND o.CODE = od.ORDR_CODE
      --   AND rp.TARF_CODE = od.TARF_CODE
      --   AND r.SHOW_INVR_STAT = '002' /* میزان حداکثر سقف فروش */;
      
      -- 1399/04/19
      -- بروزرسانی موجودی جدول کالاها	
      -- ابتدا محصولات را از سبد خرید خارج میکنیم
      UPDATE p
         SET p.SALE_CART_NUMB_DNRM -= od.NUMB
        FROM dbo.Service_Robot_Seller_Product p, dbo.Order_Detail od, Inserted i
       WHERE i.CODE = od.ORDR_CODE
         AND od.TARF_CODE = p.TARF_CODE
         AND p.PROD_TYPE = '002';
      
      -- حال محصولات درون جدول را از لحاظ تعداد بروزرسانی میکنیم
      UPDATE p
         SET p.CRNT_NUMB_DNRM = p.WREH_INVR_NUMB - (p.SALE_NUMB_DNRM + p.SALE_CART_NUMB_DNRM + od.NUMB),
             p.SALE_NUMB_DNRM = ISNULL(p.SALE_NUMB_DNRM, 0) + od.NUMB
        FROM dbo.Service_Robot_Seller_Product p, dbo.Order_Detail od, Inserted i
       WHERE i.CODE = od.ORDR_CODE
         AND od.TARF_CODE = p.TARF_CODE
         AND p.PROD_TYPE = '002';
      
      -- 1399/05/06 * اگر موجودی کالایی تمام شد به امور انبارداری، و مالی، و مدیریت اطلاع رسانی کنیم
      IF EXISTS(
         SELECT *
           FROM dbo.[Order] o, Inserted i, dbo.Order_Detail od, dbo.Service_Robot_Seller_Product p
          WHERE o.CODE = i.CODE
            AND o.CODE = od.ORDR_CODE
            AND od.TARF_CODE = p.TARF_CODE
            AND p.CRNT_NUMB_DNRM = 0
      )
      BEGIN
         -- اطلاع رسانی به واحد های مشاغل فروشگاه
         DECLARE @xTemp XML;
         SET @xTemp = (
             SELECT TOP 1
                    o.SRBT_ROBO_RBID AS '@rbid',
                    o.CHAT_ID AS 'Order/@chatid',
                    '012' AS 'Order/@type',
                    'nomoreprodfromstor' AS 'Order/@oprt',
                    (
                       SELECT p.TARF_CODE + N','
                         FROM dbo.Order_Detail od, dbo.Service_Robot_Seller_Product p                      
                        WHERE od.ORDR_CODE = o.Code
                          AND od.TARF_CODE = p.TARF_CODE
                          AND p.CRNT_NUMB_DNRM = 0
                          FOR XML PATH('')                     
                    ) AS 'Order/@valu'
               FROM dbo.[Order] o, Inserted i
              WHERE o.CODE = i.CODE                
                FOR XML PATH('Robot')
         );
         EXEC dbo.SEND_MEOJ_P @X = @xTemp, @XRet = @xTemp OUTPUT;
      END
      
      -- 1399/05/07 * اگر موجودی کالا به حد پایین رسید باید به قسمت مدیران فروشگاه اطلاع رسانی کنیم
      IF EXISTS (
         SELECT *
           FROM dbo.[Order] o, Inserted i, dbo.Order_Detail od, dbo.Service_Robot_Seller_Product p
          WHERE o.CODE = i.CODE
            AND o.CODE = od.ORDR_CODE
            AND od.TARF_CODE = p.TARF_CODE
            AND p.CRNT_NUMB_DNRM > 0
            AND p.CRNT_NUMB_DNRM <= ISNULL(p.ALRM_MIN_NUMB, 0)
      )
      BEGIN
         -- اطلاع رسانی به واحد های مشاغل فروشگاه
         SET @xTemp = (
             SELECT TOP 1
                    o.SRBT_ROBO_RBID AS '@rbid',
                    o.CHAT_ID AS 'Order/@chatid',
                    '012' AS 'Order/@type',
                    'alrmnumbprodfromstor' AS 'Order/@oprt',
                    (
                       SELECT p.TARF_CODE + N','
                         FROM dbo.Order_Detail od, dbo.Service_Robot_Seller_Product p                      
                        WHERE od.ORDR_CODE = o.Code
                          AND od.TARF_CODE = p.TARF_CODE
                          AND p.CRNT_NUMB_DNRM > 0
                          AND p.CRNT_NUMB_DNRM <= ISNULL(p.ALRM_MIN_NUMB, 0)
                          FOR XML PATH('')                     
                    ) AS 'Order/@valu'
               FROM dbo.[Order] o, Inserted i
              WHERE o.CODE = i.CODE                
              FOR XML PATH('Robot')
         );
         EXEC dbo.SEND_MEOJ_P @X = @xTemp, @XRet = @xTemp OUTPUT;
      END 

      -- 1399/08/04 * اگر کارمزدی که فروشگاه کم میشود به حداقل رسیده باشد باید پیامی به مدیر فروشگاه ارسال کنیم که اعتبار رو به اتمام می باشد و بایستی دوباره شارژ کند
      SELECT TOP 1 @ChatId = sr.CHAT_ID, @ServFileNo = sr.SERV_FILE_NO, @Rbid = sr.ROBO_RBID
        FROM dbo.Service_Robot sr, dbo.Service_Robot_Group srg, dbo.[Group] g
       WHERE sr.SERV_FILE_NO = srg.SRBT_SERV_FILE_NO
         AND sr.ROBO_RBID = srg.SRBT_ROBO_RBID
         AND srg.STAT = '002'
         AND srg.GROP_GPID = g.GPID
         AND g.ADMN_ORGN = '002'
         AND g.STAT = '002'
         AND g.GPID = 131;
      
      -- بررسی اینکه کیف پول اعتباری مبلغ دارد یا خیر
      IF NOT EXISTS(SELECT * FROM dbo.Wallet w WHERE w.SRBT_ROBO_RBID = @Rbid AND w.SRBT_SERV_FILE_NO = @ServFileNo AND w.CHAT_ID = @ChatId AND w.WLET_TYPE = '001' /* کیف پول اعتباری */ AND w.AMNT_DNRM > 1000)
      BEGIN
         -- 1399/04/26
         -- اطلاع رسانی به واحد مدیریت فروشگاه
         SET @xTemp = (
          SELECT TOP 1
                 sr.ROBO_RBID AS '@rbid',
                 sr.CHAT_ID AS 'Order/@chatid',
                 '012' AS 'Order/@type',
                 'addcredwlet' AS 'Order/@oprt',
                 w.LAST_IN_AMNT_DNRM AS 'Order/@valu'
            FROM dbo.Service_Robot sr, dbo.Wallet w
           WHERE sr.SERV_FILE_NO = @ServFileNo
             AND sr.ROBO_RBID = @Rbid
             AND sr.CHAT_ID = @ChatId
             AND sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
             AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
             AND w.WLET_TYPE = '001' -- اعتباری
             FOR XML PATH('Robot')
         );
         EXEC dbo.SEND_MEOJ_P @X = @xTemp, @XRet = @xTemp OUTPUT;
      END
      
      -- اگر درخواست سفارش به گونه ای باشد که محصولات داخل سبد خرید خدمات باشد مانند قایل صوتی، ....
      IF EXISTS (SELECT * FROM Inserted i, dbo.Order_Detail od, dbo.Robot_Product_Download d WHERE i.CODE = od.ORDR_CODE AND od.TARF_CODE = d.TARF_CODE AND d.DNLD_TYPE = '002' AND d.STAT = '002')
      BEGIN
         -- 1399/09/17 * اگر فایل های دانلودی برای مشتری وجود داشته باشد که بخواهیم ارسال کنیم
         SET @xTemp = (
             SELECT i.SRBT_ROBO_RBID AS '@rbid',
                    i.CHAT_ID AS 'Order/@chatid',
                    i.CODE AS 'Order/@code',
                    '012' AS 'Order/@type',                    
                    'downloadfile' AS 'Order/@oprt',
                    '002' AS 'Order/@valu' -- Final File Download
               FROM Inserted i
                FOR XML PATH('Robot')               
         );
         EXEC dbo.SEND_MEOJ_P @X = @xTemp, @XRet = @xTemp OUTPUT;         
      END
   END -- اتمام بلاک مربوط به "پایانی شدن درخواست". 004
    
   DECLARE C$Prbt CURSOR FOR
      SELECT pr.SERV_FILE_NO, pr.ROBO_RBID, o.CODE
        FROM dbo.Personal_Robot pr, Inserted o
       WHERE pr.ROBO_RBID = o.PROB_ROBO_RBID
         AND pr.DFLT_ACES = '002'
         AND NOT EXISTS(
            SELECT *
              FROM dbo.Order_Access oa
             WHERE oa.ORDR_CODE = o.CODE               
         );
   
   DECLARE --@ServFileNo BIGINT
           @RoboRbid BIGINT
          ,@OrdrCode BIGINT;
   
   OPEN [C$Prbt];
   L$Loop:
   FETCH [C$Prbt] INTO @ServFileNo, @RoboRbid, @OrdrCode;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndLoop;
   
   INSERT INTO dbo.Order_Access
           ( ORDR_CODE ,
             PROB_SERV_FILE_NO ,
             PROB_ROBO_RBID ,
             CODE ,
             RECD_STAT 
           )
   VALUES  ( @OrdrCode , -- ORDR_CODE - bigint
             @ServFileNo , -- PROB_SERV_FILE_NO - bigint
             @RoboRbid , -- PROB_ROBO_RBID - bigint
             0 , -- CODE - bigint
             '002'  -- RECD_STAT - varchar(3)
           );
   
   GOTO L$Loop;
   L$EndLoop:
   CLOSE [C$Prbt];
   DEALLOCATE [C$Prbt];
   
   -- ثبت واقعه اتفاقی برای وضعیت درخواست
   INSERT INTO dbo.Order_Step_History
   (ORDR_CODE ,CODE ,ORDR_STAT)
   SELECT i.CODE, dbo.GNRT_NVID_U(), i.ORDR_STAT   
     FROM Inserted i
    WHERE NOT EXISTS(
          SELECT *
            FROM dbo.Order_Step_History os
           WHERE os.ORDR_CODE = i.CODE
             AND os.ORDR_STAT = i.ORDR_STAT
             AND os.RWNO = (
                 SELECT MAX(ost.RWNO)
                   FROM dbo.Order_Step_History ost
                  WHERE ost.ORDR_CODE = os.ORDR_CODE
             )
          );
   
END
GO
ALTER TABLE [dbo].[Order] ADD CONSTRAINT [PK_Order] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Order] ADD CONSTRAINT [FK_OINT_APBS] FOREIGN KEY ([SERV_INTR_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Order] ADD CONSTRAINT [FK_OJOB_APBS] FOREIGN KEY ([SERV_JOB_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Order] ADD CONSTRAINT [FK_ORDR_APBS] FOREIGN KEY ([APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Order] ADD CONSTRAINT [FK_ORDR_ORDR] FOREIGN KEY ([ORDR_CODE]) REFERENCES [dbo].[Order] ([CODE])
GO
ALTER TABLE [dbo].[Order] ADD CONSTRAINT [FK_ORDR_PROB] FOREIGN KEY ([PROB_SERV_FILE_NO], [PROB_ROBO_RBID]) REFERENCES [dbo].[Personal_Robot] ([SERV_FILE_NO], [ROBO_RBID])
GO
ALTER TABLE [dbo].[Order] ADD CONSTRAINT [FK_ORDR_ROBO] FOREIGN KEY ([SRBT_ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
ALTER TABLE [dbo].[Order] ADD CONSTRAINT [FK_ORDR_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'واحد مالی ریال یا تومن', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'AMNT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'در لیست بایگانی قرار گرفته شده یا خیر', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'ARCH_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'هزینه های سفارش', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'COST_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت ارسال به کارتابل', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'CRTB_SEND_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد روز تحویل محصول', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'DELV_TIME_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره کارت مقصد', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'DEST_CARD_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'DSCN_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ هزینه', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'EXPN_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارزش افزوده', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'EXTR_PRCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نحوه ارسال سفارش به دست مشتری', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'HOW_SHIP'
GO
EXEC sp_addextendedproperty N'MS_Description', N'توضیحات', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'ORDR_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نام فرستنده', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'OWNR_NAME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ پرداخت شده', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'PYMT_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نحوه پرداخت
کارت به کارت
درگاه پرداخت
اگر مبلغ زیر 3 میلیون باشه کارت به کارت
ولی اگر بیش از 3 میلیون باشد به درگاه پرداخت شرکت iNoti', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'PYMT_MTOD'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوبت دهی', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'SCDL_PTNT_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نحوه آشنایی مشتری', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'SERV_INTR_APBS_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'عنوان شغلی', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'SERV_JOB_APBS_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره کارت مبدا', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'SORC_CARD_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ نهایی فاکتور', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'SUM_EXPN_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ کل کارمزد :)', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'SUM_FEE_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ کارمزد مشتری', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'TXFE_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ محاسبه شده کارمزد کارفرما', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'TXFE_CALC_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درصد کارمزد کارفرما', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'TXFE_PRCT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره پیگیری پرداخت تراکنش', 'SCHEMA', N'dbo', 'TABLE', N'Order', 'COLUMN', N'TXID_DNRM'
GO
