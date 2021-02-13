SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SAVE_PYMT_P]
	-- Add the parameters for the stored procedure here
	@X XML,
	@xRet XML OUTPUT
AS
BEGIN   
	BEGIN TRY
	BEGIN TRAN [T$SAVE_PYMT_P]
	
	DECLARE @OrdrCode BIGINT = @X.query('//Payment').value('(Payment/@ordrcode)[1]', 'BIGINT')
	       ,@SorcCardNumb VARCHAR(16) = @X.query('//Payment').value('(Payment/@sorccardnumb)[1]', 'VARCHAR(16)')
	       ,@Txid VARCHAR(266) = @X.query('//Payment').value('(Payment/@txid)[1]', 'VARCHAR(266)')
	       ,@TotlAmnt INT = @X.query('//Payment').value('(Payment/@totlamnt)[1]', 'INT')
	       ,@DirCall VARCHAR(3) = @X.query('//Payment').value('(Payment/@dircall)[1]', 'VARCHAR(3)')
	       ,@AutoChngAmnt VARCHAR(3) = @X.query('//Payment').value('(Payment/@autochngamnt)[1]', 'VARCHAR(3)')
	       ,@RcmtMtod VARCHAR(3) = @X.query('//Payment').value('(Payment/@rcptmtod)[1]', 'VARCHAR(3)')
	       
	       ,@Rbid BIGINT
	       ,@ChatId BIGINT
	       ,@XMessage XML
	       ,@RsltCode VARCHAR(3);
	
	-- Local Var
	DECLARE @RcptMtod VARCHAR(3)	       ,@DestCardNumb VARCHAR(16)	       ,@TxfePrct SMALLINT  	       ,@TxfeCalcAmnt BIGINT
	       ,@TxfeAmnt BIGINT   	       ,@RefChatId BIGINT         	       ,@ConfDurtDay INT   	       ,@WletCode BIGINT
	       ,@TxfeTxid BIGINT   	       ,@TxfeType VARCHAR(3)     	       ,@AmntType VARCHAR(3)	       ,@AmntTypeDesc NVARCHAR(10)
	       ,@xTemp XML         	       ,@OrdrType VARCHAR(3)      	       ,@TOrdrCode BIGINT   	       ,@TAmnt BIGINT
	       ,@THowShip VARCHAR(3)	       ,@TNumStrn NVARCHAR(100)   	       ,@TDirPrjbCode BIGINT	       ,@TChatId BIGINT
	       ,@TOrdrType VARCHAR(3)        ,@TCode BIGINT;

   	
	SELECT @Rbid = o.SRBT_ROBO_RBID
	      ,@ChatId = o.CHAT_ID
	      ,@RcptMtod = o.PYMT_MTOD
	      ,@DestCardNumb = o.DEST_CARD_NUMB_DNRM
	      ,@TxfeAmnt = o.TXFE_AMNT_DNRM
	      ,@AmntType = o.AMNT_TYPE
	      ,@OrdrType = o.ORDR_TYPE
	      ,@TotlAmnt = CASE ISNULL(@TotlAmnt, 0) WHEN 0 THEN o.SUM_EXPN_AMNT_DNRM ELSE @TotlAmnt END 
	  FROM dbo.[Order] o
	 WHERE o.CODE = @OrdrCode;
	
	-- اگر نوع واحد مبلغ مشخص نشده از ربات اطلاعات را برداشت میکنیم
   SELECT @AmntType = ISNULL(@AmntType, r.AMNT_TYPE),
          @AmntTypeDesc = a.DOMN_DESC,
          @TNumStrn = dbo.GET_NTOS_U(ISNULL(r.CONF_DURT_DAY, 7))
     FROM dbo.Robot r, dbo.[D$AMUT] a
    WHERE r.RBID = @Rbid
      AND r.AMNT_TYPE = a.VALU;
	
	-- 1399/08/26 * اگر نرم افزار به صورت مستقیم از طریق خدمت کارت به کارت انجام شده باشد یا از طریق درگاه های پرداخت انجام شده باشد
	IF @AutoChngAmnt = '002' /* اگر ثبت وصولی غیر از ثبت دستی اتفا افتاده باشد */  AND @AmntType = '002' /* واحد مالی تومان باشد */
	   -- مبلغی که ما ارسال کرده ایم ریال هست ولی سیستم مالی ما تومان میباشد بخاطر همین باید تبدیل ریال به تومن اتفاق بیوفتد
	   SET @TotlAmnt /= 10;
	
	-- اگر سفارش برای فروشگاه ثبت شده باشد شرکت ما از آن کارمزد دریافت میکند
	IF @OrdrType = '004'
	BEGIN
	   -- اگر محاسبه کارمزد بر اساس مبلغ کل سفارش باشد
	   IF EXISTS (SELECT * FROM dbo.Transaction_Fee t WHERE t.TXFE_TYPE = '001' AND t.CALC_TYPE = '001' AND t.STAT = '002')
	   BEGIN
	      SELECT TOP 1 
	             @TxfePrct = tf.TXFE_PRCT
	            ,@TxfeCalcAmnt = (SELECT (o.SUM_EXPN_AMNT_DNRM - o.TXFE_AMNT_DNRM) * tf.TXFE_PRCT / 100 FROM dbo.[Order] o WHERE o.CODE = @OrdrCode)
	        FROM dbo.Transaction_Fee tf
	       WHERE STAT = '002'
	         AND tf.TXFE_TYPE = '001' -- محاسبه کارمزد بر اساس مبلغ کل سفارش
	         AND tf.CALC_TYPE = '001'; 
	   END 
	   -- اگر محاسبه کارمزد درخواست بر اساس سود سفارش باشد
	   ELSE -- EXISTS (SELECT * FROM dbo.Transaction_Fee t WHERE t.TXFE_TYPE = '007' AND t.CALC_TYPE = '001' AND t.STAT = '002')
	   BEGIN
	      SELECT @TxfePrct =  tf.TXFE_PRCT, 
	             @TxfeCalcAmnt =  SUM (CASE ISNULL(od.SUM_PRFT_PRIC_DNRM, 0) WHEN 0 THEN (od.SUM_EXPN_PRIC_DNRM - ISNULL(od.DSCN_AMNT_DNRM, 0)) ELSE (od.SUM_PRFT_PRIC_DNRM - ISNULL(od.DSCN_AMNT_DNRM, 0)) END) 
	        FROM dbo.Order_Detail od, dbo.Transaction_Fee tf
	       WHERE od.ORDR_CODE = @OrdrCode
	         AND tf.TXFE_TYPE = '007'
	         AND tf.CALC_TYPE = '001'
	         AND tf.STAT = '002'
	       GROUP BY tf.TXFE_PRCT;
	      
	      SET @TxfeCalcAmnt = @TxfeCalcAmnt * @TxfePrct / 100; 
	   END 
	END	
	
   IF @OrdrType IN ( '004', '015' ) /* درخواست های ثبت سفارش انلاین , افزایش نقدینگی کیف پول مشتری */
   BEGIN
	   -- اگر درخواست هیچ گونه وصولی نداشته باشد
	   IF NOT EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ('001' /* وصولی مستقیم / کارت اعتباری / کیف پول */, '002' /* تخفیف */, '005' /* رسید پرداخت */))
	   BEGIN
	      -- درج ردیف وصولی در جدول وضعیت درخواست
	      INSERT INTO dbo.Order_State
         (ORDR_CODE ,CODE ,STAT_DATE ,AMNT ,AMNT_TYPE ,
          RCPT_MTOD ,SORC_CARD_NUMB ,DEST_CARD_NUMB ,TXID ,TXFE_PRCT ,
          TXFE_CALC_AMNT ,TXFE_AMNT, CONF_STAT, CONF_DATE )
	      VALUES  
	      (@OrdrCode, 0, GETDATE(), @TotlAmnt, '001',
	       @RcptMtod, @SorcCardNumb, @DestCardNumb, @Txid, @TxfePrct, 
	       @TxfeCalcAmnt, @TxfeAmnt, '002', GETDATE());
      	
   	   -- بروز رسانی اطلاعات مربوط به جدول درخواست 
	      UPDATE dbo.[Order]
	         SET SORC_CARD_NUMB_DNRM = @SorcCardNumb
	            ,TXID_DNRM = @Txid
	            ,TXFE_PRCT_DNRM = @TxfePrct
	            ,TXFE_CALC_AMNT_DNRM = @TxfeCalcAmnt
	            ,ORDR_STAT = '004' -- درخواست پایانی شد
	            ,END_DATE = GETDATE()
	       WHERE CODE = @OrdrCode
	         AND ORDR_STAT != '004';
   	   
	      BEGIN/* ارسال پیام به مخاطبین مربوط به سفارش */
	         SET @xTemp = (
	            SELECT RBID AS '@rbid',
	                   (
	                     SELECT o.CHAT_ID AS '@chatid',
	                            o.CODE AS '@code',
	                            o.ORDR_TYPE AS '@type'
	                       FROM dbo.[Order] o
	                      WHERE o.CODE = @OrdrCode
	                        FOR XML PATH('Order'), TYPE	                  
	                   )	       
	              FROM dbo.Robot
	             WHERE RBID = @Rbid
	               FOR XML PATH('Robot')
	         );
	         EXEC dbo.SEND_MEOJ_P @X = @xTemp, @XRet = @xTemp OUTPUT;
	      END
   	   
   	   --IF @OrdrType = '004'
   	   BEGIN/* ثبت مبلغ سفارش در کیف پول مدیر فروشگاه و کسر کارمزد از مدیر فروشگاه */
   	      -- در این قسمت برای فروشگاه ما باید مشخص کنیم که کدام یک از اعضا ربات به عنوان مدیر محسوب می باشد که بتوانیم واریزی و برداشت ها را به آن منتسب کنیم
            SELECT TOP 1 
                   @TChatId = sr.CHAT_ID
              FROM dbo.Service_Robot sr, dbo.Service_Robot_Group srg, dbo.[Group] g
             WHERE sr.SERV_FILE_NO = srg.SRBT_SERV_FILE_NO
               AND sr.ROBO_RBID = srg.SRBT_ROBO_RBID
               AND srg.GROP_GPID = g.GPID
               AND sr.ROBO_RBID = @Rbid
               AND srg.STAT = '002'
               AND g.STAT = '002'
               AND g.ADMN_ORGN = '002'
               AND g.GPID = 131
               AND EXISTS (
                   SELECT *
                     FROM dbo.Service_Robot_Card_Bank a
                    WHERE a.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                      AND a.SRBT_ROBO_RBID = sr.ROBO_RBID
                      AND a.ACNT_STAT_DNRM = '002' -- حساب فعال
                      AND a.ACNT_TYPE_DNRM = '002' -- نوع حساب فروشنده
                      AND a.ORDR_TYPE_DNRM IN ('004', '015')
               );
               
            -- Step 3 : Insert into Wallet out payment for shop
            INSERT INTO dbo.Wallet_Detail
            (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT, CONF_DATE, CONF_DESC)
            -- پرداخت فروشگاه
            SELECT o.CODE, w.CODE, dbo.GNRT_NVID_U(), o.AMNT_TYPE, os.AMNT, GETDATE(), '001', 
                  '002', --CASE @OrdrType WHEN '004' THEN '003' WHEN '015' THEN '002' END, 
                  GETDATE(), --CASE @OrdrType WHEN '004' THEN NULL WHEN '015' THEN GETDATE() END, 
                  CASE @OrdrType WHEN '004' THEN N'مبلغ واریز بابت سفارش فروش انلاین' WHEN '015' THEN N'مبلغ افزایش نقدینگی کیف پول مشتری' END 
              FROM dbo.[Order] o, dbo.Order_State os, dbo.Wallet w
             WHERE o.CODE = @OrdrCode
               AND o.SRBT_ROBO_RBID = w.SRBT_ROBO_RBID
               AND @TChatId = w.CHAT_ID -- اطلاعات کیف پول فروشگاه
               AND w.WLET_TYPE = '002' -- کیف پول نقدینگی
               AND o.CODE = os.ORDR_CODE
               AND (
                      os.AMNT_TYPE = '005' OR
                      os.AMNT_TYPE = '001' AND os.RCPT_MTOD != '005'
                   )               
             UNION 
            SELECT o.CODE, w.CODE, dbo.GNRT_NVID_U(), o.AMNT_TYPE, ISNULL(o.SUM_FEE_AMNT_DNRM, 0), GETDATE(), '002', '002', GETDATE(), N'مبلغ کارمزد بابت سفارش فروش انلاین'
              FROM dbo.[Order] o, dbo.Wallet w
             WHERE o.CODE = @OrdrCode
               AND o.SRBT_ROBO_RBID = w.SRBT_ROBO_RBID
               AND @TChatId = w.CHAT_ID -- اطلاعات کیف پول فروشگاه
               AND w.WLET_TYPE = '001' -- کیف پول اعتباری
               AND ISNULL(o.SUM_FEE_AMNT_DNRM, 0) > 0;
         END 
   	   
         SELECT @xTemp = (
            SELECT o.SUB_SYS AS '@subsys'
                  ,'100' AS '@cmndcode' -- عملیات جامع ذخیره سازی
                  ,12 AS '@refsubsys' -- محل ارجاعی
                  ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
                  ,o.CODE AS '@refcode'
                  ,o.ORDR_NUMB AS '@refnumb' -- تعداد شماره درخواست ثبت شده
                  ,o.STRT_DATE AS '@strtdate'
                  ,o.END_DATE AS '@enddate'
                  ,o.CHAT_ID AS '@chatid'
                  ,sr.REAL_FRST_NAME AS '@frstname'
                  ,sr.REAL_LAST_NAME AS '@lastname'
                  ,sr.NATL_CODE AS '@natlcode'
                  ,sr.OTHR_CELL_PHON AS '@cellphon'
                  ,o.AMNT_TYPE AS '@amnttype'
                  ,o.PYMT_MTOD AS '@pymtmtod'
                  ,os.STAT_DATE AS '@pymtdate'
                  ,os.AMNT - ISNULL(os.TXFE_AMNT, 0) AS '@amnt'
                  ,os.TXID AS '@txid'
                  ,o.TXFE_AMNT_DNRM AS '@txfeamnt'
                  ,o.TXFE_CALC_AMNT_DNRM AS '@txfecalcamnt'
                  ,o.TXFE_PRCT_DNRM AS '@txfeprct'
                  ,(
                     SELECT od.TARF_CODE AS '@tarfcode'
                           ,od.TARF_DATE AS '@tarfdate'
                           ,od.EXPN_PRIC AS '@expnpric'
                           ,od.EXTR_PRCT AS '@extrprct'
                           ,od.DSCN_AMNT_DNRM AS '@dscnpric'
                           ,od.RQTP_CODE_DNRM AS '@rqtpcode'
                           ,od.NUMB AS '@numb'
                           ,od.ORDR_CMNT + N' ' + od.BASE_USSD_CODE + CHAR(10) + od.ORDR_DESC                         
                       FROM dbo.Order_Detail od
                      WHERE od.ORDR_CODE = o.CODE
                        FOR XML PATH('Expense'), TYPE                     
                  )
              FROM dbo.[Order] o, dbo.Order_State os, dbo.Service_Robot sr
             WHERE o.CODE = @OrdrCode
               AND o.CODE = os.ORDR_CODE
               AND o.CHAT_ID = sr.CHAT_ID
               AND sr.ROBO_RBID = @Rbid
               AND os.AMNT_TYPE = '001' -- درآمد
               AND o.ORDR_STAT = '004' -- درخواست پایانی شده باشد                
               AND ISNULL(o.ARCH_STAT, '001') = '001' -- بایگانی نشده باشد            
               /*
                  زمانی که درخواست به دست زیر سیستم مورد میرسد و عملیاتی میشود ستون بایگانی به حالت 002 در می آید
                  که متوجه شویم این درخواست ها به صورت کامل درون سیستم ذخیره شده اند
                  این گزینه بخاطر این هست که ممکن است مشترکی که در زیر سیستم دیگر قرار میگیرد در وضعیت قفل قرار گرفته باشد بخاطر همین 
                  باید وضعیت هر دو طرف درون سیستم ذخیره شود که متوجه شویم عملیات به درستی درون هردو سیستم انجام شده است
               */
               FOR XML PATH('Router_Command')
         );
         L$StrtCalling1:
         EXEC dbo.RouterdbCommand @X = @xTemp, @xRet = @xRet OUTPUT -- xml      
         IF @xRet.query('//Router_Command').value('(Router_Command/@needrecall)[1]', 'VARCHAR(3)') = '002'
         BEGIN
            SET @xTemp = @xRet;
            GOTO L$StrtCalling1;
         END

	      -- پیام بازگشت به سمت مشتری
	      SELECT @xRet = (
	         SELECT N'🖐 ☺️ از پرداخت شما متشکریم' + CHAR(10) + 
	                N'💵 شرح سند : پرداخت صورتحساب ' + CHAR(10) + CHAR(10) + 
	                N'👈 [ شماره فاکتور ] : *' + CAST(o.CODE AS NVARCHAR(20)) + N'*' + CHAR(10) + 
	                N'👈 [ کد سیستم ] : ' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(20)) + ' - ' + o.ORDR_TYPE + N'*' + CHAR(10) + 
	                N'💵 [ مبلغ فاکتور ] : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N'* [ ' + au.DOMN_DESC + N' ] ' + CHAR(10) + 
	                N'🗓 [ تاریخ و ساعت ایجاد فاکتور ] : *' + dbo.GET_MTOS_U(o.STRT_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) +
	                N'🗓 [ تاریخ و ساعت پرداخت فاکتور ] : *' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.END_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) +
	                N'📑 [ شماره پیگیری ] : *' + o.TXID_DNRM + N'*'
	                --N'💳 [ کارت مقصد ] : ' + o.DEST_CARD_NUMB_DNRM
	           FROM dbo.[Order] o, dbo.[D$AMUT] au
	          WHERE o.CODE = @OrdrCode
	            AND o.AMNT_TYPE = au.VALU
	        FOR XML PATH('Message'), ROOT('Result')
	      );
	   END;
	   ELSE IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ('001' /* وصولی مستقیم / کارت اعتباری / کیف پول */, '002' /* تخفیف */, '005' /* رسید پرداخت */))
	   BEGIN
	      -- اگر آخرین عملیات روی درخواست پرداخت کارت به کارت مشتری باشد باید ردیف آن را ذخیره کنیم
	      IF LEN(@Txid) != 0
	      BEGIN	         
	         -- درج ردیف وصولی در جدول وضعیت درخواست
	         INSERT INTO dbo.Order_State
            (ORDR_CODE ,CODE ,STAT_DATE ,AMNT ,AMNT_TYPE ,
             RCPT_MTOD ,SORC_CARD_NUMB ,DEST_CARD_NUMB ,TXID ,TXFE_PRCT ,
             TXFE_CALC_AMNT ,TXFE_AMNT, CONF_STAT, CONF_DATE )
	         VALUES  
	         (@OrdrCode, 0, GETDATE(), @TotlAmnt, '001',
	          @RcptMtod, @SorcCardNumb, @DestCardNumb, @Txid, @TxfePrct, 
	          @TxfeCalcAmnt, @TxfeAmnt, '002', GETDATE());
	      END
   	   
	      -- بررسی اینکه اگر در قسمت رسید ها پرداخت رسید تایید نشده داشته باشیم سفارش اجازه تایید شدن را ندارد
	      IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE = '005' AND os.CONF_STAT != '002')
	      BEGIN
	         SET @xRet = (
	             SELECT N'⚠️ درون رسید های پرداختی شده رسید تاییدی نشده وجود دارد لطفا تا تایید نهایی رسید منتظر بمانید'
	                FOR XML PATH('Message'), ROOT('Result')
	         );
   	      
	         GOTO L$EndSP;
	      END 

         -- تاییدیه ردیف های وضعیت درخواست
         UPDATE dbo.Order_State
            SET CONF_STAT = '002',
                CONF_DATE = ISNULL(CONF_DATE, GETDATE())
          WHERE ORDR_CODE = @OrdrCode
            AND AMNT_TYPE IN ('001' /* وصولی مستقیم / کارت اعتباری / کیف پول */, '002' /* تخفیف */, '005' /* رسید پرداخت */);
   	   
   	   IF (SELECT COUNT(os.CODE) FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ('001' /* پرداخت نقدینگی */, '005' /* پرداخت از رسید */) AND os.CONF_STAT = '002') = 1
   	   BEGIN
   	      SELECT @Txid = os.TXID
   	        FROM dbo.Order_State os
   	       WHERE os.ORDR_CODE = @OrdrCode
   	         AND os.AMNT_TYPE IN ('001', '005')
   	         AND os.CONF_STAT = '002';
   	   END 
   	   ELSE
   	      SET @Txid = '***';
   	   
	      -- بروز رسانی اطلاعات مربوط به جدول درخواست 
	      UPDATE dbo.[Order]
	         SET SORC_CARD_NUMB_DNRM = @SorcCardNumb
	            ,TXID_DNRM = @Txid
	            ,TXFE_PRCT_DNRM = @TxfePrct
	            ,TXFE_CALC_AMNT_DNRM = @TxfeCalcAmnt
	            ,ORDR_STAT = '004' -- درخواست پایانی شد
	            ,END_DATE = GETDATE()
	       WHERE CODE = @OrdrCode
	         AND ORDR_STAT != '004';         
         
         /* فراخوانی تابع ارسال پیام های مربوطه به شغل های مختلف */
         BEGIN/* ارسال پیام به مخاطبین مربوط به سفارش */
	         SET @xTemp = (
	            SELECT RBID AS '@rbid',
	                   (
	                     SELECT o.CHAT_ID AS '@chatid',
	                            o.CODE AS '@code',
	                            o.ORDR_TYPE AS '@type'
	                       FROM dbo.[Order] o
	                      WHERE o.CODE = @OrdrCode
	                        FOR XML PATH('Order'), TYPE	                  
	                   )	       
	              FROM dbo.Robot
	             WHERE RBID = @Rbid
	               FOR XML PATH('Robot')
	         );
	         EXEC dbo.SEND_MEOJ_P @X = @xTemp, @XRet = @xTemp OUTPUT;
	      END         
         
         -- کثر مبلغ کارمزد مشتری از پرداختی های فاکتور
         UPDATE os
            SET os.AMNT -= ISNULL(@TxfeAmnt, 0)
           FROM dbo.Order_State os
          WHERE os.ORDR_CODE = @OrdrCode
            AND os.AMNT_TYPE IN ('001')
            AND os.CODE = (
                  SELECT MIN(osm.CODE)
                    FROM dbo.Order_State osm
                   WHERE os.ORDR_CODE = osm.ORDR_CODE
                     AND os.AMNT_TYPE = osm.AMNT_TYPE         
                );
         
         -- اگر رکوردی پیدا نشد باید از گزینه رسید پرداخت دیگر استفاده کنیم
         IF @@ROWCOUNT = 0
            UPDATE os
               SET os.AMNT -= ISNULL(@TxfeAmnt, 0)
              FROM dbo.Order_State os
             WHERE os.ORDR_CODE = @OrdrCode
               AND os.AMNT_TYPE IN ('005')
               AND os.CODE = (
                     SELECT MIN(osm.CODE)
                       FROM dbo.Order_State osm
                      WHERE os.ORDR_CODE = osm.ORDR_CODE
                        AND os.AMNT_TYPE = osm.AMNT_TYPE         
                   );

   	   --IF @OrdrType = '004'
   	   BEGIN/* ثبت مبلغ سفارش در کیف پول مدیر فروشگاه و کسر کارمزد از مدیر فروشگاه */
   	      -- در این قسمت برای فروشگاه ما باید مشخص کنیم که کدام یک از اعضا ربات به عنوان مدیر محسوب می باشد که بتوانیم واریزی و برداشت ها را به آن منتسب کنیم
            SELECT TOP 1 
                   @TChatId = sr.CHAT_ID
              FROM dbo.Service_Robot sr, dbo.Service_Robot_Group srg, dbo.[Group] g
             WHERE sr.SERV_FILE_NO = srg.SRBT_SERV_FILE_NO
               AND sr.ROBO_RBID = srg.SRBT_ROBO_RBID
               AND srg.GROP_GPID = g.GPID
               AND sr.ROBO_RBID = @Rbid
               AND srg.STAT = '002'
               AND g.STAT = '002'
               AND g.ADMN_ORGN = '002'
               AND g.GPID = 131;
               
            -- Step 3 : Insert into Wallet out payment for shop
            INSERT INTO dbo.Wallet_Detail
            (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT, CONF_DATE, CONF_DESC)
            -- پرداخت فروشگاه
            SELECT o.CODE, w.CODE, dbo.GNRT_NVID_U(), o.AMNT_TYPE, os.AMNT, GETDATE(), '001', 
                  '002',--CASE @OrdrType WHEN '004' THEN '003' WHEN '015' THEN '002' END, 
                  GETDATE(),--CASE @OrdrType WHEN '004' THEN NULL WHEN '015' THEN GETDATE() END, 
                  CASE @OrdrType WHEN '004' THEN N'مبلغ واریز بابت سفارش فروش انلاین' WHEN '015' THEN N'مبلغ افزایش نقدینگی کیف پول مشتری' END 
              FROM dbo.[Order] o, dbo.Order_State os, dbo.Wallet w
             WHERE o.CODE = @OrdrCode
               AND o.SRBT_ROBO_RBID = w.SRBT_ROBO_RBID
               AND @TChatId = w.CHAT_ID -- اطلاعات کیف پول فروشگاه
               AND w.WLET_TYPE = '002' -- کیف پول نقدینگی
               AND o.CODE = os.ORDR_CODE
               AND (
                      os.AMNT_TYPE = '005' OR
                      os.AMNT_TYPE = '001' AND os.RCPT_MTOD != '005'
                   )               
             UNION 
            SELECT o.CODE, w.CODE, dbo.GNRT_NVID_U(), o.AMNT_TYPE, ISNULL(o.SUM_FEE_AMNT_DNRM, 0), GETDATE(), '002', '002', GETDATE(), N'مبلغ کارمزد بابت سفارش فروش انلاین'
              FROM dbo.[Order] o, dbo.Wallet w
             WHERE o.CODE = @OrdrCode
               AND o.SRBT_ROBO_RBID = w.SRBT_ROBO_RBID
               AND @TChatId = w.CHAT_ID -- اطلاعات کیف پول فروشگاه
               AND w.WLET_TYPE = '001' -- کیف پول اعتباری
               AND ISNULL(o.SUM_FEE_AMNT_DNRM, 0) > 0;
         END 
         
         SET @xTemp = (
             SELECT o.SUB_SYS AS '@subsys'
                   ,'102' AS '@cmndcode' -- عملیات جامع ذخیره سازی
                   ,12 AS '@refsubsys' -- محل ارجاعی
                   ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
                   ,o.CODE AS '@refcode'
                   ,o.ORDR_NUMB AS '@refnumb' -- تعداد شماره درخواست ثبت شده
                   ,o.STRT_DATE AS '@strtdate'
                   ,o.END_DATE AS '@enddate'
                   ,o.CHAT_ID AS '@chatid'
                   ,sr.REAL_FRST_NAME AS '@frstname'
                   ,sr.REAL_LAST_NAME AS '@lastname'
                   ,sr.NATL_CODE AS '@natlcode'
                   ,sr.OTHR_CELL_PHON AS '@cellphon'
                   ,o.AMNT_TYPE AS '@amnttype'
                   ,o.TXFE_AMNT_DNRM AS '@txfeamnt'
                   ,o.TXFE_CALC_AMNT_DNRM AS '@txfecalcamnt'
                   ,o.TXFE_PRCT_DNRM AS '@txfeprct',
                   (
                     SELECT od.TARF_CODE AS '@tarfcode'
                           ,od.TARF_DATE AS '@tarfdate'
                           ,od.EXPN_PRIC AS '@expnpric'
                           ,od.EXTR_PRCT AS '@extrprct'
                           ,od.DSCN_AMNT_DNRM AS '@dscnpric'
                           ,od.RQTP_CODE_DNRM AS '@rqtpcode'
                           ,od.NUMB AS '@numb'
                           ,od.ORDR_CMNT + N' ' + od.BASE_USSD_CODE + CHAR(10) + od.ORDR_DESC                         
                       FROM dbo.Order_Detail od
                      WHERE od.ORDR_CODE = o.CODE
                        FOR XML PATH('Expense'), TYPE  
                   ),
                   (
                     SELECT os.CONF_DATE AS '@actndate',
                            os.RCPT_MTOD AS '@rcptmtod',
                            os.AMNT AS '@amnt',
                            os.TXID AS '@flowno'
                       FROM dbo.Order_State os
                      WHERE os.ORDR_CODE = o.CODE
                        AND os.AMNT_TYPE IN ('001' /* وصولی های مستقیم / کارت هدیه / کیف پول */, '005' /* رسید پرداخت */)
                        FOR XML PATH('Payment_Method'), TYPE
                   ),
                   (
                     SELECT os.AMNT AS '@amnt',
                            os.STAT_DESC AS '@pydsdesc'
                       FROM dbo.Order_State os
                      WHERE os.ORDR_CODE = o.CODE
                        AND os.AMNT_TYPE = '002' -- تخفیف
                        AND ISNULL(os.AMNT, 0) > 0
                        FOR XML PATH('Payment_Discount'), TYPE                     
                   )
               FROM dbo.[Order] o, dbo.Service_Robot sr
              WHERE o.CODE = @OrdrCode
                AND o.CHAT_ID = sr.CHAT_ID
                AND sr.ROBO_RBID = @Rbid
                AND o.ORDR_STAT = '004' -- درخواست پایانی شده باشد
                AND ISNULL(o.ARCH_STAT, '001') = '001' -- بایگانی نشده باشد
                /*
                  زمانی که درخواست به دست زیر سیستم مورد میرسد و عملیاتی میشود ستون بایگانی به حالت 002 در می آید
                  که متوجه شویم این درخواست ها به صورت کامل درون سیستم ذخیره شده اند
                  این گزینه بخاطر این هست که ممکن است مشترکی که در زیر سیستم دیگر قرار میگیرد در وضعیت قفل قرار گرفته باشد بخاطر همین 
                  باید وضعیت هر دو طرف درون سیستم ذخیره شود که متوجه شویم عملیات به درستی درون هردو سیستم انجام شده است
               */
               FOR XML PATH('Router_Command')
         );
         L$StrtCalling2:
         EXEC dbo.RouterdbCommand @X = @xTemp, @xRet = @xRet OUTPUT -- xml      
         IF @xRet.query('//Router_Command').value('(Router_Command/@needrecall)[1]', 'VARCHAR(3)') = '002'
         BEGIN
            SET @xTemp = @xRet;
            GOTO L$StrtCalling2;
         END      
         
         -- پیام بازگشت به سمت مشتری	   
	      SET @xRet = (
	          SELECT 'successful' AS '@rsltdesc',
                    '002' AS '@rsltcode',
                    o.CODE AS '@ordrcode', 
	                 N'🖐 ☺️ از پرداخت شما متشکریم' + CHAR(10) + 
	                 N'💵 شرح سند : پرداخت صورتحساب ' + CHAR(10) + 
	                 N'👈 [ شماره فاکتور ] : *' + CAST(o.CODE AS NVARCHAR(20)) + N'*' + CHAR(10) + 
	                 N'👈 [ کد سیستم ] : *' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(20)) + N'*' + CHAR(10) + 
	                 N'💵 [ مبلغ قابل پرداخت فاکتور ] : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) + 
	                 CASE ISNULL(o.DSCN_AMNT_DNRM, 0) WHEN 0 THEN '' ELSE N'🤑 [ تخفیف و سود شما ] : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.DSCN_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) END +
	                 N'🗓 [ تاریخ و ساعت ایجاد فاکتور ] : ' + dbo.GET_MTOS_U(o.STRT_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + CHAR(10) +
	                 N'🗓 [ تاریخ و ساعت پرداخت فاکتور ] : ' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.END_DATE AS TIME(0)) AS VARCHAR(5)) + CHAR(10) +
	                 N'📑 [ شرح پرداخت شما ] : ' + CHAR(10) + 
	                 (
	                  SELECT N'◀️ *' + a.DOMN_DESC + N'* ' + 
	                         N'📅 *' + dbo.GET_MTOS_U(ISNULL(os.CONF_DATE, GETDATE())) + N'* ' + 
                            N'💰 *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, os.AMNT), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' +
                            CASE LEN(os.TXID) WHEN 0 THEN '' ELSE N'✅ *' + os.TXID + N'*' END + CHAR(10)
	                    FROM dbo.Order_State os, dbo.[D$AMTP] a
	                   WHERE os.ORDR_CODE = o.CODE
	                     AND os.AMNT_TYPE IN ('001', '002', '005')
	                     AND os.CONF_STAT = '002'
	                     AND os.AMNT_TYPE = a.VALU
	                   ORDER BY os.CRET_DATE
	                     FOR XML PATH('')
	                 )
	           FROM dbo.[Order] o, dbo.[D$AMUT] au
	          WHERE o.CODE = @OrdrCode
	            AND o.AMNT_TYPE = au.VALU
	        FOR XML PATH('Message'), ROOT('Result')
	      );
	   END 	   
   END 
   ELSE IF @OrdrType = '013' /* درخواست افزایش اعتبار کیف پول */
   BEGIN
      -- اگر هیچ گونه پرداختی ثبت نشده باشد و مشتری به صورت کامل کارت به کارت کرده باشد
      IF NOT EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE IN ('001' /* وصولی مستقیم / کارت اعتباری / کیف پول */, '005' /* رسید پرداخت */))
      BEGIN
         -- درج ردیف وصولی در جدول وضعیت درخواست
         INSERT INTO dbo.Order_State
         (ORDR_CODE ,CODE ,STAT_DATE ,AMNT ,AMNT_TYPE ,
          RCPT_MTOD ,DEST_CARD_NUMB ,TXID , CONF_STAT, CONF_DATE )
         VALUES  
         (@OrdrCode, 0, GETDATE(), @TotlAmnt, '001',
          @RcptMtod, @DestCardNumb, @Txid, '002', GETDATE());
      END 
      ELSE -- اگر ثبت وصولی درخواست داشته باشد
      BEGIN
         -- اگر آخرین روش پرداخت به صورت کارت به کارت باشد
         IF LEN(@Txid) != 0 -- در هر حالتی این شرط برقرار می باشد
         BEGIN
            -- درج ردیف وصولی در جدول وضعیت درخواست
            INSERT INTO dbo.Order_State
            (ORDR_CODE ,CODE ,STAT_DATE ,AMNT ,AMNT_TYPE ,
             RCPT_MTOD ,DEST_CARD_NUMB ,TXID , CONF_STAT, CONF_DATE )
            VALUES  
            (@OrdrCode, 0, GETDATE(), @TotlAmnt, '001',
             @RcptMtod, @DestCardNumb, @Txid, '002', GETDATE());
         END
      END
      
      -- ابتدا باید این مبلغ به حساب نقدینگی شرکت انارسافت برود
      SELECT @WletCode = w.CODE
        FROM dbo.[Order] o, dbo.Robot_Card_Bank_Account b, dbo.Service_Robot_Card_Bank a, dbo.Service_Robot sr, dbo.Wallet w
       WHERE o.CODE = @OrdrCode
         AND o.DEST_CARD_NUMB_DNRM = b.CARD_NUMB
         AND b.ORDR_TYPE = o.ORDR_TYPE
         AND b.ROBO_RBID = o.SRBT_ROBO_RBID
         AND b.ACNT_TYPE = '001' -- حساب شرکت انارسافت
         AND b.ACNT_STAT = '002' -- حساب فعال باشد
         AND b.CODE = a.RCBA_CODE
         AND a.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
         AND a.SRBT_ROBO_RBID = sr.ROBO_RBID
         AND a.CHAT_ID = sr.CHAT_ID
         AND sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
         AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
         AND o.SRBT_ROBO_RBID = @Rbid
         AND w.WLET_TYPE = '002' /* Cash Wallet */;
      
      -- مشتری هزینه را پرداخت کرده است و حالا در جدول های مربوطه ذخیره میکنیم
      -- ابتدا حساب شرکت را بروزرسانی میکنیم 
      INSERT INTO dbo.Wallet_Detail( ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC )
      SELECT os.ORDR_CODE, @WletCode, dbo.GNRT_NVID_U(), @AmntType, os.AMNT, os.STAT_DATE, '001' /* ورودی */, os.CONF_STAT, os.CONF_DATE, N'افزایش مبلغ نقدینگی از طرف مشتری'
        FROM dbo.Order_State os
       WHERE os.ORDR_CODE = @OrdrCode
         AND os.AMNT_TYPE IN ('001' /* وصولی مستقیم / کارت اعتباری / کیف پول */, '005' /* رسید پرداخت */)
         AND os.CONF_STAT = '002';
      
      -- ## 1399/08/04 ** در این قسمت باید یک درخواست برداشت وجه هم زده شود تا پول از حساب کیف پول نقدینگی شرکت خارج شده و به شماره کارت مقصد واریز شود
       SELECT @XTemp =
       (
           SELECT 12 AS '@subsys',
                  '024' AS '@ordrtype',
                  '000' AS '@typecode',
                  @ChatID AS '@chatid',
                  @Rbid AS '@rbid',
                  '' AS '@ussdcode',
                  '' AS '@input',
                  0 AS '@ordrcode'
           FOR XML PATH('Action'), ROOT('Cart')
       );
       EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
       -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
       SELECT @RsltCode = @XTemp.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)'),
              @TOrdrCode = @XTemp.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');

       IF @RsltCode = '002'
       BEGIN
           -- قرار دادن شماره کارت مشتری برای درخواست واریز وجه
           MERGE dbo.Order_Detail T
           USING
           (SELECT os.ORDR_CODE, os.AMNT AS DPST_AMNT FROM dbo.Order_State os WHERE os.ORDR_CODE = @TOrdrCode AND os.CONF_STAT = '002' AND os.AMNT_TYPE IN ('001', '005')) S
           ON (T.ORDR_CODE = S.ORDR_CODE)
           WHEN NOT MATCHED THEN
               INSERT
               (
                   ORDR_CODE,
                   ELMN_TYPE,
                   ORDR_CMNT,
                   ORDR_DESC,
                   EXPN_PRIC,
                   NUMB
               )
               VALUES
               (S.ORDR_CODE, '001', N'درخواست واریز وجه', N'درخواست مبلغ برای واریز وجه به حساب شرکت',
                S.DPST_AMNT, 1)
           WHEN MATCHED THEN
               UPDATE SET T.EXPN_PRIC = S.DPST_AMNT,
                          T.NUMB = 1;
           
           -- بروزرسانی جدول درخواست وجه
           UPDATE o24
           SET o24.EXPN_AMNT =
               (
                   SELECT SUM(od.EXPN_PRIC * od.NUMB)
                   FROM dbo.Order_Detail od
                   WHERE od.ORDR_CODE = o24.CODE
               ),
               o24.AMNT_TYPE = @AmntType,
               o24.DEST_CARD_NUMB_DNRM = o13.DEST_CARD_NUMB_DNRM
           FROM dbo.[Order] o24, dbo.[Order] o13
           WHERE o24.CODE = @TOrdrCode
             AND o13.CODE = @OrdrCode;
           
           -- ثبت ردیف برداشت برای حساب شرکت
           INSERT INTO dbo.Wallet_Detail( ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC )
           SELECT @TOrdrCode, @WletCode, dbo.GNRT_NVID_U(), @AmntType, os.AMNT, os.STAT_DATE, '002' /* خروجی */, os.CONF_STAT, os.CONF_DATE, N'برداشت مبلغ نقدینگی از طرف حساب کیف پول نقدینگی شرکت جهت تسویه حساب'
             FROM dbo.Order_State os
            WHERE os.ORDR_CODE = @OrdrCode
              AND os.AMNT_TYPE IN ('001' /* وصولی مستقیم / کارت اعتباری / کیف پول */, '005' /* رسید پرداخت */)
              AND os.CONF_STAT = '002';
       END;
      
      -- مرحله دوم باید این مبلغ به حساب اعتباری مشتری برود
      SELECT @WletCode = w.CODE
        FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Wallet w
       WHERE o.CODE = @OrdrCode
         AND o.CHAT_ID = sr.CHAT_ID
         AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
         AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
         AND sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
         AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
         AND o.SRBT_ROBO_RBID = @Rbid
         AND w.WLET_TYPE = '001' /* Credit Wallet */;
      
      -- مشتری هزینه را پرداخت کرده است و حالا در جدول های مربوطه ذخیره میکنیم
      -- ابتدا حساب شرکت را بروزرسانی میکنیم 
      INSERT INTO dbo.Wallet_Detail( ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC )
      SELECT os.ORDR_CODE, @WletCode, dbo.GNRT_NVID_U(), @AmntType, os.AMNT, os.STAT_DATE, '001' /* ورودی */, os.CONF_STAT, os.CONF_DATE, N'افزایش مبلغ اعتباری برای مشتری'
        FROM dbo.Order_State os
       WHERE os.ORDR_CODE = @OrdrCode
         AND os.AMNT_TYPE IN ('001' /* وصولی مستقیم / کارت اعتباری / کیف پول */, '005' /* رسید پرداخت */)
         AND os.CONF_STAT = '002';
      
      -- پایان درخواست
      UPDATE dbo.[Order]
         SET ORDR_STAT = '004',
             END_DATE = GETDATE(),
             TXID_DNRM = @Txid
       WHERE CODE = @OrdrCode;
      
      -- ثبت و ذخیره سازی درون سیستم ارتا
      -- کاری که باید انجام دهیم این است که مبلغ افزایش اعتبار را برای مشتری ثبت کنیم
      -- ******
      -- ****** To Do
      -- ******      
      SELECT @xTemp = (
         SELECT o.SUB_SYS AS '@subsys'
               ,'100' AS '@cmndcode' -- عملیات جامع ذخیره سازی
               ,12 AS '@refsubsys' -- محل ارجاعی
               ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
               ,o.CODE AS '@refcode'
               ,o.ORDR_NUMB AS '@refnumb' -- تعداد شماره درخواست ثبت شده
               ,o.STRT_DATE AS '@strtdate'
               ,o.END_DATE AS '@enddate'
               ,o.CHAT_ID AS '@chatid'
               ,sr.REAL_FRST_NAME AS '@frstname'
               ,sr.REAL_LAST_NAME AS '@lastname'
               ,sr.NATL_CODE AS '@natlcode'
               ,sr.OTHR_CELL_PHON AS '@cellphon'
               ,o.AMNT_TYPE AS '@amnttype'
               ,o.PYMT_MTOD AS '@pymtmtod'
               ,os.STAT_DATE AS '@pymtdate'
               ,os.AMNT - ISNULL(os.TXFE_AMNT, 0) AS '@amnt'
               ,os.TXID AS '@txid'
               ,o.TXFE_AMNT_DNRM AS '@txfeamnt'
               ,o.TXFE_CALC_AMNT_DNRM AS '@txfecalcamnt'
               ,o.TXFE_PRCT_DNRM AS '@txfeprct'
               ,(
                  SELECT od.TARF_DATE AS '@tarfdate'
                        ,od.EXPN_PRIC AS '@expnpric'
                        ,od.EXTR_PRCT AS '@extrprct'
                        ,od.DSCN_AMNT_DNRM AS '@dscnpric'
                        ,od.RQTP_CODE_DNRM AS '@rqtpcode'
                        ,od.NUMB AS '@numb'
                        ,od.ORDR_CMNT + N' ' + od.BASE_USSD_CODE + CHAR(10) + od.ORDR_DESC                         
                    FROM dbo.Order_Detail od
                   WHERE od.ORDR_CODE = o.CODE
                     FOR XML PATH('Expense'), TYPE                     
               )
           FROM dbo.[Order] o, dbo.Order_State os, dbo.Service_Robot sr
          WHERE o.CODE = @OrdrCode
            AND o.CODE = os.ORDR_CODE
            AND o.CHAT_ID = sr.CHAT_ID
            AND sr.ROBO_RBID = @Rbid
            AND os.AMNT_TYPE = '001' -- درآمد
            AND o.ORDR_STAT = '004' -- درخواست پایانی شده باشد                
            AND ISNULL(o.ARCH_STAT, '001') = '001' -- بایگانی نشده باشد            
            /*
               زمانی که درخواست به دست زیر سیستم مورد میرسد و عملیاتی میشود ستون بایگانی به حالت 002 در می آید
               که متوجه شویم این درخواست ها به صورت کامل درون سیستم ذخیره شده اند
               این گزینه بخاطر این هست که ممکن است مشترکی که در زیر سیستم دیگر قرار میگیرد در وضعیت قفل قرار گرفته باشد بخاطر همین 
               باید وضعیت هر دو طرف درون سیستم ذخیره شود که متوجه شویم عملیات به درستی درون هردو سیستم انجام شده است
            */
            FOR XML PATH('Router_Command')
      );
      L$StrtCalling3:
      EXEC dbo.RouterdbCommand @X = @xTemp, @xRet = @xRet OUTPUT -- xml      
      IF @xRet.query('//Router_Command').value('(Router_Command/@needrecall)[1]', 'VARCHAR(3)') = '002'
      BEGIN
         SET @xTemp = @xRet;
         GOTO L$StrtCalling3;
      END
         
      -- پیام بازگشت به سمت مشتری
      SELECT @xRet = (
         SELECT N'🖐 ☺️ از پرداخت شما متشکریم' + CHAR(10) + 
                N'💵 شرح سند : پرداخت صورتحساب ' + CHAR(10) + CHAR(10) + 
                N'👈 [ شماره فاکتور ] : ' + CAST(o.CODE AS NVARCHAR(20)) + CHAR(10) + 
                N'👈 [ کد سیستم ] : ' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(20)) + CHAR(10) + 
                N'💵 [ مبلغ فاکتور ] : ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N' [ ' + au.DOMN_DESC + N' ] ' + CHAR(10) + 
                N'🗓 [ تاریخ و ساعت ایجاد فاکتور ] : ' + dbo.GET_MTOS_U(o.STRT_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + CHAR(10) +
                N'🗓 [ تاریخ و ساعت پرداخت فاکتور ] : ' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.END_DATE AS TIME(0)) AS VARCHAR(5)) + CHAR(10) +
                N'📑 [ شماره پیگیری ] : ' + o.TXID_DNRM 
                --N'💳 [ کارت مقصد ] : ' + o.DEST_CARD_NUMB_DNRM
           FROM dbo.[Order] o, dbo.[D$AMUT] au
          WHERE o.CODE = @OrdrCode
            AND o.AMNT_TYPE = au.VALU
        FOR XML PATH('Message'), ROOT('Result')
      );
   END 
   ELSE IF @OrdrType = '023' /* درخواست های هزینه ارسال پیک */
   BEGIN
      -- شماره درخواست هزینه ارسال پیک
      SET @TCode = @OrdrCode;
      
      -- اگر درخواست پرداخت پیک هیچ وصولی نداشته باشد و این وصولی از طریق پرداخت انلاین به وجود آماده باشد
      IF NOT EXISTS(SELECT * FROM dbo.[Order_State] os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE = '001' /* وصولی مستقیم / کارت اعتباری / کیف پول */)
      BEGIN
         -- اگر آخرین عملیات روی درخواست پرداخت کارت به کارت مشتری باشد باید ردیف آن را ذخیره کنیم
	      IF LEN(@Txid) != 0
	      BEGIN
	         -- درج ردیف وصولی در جدول وضعیت درخواست
	         INSERT INTO dbo.Order_State
            (ORDR_CODE ,CODE ,STAT_DATE ,AMNT ,AMNT_TYPE ,
             RCPT_MTOD ,SORC_CARD_NUMB ,DEST_CARD_NUMB ,TXID ,TXFE_PRCT ,
             TXFE_CALC_AMNT ,TXFE_AMNT, CONF_STAT, CONF_DATE )
	         VALUES  
	         (@OrdrCode, 0, GETDATE(), @TotlAmnt, '001',
	          @RcptMtod, @SorcCardNumb, @DestCardNumb, @Txid, @TxfePrct, 
	          @TxfeCalcAmnt, @TxfeAmnt, '002', GETDATE());
	      END
      END 
      -- در این قسمت درخواست هزینه پیک پایانی میشود
      -- درخواست خود پیک پایانی میشود
      -- درخواست انباردار پایانی میشود
      -- درخواست حسابدار پایانی میشود
      -- درخواست اعلام به مشتری پایانی میشود
      -- تاییدیه ردیف های وضعیت درخواست
      UPDATE dbo.Order_State
         SET CONF_STAT = '002',
             CONF_DATE = ISNULL(CONF_DATE, GETDATE())
       WHERE ORDR_CODE = @OrdrCode
         AND AMNT_TYPE IN ('001' /* وصولی مستقیم / کارت اعتباری / کیف پول */, '002' /* تخفیف */, '005' /* رسید پرداخت */)
      
      -- بروزرسانی درخواست حق الزحمه ارسال سفارش
      UPDATE dbo.[Order]
         SET ORDR_STAT = '004',
             ARCH_STAT = '002'
       WHERE CODE = @OrdrCode;
      
      -- شماره کیف پول نقدینگی پیک
      SELECT @WletCode = w.CODE
        FROM dbo.Service_Robot sr, dbo.Wallet w, dbo.[Order] o1, dbo.[Order] o2
       WHERE sr.ROBO_RBID = @Rbid
         AND sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
         AND sr.ROBO_RBID = w.SRBT_ROBO_RBID         
         AND w.CHAT_ID = sr.CHAT_ID
         AND w.WLET_TYPE = '002' -- کیف پول نقدینگی
         AND o1.CODE = @OrdrCode -- هزینه ارسال پیک
         AND o2.CODE = o1.ORDR_CODE -- پیک موتوری
         AND o2.SRBT_SERV_FILE_NO = w.SRBT_SERV_FILE_NO
         AND o2.SRBT_ROBO_RBID = w.SRBT_ROBO_RBID
         AND o2.CHAT_ID = w.CHAT_ID;      
      -- اگر پرداخت از طریق نقدی یا پرداخت انلاین باشد نیازی به وارد کردن اطلاعات درون کیف پول نیست
      IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.RCPT_MTOD = '005')
      BEGIN 
         -- واریز مبلغ اعتبار پرداخت شده از مشتری به حساب پیک
         INSERT INTO dbo.Wallet_Detail
         (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC )
         SELECT od.ORDR_CODE, @WletCode, 0, @AmntType, od.EXPN_PRIC, GETDATE(), '001' /* ورودی به کیف پول */, '002', GETDATE(), N'واریز مبلغ اعتبار به کیف پول بابت درآمد حق الزحمه ارسال بسته سفارش'
           FROM dbo.Order_Detail od
          WHERE od.ORDR_CODE = @OrdrCode;
      END 
       
      -- نگهداری شماره درخواست پرداخت هزینه ارسال بسته سفیر
      SET @TOrdrCode = @OrdrCode;
      -- مبلغ پرداخت شده بابت هزینه ارسال بسته
      SELECT @TAmnt = os.AMNT
        FROM dbo.Order_State os
       WHERE os.ORDR_CODE = @TOrdrCode
         AND os.AMNT_TYPE = '001';
          
      -- درخواست پیک موتری
      SELECT @OrdrCode = o.ORDR_CODE
        FROM dbo.[Order] o
       WHERE o.CODE = @OrdrCode;
      
      -- بروزرسانی و پایانی کردن اطلاعات درخواست زیر مجموعه سفارش مشتری
      UPDATE oa
         SET oa.ORDR_STAT = '004',
             oa.ARCH_STAT = '002'
        FROM dbo.[Order] o, dbo.[Order] oa
       WHERE o.CODE = @OrdrCode
         AND oa.ORDR_CODE = o.ORDR_CODE;
      
      -- درخواست سفارش
      SELECT @OrdrCode = o.ORDR_CODE
        FROM dbo.[Order] o
       WHERE o.CODE = @OrdrCode;
      
      UPDATE dbo.[Order]
         SET ORDR_STAT = '009'
       WHERE CODE = @OrdrCode;
      
      -- کسر مبلغ کارمزد از سفیر 
      IF @TAmnt != 0/* اگر هزینه ارسال توسط مشتری پرداخت میشود انگاه محاسبه کسر کارمزد از پیک انجام میشود */
      BEGIN
         -- بدست آوردن اطلاعات مربوط به نحوه ارسال بسته
         SELECT @THowShip = o.HOW_SHIP
           FROM dbo.[Order] o
          WHERE o.CODE = @OrdrCode;
         
         IF @THowShip = '002'
         BEGIN
            SELECT @TxfeTxid = t.TFID,
                   @TAmnt = @TAmnt * t.TXFE_PRCT / 100
              FROM dbo.Transaction_Fee t
             WHERE t.TXFE_TYPE = '005' -- ارسال بسته درون شهری
               AND t.STAT = '002';
         END
         ELSE IF @THowShip = '003' 
         BEGIN
            SELECT @TxfeTxid = t.TFID,
                   @TAmnt = @TAmnt * t.TXFE_PRCT / 100
              FROM dbo.Transaction_Fee t
             WHERE t.TXFE_TYPE = '006' -- ارسال بسته بیرون شهری
               AND t.STAT = '002';
         END 
         
         -- شماره کیف پول اعبتاری پیک
         SELECT @WletCode = w.CODE
           FROM dbo.Wallet w
          WHERE w.SRBT_ROBO_RBID = @Rbid
            AND w.WLET_TYPE = '001' -- کیف پول اعتباری
            AND w.CHAT_ID = (
                  SELECT wt.CHAT_ID
                    FROM dbo.Wallet wt
                   WHERE wt.CODE = @WletCode
                );
         
         INSERT INTO dbo.Wallet_Detail
         (TXFE_TFID ,ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC )
         VALUES  
         (@TxfeTxid, @TOrdrCode, @WletCode, 0, @AmntType, @TAmnt, GETDATE(), '002', '002', GETDATE(), N'کارمزد هزینه ارسال از سفیر');
      END 
      
      -- ثبت و ذخیره سازی درون سیستم ارتا
      -- کاری که باید انجام دهیم این است که هزینه پیک را به هزینه های بسته سفارش اضاقه کنیم
      -- ******
      -- ****** To Do
      -- ******
      SELECT @xTemp = (
         SELECT o.SUB_SYS AS '@subsys'
               ,'106' AS '@cmndcode' -- عملیات جامع ذخیره سازی
               ,12 AS '@refsubsys' -- محل ارجاعی
               ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
               ,@OrdrCode AS '@refcode'
               ,o.CHAT_ID AS '@chatid'
               ,o.AMNT_TYPE AS '@amnttype'
               ,os.RCPT_MTOD AS '@pymtmtod'
               ,os.STAT_DATE AS '@pymtdate'
               ,os.AMNT AS '@amnt'
               ,os.TXID AS '@txid'
           FROM dbo.[Order] o, dbo.Order_State os
          WHERE o.CODE = @TCode
            AND o.CODE = os.ORDR_CODE
            AND os.AMNT_TYPE = '001' -- درآمد
            AND o.ORDR_STAT = '004' -- درخواست پایانی شده باشد                
            --AND ISNULL(o.ARCH_STAT, '001') = '001' -- بایگانی نشده باشد            
            /*
               زمانی که درخواست به دست زیر سیستم مورد میرسد و عملیاتی میشود ستون بایگانی به حالت 002 در می آید
               که متوجه شویم این درخواست ها به صورت کامل درون سیستم ذخیره شده اند
               این گزینه بخاطر این هست که ممکن است مشترکی که در زیر سیستم دیگر قرار میگیرد در وضعیت قفل قرار گرفته باشد بخاطر همین 
               باید وضعیت هر دو طرف درون سیستم ذخیره شود که متوجه شویم عملیات به درستی درون هردو سیستم انجام شده است
            */
            FOR XML PATH('Router_Command')
      );
      L$StrtCalling4:
      EXEC dbo.RouterdbCommand @X = @xTemp, @xRet = @xRet OUTPUT -- xml      
      IF @xRet.query('//Router_Command').value('(Router_Command/@needrecall)[1]', 'VARCHAR(3)') = '002'
      BEGIN
         SET @xTemp = @xRet;
         GOTO L$StrtCalling4;
      END
      
      -- پیام بازگشت به سمت مشتری
      SELECT @xRet = (
         SELECT N'🖐 ☺️ از پرداخت شما متشکریم' + CHAR(10) + 
                N'💵 شرح سند : پرداخت صورتحساب ' + CHAR(10) + CHAR(10) + 
                N'👈 [ شماره فاکتور ] : ' + CAST(o.CODE AS NVARCHAR(20)) + CHAR(10) + 
                N'👈 [ کد سیستم ] : ' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(20)) + CHAR(10) + 
                N'💵 [ مبلغ فاکتور ] : ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N' [ ' + au.DOMN_DESC + N' ] ' + CHAR(10) + 
                N'🗓 [ تاریخ و ساعت ایجاد فاکتور ] : ' + dbo.GET_MTOS_U(o.STRT_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + CHAR(10) +
                N'🗓 [ تاریخ و ساعت پرداخت فاکتور ] : ' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.END_DATE AS TIME(0)) AS VARCHAR(5)) + CHAR(10) +
                N'📑 [ شماره پیگیری ] : ' + o.TXID_DNRM 
                --N'💳 [ کارت مقصد ] : ' + o.DEST_CARD_NUMB_DNRM
           FROM dbo.[Order] o, dbo.[D$AMUT] au
          WHERE o.CODE = @OrdrCode
            AND o.AMNT_TYPE = au.VALU
        FOR XML PATH('Message'), ROOT('Result')
      );
      
      SET @OrdrCode = NULL;
   END 
   ELSE IF @OrdrType = '024' /* درخواست انتقال وجه برای مشتری */   
   BEGIN
      -- Step 1 : Insert into Order_State for payment
      -- درج ردیف وصولی در جدول وضعیت درخواست
      IF @RcmtMtod = '009'/* اگر پرداخت به صورت کارت کارت انجام شده باشد */
      BEGIN 
         INSERT INTO dbo.Order_State
         ( ORDR_CODE ,CODE ,STAT_DATE ,AMNT ,AMNT_TYPE ,
           RCPT_MTOD ,SORC_CARD_NUMB ,DEST_CARD_NUMB ,TXID ,TXFE_PRCT ,
           TXFE_CALC_AMNT ,TXFE_AMNT, CONF_STAT, CONF_DATE, CONF_DESC, FILE_ID )
         VALUES  
         ( @OrdrCode, 0, GETDATE(), @TotlAmnt, '001',
           @RcmtMtod, @SorcCardNumb, @DestCardNumb, @Txid, @TxfePrct, 
           @TxfeCalcAmnt, @TxfeAmnt, '002', GETDATE(), N'تایید پرداخت درخواست وجه مشتری', NULL );
      END
      ELSE IF @RcmtMtod = '013' /* پرداخت از طریق واریز شبا */
      BEGIN
         -- ابتدا ردیف پرداخت را تایید میکنیم
         UPDATE os
            SET os.CONF_STAT = '002', 
                os.CONF_DATE = GETDATE(), 
                os.CONF_DESC = N'تایید پرداخت درخواست وجه مشتری',
                os.AMNT = o024.SUM_EXPN_AMNT_DNRM,
                os.TXFE_AMNT = o024.SUM_FEE_AMNT_DNRM,
                os.SORC_CARD_NUMB = o017.SORC_CARD_NUMB_DNRM,
                os.DEST_CARD_NUMB = o017.DEST_CARD_NUMB_DNRM,
                os.ORDR_CODE = o024.CODE,
                os.TXID = o017.CODE
           FROM dbo.Order_State os, dbo.[Order] o017, dbo.[Order] o024
          WHERE o024.CODE = @OrdrCode
            AND o024.CODE = o017.ORDR_CODE
            AND o017.ORDR_TYPE = '017'
            AND os.ORDR_CODE = o017.CODE;        
      END 
      
      -- در این قسمت برای فروشگاه ما باید مشخص کنیم که کدام یک از اعضا ربات به عنوان مدیر محسوب می باشد که بتوانیم واریزی و برداشت ها را به آن منتسب کنیم
      SELECT TOP 1 
             @TChatId = sr.CHAT_ID
        FROM dbo.Service_Robot sr, dbo.Service_Robot_Group srg, dbo.[Group] g
       WHERE sr.SERV_FILE_NO = srg.SRBT_SERV_FILE_NO
         AND sr.ROBO_RBID = srg.SRBT_ROBO_RBID
         AND srg.GROP_GPID = g.GPID
         AND sr.ROBO_RBID = @Rbid
         AND srg.STAT = '002'
         AND g.STAT = '002'
         AND g.ADMN_ORGN = '002'
         AND g.GPID = 131;         
      
      -- Step 2 : Insert into Wallet out payment for customer
      -- Step 3 : Insert into Wallet out payment for shop
      INSERT INTO dbo.Wallet_Detail
      (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT, CONF_DATE, CONF_DESC)
      -- حساب مشتری
      SELECT o.CODE, w.CODE, dbo.GNRT_NVID_U(), o.AMNT_TYPE, o.SUM_EXPN_AMNT_DNRM, GETDATE(), '002', '002', GETDATE(), N'مبلغ برداشت بابت درخواست انتقال وجه از کیف پول'
        FROM dbo.[Order] o, dbo.Wallet w
       WHERE o.CODE = @OrdrCode
         AND o.SRBT_SERV_FILE_NO = w.SRBT_SERV_FILE_NO
         AND o.SRBT_ROBO_RBID = w.SRBT_ROBO_RBID
         AND o.CHAT_ID = w.CHAT_ID
         AND w.WLET_TYPE = '002'; -- کیف پول نقدینگی
      
      INSERT INTO dbo.Wallet_Detail
      (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT, CONF_DATE, CONF_DESC)
      -- ثبت کارمزد از حساب مشتری
      SELECT o.CODE, w.CODE, dbo.GNRT_NVID_U(), o.AMNT_TYPE, ISNULL(o.SUM_FEE_AMNT_DNRM, 0), GETDATE(), '002', '002', GETDATE(), N'مبلغ کارمزد برداشت بابت درخواست انتقال وجه از کیف پول'
        FROM dbo.[Order] o, dbo.Wallet w
       WHERE o.CODE = @OrdrCode
         AND o.SRBT_SERV_FILE_NO = w.SRBT_SERV_FILE_NO
         AND o.SRBT_ROBO_RBID = w.SRBT_ROBO_RBID
         AND o.CHAT_ID = w.CHAT_ID
         AND ISNULL(o.TXFE_AMNT_DNRM, 0) > 0
         AND w.WLET_TYPE = '002' -- کیف پول نقدینگی
       UNION
      -- پرداخت فروشگاه
      SELECT o.CODE, w.CODE, dbo.GNRT_NVID_U(), o.AMNT_TYPE, o.SUM_EXPN_AMNT_DNRM, GETDATE(), '002', '002', GETDATE(), N'مبلغ برداشت بابت درخواست انتقال وجه از کیف پول'
        FROM dbo.[Order] o, dbo.Wallet w
       WHERE o.CODE = @OrdrCode
         AND o.SRBT_ROBO_RBID = w.SRBT_ROBO_RBID
         AND @TChatId = w.CHAT_ID -- اطلاعات کیف پول فروشگاه
         AND w.WLET_TYPE = '002'; -- کیف پول نقدینگی
      -- UNION 
      --SELECT o.CODE, w.CODE, dbo.GNRT_NVID_U(), o.AMNT_TYPE, ISNULL(o.SUM_FEE_AMNT_DNRM, 0) / 2, GETDATE(), '001', '003', N'مبلغ کارمزد برداشت بابت درخواست انتقال وجه از کیف پول به صورت شبا بانکی'
      --  FROM dbo.[Order] o, dbo.Wallet w
      -- WHERE o.CODE = @OrdrCode
      --   AND o.SRBT_ROBO_RBID = w.SRBT_ROBO_RBID
      --   AND @TChatId = w.CHAT_ID -- اطلاعات کیف پول فروشگاه
      --   AND w.WLET_TYPE = '002' -- کیف پول نقدینگی
      --   AND ISNULL(o.TXFE_AMNT_DNRM, 0) > 0
      --   AND @RcmtMtod = '013' /* پرداخت از طریق شبا انجام شده باشد */;
         
      ---- Step 4 : Send message to customer for successfull withdraw
      --UPDATE dbo.Personal_Robot_Job_Order
      --   SET ORDR_STAT = '001'
      -- WHERE ORDR_CODE = (
      --       SELECT o.CODE
      --         FROM dbo.[Order] o
      --        WHERE o.ORDR_CODE = @OrdrCode
      --          AND o.ORDR_TYPE = '012'
      --       );
      
      ---- ارسال پیام به مشتری
      --INSERT INTO dbo.Order_Detail(ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , ORDR_DESC)
      --SELECT o.CODE, '001', N'انتقال وجه از کیف پول به حساب بانکی', 
      --       N'*' + o.OWNR_NAME + N'* عزیز' + CHAR(10) + 
      --       N'مبلغ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @TotlAmnt), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' با شماره پیگیری *' + @Txid + N'*' + 
      --       CASE @RcmtMtod
      --            WHEN '013' THEN N' *شبا* گردید و طی *24* ساعت آینده از طرف *بانک* به حساب شما *واریز* میگردد' 
      --            WHEN '009' THEN N' *کارت به کارت* گردید و به حساب شما *واریز* گردید'
      --       END + CHAR(10) + 
      --       N'با تشکر'
      --  FROM dbo.[Order] o
      -- WHERE o.ORDR_CODE = @OrdrCode
      --   AND o.ORDR_TYPE = '012';

      -- ارسال پیام برای مشتری جهت پرداخت وجه درخواستی
      -- در این قسمت متن پیام به صورت ارسال عکس مربوط به رسید شبا برای مشتری باشد
      -- بدست آوردن شماره درخواست اعلام به مشتری
      SELECT @TOrdrCode = o.CODE
        FROM dbo.[Order] o
       WHERE o.ORDR_CODE = @OrdrCode
         AND o.ORDR_TYPE = '012';
      
      UPDATE dbo.Personal_Robot_Job_Order
         SET ORDR_STAT = '001'
       WHERE ORDR_CODE = @TOrdrCode;
      
      -- آماده سازی پیام برای مشتری
      INSERT INTO dbo.Order_Detail
      ( ORDR_CODE ,ELMN_TYPE ,ORDR_DESC ,EXPN_PRIC ,NUMB ,ORDR_CMNT ,IMAG_PATH )
      SELECT o012.CODE, CASE WHEN os.[FILE_ID] IS NULL THEN '001' ELSE '002' END , 
             N'*' + o024.OWNR_NAME + N'* عزیز' + CHAR(10) + 
             N'مبلغ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o024.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' با شماره پیگیری *' + os.TXID + N'*' + 
             CASE @RcmtMtod
                  WHEN '013' THEN N' *شبا* گردید و طی *24* ساعت آینده از طرف *بانک* به حساب شما *واریز* میگردد' 
                  WHEN '009' THEN N' *کارت به کارت* گردید و به حساب شما *واریز* شد'
             END + CHAR(10) + 
             N'با تشکر',
             o024.SUM_EXPN_AMNT_DNRM, 1, N'رسید پرداخت درخواست وجه شما', os.FILE_ID
        FROM dbo.[Order] o012, dbo.[Order] o024, dbo.Order_State os
       WHERE o012.CODE = @TOrdrCode
         AND o012.ORDR_CODE = o024.CODE
         AND os.ORDR_CODE = o024.CODE;      
      
      -- محاسبه کسر کارمزد
      -- اگر فروشگاه به صورت شبا پرداخت کرده باشد مبلغ نصف مبلغ به فروشگاه میرسد و مبلغ دیگر به شرکت      
      -- کسر کارمزد از فروشگاه برای حساب شرکت
      INSERT INTO dbo.Wallet_Detail
      (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT, CONF_DATE, CONF_DESC)
      SELECT o.CODE, w.CODE, dbo.GNRT_NVID_U(), o.AMNT_TYPE, CASE @RcmtMtod WHEN '009' THEN ISNULL(o.SUM_FEE_AMNT_DNRM, 0) / 2 WHEN '013' THEN ISNULL(o.SUM_FEE_AMNT_DNRM, 0) END, GETDATE(), '002', '002', GETDATE(),  
      CASE @RcptMtod
           WHEN '013' THEN N'مبلغ کارمزد برداشت بابت درخواست انتقال وجه از کیف پول به صورت شبا بانکی'
           WHEN '009' THEN N'مبلغ کارمزد برداشت بابت درخواست انتقال وجه از کیف پول به صورت کارت به کارت بانکی'
      END 
        FROM dbo.[Order] o, dbo.Wallet w
       WHERE o.CODE = @OrdrCode
         AND o.SRBT_ROBO_RBID = w.SRBT_ROBO_RBID
         AND @TChatId = w.CHAT_ID
         AND w.WLET_TYPE = '001' -- کیف پول اعتباری
         AND ISNULL(o.TXFE_AMNT_DNRM, 0) > 0;
      
      -- ثبت و ذخیره سازی درون سیستم ارتا
      -- در این قسمت باید تغییرات ریالی برای مشتری ثبت شود که یکی بابت خود مبلغ هست و یکی هم بابت کسر کارمزد
      -- ******
      -- ****** To Do
      -- ******     
      SELECT @xTemp = (
         SELECT o.SUB_SYS AS '@subsys'
               ,'107' AS '@cmndcode' -- عملیات جامع ذخیره سازی
               ,12 AS '@refsubsys' -- محل ارجاعی
               ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
               ,o.CODE AS '@refcode'
               ,o.ORDR_NUMB AS '@refnumb' -- تعداد شماره درخواست ثبت شده
               ,o.STRT_DATE AS '@strtdate'
               ,o.CHAT_ID AS '@chatid'
               ,o.AMNT_TYPE AS '@amnttype'
               ,os.RCPT_MTOD AS '@pymtmtod'
               ,os.STAT_DATE AS '@pymtdate'
               ,os.AMNT AS '@amnt'
               ,os.TXID AS '@txid'
           FROM dbo.[Order] o, dbo.Order_State os
          WHERE o.CODE = @OrdrCode
            AND o.CODE = os.ORDR_CODE
            AND os.AMNT_TYPE = '001' -- درآمد
            AND o.ORDR_STAT = '004' -- درخواست پایانی شده باشد                
            --AND ISNULL(o.ARCH_STAT, '001') = '001' -- بایگانی نشده باشد            
            /*
               زمانی که درخواست به دست زیر سیستم مورد میرسد و عملیاتی میشود ستون بایگانی به حالت 002 در می آید
               که متوجه شویم این درخواست ها به صورت کامل درون سیستم ذخیره شده اند
               این گزینه بخاطر این هست که ممکن است مشترکی که در زیر سیستم دیگر قرار میگیرد در وضعیت قفل قرار گرفته باشد بخاطر همین 
               باید وضعیت هر دو طرف درون سیستم ذخیره شود که متوجه شویم عملیات به درستی درون هردو سیستم انجام شده است
            */
            FOR XML PATH('Router_Command')
      );
      L$StrtCalling5:
      EXEC dbo.RouterdbCommand @X = @xTemp, @xRet = @xRet OUTPUT -- xml      
      IF @xRet.query('//Router_Command').value('(Router_Command/@needrecall)[1]', 'VARCHAR(3)') = '002'
      BEGIN
         SET @xTemp = @xRet;
         GOTO L$StrtCalling5;
      END
      
      -- پایانی کردن درخواستهای زیر مجموعه
      
      UPDATE dbo.[Order]
         SET ORDR_STAT = '004',
             ARCH_STAT = '002',
             END_DATE = GETDATE()
       WHERE ORDR_CODE = @OrdrCode;
      
      SELECT TOP 1 
             @Txid = os.TXID
        FROM dbo.Order_State os
       WHERE os.ORDR_CODE = @OrdrCode
         AND os.AMNT_TYPE IN ('001', '005')
         AND os.CONF_STAT = '002';
      
      -- پایانی شدن درخواست انتقال وجه مشتری
      UPDATE dbo.[Order]
         SET ORDR_STAT = '004',
             END_DATE = GETDATE(),
             TXID_DNRM = @Txid,
             PYMT_AMNT_DNRM = (SELECT SUM(os.AMNT) FROM dbo.Order_State os WHERE os.ORDR_CODE = dbo.[Order].CODE AND os.AMNT_TYPE IN ('001', '005') AND os.CONF_STAT = '002')
       WHERE CODE = @OrdrCode;
      
      SELECT @xRet = (
         SELECT N'🖐 ☺️ از پرداخت شما متشکریم' + CHAR(10) + 
                N'💵 شرح سند : پرداخت سند واریزی ' + CHAR(10) + CHAR(10) + 
                N'👈 [ شماره سند واریز ] : ' + CAST(o.CODE AS NVARCHAR(20)) + CHAR(10) + 
                N'👈 [ کد سیستم ] : ' + CAST(o.ORDR_TYPE_NUMB AS NVARCHAR(20)) + N' - ' + o.ORDR_TYPE + CHAR(10) + 
                N'💵 [ مبلغ سند ] : ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N' [ ' + au.DOMN_DESC + N' ] ' + CHAR(10) + 
                N'💵 [ مبلغ کسر کارمزد سند ] : ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_FEE_AMNT_DNRM), 1), '.00', '') + N' [ ' + au.DOMN_DESC + N' ] ' + CHAR(10) + 
                N'🗓 [ تاریخ و ساعت ایجاد سند ] : ' + dbo.GET_MTOS_U(o.STRT_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + CHAR(10) +
                N'🗓 [ تاریخ و ساعت پرداخت سند ] : ' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.END_DATE AS TIME(0)) AS VARCHAR(5)) + CHAR(10) +
                N'📑 [ شماره پیگیری ] : ' + o.TXID_DNRM 
                --N'💳 [ کارت مقصد ] : ' + o.DEST_CARD_NUMB_DNRM
           FROM dbo.[Order] o, dbo.[D$AMUT] au
          WHERE o.CODE = @OrdrCode
            AND o.AMNT_TYPE = au.VALU
        FOR XML PATH('Message'), ROOT('Result')
      );
      
      SET @OrdrCode = NULL;
   END 
   
   -- در آخرین قسمت اگر تابع به صورت مستقیم فراخوانی شده باشد باید دکمه های خروجی آن را هم برایش درست کنیم
   IF @DirCall = '002'
   BEGIN
      IF @OrdrType IN ( '004' ) /* در حال حاضر این گزینه برای سفارش انلاین در نظر گرفته شده است */
      BEGIN
         SET @XTemp = (
            SELECT @Rbid AS '@rbid'
                  ,@ChatID AS '@chatid'
                  ,'*0#' AS '@ussdcode'
                  ,'lessfinlcart' AS '@cmndtext'
                  ,@OrdrCode AS '@ordrcode'
               FOR XML PATH('RequestInLineQuery')
         )
         EXEC dbo.CRET_ILQM_P @X = @XTemp, -- xml
             @XRet = @XTemp OUTPUT; -- xml
         
         SET @xRet = (
            SELECT 'successful' AS '@rsltdesc',
                    '002' AS '@rsltcode',
                    (
                        SELECT '1' AS '@order',
                               @xRet.query('//Message').value('.', 'NVARCHAR(MAX)') AS '@caption',
                               @XTemp
                           FOR XML PATH('InlineKeyboardMarkup')
                    )
               FOR XML PATH('Message'), ROOT('Result')
         );
      END 
   END 
   
   -- Public Operation
   -- اگر در ردیف درخواست کارت اعتباری وجود داشته باشد باید مراحل ثبت آن هم برای مشتری درون ربات انجام دهیم
   IF EXISTS(
      SELECT * 
        FROM dbo.Order_Detail od, dbo.Robot_Product rp
       WHERE od.ORDR_CODE = @OrdrCode
         AND od.TARF_CODE = rp.TARF_CODE
         AND rp.ROBO_RBID = @Rbid
         AND rp.GROP_CODE_DNRM = 13992171200883 /* گروه کارت هدیه */
    )
    BEGIN
      INSERT INTO dbo.Service_Robot_Gift_Card
      (SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_CODE ,GCID ,
      CARD_NUMB ,AMNT ,BLNC_AMNT_DNRM ,VALD_TYPE, FILE_ID, FILE_TYPE, GIFT_TEXT )
      SELECT o.SRBT_SERV_FILE_NO, o.SRBT_ROBO_RBID, o.CODE, 0,
             SUBSTRING(CONVERT(VARCHAR(100), NEWID()),1, 8), od.EXPN_PRIC, od.EXPN_PRIC, '002',
             od.IMAG_PATH, od.ELMN_TYPE, od.ORDR_DESC
        FROM dbo.[Order] o, dbo.Order_Detail od, dbo.Robot_Product rp
       WHERE o.CODE = od.ORDR_CODE
         AND od.TARF_CODE = rp.TARF_CODE
         AND rp.ROBO_RBID = @Rbid
         AND o.CODE = @OrdrCode
         AND rp.GROP_CODE_DNRM = 13992171200883; /* گروه کارت هدیه */         
    END;
    
   -- اگر درخواست افزایش اعتبار مشتری ثبت کرده باشد باید درون کیف پول تغییرات را اعمال کنیم
   --IF EXISTS(
   --    SELECT *
   --      FROM dbo.[Order] o 
   --     WHERE o.CODE = @OrdrCode
   --       AND o.ORDR_TYPE = '015'                      
   -- )
   -- BEGIN
   --   -- آیا مشتری دارای معرف میباشد یا خیر
   --   SELECT @WletCode = w.CODE
   --     FROM dbo.Service_Robot sr, dbo.Wallet w
   --    WHERE sr.ROBO_RBID = @Rbid
   --      AND sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
   --      AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
   --      AND sr.CHAT_ID = @ChatId
   --      AND w.WLET_TYPE = '002'
   --      AND w.CHAT_ID = sr.CHAT_ID;
      
   --   INSERT INTO dbo.Wallet_Detail
   --   (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,
   --   AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC )
   --   SELECT od.ORDR_CODE, @WletCode, 0, @AmntType, od.EXPN_PRIC, GETDATE(), '001' /* ورودی به کیف پول */, '002', GETDATE(), N'افزایش مبلغ نقدینگی کیف پول'
   --     FROM dbo.Order_Detail od
   --    WHERE od.ORDR_CODE = @OrdrCode
   --      AND od.RQTP_CODE_DNRM = '020';         
   -- END 
    
   -- اگر فروشگاه سیستم پورسانت دهی برای مشتریان خودش قرار داده باشد اینجا باید برای مشتریان پورسانت آن را لحاظ کنیم 
   IF EXISTS (
         SELECT *
           FROM dbo.Transaction_Fee tf
          WHERE tf.TXFE_TYPE IN ( '003', '004' )
            AND tf.STAT = '002'
      ) AND 
      -- درخواست "ثبت سفارش"، "افزایش اعتبار کیف پول" فقط شامل پورسانت مجموعه میشود
      EXISTS (
         SELECT *
           FROM dbo.[Order] o, dbo.Service_Robot sr
          WHERE o.ORDR_TYPE IN ( '004'/*, '013'*/ )
            AND o.CODE = @OrdrCode
            AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
            AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
            AND o.CHAT_ID = sr.CHAT_ID
            AND ISNULL(sr.REF_CHAT_ID, 0) != 0
      )
   BEGIN
      -- محاسبه پورسانت بالاسری بابت فاکتور فروش یا افزایش اعتبار کیف پول
      SELECT @TxfeTxid = TFID, 
             @TxfeType = TXFE_TYPE,
             @TxfePrct = TXFE_PRCT
        FROM dbo.Transaction_Fee
       WHERE TXFE_TYPE IN ('003', '004')
         AND STAT = '002';

      -- پیدا کردن اطلاعات معرف مشتری
      SELECT @RefChatId = REF_CHAT_ID, @ConfDurtDay = CASE @OrdrType WHEN '004' THEN ISNULL(r.CONF_DURT_DAY, 7) WHEN '013' THEN 0 END ,
             @WletCode = w.CODE
        FROM dbo.Service_Robot sr, dbo.Robot r, dbo.Wallet w
       WHERE sr.ROBO_RBID = @Rbid
         AND sr.ROBO_RBID = r.RBID            
         AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
         AND sr.CHAT_ID = @ChatId
         AND w.CHAT_ID = sr.REF_CHAT_ID
         AND w.WLET_TYPE = CASE @OrdrType 
                                WHEN '004' /* ثبت سفارش */THEN 
                                     CASE @TxfeType 
                                          WHEN '004' THEN '002' /* کیف پول نقدینگی */ 
                                          WHEN '003' THEN '001' /* کیف پول اعتباری */ 
                                     END 
                                WHEN '013' /* افزایش اعتبار */ THEN 
                                     '001' /* کیف پول اعتباری */ 
                           END; 
      
      -- 1399/09/01 * محاسبه پورسانت معرفین
      -- اگر محاسبه کارمزد فروشگاه بر اساس مبلغ کل سفارش باشد
	   IF EXISTS (SELECT * FROM dbo.Transaction_Fee t WHERE t.TXFE_TYPE = '001' AND t.CALC_TYPE = '001' AND t.STAT = '002')
	   BEGIN
	      SET @TxfeCalcAmnt = (SELECT (o.SUM_EXPN_AMNT_DNRM - o.TXFE_AMNT_DNRM) * @TxfePrct / 100 FROM dbo.[Order] o WHERE o.CODE = @OrdrCode);	        
	   END 
	   -- اگر محاسبه کارمزد فروشگاه بر اساس سود سفارش باشد
	   ELSE -- EXISTS (SELECT * FROM dbo.Transaction_Fee t WHERE t.TXFE_TYPE = '007' AND t.CALC_TYPE = '001' AND t.STAT = '002')
	   BEGIN
	      SELECT @TxfeCalcAmnt =  SUM (CASE ISNULL(od.SUM_PRFT_PRIC_DNRM, 0) WHEN 0 THEN (od.SUM_EXPN_PRIC_DNRM - ISNULL(od.DSCN_AMNT_DNRM, 0)) ELSE (od.SUM_PRFT_PRIC_DNRM - ISNULL(od.DSCN_AMNT_DNRM, 0)) END) 
	        FROM dbo.Order_Detail od
	       WHERE od.ORDR_CODE = @OrdrCode;
	      
	      SET @TxfeCalcAmnt = @TxfeCalcAmnt * @TxfePrct / 100; 
	   END 
      
      -- ذخیره کردن پورسانت مشتری بالاسری در کیف پول
      /*INSERT INTO dbo.Wallet_Detail(TXFE_TFID, ORDR_CODE ,WLET_CODE ,CODE ,
      CHAT_ID ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT, CONF_DATE, CONF_DESC)
      VALUES(@TxfeTxid, @OrdrCode, @WletCode, dbo.GNRT_NVID_U(), 
             @RefChatId, @AmntType, ((@TotlAmnt - ISNULL(@TxfeAmnt, 0)) * @TxfePrct / 100), GETDATE(), '001', '003', DATEADD(DAY, @ConfDurtDay, GETDATE()), N'پورسانت فروش زیر مجموعه');*/
      
      INSERT INTO dbo.Wallet_Detail(TXFE_TFID, ORDR_CODE ,WLET_CODE ,CODE ,
      CHAT_ID ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT, CONF_DATE, CONF_DESC)
      VALUES(@TxfeTxid, @OrdrCode, @WletCode, dbo.GNRT_NVID_U(), 
             @RefChatId, @AmntType, @TxfeCalcAmnt, GETDATE(), '001', '003', DATEADD(DAY, @ConfDurtDay, GETDATE()), N'پورسانت فروش زیر مجموعه');
      
      -- ارسال پیام محاسبه پورسانت خرید زیر مجموعه برای بالاسری
      INSERT INTO dbo.[Order] ( SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,CHAT_ID ,SUB_SYS ,ORDR_CODE ,CODE ,ORDR_TYPE ,ORDR_STAT )
      SELECT sr.SERV_FILE_NO, sr.ROBO_RBID, sr.CHAT_ID, 5, @OrdrCode, dbo.GNRT_NVID_U(), '012', '001'
        FROM dbo.Service_Robot sr
       WHERE ROBO_RBID = @Rbid
         AND CHAT_ID = @RefChatId;
      
      IF @OrdrType = '004'/* پورسانت خرید زیرمجموعه */ AND @TxfeType = '004' /* دریافت پورسانت نقدی */
      BEGIN 
         INSERT INTO dbo.Order_Detail ( ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT ,ORDR_DESC ,IMAG_PATH )
         SELECT op.CODE, '002', N'گزارش محاسبه پورسانت نقدی', 
                N'*' + op.OWNR_NAME + N'* عزیز' + CHAR(10) + 
                N'😊🖐️ با سلام ضمن تشکر از زحمات شما ' + CHAR(10) + 
                N'📇 *محاسبه پاداش خرید*' + CHAR(10) + CHAR(10) +
                
                N'بابت 🛒 خرید *' + om.OWNR_NAME + N'* به مبلغ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, om.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' در تاریخ *' + dbo.GET_MTOS_U(om.END_DATE) + N'* پاداش *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, /*((@TotlAmnt - ISNULL(@TxfeAmnt, 0)) * @TxfePrct / 100)*/@TxfeCalcAmnt), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' برای شما لحاظ شده است.' + CHAR(10) + 
                N'🔵 این مبلغ حداکثر تا *' + @TNumStrn + N'* روز به حساب کیف پول شما واریز میگردد.' + CHAR(10) + CHAR(10) +
                
                N'📍 _' + om.SORC_POST_ADRS + N'_' + CHAR(10) + 
                N'📲 _' + om.SORC_CELL_PHON + N'_' + CHAR(10) + 
                N'☎️ _' + om.SORC_TELL_PHON + N'_' + CHAR(10) + CHAR(10) + 
                N'⏰ '+ dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)),
                (
                  SELECT TOP 1 
                         og.FILE_ID
                    FROM dbo.Organ_Media og
                   WHERE og.ROBO_RBID = @Rbid
                     AND og.STAT = '002'
                     AND og.RBCN_TYPE = '010'
                     AND og.IMAG_TYPE = '002'                
                )
           FROM dbo.[Order] op, dbo.[Order] om
          WHERE op.ORDR_CODE = @OrdrCode
            AND om.CODE = @OrdrCode
            AND op.ORDR_TYPE = '012'
            AND op.CHAT_ID = @RefChatId
            AND op.ORDR_STAT = '001'; 
      END 
      ELSE IF @OrdrType = '004'/* پورسانت خرید زیرمجموعه */ AND @TxfeType = '003' /* دریافت پورسانت اعتباری */
      BEGIN
         INSERT INTO dbo.Order_Detail ( ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT ,ORDR_DESC ,IMAG_PATH )
         SELECT op.CODE, '002', N'گزارش محاسبه پورسانت اعتباری', 
                N'*' + op.OWNR_NAME + N'* عزیز' + CHAR(10) + 
                N'😊🖐️ با سلام ضمن تشکر از زحمات شما ' + CHAR(10) + 
                N'📇 *محاسبه پاداش خرید*' + CHAR(10) + CHAR(10) +
                
                N'بابت 🛒 خرید *' + om.OWNR_NAME + N'* به مبلغ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, om.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' در تاریخ *' + dbo.GET_MTOS_U(om.END_DATE) + N'* پاداش *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, /*((@TotlAmnt - ISNULL(@TxfeAmnt, 0)) * @TxfePrct / 100)*/@TxfeCalcAmnt), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' برای شما لحاظ شده است.' + CHAR(10) + 
                N'🔵 این مبلغ حداکثر تا *' + @TNumStrn + N'* روز به حساب کیف پول شما واریز میگردد.' + CHAR(10) + CHAR(10) +
                
                N'📍 _' + om.SORC_POST_ADRS + N'_' + CHAR(10) + 
                N'📲 _' + om.SORC_CELL_PHON + N'_' + CHAR(10) + 
                N'☎️ _' + om.SORC_TELL_PHON + N'_' + CHAR(10) + CHAR(10) + 
                N'⏰ '+ dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)),
                (
                  SELECT TOP 1 
                         og.FILE_ID
                    FROM dbo.Organ_Media og
                   WHERE og.ROBO_RBID = @Rbid
                     AND og.STAT = '002'
                     AND og.RBCN_TYPE = '010'
                     AND og.IMAG_TYPE = '002'                
                )
           FROM dbo.[Order] op, dbo.[Order] om
          WHERE op.ORDR_CODE = @OrdrCode
            AND om.CODE = @OrdrCode
            AND op.ORDR_TYPE = '012'
            AND op.CHAT_ID = @RefChatId
            AND op.ORDR_STAT = '001'; 
      END 
      ELSE IF @OrdrType = '013'/* پورسانت افزایش اعتبار مشتریان یا زیر مجموعه */
      BEGIN
         INSERT INTO dbo.Order_Detail ( ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT ,ORDR_DESC ,IMAG_PATH )
         SELECT op.CODE, '002', N'گزارش محاسبه پورسانت اعتباری', 
                N'*' + op.OWNR_NAME + N'* عزیز' + CHAR(10) + 
                N'😊🖐️ با سلام ضمن تشکر از زحمات شما ' + CHAR(10) + 
                N'📇 *محاسبه پاداش افزایش اعتبار کیف پول*' + CHAR(10) + CHAR(10) +
                
                N'بابت 🛒 افزایش اعتبار کیف پول *' + om.OWNR_NAME + N'* به مبلغ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, om.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' در تاریخ *' + dbo.GET_MTOS_U(om.END_DATE) + N'* پاداش *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, /*((@TotlAmnt - ISNULL(@TxfeAmnt, 0)) * @TxfePrct / 100)*/@TxfeCalcAmnt), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' برای شما لحاظ شده است.' + CHAR(10) + 
                N'🔵 مبلغ به حساب کیف پول اعتباری شما واریز گردید.' + CHAR(10) + CHAR(10) +
                
                N'⏰ '+ dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)),
                (
                  SELECT TOP 1 
                         og.FILE_ID
                    FROM dbo.Organ_Media og
                   WHERE og.ROBO_RBID = @Rbid
                     AND og.STAT = '002'
                     AND og.RBCN_TYPE = '010'
                     AND og.IMAG_TYPE = '002'                
                )
           FROM dbo.[Order] op, dbo.[Order] om
          WHERE op.ORDR_CODE = @OrdrCode
            AND om.CODE = @OrdrCode
            AND op.ORDR_TYPE = '012'
            AND op.CHAT_ID = @RefChatId
            AND op.ORDR_STAT = '001'; 
      END
       
      -- پیدا کردن کد مربوط به ارسال پیامک
      SELECT @TDirPrjbCode = a.CODE,
             @TOrdrCode = o.CODE
        FROM dbo.Personal_Robot_Job a, dbo.Job b, dbo.[Order] o
       WHERE a.PRBT_ROBO_RBID = @Rbid
         AND a.JOB_CODE = b.CODE
         AND b.ORDR_TYPE = '012' /* اعلام دریافت پورسانت */
         AND o.ORDR_TYPE = '012' /* اعلام دریافت پورسانت */
         AND o.ORDR_CODE = @OrdrCode
         AND o.CHAT_ID = @RefChatId
         AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO;

            -- ارسال پیامک
      SELECT  @XMessage = ( 
         SELECT @TOrdrCode AS '@code' ,
                @Rbid AS '@roborbid' ,
                '012' '@type',
                @TDirPrjbCode '@dirprjbcode'
        FOR XML PATH('Order'), ROOT('Process')
      );
      EXEC Send_Order_To_Personal_Robot_Job @XMessage;      
   END;
	
	L$EndSP:
	COMMIT TRAN [T$SAVE_PYMT_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   SET @XRet = (
          SELECT 'failed' AS '@rsltdesc',
                 '001' AS '@rsltcode',
                 @ErorMesg
             FOR XML PATH('Message'), ROOT('Result')
      );
      RAISERROR ( @ErorMesg, 16, 1 );
      ROLLBACK TRAN [T$SAVE_PYMT_P];
	END CATCH
END
GO
