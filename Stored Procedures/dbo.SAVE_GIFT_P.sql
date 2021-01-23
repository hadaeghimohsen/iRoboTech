SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SAVE_GIFT_P]
	@X XML,
	@XRet XML OUTPUT
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION [T$SAVE_GIFT_P]
	
	DECLARE @OrdrCode BIGINT,
	        @Gcid BIGINT,
	        @Rbid BIGINT,
	        @ChatId BIGINT,
	        @OprtType VARCHAR(3);
	
	SELECT @OrdrCode = @X.query('//Service_Robot_Gift_Card').value('(Service_Robot_Gift_Card/@ordrcode)[1]', 'BIGINT'),
	       @Gcid     = @X.query('//Service_Robot_Gift_Card').value('(Service_Robot_Gift_Card/@gcid)[1]', 'BIGINT'),
	       @Rbid     = @X.query('//Service_Robot_Gift_Card').value('(Service_Robot_Gift_Card/@rbid)[1]', 'BIGINT'),
	       @ChatId   = @X.query('//Service_Robot_Gift_Card').value('(Service_Robot_Gift_Card/@chatid)[1]', 'BIGINT'),
	       @OprtType = @X.query('//Service_Robot_Gift_Card').value('(Service_Robot_Gift_Card/@oprttype)[1]', 'VARCHAR(3)');
   
   IF @OprtType = 'del'
   BEGIN
      UPDATE g
         SET g.TEMP_AMNT_USE = 0
        FROM dbo.Service_Robot_Gift_Card g
       WHERE g.GCID = @Gcid;
      
      DELETE dbo.Order_State 
       WHERE GIFC_GCID = @Gcid;
      
      SET @XRet = (
          SELECT 'successful' AS '@rsltdesc',
                 '002' AS '@rsltcode',
                 N'✅ مبلغ کارت اعتباری به حساب شما برگشت داده شد'
             FOR XML PATH('Message'), ROOT('Result')
      );
      GOTO L$EndSP;
   END 
   
   -- var local
   DECLARE @DebtAmnt BIGINT
          ,@BlncGiftAmnt BIGINT
          ,@TrgtAmnt BIGINT
   	    ,@AmntType VARCHAR(3)
	       ,@AmntTypeDesc NVARCHAR(255)
	       ,@DestCardNumb VARCHAR(16)
 	       ,@TxfePrct SMALLINT
	       ,@TxfeCalcAmnt BIGINT;
   
   SELECT @AmntType = AMNT_TYPE
         ,@AmntTypeDesc = a.DOMN_DESC
     FROM dbo.Robot r, dbo.[D$AMUT] a
    WHERE r.RBID = @Rbid
      AND r.AMNT_TYPE = a.VALU;
   
   -- بدست آوردن مبلغ بدهی صورتحساب
   SELECT @DebtAmnt = o.DEBT_DNRM,
          @DestCardNumb = o.DEST_CARD_NUMB_DNRM
     FROM dbo.[Order] o
    WHERE o.CODE = @OrdrCode;
	
	-- اگر مبلغ بدهی صفر باشد پیام اینکه صورتحساب تسویه میباشد را باید به مشتری نشان دهیم
	IF @DebtAmnt = 0
	BEGIN
	   SET @XRet = (
          SELECT 'successful' AS '@rsltdesc',
                 '002' AS '@rsltcode',
                 N'✅ صورتحساب شما نیاز به پرداخت هزینه اضافه ندارد لطفا جهت اتمام *⚡️ پایان سفارش* را انتخاب کنید'
             FOR XML PATH('Message'), ROOT('Result')
      );
      
      GOTO L$EndSP;
	END 
	
	-- بدست آوردن مبلغ اعتبار کارت انتخابی
	SELECT @BlncGiftAmnt = BLNC_AMNT_DNRM - ISNULL(TEMP_AMNT_USE, 0)
	  FROM dbo.Service_Robot_Gift_Card
	 WHERE GCID = @Gcid;
	
	-- اگر کارت هیچ گونه موجودی نداشته باشد
	IF @BlncGiftAmnt = 0
	BEGIN
	   SET @XRet = (
          SELECT 'successful' AS '@rsltdesc',
                 '002' AS '@rsltcode',
                 N'⚠️ کارت اعتباری انتخاب شده فاقد اعتبار مالی میباشد'
             FOR XML PATH('Message'), ROOT('Result')
      );
      
      GOTO L$EndSP;
	END 
	
	-- پیدا کردن کمترین مبلغ
	SELECT @TrgtAmnt = MIN(T.Amnt)
	  FROM (VALUES (@DebtAmnt), (@BlncGiftAmnt)) AS T(Amnt);
	
	-- بروزرسانی مبلغ کارت هیده به صورت موقت
	UPDATE dbo.Service_Robot_Gift_Card
	   SET TEMP_AMNT_USE += @TrgtAmnt
	 WHERE GCID = @Gcid;
   
   -- اگر سفارش برای فروشگاه ثبت شده باشد شرکت ما از آن کارمزد دریافت میکند
	IF EXISTS (SELECT * FROM dbo.[Order] o WHERE o.ORDR_TYPE = '004')
	BEGIN
	   SELECT TOP 1 
	          @TxfePrct = tf.TXFE_PRCT
	         ,@TxfeCalcAmnt = (SELECT o.SUM_EXPN_AMNT_DNRM * tf.TXFE_PRCT / 100 FROM dbo.[Order] o WHERE o.CODE = @OrdrCode)
	     FROM dbo.Transaction_Fee tf
	    WHERE STAT = '002'
	      AND tf.TXFE_TYPE = '001'
	      AND tf.CALC_TYPE = '001';
	END
   
   -- درج اطلاعات واریزی در جدول وضعیت سفارش
   INSERT INTO dbo.Order_State
   ( ORDR_CODE , CODE ,GIFC_GCID ,STAT_DATE ,STAT_DESC ,AMNT ,AMNT_TYPE ,RCPT_MTOD ,CONF_STAT, TXID, TXFE_PRCT, TXFE_CALC_AMNT )
   VALUES 
   ( @OrdrCode, 0, @Gcid, GETDATE(), N'کسر مبلغ اعتبار کارت هدیه برای سفارش', @TrgtAmnt, '001', '005', '002', @Gcid, @TxfePrct, @TxfeCalcAmnt);
   
   SET @XRet = (
       SELECT 'successful' AS '@rsltdesc',
              '002' AS '@rsltcode',
              N'✅ ثبت مبلغ کارت هدیه اعتباری برای سفارش' + CHAR(10) +
              N'🛍 مبلغ قابل پرداخت سفارش *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @DebtAmnt), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ]' + CHAR(10) + 
              N'💵 مبلغ کسر شده کارت هدیه *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, os.AMNT), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ]' + CHAR(10) + 
              CASE 
                   WHEN @DebtAmnt > os.AMNT THEN N'👈 مبلغ باقیمانده *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @DebtAmnt - os.AMNT), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ]' + CHAR(10) 
                   WHEN @DebtAmnt = os.AMNT THEN N'✅ *تسویه حساب کامل*' + CHAR(10) + N'👈 جهت اتمام فرآیند *⚡️ پایان سفارش* را انتخاب کنید'
              END               
         FROM dbo.Order_State os
        WHERE os.GIFC_GCID = @Gcid
          AND os.ORDR_CODE = @OrdrCode
          FOR XML PATH('Message'), ROOT('Result')
   );
	
	L$EndSP:
	COMMIT TRANSACTION [T$SAVE_GIFT_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR (@ErorMesg, 16, 1);
	   ROLLBACK TRANSACTION [T$SAVE_GIFT_P];
	END CATCH
END
GO
