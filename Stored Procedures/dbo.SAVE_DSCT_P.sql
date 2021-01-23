SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SAVE_DSCT_P]
	@X XML ,
	@XRet XML OUTPUT
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION [T$SAVE_DSCT_P];
	
	DECLARE @Dcid BIGINT,	        
	        @OffPrct REAL,
	        @OffType VARCHAR(3),
	        @OffKind VARCHAR(3),
	        @FromAmnt BIGINT,
	        @MaxAmntOff BIGINT,
	        @DiscCode VARCHAR(8),
	        @ExprDate DATETIME,
	        @ValdType VARCHAR(3),
	        @OrdrCode BIGINT,
	        @Rbid BIGINT,
	        @AmntType VARCHAR(3),
	        @AmntTypeDesc NVARCHAR(255),
	        @ExpnPric BIGINT,
	        @ExtrPrct BIGINT,
	        @DebtDnrm BIGINT;
	
	SELECT @Dcid = @X.query('//Service_Robot_Discount_Card').value('(Service_Robot_Discount_Card/@dcid)[1]', 'BIGINT'),
	       @OrdrCode = @X.query('//Service_Robot_Discount_Card').value('(Service_Robot_Discount_Card/@ordrcode)[1]', 'BIGINT'),
	       @Rbid = @X.query('//Service_Robot_Discount_Card').value('(Service_Robot_Discount_Card/@rbid)[1]', 'BIGINT');
   
   SELECT @Rbid = RBID
         ,@AmntType = AMNT_TYPE
         ,@AmntTypeDesc = a.DOMN_DESC
     FROM dbo.Robot r, dbo.[D$AMUT] a
    WHERE r.RBID = @Rbid
      AND r.AMNT_TYPE = a.VALU;
   
   --PRINT @OrdrCode
   
   -- بررسی اینکه برای خرید سفارش آیا کد تخفیفی تا الان ذخیره شده یا خیر
   IF EXISTS(
      SELECT *
        FROM dbo.Order_State os
       WHERE os.ORDR_CODE = @OrdrCode
         AND os.AMNT_TYPE = '002' -- ثبت کد تخفیف         
         AND os.CONF_STAT = '002' -- در انتظار تاییدیه
   )
   BEGIN
      SET @XRet = (
          SELECT 'failed' AS '@rsltdesc',
                 '001' AS '@rsltcode',
                 N'🔔 کد تخفیف شما در سفارشتان ثبت شده' + CHAR(10) 
                 --N'🤑 مبلغ تخفیف *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, os.AMNT), 1), '.00', '') + N'*'
            FROM dbo.Order_State os, dbo.Service_Robot_Discount_Card a
           WHERE os.DISC_DCID = a.DCID
             AND os.ORDR_CODE = @OrdrCode
             AND os.AMNT_TYPE = '002' -- تخفیف
             AND os.CONF_STAT = '002' -- در حال انتظار تاییدیه
             FOR XML PATH('Message'), ROOT('Result')
      );
      GOTO L$EndSP;
   END    
   
   -- ابتدا چک میکنیم که ایا این کد تخفیف قبلا درون سفارشات استفاده شده یا خیر
   IF dbo.CHK_DSCT_U(@X) = '001' -- کد تخفیف نا معتبر است
   BEGIN
      SET @XRet = (
          SELECT 'failed' AS '@rsltdesc',
                 '001' AS '@rsltcode',
                 N'⛔️ کد تخفیف قابل استفاده برای سفارش شما نیست' + CHAR(10) +
                 N'👈 نوع کد تخفیف شما *' + b.DOMN_DESC + N'*' + CHAR(10) + 
                 N'🤑 کد تخفیف *' + a.DISC_CODE + N'*' + CHAR(10) +
                 N'⌛️ وضعیت اعتبار *' + c.DOMN_DESC + N'*' + CHAR(10) + 
                 CASE WHEN a.EXPR_DATE >= GETDATE() THEN N'📆 تاریخ اعتبار *' + dbo.GET_MTOS_U(a.EXPR_DATE) + N'*' ELSE N'🚫 کد تخفیف فاقد اعتبار تاریخی می باشد' END + CHAR(10) + 
                 CASE a.OFF_KIND
                      WHEN '001' THEN N'⁉️ لطفا کالاهای درون سبد خود را چک کنید که فروشگاه برای آنها تخفیف در نظر نگرفته باشد در آن صورت می توانید از کد تخفیف استفاده کنید' + CHAR(10)
                      WHEN '002' THEN N'👈 مبلغ قابل پرداخت سفارش باید بالای *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, a.FROM_AMNT), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ]' + CHAR(10) + 
                                      CASE 
                                           WHEN ISNULL(a.OFF_PRCT, 0) != 0 THEN N'👈 درصد تخفیف *' + CAST(a.OFF_PRCT AS VARCHAR(10)) + N'*'
                                           WHEN ISNULL(a.MAX_AMNT_OFF, 0) != 0 THEN N'👈 مبلغ سقف تخفیف *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, a.MAX_AMNT_OFF), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ]' + CHAR(10) 
                                      END +
                                      N'🛍 مبلغ قابل پرداخت سفارش شما *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.DEBT_DNRM), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ]' + CHAR(10) +
                                      N'👌 مبلغ کسری شما *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, a.FROM_AMNT - o.DEBT_DNRM ), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ]' + CHAR(10) 
                                      
                 END                  
            FROM dbo.Service_Robot_Discount_Card a, dbo.[D$OFKD] b, dbo.[D$RCST] c, dbo.[Order] o
           WHERE a.DCID = @Dcid
             AND a.OFF_KIND = b.VALU
             AND a.VALD_TYPE = c.VALU
             AND o.CODE = @OrdrCode
             FOR XML PATH('Message'), ROOT('Result')            
      );
      GOTO L$EndSP;
   END 	
	
	-- بدست آوردن اطلاعات کد تخفیف مشتری
	SELECT @OffPrct = a.OFF_PRCT,
	       @OffType = a.OFF_TYPE,
	       @OffKind = a.OFF_KIND,
	       @FromAmnt = a.FROM_AMNT,	       
	       @DiscCode = a.DISC_CODE,
	       @MaxAmntOff = a.MAX_AMNT_OFF,
	       @ExprDate = a.EXPR_DATE,
	       @ValdType = a.VALD_TYPE	     
	  FROM dbo.Service_Robot_Discount_Card a
	 WHERE a.DCID = @Dcid;
	
	-- اطلاعات سفارش مشتری
	SELECT @ExpnPric = o.EXPN_AMNT,
	       @ExtrPrct = o.EXTR_PRCT,
	       @DebtDnrm = o.DEBT_DNRM
	  FROM dbo.[Order] o
	 WHERE o.CODE = @OrdrCode;
	
	IF @OffKind = '001' /* تخفیف عادی */
	BEGIN
	   -- درج دکورد تخفیف در جدول
	   INSERT INTO dbo.Order_State (ORDR_CODE ,CODE ,DISC_DCID ,STAT_DATE ,
      STAT_DESC ,AMNT_TYPE ,CONF_STAT  )
      VALUES (@OrdrCode, 0, @Dcid, GETDATE(), 
      N'محاسبه کارت تخفیف عادی', '002', '002');
      
      -- بروزرسانی کد تخفیف برای کالایی که تخفیف برای انها لحاظ نشده است
      UPDATE od
         SET od.OFF_PRCT = d.OFF_PRCT,
             od.OFF_KIND = d.OFF_KIND,
             od.OFF_TYPE = d.OFF_TYPE
        FROM Order_Detail od, dbo.Service_Robot_Discount_Card d
      WHERE od.ORDR_CODE = @OrdrCode
        AND d.DCID = @Dcid
        AND ISNULL(od.OFF_PRCT, 0) = 0
        AND od.OFF_KIND IS NULL;
	END 
	ELSE IF @OffKind = '002'  /* تخفیف فروش گردونه شانس */
	BEGIN
	   IF @FromAmnt <= @DebtDnrm
	   BEGIN	   
	      IF ISNULL(@OffPrct, 0) != 0
	      BEGIN
	         INSERT INTO dbo.Order_State (ORDR_CODE ,CODE ,DISC_DCID ,STAT_DATE ,
            STAT_DESC ,AMNT ,AMNT_TYPE ,CONF_STAT ,CONF_DESC )
            VALUES (@OrdrCode, 0, @Dcid, GETDATE(), 
            N'تخفیف از طریق بن تخفیف درصدی گردونه شانس', (@DebtDnrm * @OffPrct / 100), '002', '002', N'انتخاب کد تخفیف برای تاییدیه سفارش' );
	      END 
	      ELSE IF ISNULL(@MaxAmntOff, 0) != 0
	      BEGIN
   	      INSERT INTO dbo.Order_State (ORDR_CODE ,CODE ,DISC_DCID ,STAT_DATE ,
            STAT_DESC ,AMNT ,AMNT_TYPE ,CONF_STAT ,CONF_DESC )
            VALUES (@OrdrCode, 0, @Dcid, GETDATE(), 
            N'تخفیف از طریق بن تخفیف کسر مبلغ با سقف مشخص سفارش گردونه شانس', @MaxAmntOff, '002', '002', N'انتخاب کد تخفیف برای تاییدیه سفارش' );
	      END 
	   END 
	END 
	IF @OffKind = '004' /* تخفیف فروش همکار */
	BEGIN
	   -- درج دکورد تخفیف در جدول
	   INSERT INTO dbo.Order_State (ORDR_CODE ,CODE ,DISC_DCID ,STAT_DATE ,
      STAT_DESC ,AMNT_TYPE ,CONF_STAT  )
      VALUES (@OrdrCode, 0, @Dcid, GETDATE(), 
      N'محاسبه کارت تخفیف ویژه فروش همکار', '002', '002');
      
      -- بروزرسانی کد تخفیف برای کالایی که تخفیف برای انها لحاظ نشده است
      UPDATE od
         SET od.OFF_PRCT = d.OFF_PRCT,
             od.OFF_KIND = d.OFF_KIND,
             od.OFF_TYPE = d.OFF_TYPE
        FROM Order_Detail od, dbo.Service_Robot_Discount_Card d
      WHERE od.ORDR_CODE = @OrdrCode
        AND d.DCID = @Dcid
        AND ISNULL(od.OFF_PRCT, 0) = 0
        AND od.OFF_KIND IS NULL
        AND od.SRSP_CODE IS NULL;
	END 
	
	SET @XRet = (
	    SELECT 'successful' AS '@rsltdesc',
              '002' AS '@rsltcode',
	           N'✅ ثبت کد تخفیف برای سفارش شما' + CHAR(10) +
	           CASE d.OFF_KIND
	                WHEN '001' /* کد تخفیف عادی */ THEN N'🤑 درصد تخفیف *' + CAST(d.OFF_PRCT AS VARCHAR(3)) + N'% *' + CHAR(10)	                
	                WHEN '002' /* کد تخفیف شانس گردونه */ THEN N'🤑 مبلغ تخفیف *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, os.AMNT), 1), '.00', '') + N'*' + CHAR(10) 
	                WHEN '004' /* کد تخفیف ویژه همکار فروش */ THEN N'🤑 درصد تخفیف *' + CAST(d.OFF_PRCT AS VARCHAR(3)) + N'% *' + CHAR(10)
	           END + 
	           N'👈 نکته : بعد از وارد کردن کد تخفیف به هیچ عنوان سفارش خود را تغییر ندهید' + 
	           N'در صورتی که هر تغییری درون سفارش شما اعمال شود کد تخفیف به خودی خود از سفارش شما حذف میشود' +
	           N'و باید دوباره کد تخفیف خود را وارد کنید'
	      FROM dbo.[Order_State] os, dbo.Service_Robot_Discount_Card d
	     WHERE os.DISC_DCID = @Dcid	
	       AND d.DCID = @Dcid
	       AND os.ORDR_CODE = @OrdrCode
	       FOR XML PATH('Message'), ROOT('Result')
	);
	
	L$EndSP:	
	COMMIT TRANSACTION [T$SAVE_DSCT_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR( @ErorMesg, 16, 1 );
	   ROLLBACK TRANSACTION [T$SAVE_DSCT_P];
	END CATCH
END
GO
