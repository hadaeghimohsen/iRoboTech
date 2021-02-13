SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[REGS_ORDR_P]
	@X XML,
	@XRet XML OUTPUT
AS
BEGIN
	BEGIN TRY 
	BEGIN TRAN [T$REGS_ORDR_P];
	   -- Global Parameters
	   DECLARE @OrdrCode BIGINT;
	   SELECT @OrdrCode = @X.query('Order').value('(Order/@code)[1]', 'BIGINT');
	   
	   -- Local Variable Procedure
	   DECLARE @XTemp XML
	          ,@Rbid BIGINT
	          ,@Chatid BIGINT
	          ,@SumAmnt BIGINT
	          ,@RcptMtod VARCHAR(3)
	          ,@OdstCode BIGINT
	          ,@AmntType VARCHAR(3)
	          ,@TOrdrCode BIGINT;
	   
	   -- ابتدا تمامی ردیف های پرداختی را درون کیف پول نقدی قرار میدهیم	   
	   -- ذخیره کردن جمع پرداختی ها درون جدول کیف پول نقدی مشتری
      SELECT @SumAmnt = SUM(os.AMNT)
        FROM dbo.Order_State os
       WHERE os.ORDR_CODE = @OrdrCode
         AND os.AMNT_TYPE = '006'
         AND os.RCPT_MTOD NOT IN ('014', '015');
	   
	   -- بدست آوردن اینکه مبلغ ریالی میباشد یا تومان
	   SELECT @AmntType = o.AMNT_TYPE, @Rbid = o.SRBT_ROBO_RBID, @Chatid = o.CHAT_ID
	     FROM dbo.[Order] o
	    WHERE o.CODE = @OrdrCode;
	   
	   -- اگر مبلغ تومان باشد باید تبدیل به ریال شود
	   IF @AmntType = '002' SET @SumAmnt *= 10;
	   
	   -- مبلغ ورودی به تابع بر اساس ریال می باشد
	   -- ثبت مبلغ نقدی در کیف پول
	   SET @XTemp = (
	       SELECT r.TKON_CODE AS '@token',
	              '002' AS 'Message/@cbq',
	              '*0*3*3#' AS 'Message/@ussd',
	              @Chatid AS 'Message/@chatid',
	              dbo.STR_FRMT_U('howinccashwlet,{0}', @SumAmnt) AS 'Message/Text/@param',
	              'lessaddwlet' AS 'Message/Text/@postexec',
	              'addamntwlet' AS 'Message/Text'
	         FROM dbo.Robot r
	        WHERE r.RBID = @Rbid
	          FOR XML PATH ('Robot')
	   );
	   EXEC dbo.AnarShop_Analisis_Message_P @X = @XTemp, @XResult = @XTemp OUTPUT;
	   
	   -- درخواست افزایش مبلغ کیف پول نقدی را باید دوباره به حالت اول برگردانیم
	   -- اگر مبلغ ریال باشد باید تبدیل به تومان شود
	   -- این بخاطر این میباشد که درخواست افزایش مبلغ بر اساس نوع واحد مالی تولید میشود
	   IF @AmntType = '002' SET @SumAmnt /= 10;
	   
	   -- بدست آوردن شماره درخواست افزایش مبلغ کیف پول نقدی	   	   
	   -- در این قسمت باید درخواست سفارش خود را درون سیستم ثبت و نهایی کنیم
	   SET @XTemp = (
	       SELECT o.CODE AS '@ordrcode'
	             ,o.CODE AS '@txid'
	             ,o.DEBT_DNRM AS '@totlamnt'
	             ,'001' AS '@autochngamnt'
	             ,'001' AS '@rcptmtod'
	         FROM dbo.[Order] o
	        WHERE o.SRBT_ROBO_RBID = @Rbid
	          AND o.CHAT_ID = @Chatid
	          AND o.ORDR_TYPE = '015'
	          AND o.ORDR_STAT = '001'
	          AND o.DEBT_DNRM = @SumAmnt
	          FOR XML PATH('Payment')
	   );	   
	   EXEC dbo.SAVE_PYMT_P @X = @XTemp, @xRet = @XTemp OUTPUT;
	   
	   --  غیر فعال کردن پرداختی های حضوری درون جدول پرداختی ها
	   UPDATE dbo.Order_State 
	      SET AMNT_TYPE = '007'
	    WHERE ORDR_CODE = @OrdrCode
	      AND AMNT_TYPE = '006';
	   
	   -- از این قسمت به بعد اجرای عملیات برای ثبت سفارش انجام میشود
	   -- بعد از ذخیره کردن مبلغ ها درون کیف پول نقدی موقع آن فرا رسیده که مبلغ کیف پول نقدی را برای ثبت سفارش خرج کنیم   
	   SET @XTemp = (
	       SELECT o.CODE AS '@ordrcode'
	             ,o.SRBT_ROBO_RBID AS '@rbid'
	             ,o.CHAT_ID AS '@chatid'
	             ,'add' AS '@oprttype'
	             ,'002' AS 'wlettype'	       
	         FROM dbo.[Order] o
	        WHERE o.CODE = @OrdrCode
	           FOR XML PATH('Wallet_Detail')	        
	   );
	   EXEC dbo.SAVE_WLET_P @X = @XTemp, @XRet = @XTemp OUTPUT;
	   	   	   
	   -- اگر درون پرداختی ها از کیف اعتباری هم استفاده شده باشد
	   IF EXISTS(SELECT * FROM dbo.Order_State os WHERE os.ORDR_CODE = @OrdrCode AND os.AMNT_TYPE = '007' AND os.RCPT_MTOD = '015')
	   BEGIN
	      -- ذخیره کردن مبلغ کیف پول اعتباری برای ثبت سفارش
	      SET @XTemp = (
	          SELECT o.CODE AS '@ordrcode'
	                ,o.SRBT_ROBO_RBID AS '@rbid'
	                ,o.CHAT_ID AS '@chatid'
	                ,'add' AS '@oprttype'
	                ,'001' AS 'wlettype'	       
	            FROM dbo.[Order] o
	           WHERE o.CODE = @OrdrCode
	              FOR XML PATH('Wallet_Detail')	        
	      );
	      EXEC dbo.SAVE_WLET_P @X = @XTemp, @XRet = @XTemp OUTPUT;
	   END 
	   
	   -- عملیات پرداخت سفارش به اتمام رسیده حال باید سفارش را نهایی کنیم
	   SET @XTemp = (
	       SELECT r.TKON_CODE AS '@token',
	              '002' AS 'Message/@cbq',
	              '*0#' AS 'Message/@ussd',
	              @Chatid AS 'Message/@chatid',
	              @OrdrCode AS 'Message/Text/@param',
	              'lessfinlcart' AS 'Message/Text/@postexec',
	              'finalcart' AS 'Message/Text'
	         FROM dbo.Robot r
	        WHERE r.RBID = @Rbid
	          FOR XML PATH ('Robot')
	   );
	   EXEC dbo.AnarShop_Analisis_Message_P @X = @XTemp, @XResult = @XTemp OUTPUT;	   
	   
	   SET @XRet = @XTemp;
	COMMIT TRAN [T$REGS_ORDR_P];
	END TRY
	BEGIN CATCH
      DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR(@ErorMesg, 16, 1);
      ROLLBACK TRANSACTION [T$REGS_ORDR_P];
	END CATCH
END
GO
