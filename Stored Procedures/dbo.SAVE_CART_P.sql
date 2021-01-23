SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SAVE_CART_P]
	-- Add the parameters for the stored procedure here
	@X XML,
	@xRet XML OUTPUT
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [SAVE_CART_P]
	
	DECLARE @OrdrType VARCHAR(3)
	       ,@TypeCode VARCHAR(3)
	       ,@TypeDesc NVARCHAR(100)
	       ,@ProdCode BIGINT
	       ,@Pric BIGINT
	       ,@TaxPrct INT
	       ,@OffPrct INT
	       ,@Numb REAL 
	       ,@Chatid BIGINT
	       ,@Rbid BIGINT
	       ,@Muid BIGINT
	       ,@UssdCode VARCHAR(250)
	       ,@ChildUssdCode VARCHAR(250)
	       ,@SubSys INT
	       ,@TarfCode VARCHAR(100)
	       ,@TarfDate DATE
	       ,@RqtpCode VARCHAR(3)
	       
	       ,@ServFileNo BIGINT
	       ,@ServRwno INT
	       ,@CellPhon VARCHAR(11)
	       ,@ServAdrs NVARCHAR(1000)
	       ,@OrdrCode BIGINT
	       
	       ,@Title NVARCHAR(250)
	       ,@Description NVARCHAR(250);
	
	SELECT @OrdrType = @X.query('//Action').value('(Action/@ordrtype)[1]', 'VARCHAR(3)')
	      ,@TypeCode = @X.query('//Action').value('(Action/@typecode)[1]', 'VARCHAR(3)')
	      ,@TypeDesc = @X.query('//Action').value('(Action/@typedesc)[1]', 'NVARCHAR(100)')
	      ,@ProdCode = @X.query('//Action').value('(Action/@prodcode)[1]', 'BIGINT')
	      ,@Pric     = @X.query('//Action').value('(Action/@pric)[1]', 'BIGINT')
	      ,@TaxPrct  = @X.query('//Action').value('(Action/@taxprct)[1]', 'INT')
	      ,@OffPrct  = @X.query('//Action').value('(Action/@offprct)[1]', 'INT')
	      ,@Numb     = @X.query('//Action').value('(Action/@numb)[1]', 'REAL')
	      ,@Chatid   = @X.query('//Action').value('(Action/@chatid)[1]', 'BIGINT')
	      ,@Rbid     = @X.query('//Action').value('(Action/@rbid)[1]', 'BIGINT')
	      ,@Muid     = @X.query('//Action').value('(Action/@muid)[1]', 'BIGINT')
	      ,@UssdCode = @X.query('//Action').value('(Action/@ussdcode)[1]', 'VARCHAR(250)')
	      ,@ChildUssdCode = @X.query('//Action').value('(Action/@childussdcode)[1]', 'VARCHAR(250)')
	      ,@SubSys = @X.query('//Action').value('(Action/@subsys)[1]', 'INT')
	      ,@TarfCode = @X.query('//Action').value('(Action/@tarfcode)[1]', 'VARCHAR(100)')
	      ,@TarfDate = @X.query('//Action').value('(Action/@tarfdate)[1]', 'DATE')
	      ,@RqtpCode = @X.query('//Action').value('(Action/@rqtpcode)[1]', 'VARCHAR(3)');
	  
	SELECT @ServFileNo = SERV_FILE_NO
	      ,@ServRwno = SRPB_RWNO
	      ,@CellPhon = CELL_PHON
	      ,@ServAdrs = SERV_ADRS
	  FROM dbo.Service_Robot
	 WHERE ROBO_RBID = @Rbid
	   AND CHAT_ID = @Chatid;
	
	IF @SubSys IS NULL
	   SET @SubSys = 12;
	
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
	
	IF NOT EXISTS(
	   SELECT * 
	     FROM dbo.[Order] o 
	    WHERE o.SRBT_ROBO_RBID = @Rbid 
	      --AND o.SRBT_SERV_FILE_NO = @ServFileNo 
	      --AND o.SRBT_SRPB_RWNO = @ServRwno 
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
	      AND o.ORDR_STAT = '001'
	      AND o.ORDR_TYPE = @OrdrType
	      AND CAST(o.STRT_DATE AS DATE) != CAST(GETDATE() AS DATE)
	)
	BEGIN
	   -- درخواست های از قبل مانده را باید انصراف بزنیم
	   UPDATE dbo.[Order]
	      SET ORDR_STAT = '003'
	    WHERE SRBT_ROBO_RBID = @Rbid
	      AND CHAT_ID = @Chatid
	      AND ORDR_TYPE = @OrdrType
	      AND ORDR_STAT = '001'
	      AND CAST(STRT_DATE AS DATE) != CAST(GETDATE() AS DATE);
	   
	   -- دوباره ثبت درخواست جدید برای تاریخ فعلی ثبت میکینم
	   GOTO L$INS_ORDR;	   
	END
	-- درخواست سفارشی داریم که متعلق به همین امروز می باشد و می توانیم از آن استفاده کنیم
	ELSE	
	BEGIN
      -- بدست آوردن شماره درخواست ثبت شده
	   SELECT @OrdrCode = o.CODE
	     FROM dbo.[Order] o
	    WHERE o.SRBT_ROBO_RBID = @Rbid
	      AND o.CHAT_ID = @Chatid
	      AND o.ORDR_STAT = '001' -- ثبت درخواست
	      AND o.ORDR_TYPE = @OrdrType -- نوع درخواست
	      AND CAST(o.STRT_DATE AS DATE) = CAST(GETDATE() AS DATE);
	END
	
	-- بدست آوردن شماره درخواست سفارش ثبت شده
	-- @OrdrCode => (value)
	
	-- حال باید ببینیم از تابع چه درخواست چه عملیاتی داریم
	IF @TypeCode IN ( '001', '003', '006' )
	BEGIN	   
	   PRINT @TypeDesc;
	   
	   DECLARE @getdirectpaymentprocess TABLE (
	         Price BIGINT, Ussd_Code VARCHAR(250), Child_Ussd_Code VARCHAR(250),
	         Muid BIGINT, Gpid BIGINT, Auto_Join VARCHAR(3), [Default] VARCHAR(3),
	         Title NVARCHAR(100), [Description] NVARCHAR(250),
	         Tax INT, Off_Percentage INT
	      );
	      
      INSERT INTO @getdirectpaymentprocess
             (
               Price ,Ussd_Code ,Child_Ussd_Code ,
               Muid ,Gpid ,
               Auto_Join ,[Default] ,
               Title ,[Description] ,
               Tax ,Off_Percentage
             )	      
      SELECT ghi.PRIC AS Price, @UssdCode AS Ussd_Code, @ChildUssdCode AS Child_Ussd_Code,
             ghi.GRMU_MNUS_MUID AS Muid, ghi.GRMU_GROP_GPID AS Gpid,
             g.AUTO_JOIN, srg.DFLT_STAT AS [Default],
             ghi.GHDT_DESC AS Title, gh.GRPH_DESC AS [Description],
             ghi.TAX_PRCT AS Tax, g.OFF_PRCT AS Off_Percentage
        FROM dbo.[Group_Header] gh, dbo.Group_Header_Item ghi, dbo.Group_Menu_Ussd gm, dbo.[Group] g, dbo.Menu_Ussd m, dbo.Service_Robot_Group srg, dbo.Service_Robot sr
       WHERE -- Group_Header_Item join Group_Header
             ghi.GPHD_GHID = gh.GHID
             -- Group_Header_Item join Group_Menu_Ussd
         AND ghi.GRMU_GROP_GPID = gm.GROP_GPID
         AND ghi.GRMU_MNUS_ROBO_RBID = gm.MNUS_ROBO_RBID
         AND ghi.GRMU_MNUS_MUID = gm.MNUS_MUID
             -- Group_Menu_Ussd join Group
         AND gm.GROP_GPID = g.GPID
             -- Group_Menu_Ussd join Menu_Ussd
         AND gm.MNUS_ROBO_RBID = m.ROBO_RBID
         AND gm.MNUS_MUID = m.MUID
             -- Group join Service_Robot_Group
         AND g.GPID = srg.GROP_GPID
             -- Service_Robot_Group join Service_Robot
         AND srg.SRBT_ROBO_RBID = sr.ROBO_RBID
         AND srg.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
             -- Where condition
         AND m.ROBO_RBID = @Rbid
         AND sr.CHAT_ID = @Chatid
         AND ghi.STAT = '002'
         AND g.STAT = '002'
         AND gm.STAT = '002'
         AND srg.STAT = '002'
         AND ghi.CODE = @ProdCode	         
         AND m.MUID = @Muid;
	   
	   DECLARE @getdefaultgroupaccess TABLE (Off_Percentage INT);
	      
      INSERT INTO @getdefaultgroupaccess
             ( Off_Percentage )
      SELECT g.OFF_PRCT
        FROM dbo.Group_Menu_Ussd gm, dbo.[Group] g, dbo.Service_Robot_Group srg, dbo.Service_Robot sr
       WHERE gm.GROP_GPID = g.GPID
         AND g.GPID = srg.GROP_GPID
         AND srg.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
         AND srg.SRBT_ROBO_RBID = sr.ROBO_RBID
         AND sr.ROBO_RBID = @Rbid
         AND sr.CHAT_ID = @Chatid
         AND srg.DFLT_STAT = '002'
         AND g.STAT = '002'
         AND gm.STAT = '002'
         AND srg.STAT = '002'
         AND gm.MNUS_MUID = @Muid;
	   
	   DECLARE @dfltgropamnt TABLE (
	         Price BIGINT, Ussd_Code VARCHAR(250), Child_Ussd_Code VARCHAR(250),
	         Muid BIGINT, Gpid BIGINT, Auto_Join VARCHAR(3), [Default] VARCHAR(3),
	         Title NVARCHAR(100), [Description] NVARCHAR(250),
	         Tax INT, Off_Percentage INT
	      );
	   
	   INSERT INTO @dfltgropamnt
	          (
	             Price ,Ussd_Code ,Child_Ussd_Code ,
                Muid ,Gpid ,
                Auto_Join ,[Default] ,
                Title ,[Description] ,
                Tax ,Off_Percentage
	          )
	   SELECT Price ,Ussd_Code ,Child_Ussd_Code ,
             Muid ,Gpid ,
             Auto_Join ,[Default] ,
             Title ,[Description] ,
             Tax ,Off_Percentage
	     FROM @getdirectpaymentprocess
	    WHERE [Default] = '002';
	   
	         
	   -- آیا مشتری دارای نرخ تخفیف ویژه می باشد یا خیر
	   IF EXISTS(
	      SELECT *
	        FROM @getdirectpaymentprocess
	       WHERE [Default] = '002'
	   )
	   BEGIN	
	      -- بدست آوردن مبلغ برای مشتریان با تخفیف ویژه مانند همکاران فروش
	      SELECT @Pric = MAX(Price)
	        FROM @dfltgropamnt;
	      
	      SELECT @TaxPrct = Tax
	        FROM @dfltgropamnt
	       WHERE Price = @Pric;	      
	      
	      -- بدست آوردن آیتم های شرح
	      SELECT @Title = Title, @Description = [Description]
	        FROM @dfltgropamnt
	       WHERE Price = @Pric;
	   END
	   -- اگر مشتری نرخ مشخصی برای تخفیف نداشته باشد	   
	   ELSE
	   BEGIN
	      SELECT @Pric = MAX(Price)
	        FROM @getdirectpaymentprocess
	       WHERE Auto_Join = '002';
	      
	      SELECT @TaxPrct = Tax
	        FROM @getdirectpaymentprocess
	       WHERE Auto_Join = '002'
	         AND Price = @Pric;
	      
	      -- اگر مشتری به گروه های پیش فرض دسترسی داشته باشد
	      -- ولی برای گروه دسترسی مبلغی در نظر گرفته نشده است
	      -- بر این اساس مشخص میکنیم که ایا گروه پیش فرض درصد تخفیف برای آن لحاظ شده یا خیر
	      
	      IF NOT EXISTS(SELECT * FROM @getdefaultgroupaccess)
	         SELECT TOP 1 
	                @OffPrct = Off_Percentage
	           FROM @getdirectpaymentprocess
	          WHERE Auto_Join = '002'
	            AND Price = @Pric;
	      ELSE
	         SELECT @OffPrct = MAX(Off_Percentage)
	           FROM @getdefaultgroupaccess;	         
         
         SELECT @Title = Title, @Description = [Description]
           FROM @getdirectpaymentprocess
          WHERE Auto_Join = '002'
            AND Price = @Pric;	      
	   END 
	   
	   IF @OffPrct > 0
	      SET @Pric -= (@Pric * @OffPrct) / 100;
	   
	   IF NOT EXISTS( 
	      SELECT * 
	        FROM dbo.Order_Detail od
	       WHERE od.ORDR_CODE = @OrdrCode
	         AND od.GHIT_CODE = @ProdCode
	   )
	   BEGIN	 	      
	      EXEC dbo.INS_ODRT_P @Ordr_Code = @OrdrCode, -- bigint
	          @Elmn_Type = '011', -- varchar(3)
	          @Ordr_Desc = @Title, -- nvarchar(max)
	          @Expn_Pric = @Pric, -- bigint
	          @Extr_Prct = NULL, -- bigint
	          @Tax_Prct = @TaxPrct, -- int
	          @Off_Prct = @OffPrct, -- int
	          @Numb = @Numb, -- int
	          @Base_Ussd_Code = @UssdCode, -- varchar(250)
	          @Sub_Ussd_Code = @ChildUssdCode, -- varchar(250)
	          @Ordr_Cmnt = @Description, -- nvarchar(4000)
	          @Ordr_Imag = NULL, -- image
	          @Imag_Path = N'', -- nvarchar(4000)
	          @Mime_Type = '', -- varchar(100)
	          @Ghit_Code = @ProdCode, -- bigint
	          @Ghit_Min_Date = NULL, -- datetime
	          @Ghit_Max_Date = NULL; -- datetime
	      
	      UPDATE dbo.Order_Detail
	         SET TARF_CODE = @TarfCode
	            ,TARF_DATE = @TarfDate
	            ,RQTP_CODE_DNRM = @RqtpCode
	       WHERE ORDR_CODE = @OrdrCode
	         AND GHIT_CODE = @ProdCode;
	   END
	   ELSE
	   BEGIN
	      DECLARE @OrdrRwno BIGINT;
	      -- اضافه کردن یک به یک به سبد خرید
	      
         SELECT @OrdrRwno = RWNO, 
                @Numb = CASE @TypeCode 
                             WHEN '001' then ISNULL(NUMB, 0) + 1
                             WHEN '003' THEN @Numb
                             WHEN '006' THEN @Numb
                        END                
           FROM dbo.Order_Detail
          WHERE ORDR_CODE = @OrdrCode
            AND GHIT_CODE = @ProdCode;	      
	         
	      EXEC dbo.UPD_ODRT_P @Ordr_Code = @OrdrCode, -- bigint
	          @Rwno = @OrdrRwno, -- bigint
	          @Elmn_Type = '011', -- varchar(3)
	          @Ordr_Desc = @Title, -- nvarchar(max)
	          @Expn_Pric = @Pric, -- bigint
	          @Extr_Prct = NULL, -- bigint
	          @Tax_Prct = @TaxPrct, -- int
	          @Off_Prct = @OffPrct, -- int
	          @Numb = @Numb, -- int
	          @Base_Ussd_Code = @UssdCode, -- varchar(250)
	          @Sub_Ussd_Code = @ChildUssdCode, -- varchar(250)
	          @Ordr_Cmnt = @Description, -- nvarchar(4000)
	          @Ordr_Imag = NULL, -- image
	          @Imag_Path = N'', -- nvarchar(4000)
	          @Mime_Type = '', -- varchar(100)
	          @Ghit_Code = @ProdCode, -- bigint
	          @Ghit_Min_Date = NULL, -- datetime
	          @Ghit_Max_Date = NULL; -- datetime	      
	   END
	END
	ELSE IF @TypeCode = '002'
	BEGIN
	   PRINT @TypeDesc;
	   IF EXISTS(
	      SELECT *
	        FROM dbo.Order_Detail
	       WHERE ORDR_CODE = @OrdrCode
	         AND GHIT_CODE = @ProdCode
	         AND ISNULL(NUMB, 0) > 1
	   )
	   BEGIN
	      UPDATE dbo.Order_Detail
	         SET NUMB -= 1
	       WHERE ORDR_CODE = @OrdrCode
	         AND GHIT_CODE = @ProdCode;
	   END 
	   ELSE
	   BEGIN
	      DELETE dbo.Order_Detail
	        WHERE ORDR_CODE = @OrdrCode
	          AND GHIT_CODE = @ProdCode;	          
	   END 
	END 

	
	-- در آخر ستون های مربوط به جدول درخواست به ترتیب باید بروزرسانی شود
	-- Expn_Amnt, Extr_Prct, Dscn_Amnt_Dnrm, Pymt_Amnt_Dnrm, Cost_Amnt_Dnrm
	UPDATE o
	   SET o.Expn_Amnt = (SELECT SUM(od.EXPN_PRIC * od.NUMB) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE)
	      ,o.EXTR_PRCT = (SELECT SUM(od.EXTR_PRCT * od.NUMB) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE)
	      ,o.DSCN_AMNT_DNRM = (SELECT SUM(((od.EXPN_PRIC + od.EXTR_PRCT) * od.NUMB) * od.OFF_PRCT / 100 ) FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE)
	      ,o.AMNT_TYPE = (SELECT DISTINCT ghi.AMNT_TYPE FROM dbo.Order_Detail od, dbo.Group_Header_Item ghi WHERE od.ORDR_CODE = o.CODE AND od.GHIT_CODE = ghi.CODE)
	  FROM dbo.[Order] o
	 WHERE o.CODE = @OrdrCode;
	
	IF EXISTS(SELECT * FROM dbo.Order_Detail WHERE ORDR_CODE = @OrdrCode)
	   SELECT @xRet = (
	          SELECT 'successful' AS '@rsltdesc',
                    '002' AS '@rsltcode',
                    @OrdrCode AS '@ordrcode',
	                 CASE @TypeCode 
	                      WHEN '001' THEN N'➕ محصول مورد نظر شما با موفقیت در سبد خرید قرار گرفت'
	                      WHEN '002' THEN N'❌ محصول مورد نظر شما از سبد خرید حذف گردید'
	                      WHEN '003' THEN N'#️⃣ محصول مورد نظر شما با تعداد وارد شده در سبد خرید ویرایش گردید'
	                      WHEN '004' THEN N'🛍 درخواست نمایش سبد خرید شما'
	                      WHEN '006' THEN N'⭐️ صدور فاکتور'
	                 END + CHAR(10) + CHAR(10) + 
	                 N'📋  صورتحساب شما' + CHAR(10) + 
	                 N'👈  شماره فاکتور *' + CAST(@OrdrCode AS NVARCHAR(30)) + N'*' + CHAR(10) + CHAR(10) + 
	                 (
	                    SELECT --CAST(od.RWNO AS NVARCHAR(3)) + N' ) ' + 
	                           N'📦 '+ m.MENU_TEXT + CHAR(10) + 
	                           N'💰 [ مبلغ ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, od.EXPN_PRIC), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' +
	                           CASE WHEN ISNULL(od.TAX_PRCT, 0) != 0 THEN N'🇮🇷 [ ارزش افزوده ] ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, od.EXTR_PRCT), 1), '.00', '') + + N' [ ' + au.DOMN_DESC + N' ] ' + N'🔢 [ تعداد ]  ' + CAST(od.NUMB AS NVARCHAR(10)) + N'  [ ' + a.TITL_DESC + N' ]'+ CHAR(10) + CHAR(10) 
	                                ELSE N'🔢 [ تعداد ]  *' + CAST(od.NUMB AS NVARCHAR(10)) + N'*  [ *' + a.TITL_DESC + N'* ]'+ CHAR(10) + CHAR(10) 
	                           END
	                      FROM dbo.Order_Detail od, dbo.Group_Header_Item ghi, dbo.Group_Header gh, dbo.Menu_Ussd m, dbo.App_Base_Define a, dbo.[D$AMUT] au
	                     WHERE ORDR_CODE = @OrdrCode
	                       AND od.GHIT_CODE = ghi.CODE
	                       AND ghi.GPHD_GHID = gh.GHID
	                       AND ghi.GRMU_MNUS_ROBO_RBID = m.ROBO_RBID
	                       AND ghi.GRMU_MNUS_MUID = m.MUID
	                       AND ghi.UNIT_APBS_CODE = a.CODE
	                       AND ghi.AMNT_TYPE = au.VALU
	                   FOR XML PATH('')
	                 ) + --CHAR(10) +
	                 (
	                   SELECT CASE WHEN ISNULL(o.EXTR_PRCT, 0) != 0 THEN 
	                                 N'🛍 [ جمع مبلغ صورتحساب ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.EXPN_AMNT), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) + 
	                                 N'🇮🇷 [ ارزش افزوده ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.EXTR_PRCT), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) + 
	                                 CASE WHEN ISNULL(o.TXFE_AMNT_DNRM, 0) != 0 THEN 
	                                        N'👈 [ کارمزد خدمات غیرحضوری ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.TXFE_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) +
	                                        N'💵 [ مبلغ نهایی ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.EXPN_AMNT + o.EXTR_PRCT + o.TXFE_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' 
	                                      ELSE
	                                        N'💵 [ مبلغ نهایی ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.EXPN_AMNT + o.EXTR_PRCT), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' 
	                                 END    	                                 
	                               ELSE 	                                 
	                                 CASE WHEN ISNULL(o.TXFE_AMNT_DNRM, 0) != 0 THEN 
	                                        N'🛍 [ جمع مبلغ صورتحساب ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.EXPN_AMNT), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) + 
	                                        N'👈 [ کارمزد خدمات غیرحضوری ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.TXFE_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' + CHAR(10) +
	                                        N'💵 [ مبلغ نهایی ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.EXPN_AMNT + o.TXFE_AMNT_DNRM), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' 
	                                      ELSE
	                                        N'💵 [ مبلغ نهایی ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.EXPN_AMNT), 1), '.00', '') + N'* [ *' + au.DOMN_DESC + N'* ] ' 
	                                 END    	                                 
	                          END + CHAR(10) 	                          
	                     FROM dbo.[Order] o, dbo.[D$AMUT] au
	                    WHERE o.CODE = @OrdrCode
	                      AND o.AMNT_TYPE = au.VALU
	                 ) + CHAR(10) + 
	                 --N'📢 توجه داشته باشید که مبالغ بر حسب [ ریال ] میباشد' + CHAR(10) + 
	                 CASE @OrdrType 
	                    WHEN '004' THEN 
	                       CASE WHEN @TypeCode = '003' THEN N'👈  لطفا جهت پرداخت صورتحساب دکمه *"🔺 بازگشت"* را فشار دهید و بعد دکمه *"💳 عملیات پرداخت"* را فشار دهید'
	                            ELSE N'👈 لطفا جهت پرداخت صورتحساب دکمه *"💳 عملیات پرداخت"* را فشار دهید' 
	                       END
	                    ELSE N'👈 لطفا جهت پرداخت صورتحساب دکمه *"پرداخت"* را فشار دهید' 
	                 END 
	                 
	             FOR XML PATH('Message'), ROOT('Result')   	
	   )
	ELSE
	   SELECT @xRet = (
	      SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                0 AS '@ordrcode',
                N'⚠️ سبد خرید شما خالی می باشد'
	     FOR XML PATH('Message'), ROOT('Result')	     
	   );
	
	COMMIT TRAN [SAVE_CART_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX);
	   SET @ErorMesg = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN [SAVE_CART_P];
	END CATCH
END
GO
