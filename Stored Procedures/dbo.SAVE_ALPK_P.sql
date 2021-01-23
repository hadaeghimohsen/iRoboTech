SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SAVE_ALPK_P]
	@X XML,
	@xRet XML OUTPUT
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$SAVE_ALPK_P]
	
	DECLARE @Rbid BIGINT  
	       ,@OrdrCode BIGINT
	       ,@PeykOrdrCode BIGINT
	       ,@ActnCode VARCHAR(3)
	       ,@ActnDesc NVARCHAR(250)
	       ,@ExpnAmnt BIGINT
	       ,@AmntType VARCHAR(3)
	       ,@Chatid BIGINT
	       ,@Cmnd VARCHAR(100)
	       ,@OrdrNumb BIGINT
	       ,@Token VARCHAR(100)
	       ,@ServFileNo BIGINT
	       ,@MsgbText NVARCHAR(max);
	
	SELECT @Rbid = @x.query('//RequestAlopeyk').value('(RequestAlopeyk/@rbid)[1]', 'BIGINT')
	      ,@OrdrCode = @X.query('//RequestAlopeyk').value('(RequestAlopeyk/@ordrcode)[1]', 'BIGINT')
	      ,@ExpnAmnt = @X.query('//RequestAlopeyk').value('(RequestAlopeyk/@expnamnt)[1]', 'BIGINT')
	      ,@AmntType = @X.query('//RequestAlopeyk').value('(RequestAlopeyk/@amnttype)[1]', 'VARCHAR(3)')
	      ,@ActnCode = @x.query('//RequestAlopeyk').value('(RequestAlopeyk/@actncode)[1]', 'VARCHAR(3)')
	      ,@ActnDesc = @x.query('//RequestAlopeyk').value('(RequestAlopeyk/@actndesc)[1]', 'NVARCHAR(250)')
	      ,@Cmnd = @x.query('//RequestAlopeyk').value('(RequestAlopeyk/@cmnd)[1]', 'VARCHAR(100)')
	      ,@Token = @x.query('//RequestAlopeyk').value('(RequestAlopeyk/@token)[1]', 'VARCHAR(100)');
	
	-- مدیریت کد های دستوری	
	IF @ActnCode = '000'
	BEGIN	
	   -- بدست آوردن شماره ربات
	   SELECT @Rbid = RBID
	     FROM dbo.Robot
	    WHERE TKON_CODE = @Token;
	    
	   IF @Cmnd LIKE '__*%'
	   BEGIN
	      -- درخواست گرفتن بسته برای بردن توسط پیک موتوری
	      -- با این گزینه پیام برای دیگر پیک ها زده میشود که بسته توسط پیکی گرفته شده
	      -- بعد از آن درخواست مابقی پیکی ها از پایگاه داده حذف میشود
	      SET @ActnCode = '002'
	   END 
	   ELSE IF @Cmnd LIKE '__!%'
	   BEGIN
	      -- انصراف درخواست گرفتن بسته برای بردن توسط پیک موتوری
	      -- ثبت مجدد درخواست برای بقیه پیک ها
	      SET @ActnCode = '003'
	   END 
	   ELSE IF @Cmnd LIKE '__#%'
	   BEGIN
	      -- پیک بسته را از مبدا دریافت کرد
	      -- به حسابدار، انباردار و مشتری پیام میدهیم که بسته در حال ارسال به مقصد میباشد
	      SET @ActnCode = '004'
	   END 
	   ELSE IF @Cmnd LIKE '__$%'
	   BEGIN
	      -- پیک بسته را به مقصد تحویل داد
	      -- به حسابدار و مشتری پیام میدهیم که بسته تحویل به مقصد داده شده است
	      SET @ActnCode = '005'
	   END 
	   ELSE IF @Cmnd LIKE '__@%'
	   BEGIN
	      -- مشتری اعلام میکند که بسته به دستش رسیده
	      -- به حسابدار و پیک پیام تشکر میدهیم که بسته تحویل به مقصد داده شده است
	      SET @ActnCode = '006'
	   END
	   
	   SELECT @OrdrNumb = SUBSTRING(@Cmnd, 4, LEN(@Cmnd));
	   -- این درخواست ثبت سفارش می باشد
	   SELECT @OrdrCode = o.CODE
	     FROM dbo.[Order] o
	    WHERE o.SRBT_ROBO_RBID = @Rbid
	      --AND o.CHAT_ID = @Chatid
	      AND o.ORDR_TYPE = '004'
	      AND o.ORDR_NUMB = @OrdrNumb;
	   
	   -- اگر درخواستی ثبت نشده باشد
	   IF @OrdrCode IS NULL
	   BEGIN
	      SET @xRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ *شماره تاییدیه درست نیست*' + CHAR(10) + CHAR(10) + 
                   N'💡 کد خروجی : ' + N'*3*' + CHAR(10) +
                   N'👈 لطفا *شماره* را *درست* وارد کنید' + CHAR(10) +
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')              
         );
         
         -- پایان کار
         GOTO L$EndSP;
	   END;
	   
	   -- بدست آوردن شماره اشتراک
	   SELECT @Chatid = @x.query('//Alopeyk').value('(Alopeyk/@chatid)[1]', 'BIGINT');
	   
	   IF @ActnCode IN ('002', '003', '004', '005')
	   BEGIN
	      -- بدست آوردن شماره درخواست مربوط به پیک جاری
	      SELECT @PeykOrdrCode = o.CODE
	        FROM dbo.[Order] o
	       WHERE o.ORDR_TYPE = '019'
	         AND o.ORDR_CODE = @OrdrCode -- درخواست ثبت سفارش
	         AND o.CHAT_ID = @Chatid;	   
	   END;
	   ELSE IF @ActnCode = '006'
	   BEGIN
	      SELECT @PeykOrdrCode = o.CODE
	        FROM dbo.[Order] o
	       WHERE o.ORDR_CODE = @OrdrCode
	         AND o.ORDR_TYPE = '019'
	         AND o.ORDR_STAT = '008';
	      
	      --SELECT @Chatid = CHAT_ID
	      --  FROM dbo.[Order]
	      -- WHERE CODE = @OrdrCode;
	   END;
	   
	END -- if @actncode = '000'	
	
	-- ثبت درخواست اولیه پیک موتوری های انتخاب شده
	IF @ActnCode = '001'
	BEGIN
	   DECLARE @docHandle INT;	
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;

      DECLARE C$Alopeyks CURSOR
      FOR
      SELECT  *
      FROM    OPENXML(@docHandle, N'//Alopeyk')
      WITH (
        Chat_Id BIGINT './@chatid'     
      );
      
      OPEN [C$Alopeyks];
      L$Loop$Alopeyks:
      FETCH [C$Alopeyks] INTO @Chatid;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoopC$Alopeyks;
      
      IF NOT EXISTS(SELECT * FROM dbo.[Order] o WHERE o.SRBT_ROBO_RBID = @Rbid AND o.CHAT_ID = @Chatid AND o.ORDR_TYPE = '019' AND o.ORDR_STAT = '001' AND o.ORDR_CODE = @OrdrCode)
      BEGIN       
         -- ذخیره سازی درخواست برای ارسال به پیام به پیک موتوری ها
         INSERT  INTO dbo.[Order](CODE, ORDR_CODE, SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,ORDR_TYPE ,STRT_DATE ,ORDR_STAT, CORD_X, CORD_Y, CELL_PHON, TELL_PHON, SERV_ADRS, SORC_CORD_X, SORC_CORD_Y, SORC_CELL_PHON, SORC_TELL_PHON, SORC_POST_ADRS, SORC_EMAL_ADRS, SORC_WEB_SITE, EXPN_AMNT, AMNT_TYPE)
         SELECT dbo.GNRT_NVID_U(), @OrdrCode, pr.SERV_FILE_NO, pr.ROBO_RBID, '019', GETDATE(), '001', o.CORD_X, o.CORD_Y, o.CELL_PHON, o.TELL_PHON, o.SERV_ADRS, o.SORC_CORD_X, o.SORC_CORD_Y, o.SORC_CELL_PHON, o.SORC_TELL_PHON, o.SORC_POST_ADRS, o.SORC_EMAL_ADRS, o.SORC_WEB_SITE, @ExpnAmnt, @AmntType
           FROM Job j , Personal_Robot pr ,Personal_Robot_Job prj, dbo.[Order] o
          WHERE j.CODE = prj.JOB_CODE 
            AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID 
            AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO 
            AND j.ROBO_RBID = prj.PRBT_ROBO_RBID
            AND j.ROBO_RBID = @Rbid
            AND pr.CHAT_ID = @Chatid
            AND j.ORDR_TYPE = '019'
            AND pr.STAT = '002'
            AND prj.STAT = '002'
            AND o.CODE = @OrdrCode;
         
        INSERT INTO dbo.Order_Detail
        (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , ORDR_DESC )
        SELECT op.CODE, '001', N'درخواست سفیر بابت ارسال بسته',
               (
                  SELECT N'📝 [ اطلاعات بسته ارسالی ]' + CHAR(10) +
                         N'[ وضعیت ارسال ] : *' +  N'✅ تایید شده *' + CHAR(10) + 
	                      N'[ شماره درخواست بسته ] : ' + CAST(o.CODE AS NVARCHAR(20)) + CHAR(10) + 
	                      N'[ شماره تاییدیه ] : *' + CAST(o.ORDR_NUMB AS NVARCHAR(20)) + N'*' + CHAR(10) +
	                      N'[ تاریخ و زمان ] : *' + dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) + CHAR(10) + 
	                      
	                      N'💵 [ هزینه ارسال بسته ]' + CHAR(10) + 
	                      CASE WHEN ISNULL(@ExpnAmnt, 0) = 0 THEN N'👈 *هزینه شما به عهده مقصد میباشد*'
	                           ELSE N'⚠️ هزینه ارسال : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @ExpnAmnt), 1), '.00', '') + N'* [ ' + au.DOMN_DESC + N' ] ' 
	                      END + CHAR(10) + CHAR(10) + 	                      
   	                   
   	                   N'📍 [ آدرس مبدا ] : ' + CHAR(10) +
   	                   REPLACE(N'*{0}*', '{0}', o.SORC_POST_ADRS) + CHAR(10) +
   	                   --CASE WHEN o.SORC_CORD_X IS NOT NULL THEN REPLACE(REPLACE('📌 https://maps.google.com/maps?q={0}&ll={1}&z=18', '{0}' ,o.SORC_CORD_X), '{1}', o.SORC_CORD_Y) ELSE N' ' END + CHAR(10) + 
   	                   N'📱 [ موبایل ] : *' + ISNULL(o.SORC_CELL_PHON, ' --- ') + N'*' + CHAR(10) + 
   	                   N'☎️ [ تلفن ] : *' + ISNULL(o.SORC_TELL_PHON, ' --- ') + N'*' + CHAR(10) + CHAR(10) +
   	                   
   	                   N'🏁 [ آدرس مقصد ] : ' + CHAR(10) +
	                      REPLACE(N'*{0}*', '{0}', o.SERV_ADRS) + CHAR(10) +
   	                   --CASE WHEN o.CORD_X IS NOT NULL THEN REPLACE(REPLACE('📌 https://maps.google.com/maps?q={0}&ll={1}&z=18', '{0}', o.CORD_X), '{1}', o.CORD_Y) ELSE N' ' END + CHAR(10) + 
   	                   N'📱 [ موبایل ] : *' + ISNULL(o.CELL_PHON, ' --- ') + N'*' + CHAR(10) + 
   	                   N'☎️ [ تلفن ] : *' + ISNULL(o.TELL_PHON, ' --- ') + N'*' + CHAR(10) + CHAR(10) +
   	                   
   	                   N'👈 [ *شما میتونید ببرید؟* ] ' + CHAR(10) + 
   	                   N'* *%*' + CAST(o.ORDR_NUMB AS NVARCHAR(20)) + N'*' 
	                 FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s, dbo.[D$AMUT] au
	                WHERE o.CODE = @OrdrCode
	                  AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	                  AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
	                  AND sr.SERV_FILE_NO = s.FILE_NO
	                  AND ISNULL(o.AMNT_TYPE, '001') = au.VALU
               )
          FROM dbo.[Order] op
         WHERE op.ORDR_TYPE = '019' -- درخواست های سفیر
           AND op.ORDR_STAT = '001'
           AND op.CHAT_ID = @Chatid
           AND op.ORDR_CODE = @OrdrCode
        UNION
        SELECT op.CODE, '005', N'آدرس مبدا برای دریافت بسته',
               CONVERT(VARCHAR(max), op.SORC_CORD_X, 128) + ',' + CONVERT(VARCHAR(max), op.SORC_CORD_Y, 128)
          FROM dbo.[Order] op
         WHERE op.ORDR_TYPE = '019' -- ثبت آدرس مبدا
           AND op.ORDR_STAT = '001'
           AND op.CHAT_ID = @Chatid
           AND op.ORDR_CODE = @OrdrCode
           AND op.SORC_CORD_X IS NOT NULL
        UNION
        SELECT op.CODE, '005', N'آدرس مقصد برای ارسال بسته',
               CONVERT(VARCHAR(max), op.CORD_X, 128) + ',' + CONVERT(VARCHAR(max), op.CORD_Y, 128)
          FROM dbo.[Order] op
         WHERE op.ORDR_TYPE = '019' -- ثبت آدرس مبدا
           AND op.ORDR_STAT = '001'
           AND op.CHAT_ID = @Chatid
           AND op.ORDR_CODE = @OrdrCode
           AND op.CORD_X IS NOT NULL;
      END;
      
      GOTO L$Loop$Alopeyks;
      L$EndLoopC$Alopeyks:
      CLOSE [C$Alopeyks];
      DEALLOCATE [C$Alopeyks];
      
      EXEC sp_xml_removedocument @docHandle;  
      
      DECLARE C$SndMsg2PJob CURSOR FOR
	      SELECT o.CODE, o.ORDR_TYPE
	        FROM dbo.[Order] o
	       WHERE o.ORDR_CODE = @OrdrCode
	         AND o.ORDR_STAT = '001'
	         AND o.ORDR_TYPE IN ('019' /* شغل پیک موتوری */)
	   
	   DECLARE @Code BIGINT
	          ,@OrdrType VARCHAR(3);
	   
	   OPEN [C$SndMsg2PJob];
	   L$Loop_C$SndMsg2PJob:
	   FETCH [C$SndMsg2PJob] INTO @Code, @OrdrType;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop_C$SndMsg2PJob;	   
	      
      UPDATE dbo.[Order]
         SET ORDR_STAT = '002'
       WHERE CODE = @Code;
      
      DECLARE @XMessage XML;
      
      SELECT  @XMessage = ( 
         SELECT @Code AS '@code' ,
                @Rbid AS '@roborbid' ,
                @OrdrType '@type',
                prj.CODE AS '@dirprjbcode'
           FROM dbo.Job j, dbo.Personal_Robot pr, dbo.Personal_Robot_Job prj
         WHERE j.ROBO_RBID = @Rbid
           AND j.ORDR_TYPE = '019' -- پیک موتوری
           AND pr.ROBO_RBID = @Rbid
           AND pr.CHAT_ID = @Chatid
           AND j.CODE = prj.JOB_CODE
           AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO
           AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID
        FOR XML PATH('Order'), ROOT('Process')
      );
      EXEC Send_Order_To_Personal_Robot_Job @XMessage;
      
      GOTO L$Loop_C$SndMsg2PJob;
      L$EndLoop_C$SndMsg2PJob:
      CLOSE [C$SndMsg2PJob];
      DEALLOCATE [C$SndMsg2PJob]; 
   END -- if @actncode = '001'
   ELSE IF @ActnCode = '002'
   BEGIN
      -- محافظت از ناحیه بحرانی
      SELECT 'LockTab' FROM dbo.[Order] o WITH (TABLOCKX) WHERE o.CODE = @OrdrCode;
      
      -- اگر درخواست توسط سفیر دیگری گرفته شده باشد کلیه درخواست های پیک های دیگر حذف میشود
      IF NOT EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @PeykOrdrCode)
      BEGIN
         SET @xRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ *درخواست توسط سفیر دیگری گرفته شد*' + CHAR(10) + CHAR(10) + 
                   N'💡 کد خروجی : ' + N'*1*' + CHAR(10) +
                   N'👈 لطفا منتظر درخواست *بعدی* باشید' + CHAR(10) +
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')              
         );
         
         -- پایان کار
         GOTO L$EndSP;
      END;
      
      -- اگر سفیری درخواست اعلام آمادگی کرده که بسته را جابه جا کند
      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.ORDR_CODE = @OrdrCode AND o.ORDR_TYPE = '019' AND o.CHAT_ID != @Chatid AND o.ORDR_STAT = '006' /* سفیر اعلام آمادگی کرده */)
      BEGIN
         SET @xRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ *درخواست توسط سفیر دیگری گرفته شد*' + CHAR(10) + CHAR(10) + 
                   N'💡 کد خروجی : ' + N'*2*' + CHAR(10) +
                   N'👈 لطفا منتظر درخواست *بعدی* باشید' + CHAR(10) +
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')              
         );
         
         -- پایان کار
         GOTO L$EndSP;
      END 
      
      -- اگر سفیر درخواست را دوباره ارسال کرده باشد
      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @PeykOrdrCode AND o.ORDR_STAT = '006')
      BEGIN
         SET @xRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ *درخواست توسط شما ثبت شده*' + CHAR(10) + CHAR(10) + 
                   N'💡 کد خروجی : ' + N'*4*' + CHAR(10) +
                   N'👈 لطفا به *محل مبدا* برای *گرفتن بسته* اقدام فرمایید' + CHAR(10) +
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')              
         );
         
         -- پایان کار
         GOTO L$EndSP;
      END 
      
      -- در این قسمت درخواست بدون هیچ مشکلی می تواند توسط سفیر گرفته شود
      -- تغییر وضعیت درخواست برای پیک به حالت {اعلام آمادگی سفیر} برای جابه جا کردن بسته
      UPDATE dbo.[Order]
         SET ORDR_STAT = '006'
       WHERE CODE = @PeykOrdrCode
         AND ORDR_STAT = '002';
      
      -- حذف مابقی درخواست های ثبت شده برای سفیران
      DELETE FROM dbo.[Order] 
       WHERE ORDR_CODE = @OrdrCode
         AND ORDR_TYPE = '019' 
         AND CODE != @PeykOrdrCode;
      
      -- آماده سازی پیام برای ارسال به واحد حسابداری و انبارداری
      INSERT INTO dbo.Order_Detail
      (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , ORDR_DESC )
      SELECT op.CODE, '001', N'تاییدیه سفیر بابت ارسال بسته',
             (
                SELECT N'📝 [ اطلاعات سفیر ]' + CHAR(10) +
                       N'[ شماره اشتراک ] : *' + CAST(o.CHAT_ID AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                       N'[ نام سفیر ] : *' + ISNULL(sr.NAME, N'---') + N'*' + CHAR(10) + 
                       N'[ شماره تلفن ] : *' + ISNULL(sr.CELL_PHON, N'---') + N'*' + CHAR(10) 
                  FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s
                 WHERE o.CODE = @PeykOrdrCode
                   AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                   AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                   AND sr.SERV_FILE_NO = s.FILE_NO
            )
       FROM dbo.[Order] op
      WHERE op.ORDR_CODE = @OrdrCode
        AND op.ORDR_TYPE IN ('017' /* شغل حسابداری */, '018' /* شغل انبارداری */);
        
      -- ارسال پیام به واحد های حسابداری و انبارداری جهت آمدن پیک مورد نظر
      DECLARE C$SndMsg2PJob1 CURSOR FOR
	      SELECT o.CODE, o.ORDR_TYPE
	        FROM dbo.[Order] o
	       WHERE o.ORDR_CODE = @OrdrCode	         
	         AND o.ORDR_TYPE IN ('017' /* شغل حسابداری */, '018' /* شغل انبارداری */)
	   
	   OPEN [C$SndMsg2PJob1];
	   L$Loop_C$SndMsg2PJob1:
	   FETCH [C$SndMsg2PJob1] INTO @Code, @OrdrType;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop_C$SndMsg2PJob1;
	   
	   -- آمادگی ارسال مجدد به شغلها
	   UPDATE dbo.Personal_Robot_Job_Order
	      SET ORDR_STAT = '001'
	    WHERE ORDR_CODE = @Code;
      --SELECT  @XMessage = ( 
      --   SELECT @Code AS '@code' ,
      --          @Rbid AS '@roborbid' ,
      --          @OrdrType '@type'
      --     FROM dbo.Job j, dbo.Personal_Robot pr, dbo.Personal_Robot_Job prj
      --   WHERE j.ROBO_RBID = @Rbid
      --     AND j.ORDR_TYPE IN ('017' /* شغل حسابداری */, '018' /* شغل انبارداری */)
      --     AND pr.ROBO_RBID = @Rbid
      --     AND j.CODE = prj.JOB_CODE
      --     AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO
      --     AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID
      --  FOR XML PATH('Order'), ROOT('Process')
      --);
      --EXEC Send_Order_To_Personal_Robot_Job @XMessage;
      
      GOTO L$Loop_C$SndMsg2PJob1;
      L$EndLoop_C$SndMsg2PJob1:
      CLOSE [C$SndMsg2PJob1];
      DEALLOCATE [C$SndMsg2PJob1];
      
      SET @xRet = (
            SELECT 'successful' AS '@rsltdesc',
                   '002' AS '@rsltcode',
                   N'✅️ *درخواست توسط شما ثبت شده*' + CHAR(10) + CHAR(10) + 
                   --N'💡 کد خروجی : ' + N'*4*' + CHAR(10) +
                   N'👈 لطفا به *آدرس مبدا* برای *گرفتن بسته* اقدام فرمایید' + CHAR(10) +
                   N'بعد از گرفتن بسته از آدرس مبدا *کد تاییدیه زیر* را وارد کنید' + CHAR(10) + CHAR(10) +
                   N'👈 [ *بسته را تحویل گرفتید؟* ] ' + CHAR(10) + 
   	             N'* *%#' + CAST(@OrdrNumb AS NVARCHAR(20)) + N'*' + CHAR(10) +
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')              
         );      
   END -- @actncode = '002'
   ELSE IF @ActnCode = '004'
   BEGIN
      -- اگر سفیر قبلا این بسته را تاییدیه داده باشد
      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @PeykOrdrCode AND o.ORDR_STAT = '007' /* ردیافت بسته و جهت ارسال به مشتری */)
      BEGIN
         SET @xRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ *شما بسته را قبلا دریافت کرده اید*' + CHAR(10) + CHAR(10) + 
                   N'💡 کد خروجی : ' + N'*6*' + CHAR(10) +
                   N'👈 لطفا *بسته* را به *مقصد مشتری* ارسال کنید' + CHAR(10) +
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')              
         );
         
         -- پایان کار
         GOTO L$EndSP;
      END

      -- بررسی اینکه شماره درخواست پیک در مرحله قبل به درستی عبور کرده با خیر
      IF NOT EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @PeykOrdrCode AND o.ORDR_STAT = '006' /* درخواست در وضعیت {اعلام آمادگی پیک برای رساندن بسته} */)
      BEGIN
         SET @xRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ *ارسال بسته به شما تعلق ندارد*' + CHAR(10) + CHAR(10) + 
                   N'💡 کد خروجی : ' + N'*5*' + CHAR(10) +
                   N'👈 لطفا ابتدا درخواست آمادگی برای ارسال بسته را وارد کنید' + CHAR(10) + CHAR(10) + 
                   N'👈 [ ارسال درخواست اعلام آمادگی ] : * *%*' + CAST(@OrdrNumb AS NVARCHAR(20)) + N'*' + CHAR(10) +
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')              
         );
         
         -- پایان کار
         GOTO L$EndSP;
      END      
      
      -- تغییر وضعیت درخواست به حالت دریافت بسته و جهت ارسال به مشتری
      UPDATE dbo.[Order] 
         SET ORDR_STAT = '007'
       WHERE CODE = @PeykOrdrCode
         AND ORDR_STAT = '006';
      
      -- آماده سازی پیام برای دریافت بسته توسط سفیر به واحد حسابداری و انبارداری و مشتری
      INSERT INTO dbo.Order_Detail
      (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , ORDR_DESC )
      SELECT op.CODE, '001', N'تاییدیه سفیر بابت دریافت بسته',
             (
                SELECT N'📝 [ اطلاعات سفیر ]' + CHAR(10) +
                       N'[ شماره اشتراک ] : *' + CAST(o.CHAT_ID AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                       N'[ نام سفیر ] : *' + ISNULL(sr.NAME, N'---') + N'*' + CHAR(10) + 
                       N'[ شماره تلفن ] : *' + ISNULL(sr.CELL_PHON, N'---') + N'*' + CHAR(10) 
                  FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s
                 WHERE o.CODE = @PeykOrdrCode
                   AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                   AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                   AND sr.SERV_FILE_NO = s.FILE_NO
            )
       FROM dbo.[Order] op
      WHERE op.ORDR_CODE = @OrdrCode
        AND op.ORDR_TYPE IN ('017' /* شغل حسابداری */, '018' /* شغل انبارداری */);        
              
      -- ارسال پیام به واحد های حسابداری و انبارداری جهت آمدن پیک مورد نظر
      DECLARE C$SndMsg2PJob2 CURSOR FOR
	      SELECT o.CODE, o.ORDR_TYPE
	        FROM dbo.[Order] o
	       WHERE o.ORDR_CODE = @OrdrCode	         
	         AND o.ORDR_TYPE IN ('017' /* شغل حسابداری */, '018' /* شغل انبارداری */)
	   
	   OPEN [C$SndMsg2PJob2];
	   L$Loop_C$SndMsg2PJob2:
	   FETCH [C$SndMsg2PJob2] INTO @Code, @OrdrType;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop_C$SndMsg2PJob2;
	   
	   -- Ready for Send Agine
	   UPDATE dbo.Personal_Robot_Job_Order
	      SET ORDR_STAT = '001'
	    WHERE ORDR_CODE = @Code;
      --SELECT  @XMessage = ( 
      --   SELECT @Code AS '@code' ,
      --          @Rbid AS '@roborbid' ,
      --          @OrdrType '@type'
      --     FROM dbo.Job j, dbo.Personal_Robot pr, dbo.Personal_Robot_Job prj
      --   WHERE j.ROBO_RBID = @Rbid
      --     AND j.ORDR_TYPE IN ('017' /* شغل حسابداری */, '018' /* شغل انبارداری */)
      --     AND pr.ROBO_RBID = @Rbid
      --     AND j.CODE = prj.JOB_CODE
      --     AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO
      --     AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID
      --  FOR XML PATH('Order'), ROOT('Process')
      --);
      --EXEC Send_Order_To_Personal_Robot_Job @XMessage;
      
      GOTO L$Loop_C$SndMsg2PJob2;
      L$EndLoop_C$SndMsg2PJob2:
      CLOSE [C$SndMsg2PJob2];
      DEALLOCATE [C$SndMsg2PJob2];
      
      -- بروزرسانی آدرس مقصد برای سفیر
      UPDATE oa
         SET oa.HOW_SHIP = o.HOW_SHIP,
             oa.SERV_ADRS = o.SERV_ADRS,
             oa.CORD_X = o.CORD_X,
             oa.CORD_Y = o.CORD_Y,
             oa.CELL_PHON = o.CELL_PHON,
             oa.TELL_PHON = o.TELL_PHON             
        FROM dbo.[Order] o, dbo.[Order] oa
       WHERE o.CODE = @OrdrCode
         AND oa.CODE = @PeykOrdrCode;
      
      SELECT @MsgbText = (
             N'🏍 حرکت سفیر به سوی شما' + CHAR(10) + CHAR(10) + 
             (SELECT N'📝 [ اطلاعات سفیر ]' + CHAR(10) +
                    N'[ شماره اشتراک ] : *' + CAST(o.CHAT_ID AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                    N'[ نام سفیر ] : *' + ISNULL(sr.NAME, N'---') + N'*' + CHAR(10) + 
                    N'[ شماره تلفن ] : *' + ISNULL(sr.CELL_PHON, N'---') + N'*' + CHAR(10) + CHAR(10) +
                    
                    N'🏁 [ آدرس مقصد ] : ' + CHAR(10) +
                    REPLACE(N'*{0}*', '{0}', o.SERV_ADRS) + CHAR(10) +
                    N'📱 [ موبایل ] : *' + ISNULL(o.CELL_PHON, ' --- ') + N'*' + CHAR(10) + 
                    N'☎️ [ تلفن ] : *' + ISNULL(o.TELL_PHON, ' --- ') + N'*' + CHAR(10) + CHAR(10) + 
                    N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5))
               FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s
              WHERE o.CODE = @PeykOrdrCode
                AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                AND sr.SERV_FILE_NO = s.FILE_NO)
             ),
             @ServFileNo = op.Srbt_Serv_File_No
       FROM dbo.[Order] op
      WHERE op.CODE = @OrdrCode;
      
      EXEC iRoboTech.dbo.INS_SRRM_P @SRBT_SERV_FILE_NO = @ServFileNo, -- bigint
          @SRBT_ROBO_RBID = @Rbid, -- bigint
          @RWNO = 0, -- bigint
          @SRMG_RWNO = NULL, -- bigint
          @Ordt_Ordr_Code = NULL, -- bigint
          @Ordt_Rwno = NULL, -- bigint
          @MESG_TEXT = @MsgbText, -- nvarchar(max)
          @FILE_ID = NULL, -- varchar(200)
          @FILE_PATH = NULL, -- nvarchar(max)
          @MESG_TYPE = '001', -- varchar(3)
          @LAT = NULL, -- float
          @LON = NULL, -- float
          @CONT_CELL_PHON = NULL; -- varchar(11)	
      
      SET @xRet = (
            SELECT 'successful' AS '@rsltdesc',
                   '002' AS '@rsltcode',
                   N'✅️ *بسته توسط شما دریافت شد*' + CHAR(10) + CHAR(10) + 
                   --N'💡 کد خروجی : ' + N'*4*' + CHAR(10) +
                   N'👈 لطفا به *آدرس مقصد* برای *ارسال بسته* اقدام فرمایید' + CHAR(10) +
                   N'بعد از ارسال بسته به مقصد *کد تاییدیه زیر* را وارد کنید' + CHAR(10) + CHAR(10) +
                   N'👈 [ *بسته را تحویل دادید؟* ] ' + CHAR(10) + 
   	             N'* *%$' + CAST(@OrdrNumb AS NVARCHAR(20)) + N'*' + CHAR(10) +
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')              
         );      
   END -- if @actncode = '004'
   ELSE IF @ActnCode = '005'
   BEGIN
      -- اگر سفیر قبلا این بسته را تحویل داده باشد
      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @PeykOrdrCode AND o.ORDR_STAT = '008' /* سفیر بسته را به مشتری تحویل داده شده */)
      BEGIN
         SET @xRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ *شما بسته را قبلا تحویل داده اید*' + CHAR(10) + CHAR(10) + 
                   N'💡 کد خروجی : ' + N'*7*' + CHAR(10) +                   
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')              
         );
         
         -- پایان کار
         GOTO L$EndSP;
      END

      -- بررسی اینکه شماره درخواست پیک در مرحله قبل به درستی عبور کرده با خیر
      IF NOT EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @PeykOrdrCode AND o.ORDR_STAT = '007' /* درخواست در وضعیت {ارسال به سمت آدرس مشتری} */)
      BEGIN
         SET @xRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ *تایید تحویل بسته به شما تعلق ندارد*' + CHAR(10) + CHAR(10) + 
                   N'💡 کد خروجی : ' + N'*8*' + CHAR(10) +
                   N'👈 لطفا ابتدا درخواست ارسال بسته به سمت مشتری را وارد کنید' + CHAR(10) + CHAR(10) +
                   N'👈 [ ارسال بسته به سمت مقصد مشتری ] : * *%#' + CAST(@OrdrNumb AS NVARCHAR(20)) + N'*' + CHAR(10) +
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')
         );
         
         -- پایان کار
         GOTO L$EndSP;
      END      
      
      -- تغییر وضعیت درخواست به حالت دریافت بسته و جهت ارسال به مشتری
      UPDATE dbo.[Order] 
         SET ORDR_STAT = '008'
       WHERE CODE = @PeykOrdrCode
         AND ORDR_STAT = '007';
      
      -- آماده سازی پیام برای دریافت بسته توسط سفیر به واحد حسابداری و مشتری
      INSERT INTO dbo.Order_Detail
      (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , ORDR_DESC )
      SELECT o.CODE, '001', N'تاییدیه سفیر بابت ارسال بسته به مقصد نهایی',
             (
                SELECT N'📝 [ اطلاعات سفیر ]' + CHAR(10) +
                       N'[ شماره اشتراک ] : *' + CAST(@Chatid AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                       N'[ نام سفیر ] : *' + ISNULL(sr.NAME, N'---') + N'*' + CHAR(10) + 
                       N'[ شماره تلفن ] : *' + ISNULL(sr.CELL_PHON, N'---') + N'*' + CHAR(10) 
                  FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s
                 WHERE o.CODE = @PeykOrdrCode
                   AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                   AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                   AND sr.SERV_FILE_NO = s.FILE_NO
            )
       FROM dbo.[Order] o
      WHERE o.ORDR_CODE = @OrdrCode
        AND o.ORDR_TYPE IN ('017' /* شغل حسابداری */);        
              
      -- ارسال پیام به واحد های حسابداری و انبارداری جهت آمدن پیک مورد نظر
      DECLARE C$SndMsg2PJob3 CURSOR FOR
	      SELECT o.CODE, o.ORDR_TYPE
	        FROM dbo.[Order] o
	       WHERE o.ORDR_CODE = @OrdrCode	         
	         AND o.ORDR_TYPE IN ('017' /* شغل حسابداری */)
	   
	   OPEN [C$SndMsg2PJob3];
	   L$Loop_C$SndMsg2PJob3:
	   FETCH [C$SndMsg2PJob3] INTO @Code, @OrdrType;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop_C$SndMsg2PJob3;
	   
	   -- Ready for Send Agine
	   UPDATE dbo.Personal_Robot_Job_Order
	      SET ORDR_STAT = '001'
	    WHERE ORDR_CODE = @Code;
      --SELECT  @XMessage = ( 
      --   SELECT @Code AS '@code' ,
      --          @Rbid AS '@roborbid' ,
      --          @OrdrType '@type'
      --     FROM dbo.Job j, dbo.Personal_Robot pr, dbo.Personal_Robot_Job prj
      --   WHERE j.ROBO_RBID = @Rbid
      --     AND j.ORDR_TYPE IN ('017' /* شغل حسابداری */)
      --     AND pr.ROBO_RBID = @Rbid
      --     AND j.CODE = prj.JOB_CODE
      --     AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO
      --     AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID
      --  FOR XML PATH('Order'), ROOT('Process')
      --);
      --EXEC Send_Order_To_Personal_Robot_Job @XMessage;
      
      GOTO L$Loop_C$SndMsg2PJob3;
      L$EndLoop_C$SndMsg2PJob3:
      CLOSE [C$SndMsg2PJob3];
      DEALLOCATE [C$SndMsg2PJob3];
      
      SELECT @MsgbText = (
             N'🏍 *سفیر بسته شما را به مقصد رساند*' + CHAR(10) + CHAR(10) + 
             (SELECT N'📝 [ اطلاعات سفیر ]' + CHAR(10) +
                    N'[ شماره اشتراک ] : *' + CAST(o.CHAT_ID AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                    N'[ نام سفیر ] : *' + ISNULL(sr.NAME, N'---') + N'*' + CHAR(10) + 
                    N'[ شماره تلفن ] : *' + ISNULL(sr.CELL_PHON, N'---') + N'*' + CHAR(10) + CHAR(10) +
                    
                    N'🏁 [ آدرس مقصد ] : ' + CHAR(10) +
                    REPLACE(N'*{0}*', '{0}', o.SERV_ADRS) + CHAR(10) +
                    N'📱 [ موبایل ] : *' + ISNULL(o.CELL_PHON, ' --- ') + N'*' + CHAR(10) + 
                    N'☎️ [ تلفن ] : *' + ISNULL(o.TELL_PHON, ' --- ') + N'*' + CHAR(10) + CHAR(10) + 
                    
                    N'👈 لطفا جهت پایان فرایند ثبت سفارش آنلاین *کد تاییدیده زیر* را وارد کنید' + CHAR(10) + 
                    N'* *%@' + CAST(@OrdrNumb AS NVARCHAR(20)) + N'*' + CHAR(10) + CHAR(10) + 
                    
                    N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5))
               FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s
              WHERE o.CODE = @PeykOrdrCode
                AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                AND sr.SERV_FILE_NO = s.FILE_NO)
             ),
             @ServFileNo = op.Srbt_Serv_File_No
       FROM dbo.[Order] op
      WHERE op.CODE = @OrdrCode;
      
      EXEC iRoboTech.dbo.INS_SRRM_P @SRBT_SERV_FILE_NO = @ServFileNo, -- bigint
          @SRBT_ROBO_RBID = @Rbid, -- bigint
          @RWNO = 0, -- bigint
          @SRMG_RWNO = NULL, -- bigint
          @Ordt_Ordr_Code = NULL, -- bigint
          @Ordt_Rwno = NULL, -- bigint
          @MESG_TEXT = @MsgbText, -- nvarchar(max)
          @FILE_ID = NULL, -- varchar(200)
          @FILE_PATH = NULL, -- nvarchar(max)
          @MESG_TYPE = '001', -- varchar(3)
          @LAT = NULL, -- float
          @LON = NULL, -- float
          @CONT_CELL_PHON = NULL; -- varchar(11)	
      
      SET @xRet = (
            SELECT 'successful' AS '@rsltdesc',
                   '002' AS '@rsltcode',
                   N'✅️ *بسته توسط شما به مقصد ارسال شد*' + CHAR(10) + CHAR(10) + 
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')              
         ); 
   END -- if @actncode = '005'
   ELSE IF @ActnCode = '006'
   BEGIN
      -- اگر مشتری قبلا درخواست پیک خود را تایید کرده باشد که بسته به دستش رسیده
      IF EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @PeykOrdrCode AND o.ORDR_STAT = '009' /* مشتری تحویل بسته را تایید کرده */)
      BEGIN
         SET @xRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ *شما بسته را قبلا تحویل گرفته اید*' + CHAR(10) + CHAR(10) + 
                   N'💡 کد خروجی : ' + N'*9*' + CHAR(10) +                   
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')              
         );
         
         -- پایان کار
         GOTO L$EndSP;
      END

      -- بررسی اینکه شماره درخواست پیک در مرحله قبل به درستی عبور کرده با خیر
      IF NOT EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @PeykOrdrCode AND o.ORDR_STAT = '008' /* درخواست در وضعیت {تایید دریافت توسط مشتری} */)
      BEGIN
         SET @xRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ *تایید دریافت بسته به شما تعلق ندارد*' + CHAR(10) + CHAR(10) + 
                   N'💡 کد خروجی : ' + N'*10*' + CHAR(10) +
                   N'👈 لطفا ابتدا درخواست دریافت بسته به مشتری را وارد کنید' + CHAR(10) + CHAR(10) +
                   N'👈 [ دریافت بسته به مقصد مشتری ] : * *%$' + CAST(@OrdrNumb AS NVARCHAR(20)) + N'*' + CHAR(10) +
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')
         );
         
         -- پایان کار
         GOTO L$EndSP;
      END
      
      IF NOT EXISTS(SELECT * FROM dbo.[Order] o WHERE o.CODE = @OrdrCode AND o.CHAT_ID = @Chatid)
      BEGIN
         SET @xRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ *تایید نهایی بسته به شما تعلق ندارد*' + CHAR(10) + CHAR(10) + 
                   N'💡 کد خروجی : ' + N'*11*' + CHAR(10) +
                   N'👈 لطفا از مشتری درخواست کنید که کد تاییدیه را وارد کند' + CHAR(10) + CHAR(10) +
                   N'👈 [ تاییدیه نهایی توسط مشتری ] : * *%@' + CAST(@OrdrNumb AS NVARCHAR(20)) + N'*' + CHAR(10) +
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')
         );
         
         -- پایان کار
         GOTO L$EndSP;
      END 
      
      -- تغییر وضعیت درخواست به حالت دریافت بسته و جهت ارسال به مشتری
      UPDATE dbo.[Order] 
         SET ORDR_STAT = '009'
            ,END_DATE = GETDATE()
       WHERE CODE = @PeykOrdrCode
         AND ORDR_STAT = '008';
      
      -- آماده سازی پیام برای دریافت بسته توسط سفیر به واحد حسابداری و مشتری
      INSERT INTO dbo.Order_Detail
      (ORDR_CODE ,ELMN_TYPE ,ORDR_CMNT , ORDR_DESC )
      SELECT op.CODE, '001', N'تاییدیه مشتری بابت دریافت بسته',
             (
                SELECT N'📝 [ اطلاعات سفیر ]' + CHAR(10) +
                       N'[ شماره اشتراک ] : *' + CAST(o.CHAT_ID AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                       N'[ نام سفیر ] : *' + ISNULL(sr.NAME, N'---') + N'*' + CHAR(10) + 
                       N'[ شماره تلفن ] : *' + ISNULL(sr.CELL_PHON, N'---') + N'*' + CHAR(10) 
                  FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s
                 WHERE o.CODE = @PeykOrdrCode
                   AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                   AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                   AND sr.SERV_FILE_NO = s.FILE_NO
            )
       FROM dbo.[Order] op
      WHERE op.ORDR_CODE = @OrdrCode
        AND op.ORDR_TYPE IN ('017' /* شغل حسابداری */)
      UNION
      SELECT op.CODE, '001', N'تاییدیه مشتری بابت دریافت بسته',
             (
                SELECT N'📝 [ اطلاعات بسته ]' + CHAR(10) +
                       N'[ شماره سفارش ] : *' + CAST(@OrdrNumb AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                       N'[ تاریخ و زمان دریافت ] : *' + iRoboTech.dbo.GET_MTOS_U(o.STRT_DATE) + N' ' + CAST(CAST(o.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10) +
                       N'[ تاریخ و زمان ارسال ] : *' + iRoboTech.dbo.GET_MTOS_U(o.END_DATE) + N' ' + CAST(CAST(o.END_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10)
                  FROM dbo.[Order] o, dbo.Service_Robot sr, dbo.Service s
                 WHERE o.CODE = @PeykOrdrCode
                   AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                   AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                   AND sr.SERV_FILE_NO = s.FILE_NO
            )
       FROM dbo.[Order] op
      WHERE op.ORDR_CODE = @OrdrCode
        AND op.ORDR_TYPE IN ('019' /* شغل پیک موتوری */);
              
      -- ارسال پیام به واحد های حسابداری و انبارداری جهت آمدن پیک مورد نظر
      DECLARE C$SndMsg2PJob4 CURSOR FOR
	      SELECT o.CODE, o.ORDR_TYPE
	        FROM dbo.[Order] o
	       WHERE o.ORDR_CODE = @OrdrCode	         
	         AND o.ORDR_TYPE IN ('017' /* شغل حسابداری */, '019' /* شغل پیک موتوری */)
	   
	   OPEN [C$SndMsg2PJob4];
	   L$Loop_C$SndMsg2PJob4:
	   FETCH [C$SndMsg2PJob4] INTO @Code, @OrdrType;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop_C$SndMsg2PJob4;
	   
	   -- Ready for Send Agine
	   UPDATE dbo.Personal_Robot_Job_Order
	      SET ORDR_STAT = '001'
	    WHERE ORDR_CODE = @Code;
      --SELECT  @XMessage = ( 
      --   SELECT @Code AS '@code' ,
      --          @Rbid AS '@roborbid' ,
      --          @OrdrType '@type'
      --     FROM dbo.Job j, dbo.Personal_Robot pr, dbo.Personal_Robot_Job prj
      --   WHERE j.ROBO_RBID = @Rbid
      --     AND j.ORDR_TYPE IN ('017' /* شغل حسابداری */, '019' /* شغل پیک موتوری */)
      --     AND pr.ROBO_RBID = @Rbid
      --     AND j.CODE = prj.JOB_CODE
      --     AND pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO
      --     AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID
      --  FOR XML PATH('Order'), ROOT('Process')
      --);
      --EXEC Send_Order_To_Personal_Robot_Job @XMessage;
      
      GOTO L$Loop_C$SndMsg2PJob4;
      L$EndLoop_C$SndMsg2PJob4:
      CLOSE [C$SndMsg2PJob4];
      DEALLOCATE [C$SndMsg2PJob4];
      
      SET @xRet = (
            SELECT 'successful' AS '@rsltdesc',
                   '002' AS '@rsltcode',
                   N'✅️ *بسته توسط شما تحویل گرفته شد*' + CHAR(10) + CHAR(10) + 
                   N'🏍 *پایان سفر*' + CHAR(10) + CHAR(10) + 
                   N'👈 [ کد سفارش ] : *' + CAST(@OrdrNumb AS NVARCHAR(20)) + N'*' + CHAR(10) + CHAR(10) + 
                   N'🙏 با تشکر از شما'
              FOR XML PATH('Message'), ROOT('Result')              
         );
   END
   L$EndSP:
   COMMIT TRAN [T$SAVE_ALPK_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX);
	   SET @ErorMesg = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1 );
      ROLLBACK TRAN [T$SAVE_ALPK_P];
	END CATCH
END
GO
