SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mohsen Hadaeghi
-- Create date: 2020-11-01
-- Description:	Call Customer's External database server or Web service
-- =============================================
CREATE PROCEDURE [dbo].[LKS_EXTR_P]
	@X XML
AS
BEGIN
   BEGIN TRY 
   --BEGIN TRAN T$LKS_EXTR_P
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--RETURN;
	/*
	   قبل از هر اقدامی باید ارتباط لینک سرور برقرار شود که از طریق تابع
	   CRET_LKSN_P
	   انجام پذیر میباشد، که این گزینه باید توسط کاربر درون نرم افزار انجام شود که منبع اصلی اطلاعات کدام میباشد که سرور بتواند اخرین اطلاعات بروز را دریافت کند
	*/
	
   -- در این قسمت اندازه کد تعرفه ورودی را زیاد گرفتیم بخاطر اینکه ممکن است کاربر ورودی های مختلفی داشته باشد
	-- مثلا
	-- 00701005                   => مسیر بهشت خسرو محمودیان روز های زوج شنبه تا چهارشنبه ساعت 14:00 تا 16:00 سه ماه 36 جلسه مبلغ 360 هزار تومن به تاریه امروز مباشد
	-- 00701005*d12               => این به معنای همان عبارت بالا ولی برای 12 روز آینده 
	-- 00701005*dt1398/12/20      => این به معنای این می باشد که تاریخ شروع دوره در تاریخ 1398/12/20 شروع میشود
	-- 00701005*n2                => دو دوره پشت سرهم ثبت نام شود
	-- 00701005*++                => این گزینه برای اضافه کردن خودکار میباشد
	-- 00701005*--                => این گزینه برای کم کردن خودکار میباشد
	-- 00701005*+=5               => اضافه کردن تعداد 5 عدد به کالای مورد نظر
	-- 00701055*-=5               => کم کردن تعداد 5 عدد از کالای مورد نظر
	-- 00701005*n2*d12            =>
	-- 00701005*n2*dt1398/12/20   =>
	-- 00701005*del               => حذف کردن دوره از لیست تمدید
	-- 00701055*count             => تعداد کالای ثبت شده درون فاکتور
	-- show                       => نمایش سبد خرید دوره جاری
	-- empty                      => حذف تمامی آیتم های سبد خرید دوره
	
	-- Global Var
	DECLARE @Rbid BIGINT,
	        @OrdrCode BIGINT,
	        @ChatId BIGINT,
	        @Input NVARCHAR(500);
	
	SELECT @Rbid = @X.query('//Action').value('(Action/@rbid)[1]', 'BIGINT')
	      ,@ChatId   = @X.query('//Action').value('(Action/@chatid)[1]', 'BIGINT')
	      ,@Input = REPLACE(LOWER(@X.query('//Action').value('(Action/@input)[1]', 'NVARCHAR(500)')), ' ', '')
	      ,@OrdrCode = @X.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');
   
	-- Local Var
	DECLARE @ExtrSorcStat VARCHAR(3),           
	        @BotName VARCHAR(50),
	        @XTemp XML,
	        @CmndText NVARCHAR(MAX);
	
	-- بدست آوردن اطلاعات از جدول ربات
	SELECT @ExtrSorcStat = EXTR_SORC_STAT
	      ,@BotName = NAME
	  FROM dbo.Robot
	 WHERE RBID = @Rbid;
	 
	-- اگر دسترسی به سرور بیرونی برای مشتری وجود نداشته باشد
	IF @ExtrSorcStat = '001' RETURN;	   
	
	DECLARE @CmndType VARCHAR(100)
	       ,@ParamText NVARCHAR(500);
	
	-- بدست آوردن اطلاعات ارسال شده و تفکیک اطلاعات دستوری و پارامتری
	SELECT @CmndType = CASE a.id WHEN 1 THEN a.Item ELSE @CmndType END 
	      ,@ParamText = CASE a.id WHEN 2 THEN a.Item ELSE @ParamText END	
	  FROM dbo.SplitString(@Input, ':') a;
	
	-- فروشگاه قلعه
	IF LOWER(@BotName) = '@offkade_org_bot'
	BEGIN
	   -- ثبت اطلاعات مشتری
	   IF @CmndType = 'savecust'
	   BEGIN
	      PRINT 'Save Customer in Remote Database'
	   END 
   	-- بدست آوردن اطلاعات مربوط به محصول
	   ELSE IF @CmndType = 'infoprod'
	   BEGIN
	      PRINT 'Get Info Product';
	      SET @CmndText = '	         
	         DECLARE @XTemp XML = (
   	         SELECT ' + CAST(@Rbid AS VARCHAR(10)) + ' AS RBID
   	               ,LTRIM(RTRIM(k_code)) AS TARF_CODE 
                     ,LTRIM(RTRIM(k_name)) AS TARF_TEXT 
                     ,f_taki AS EXPN_PRIC 
                     ,k_prc1 AS BUY_PRIC 
                     ,( SELECT ISNULL(SUM(mo), 0)
                        FROM   LKS_EXTR_N.melli1.dbo.tbl_mojoodi m
                        WHERE  m.a_code = 1
                               AND m.k_code = k.k_code
                      ) AS QNTY
                 FROM  LKS_EXTR_N.melli1.dbo.tbl_kala k 
                WHERE k.k_code = ''' + @ParamText + '''
                  FOR XML PATH(''Table'')
            );            
            EXEC dbo.REQL_URPR_P @X = @XTemp -- xml';
	      EXEC (@CmndText);
	   END 
	   -- ثبت اطلاعات سبد خرید مشتری
	   ELSE IF @CmndType = 'saveordr'
	   BEGIN
	      PRINT 'Save Cart to pending'
	   END 
	   -- پایانی کردن درخواست خرید مشتری
	   ELSE IF @CmndType = 'submitordr'
	   BEGIN
	      PRINT 'Submit Order to finalization'
	   END 
	END 
	-- فروشگاه کنترل صنعت هوشمند
	ELSE IF LOWER(@BotName) = '@cih_bot'
	BEGIN
	   -- ثبت اطلاعات مشتری
	   IF @CmndType = 'savecust'
	   BEGIN
	      PRINT 'Save Customer in Remote Database'
	   END 
   	-- بدست آوردن اطلاعات مربوط به محصول
	   ELSE IF @CmndType = 'infoprod'
	   BEGIN
	      PRINT 'Get Info Product';
	      SET @CmndText = '	         
	         DECLARE @XTemp XML = (
   	         SELECT ' + CAST(@Rbid AS VARCHAR(10)) + ' AS RBID
                      RTRIM(LTRIM(A_Code)) AS TARF_CODE, 
                      A_Name AS TARF_TEXT, 
                      ISNULL(EndBuy_Price, 0) AS BUY_PRIC, 
                      ISNULL(Sel_Price, 0) AS EXPN_PRIC, 
                      ISNULL(Exist, 0) AS QNTY, 
                      ''TARF:1:4'' AS GROP_CODE, 
                      ''TARF:1:2'' AS BRND_CODE, 
                      13981881902068 AS UNIT_CODE 
                 FROM LKS_EXTR_N.holoo1.dbo.ARTICLE
                WHERE a_code = ''' + @ParamText + '''
                  FOR XML PATH(''Table'')
            );            
            EXEC dbo.REQL_URPR_P @X = @XTemp -- xml';
	      EXEC (@CmndText);
	   END 
	   -- ثبت اطلاعات سبد خرید مشتری
	   ELSE IF @CmndType = 'saveordr'
	   BEGIN
	      PRINT 'Save Cart to pending'
	   END 
	   -- پایانی کردن درخواست خرید مشتری
	   ELSE IF @CmndType = 'submitordr'
	   BEGIN
	      PRINT 'Submit Order to finalization'
	   END 
	END 
	
	--COMMIT TRAN [T$LKS_EXTR_P];
	L$EndSP:
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX);
	   SET @ErorMesg = ERROR_MESSAGE();
	   --PRINT @ErorMesg;
	   --ROLLBACK TRAN [T$LKS_EXTR_P];
	END CATCH;
END
GO
