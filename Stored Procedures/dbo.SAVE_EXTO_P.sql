SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SAVE_EXTO_P]
	-- Add the parameters for the stored procedure here
	@X XML ,
	@xRet XML OUTPUT
	/*
	   <Order subsys="12" typecode="001" typedesc="Insert New Membership in MemberShip List from Service" tarfcode="00101001" />
	*/
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$SAVE_EXTO_P];
   
   DECLARE @SubSys INT
          ,@TypeCode VARCHAR(3)
          ,@OrdrType VARCHAR(3)	       
	       ,@Chatid BIGINT
	       ,@TChatId BIGINT -- این گزینه برای مشتریانی هست که بخواهیم چک کنیم آیا هنوز سبدی داریم که از تاریخ انقضای انها گذشته باشد یا خیر
	       ,@Rbid BIGINT
	       
	       ,@ServFileNo BIGINT
	       ,@ServRwno INT
	       ,@CellPhon VARCHAR(11)
	       ,@ServAdrs NVARCHAR(1000)
	       ,@OrdrCode BIGINT
	       ,@TOrdrCode BIGINT -- این گزینه برای درخواست هایی هست که بخواهیم چک کنیم آیا هنوز سبدی داریم که از تاریخ انقضای انها گذشته باشد یا خیر
	       
	       ,@Title NVARCHAR(250)
	       ,@Description NVARCHAR(250)
	       
	       ,@OrdrExprStat VARCHAR(3)
	       ,@OrdrExprTime INT
	       
	       ,@xTemp XML;
   
   SELECT @SubSys   = @X.query('//Action').value('(Action/@subsys)[1]', 'INT')
         ,@OrdrType = @X.query('//Action').value('(Action/@ordrtype)[1]', 'VARCHAR(3)')
	      ,@TypeCode = @X.query('//Action').value('(Action/@typecode)[1]', 'VARCHAR(3)')
	      ,@Chatid   = @X.query('//Action').value('(Action/@chatid)[1]', 'BIGINT')
	      ,@Rbid     = @X.query('//Action').value('(Action/@rbid)[1]', 'BIGINT')
	      ,@OrdrCode = @X.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT')
	      
	      --,@ProdCode = @X.query('//Action').value('(Action/@prodcode)[1]', 'BIGINT')
	      --,@Pric     = @X.query('//Action').value('(Action/@pric)[1]', 'BIGINT')
	      --,@TaxPrct  = @X.query('//Action').value('(Action/@taxprct)[1]', 'INT')
	      --,@OffPrct  = @X.query('//Action').value('(Action/@offprct)[1]', 'INT')
	      --,@Numb     = @X.query('//Action').value('(Action/@numb)[1]', 'REAL')
	      
	      --,@Muid     = @X.query('//Action').value('(Action/@muid)[1]', 'BIGINT')
	      --,@UssdCode = @X.query('//Action').value('(Action/@ussdcode)[1]', 'VARCHAR(250)')
	      --,@ChildUssdCode = @X.query('//Action').value('(Action/@childussdcode)[1]', 'VARCHAR(250)');
	
	-- 1399/04/19 * جهت اینکه سبد خرید دارای زمان انقضا میباشد یا خیر 
	SELECT @OrdrExprStat = ORDR_EXPR_STAT,
	       @OrdrExprTime = ORDR_EXPR_TIME
	  FROM dbo.Robot
	 WHERE RBID = @Rbid;
	  
	SELECT @ServFileNo = SERV_FILE_NO
	      ,@ServRwno = SRPB_RWNO
	      ,@CellPhon = CELL_PHON
	      ,@ServAdrs = SERV_ADRS
	  FROM dbo.Service_Robot
	 WHERE ROBO_RBID = @Rbid
	   AND CHAT_ID = @Chatid;
	
	IF @ServRwno IS NULL
     	SELECT @ServRwno = MAX(RWNO)
	     FROM dbo.Service_Robot_Public
	    WHERE CHAT_ID = @Chatid
	      AND SRBT_ROBO_RBID = @Rbid;
   
   IF @TypeCode = '005' /* Delete All Open Cart(s) */
	BEGIN
	   -- درخواست های از قبل مانده را باید انصراف بزنیم
	   UPDATE dbo.[Order]
	      SET ORDR_STAT = '003'
	    WHERE SRBT_ROBO_RBID = @Rbid
	      AND CHAT_ID = @Chatid
	      AND ORDR_TYPE = @OrdrType
	      AND ORDR_STAT = '001';
	   
	   SET @xRet = (
	      SELECT N'❌ حذف فاکتور با موفقیت انجام شد'
	     FOR XML PATH('Message'), ROOT('Result')	        
	   );
	   
	   COMMIT TRAN [SAVE_CART_P];
	   
	   RETURN;
	END 
	ELSE IF @TypeCode = '006' /* Show Invoice & Payment */
	BEGIN
	   GOTO L$Jump1;
	END
	ELSE IF ISNULL(@OrdrCode, 0) != 0
	BEGIN
	   GOTO L$Jump1;
	END 
	
   IF NOT EXISTS(
	   SELECT * 
	     FROM dbo.[Order] o 
	    WHERE o.SRBT_ROBO_RBID = @Rbid 
	      AND o.SUB_SYS = @SubSys
	      AND o.CHAT_ID = @Chatid 
	      AND o.ORDR_TYPE = @OrdrType /* نوع درخواست */ 
	      AND o.ORDR_STAT IN ('001' /* ثبت درخواست */) 
	)
	BEGIN
	   L$INS_ORDR:
	   -- درج جدید درخواست سفارش برای مشتری
	   EXEC dbo.INS_ORDR_P @Srbt_Serv_File_No = @ServFileNo, -- bigint
	       @Srbt_Robo_Rbid = @Rbid, -- bigint
	       @Srbt_Srpb_Rwno = @ServRwno, -- int
	       @Prob_Serv_File_No = NULL, -- bigint
	       @Prob_Robo_Rbid = NULL, -- bigint
	       @Chat_Id = @Chatid, -- bigint
	       @Ordr_Code = NULL, -- bigint
	       @Ordr_Numb = NULL, -- bigint
	       @Serv_Ordr_Rwno = NULL, -- bigint
	       @Ownr_Name = N'', -- nvarchar(250)
	       @Ordr_Type = @OrdrType, -- varchar(3)
	       @Strt_Date = NULL, -- datetime
	       @End_Date = NULL, -- datetime
	       @Ordr_Stat = '001', -- varchar(3)
	       @Cord_X = 0.0, -- float
	       @Cord_Y = 0.0, -- float
	       @Cell_Phon = @CellPhon, -- varchar(13)
	       @Tell_Phon = '', -- varchar(11)
	       @Serv_Adrs = @ServAdrs, -- nvarchar(1000)
	       @Arch_Stat = '001', -- varchar(3)
	       @Serv_Job_Apbs_Code = NULL, -- bigint
	       @Serv_Intr_Apbs_Code = NULL, -- bigint
	       @Mdfr_Stat = '', -- varchar(3)
	       @Crtb_Send_Stat = '', -- varchar(3)
	       @Apbs_Code = NULL, -- bigint
	       @Expn_Amnt = 0, -- bigint
	       @Extr_Prct = 0,
	       @Sub_Sys = @SubSys; -- bigint
	   
	   -- بدست آوردن شماره درخواست ثبت شده
	   SELECT @OrdrCode = o.CODE
	     FROM dbo.[Order] o
	    WHERE o.SRBT_ROBO_RBID = @Rbid
	      AND o.CHAT_ID = @Chatid
	      AND o.SUB_SYS = @SubSys
	      AND o.ORDR_STAT = '001' -- ثبت درخواست
	      AND o.ORDR_TYPE = @OrdrType -- نوع درخواست
	      AND CAST(o.STRT_DATE AS DATE) = CAST(GETDATE() AS DATE);
	END 
	-- ایا درخواستی داریم که از قبل مانده باشد
	ELSE IF EXISTS(
	   SELECT *
	     FROM dbo.[Order] o
	    WHERE o.SRBT_ROBO_RBID = @Rbid
	      AND o.CHAT_ID = @Chatid
	      AND o.SUB_SYS = @SubSys
	      AND o.ORDR_STAT = '001'
	      AND o.ORDR_TYPE = @OrdrType
	      AND ( 
	            CAST(o.STRT_DATE AS DATE) != CAST(GETDATE() AS DATE)	            
	          )
	) AND @OrdrType NOT IN ( '024' /* درخواست دریافت وجه از جانب مشتری */ )
	BEGIN
	   -- درخواست های از قبل مانده را باید انصراف بزنیم
	   UPDATE dbo.[Order]
	      SET ORDR_STAT = '003'
	    WHERE SRBT_ROBO_RBID = @Rbid
	      AND CHAT_ID = @Chatid
	      AND SUB_SYS = @SubSys
	      AND ORDR_TYPE = @OrdrType
	      AND ORDR_STAT = '001'
	      AND CAST(STRT_DATE AS DATE) != CAST(GETDATE() AS DATE);
	   
	   -- دوباره ثبت درخواست جدید برای تاریخ فعلی ثبت میکینم
	   GOTO L$INS_ORDR;	   
	END
	-- 1399/04/19
	-- اگر تاریخ انقضای سبد خرید تمام شد سبد خرید باید تمام محصولات را برگرداند
	ELSE IF @OrdrType = '004' AND 
	        EXISTS (
	           SELECT *
	             FROM dbo.[Order] o
	            WHERE o.SRBT_ROBO_RBID = @Rbid
	              AND o.CHAT_ID = @Chatid
	              AND o.SUB_SYS = @SubSys
	              AND o.ORDR_STAT = '001'
	              AND o.ORDR_TYPE = '004' /* ثبت سفارش */
	              AND (ISNULL(@OrdrExprStat, '000') = '002' /* سبد خرید دارای زمان انقضا میباشد */ AND DATEADD(MINUTE, ISNULL(@OrdrExprTime, 15), o.STRT_DATE) < GETDATE()) 
	         )
	BEGIN
	   -- 1399/08/23 * Save Data on Temo Variable
	   SELECT @TChatId = @Chatid,
	          @TOrdrCode = @OrdrCode;
	   -- بدست آوردن شماره درخواست ثبت شده
	   SELECT @OrdrCode = o.CODE
	     FROM dbo.[Order] o
	    WHERE o.SRBT_ROBO_RBID = @Rbid
	      AND o.CHAT_ID = @Chatid
	      AND o.SUB_SYS = @SubSys
	      AND o.ORDR_STAT = '001' -- ثبت درخواست
	      AND o.ORDR_TYPE = '004' -- نوع درخواست
	      AND CAST(o.STRT_DATE AS DATE) = CAST(GETDATE() AS DATE);
	   
	   
	   -- 1399/04/28
	   -- اگر سبد خریدی که انتخاب شده حداقل یک ردیف پرداختی داشته باشد نباید کالاهای درون سبد خرید 
	   IF NOT EXISTS(
	      SELECT *
	        FROM dbo.[Order_State] os
	       WHERE os.ORDR_CODE = @OrdrCode
	         AND os.CONF_STAT = '002'
	         AND os.AMNT_TYPE IN ('001', '005')
	      )  
	   BEGIN
	      L$ProductsBackToShelf:
	      -- نگهداری اطلاعات ورودی مشتری
	      SET @xTemp = @X;
	
	      SET @x.modify('replace value of (//Action/@input)[1] with "empty"');
	      -- قرار دادن شماره درخواست در پارامتر ورودی تابع های
	      SET @x.modify('replace value of (//Action/@ordrcode)[1] with sql:variable("@ordrcode")');
	      SET @x.modify('replace value of (//Action/@chatid)[1] with sql:variable("@chatid")');
	      SET @x.modify('insert attribute rsltcode {"002"} into (//Action)[1]');
	      -- در این قسمت با توجه به شماره درخواست زیر سیستم تابع های هر بخش را فراخوانی میکنیم
	      -- نرم افزار مدیریتی آرتا
	      IF @SubSys = 5
	      BEGIN
	         EXEC dbo.SAVE_S05C_P @X , @xRet OUTPUT
	      END 
	      SET @xRet = NULL;	      
	      -- بازگردانی اطلاعات به روال عادی
	      SET @X = @xTemp;	      
	   END
	   
	   SELECT @OrdrCode = NULL, @Chatid = NULL;	   
	   -- 1399/08/23 * اگر مشتریان دیگری باشند که سبد خرید منقضی شده داشته باشند باید سبد انها را ازاد کنیم 
	   SELECT TOP 1 @OrdrCode = o.CODE, @Chatid = o.CHAT_ID
       FROM dbo.[Order] o
      WHERE o.SRBT_ROBO_RBID = @Rbid
        --AND o.CHAT_ID = @Chatid
        AND o.SUB_SYS = @SubSys
        AND o.ORDR_STAT = '001'
        AND o.ORDR_TYPE = '004' /* ثبت سفارش */
        AND (ISNULL(@OrdrExprStat, '000') = '002' /* سبد خرید دارای زمان انقضا میباشد */ AND DATEADD(MINUTE, ISNULL(@OrdrExprTime, 15), o.STRT_DATE) < GETDATE())
        AND NOT EXISTS (
               SELECT *
	              FROM dbo.[Order_State] os
	             WHERE os.ORDR_CODE = o.CODE
	               AND os.CONF_STAT = '002'
	               AND os.AMNT_TYPE IN ('001', '005') 
            );
            
      -- اگر درخواستی وجود داشته باشد که منقضی شده باشد
      IF ( ISNULL(@OrdrCode, 0) != 0 AND ISNULL(@Chatid , 0) != 0 ) GOTO L$ProductsBackToShelf;
      ELSE
         -- اگر درخواستی وجود نداشته باشد بر میگردیم که اولین درخواست اصلی
         SELECT @OrdrCode = @TOrdrCode, @Chatid = @TChatId;
	END 
	-- درخواست سفارشی داریم که متعلق به همین امروز می باشد و می توانیم از آن استفاده کنیم
	ELSE IF @OrdrType NOT IN ('024' /* درخواست دریافت وجه برای مشتریان */)
	BEGIN
      -- بدست آوردن شماره درخواست ثبت شده
	   SELECT @OrdrCode = o.CODE
	     FROM dbo.[Order] o
	    WHERE o.SRBT_ROBO_RBID = @Rbid
	      AND o.CHAT_ID = @Chatid
	      AND o.SUB_SYS = @SubSys
	      AND o.ORDR_STAT = '001' -- ثبت درخواست
	      AND o.ORDR_TYPE = @OrdrType -- نوع درخواست
	      AND CAST(o.STRT_DATE AS DATE) = CAST(GETDATE() AS DATE);
	END
	ELSE IF @OrdrType IN ( '024' /* درخواست دریافت وجه مشتریان */ )
	BEGIN
	   -- بدست آوردن شماره درخواست ثبت شده
	   -- OrdrType = '024'
	   -- در این نوع درخواست اگر زمانی درخواستی ثبت شد باید منتظر این باشیم که درخواست پاسخ داده شود که پورسانت مشتری به چه صورتی در می آید
	   -- درخواست یا انصراف خورده میشود از طرف مشتری یا از طرف فروشگاه پرداخت کامل انجام داده میشود
	   
	   SELECT @OrdrCode = o.CODE
	     FROM dbo.[Order] o
	    WHERE o.SRBT_ROBO_RBID = @Rbid
	      AND o.CHAT_ID = @Chatid
	      AND o.SUB_SYS = @SubSys
	      AND o.ORDR_STAT = '001' -- ثبت درخواست
	      AND o.ORDR_TYPE = @OrdrType; -- نوع درخواست	      
	END 
	
	-- قرار دادن شماره درخواست در پارامتر ورودی تابع های
	SET @x.modify('replace value of (//Action/@ordrcode)[1] with sql:variable("@ordrcode")');
	SET @x.modify('insert attribute rsltcode {"002"} into (//Action)[1]');
	
	L$Jump1:
	-- در این قسمت با توجه به شماره درخواست زیر سیستم تابع های هر بخش را فراخوانی میکنیم
	-- نرم افزار مدیریتی آرتا
	IF @SubSys = 5
	BEGIN
	   EXEC dbo.SAVE_S05C_P @X , @xRet OUTPUT
	END 
	ELSE 
	   SET @xRet = @X;
	
	COMMIT TRAN [T$SAVE_EXTO_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX);
	   SET @ErorMesg = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK TRAN [T$SAVE_EXTO_P];
	END CATCH;
END
GO
