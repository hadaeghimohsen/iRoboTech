SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SAVE_WLET_P]
	@X XML,
	@XRet XML OUTPUT
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION [T$SAVE_WLET_P]
	
	DECLARE @OrdrCode BIGINT = @X.query('//Wallet_Detail').value('(Wallet_Detail/@ordrcode)[1]', 'BIGINT'),
	        @WldtCode BIGINT = @X.query('//Wallet_Detail').value('(Wallet_Detail/@wldtcode)[1]', 'BIGINT'),
	        @Rbid BIGINT = @X.query('//Wallet_Detail').value('(Wallet_Detail/@rbid)[1]', 'BIGINT'),
	        @ChatId BIGINT = @X.query('//Wallet_Detail').value('(Wallet_Detail/@chatid)[1]', 'BIGINT'),
	        @OprtType VARCHAR(3) = @X.query('//Wallet_Detail').value('(Wallet_Detail/@oprttype)[1]', 'VARCHAR(3)'),
	        @WletType VARCHAR(3) = @X.query('//Wallet_Detail').value('(Wallet_Detail/@wlettype)[1]', 'VARCHAR(3)');
	
   IF @WletType IS NULL SET @WletType = '002' -- حساب نقدینگی
      
   IF @OprtType = 'del'
   BEGIN
      DELETE dbo.Order_State 
       WHERE WLDT_CODE = @WldtCode;
   
      -- برگشت مبلغ کسر شده از کیف پول
      UPDATE w
         SET w.TEMP_AMNT_USE = 0
        FROM dbo.Wallet w, dbo.Wallet_Detail wd
       WHERE w.CODE = wd.WLET_CODE
         AND wd.ORDR_CODE = @OrdrCode
         AND w.WLET_TYPE = @WletType /* Cash, Credit Wallet */;
      
      DELETE dbo.Wallet_Detail
       WHERE CODE = @WldtCode;      
      
      SET @XRet = (
          SELECT 'successful' AS '@rsltdesc',
                 '002' AS '@rsltcode',
                 N'✅ مبلغ کیف پول شما به حسابتان برگشت داده شد'
             FOR XML PATH('Message'), ROOT('Result')
      );
      GOTO L$EndSP;
   END 
   
   -- var local
   DECLARE @DebtAmnt BIGINT
          ,@BlncWaltAmnt BIGINT
          ,@TrgtAmnt BIGINT
   	    ,@AmntType VARCHAR(3)
	       ,@AmntTypeDesc NVARCHAR(255)
	       ,@WletCode BIGINT
	       ,@DestCardNumb VARCHAR(16)
 	       ,@TxfePrct SMALLINT
	       ,@TxfeCalcAmnt BIGINT
	       ,@OrdrType VARCHAR(3);
   
   SELECT @AmntType = AMNT_TYPE
         ,@AmntTypeDesc = a.DOMN_DESC
     FROM dbo.Robot r, dbo.[D$AMUT] a
    WHERE r.RBID = @Rbid
      AND r.AMNT_TYPE = a.VALU;
   
   -- بدست آوردن مبلغ بدهی صورتحساب
   SELECT @DebtAmnt = o.DEBT_DNRM,
          @DestCardNumb = o.DEST_CARD_NUMB_DNRM,
          @OrdrType = o.ORDR_TYPE
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
	SELECT @BlncWaltAmnt = w.AMNT_DNRM, 
	       @WletCode = w.CODE
	  FROM dbo.Wallet w
	 WHERE w.SRBT_ROBO_RBID = @Rbid
	   AND w.CHAT_ID = @ChatId
	   AND w.WLET_TYPE = @WletType /* Cash/Credit Wallet */;
	
	-- پیدا کردن کمترین مبلغ
	SELECT @TrgtAmnt = MIN(T.Amnt)
	  FROM (VALUES (@DebtAmnt), (@BlncWaltAmnt)) AS T(Amnt);
	
	-- بروزرسانی مبلغ کارت هیده به صورت موقت
	INSERT INTO dbo.Wallet_Detail
   (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT)
   VALUES
   (@OrdrCode, @WletCode, 0, @AmntType, @TrgtAmnt, GETDATE(), '002', '003');
   
   -- بدست آوردن اطلاعات برداشت از حساب کیف پول
   SELECT @WldtCode = wd.CODE
     FROM dbo.Wallet_Detail wd
    WHERE wd.WLET_CODE = @WletCode
      AND wd.ORDR_CODE = @OrdrCode
      AND wd.AMNT_STAT = '002';
   
   -- ثبت مبلغ برداشت شده در متغییر موقت
   UPDATE dbo.Wallet
      SET TEMP_AMNT_USE = @TrgtAmnt
    WHERE CODE = @WletCode;

   -- اگر سفارش برای فروشگاه ثبت شده باشد شرکت ما از آن کارمزد دریافت میکند
	IF EXISTS (SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND o.ORDR_TYPE = '004')
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
   ( ORDR_CODE , CODE ,WLDT_CODE ,STAT_DATE ,STAT_DESC ,AMNT ,AMNT_TYPE ,RCPT_MTOD ,CONF_STAT, TXID, TXFE_PRCT, TXFE_CALC_AMNT )
   VALUES 
   ( @OrdrCode, 0, @WldtCode, GETDATE(), CASE @OrdrType WHEN '004' THEN N'کسر مبلغ کیف پول برای سفارش' WHEN '023' THEN N'کسر مبلغ کیف پول برای پرداخت هزینه ارسال سفارش' END , @TrgtAmnt, '001', '005', '002', @WldtCode, @TxfePrct, @TxfeCalcAmnt);
   
   SET @XRet = (
       SELECT 'successful' AS '@rsltdesc',
              '002' AS '@rsltcode',
              N'✅ ثبت مبلغ از کیف پول برای سفارش' + CHAR(10) +
              N'🛍 مبلغ قابل پرداخت سفارش *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @DebtAmnt), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ]' + CHAR(10) + 
              N'💵 مبلغ کسر شده کیف پول *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, os.AMNT), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ]' + CHAR(10) + 
              CASE 
                   WHEN @DebtAmnt > os.AMNT THEN N'👈 مبلغ باقیمانده *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @DebtAmnt - os.AMNT), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ]' + CHAR(10) 
                   WHEN @DebtAmnt = os.AMNT THEN N'✅ *تسویه حساب کامل*' + CHAR(10) + N'👈 جهت اتمام فرآیند *⚡️ پایان سفارش* را انتخاب کنید'
              END               
         FROM dbo.Order_State os
        WHERE os.WLDT_CODE = @WldtCode
          AND os.ORDR_CODE = @OrdrCode
          FOR XML PATH('Message'), ROOT('Result')
   );
	
	L$EndSP:
	COMMIT TRANSACTION [T$SAVE_WLET_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR (@ErorMesg, 16, 1);
	   ROLLBACK TRANSACTION [T$SAVE_WLET_P];
	END CATCH
END
GO
