SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Baharnekou_Analisis_Message_P]
	@X XML,
	@XResult XML OUT
AS
BEGIN
   DECLARE @UssdCode VARCHAR(250),
           @ChildUssdCode VARCHAR(250),    
           @MenuText NVARCHAR(MAX),
           @Message NVARCHAR(MAX),
		     @XMessage XML,
		     @XTemp XML,
           @ChatID BIGINT,
           @CordX  FLOAT,
           @CordY  FLOAT,
           @PhotoFileId VARCHAR(MAX),
           @VideoFileId VARCHAR(MAX),
           @DocumentFileId VARCHAR(MAX),
           @ElmnType VARCHAR(3),
           @Item NVARCHAR(1000),
           @NameService NVARCHAR(100),
           @CellPhon VARCHAR(13),
           @ServAddres NVARCHAR(1000),
           @Index BIGINT = 0;
;

	
	SELECT @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]', 'VARCHAR(250)'),
	       @ChildUssdCode = @X.query('//Message').value('(Message/@childussd)[1]', 'VARCHAR(250)'),    
	       @ChatID   = @X.query('//Message').value('(Message/@chatid)[1]', 'BIGINT'),	       
	       @ElmnType   = @X.query('//Message').value('(Message/@elmntype)[1]', 'VARCHAR(3)'),	       
	       @MenuText = @X.query('//Text').value('.', 'NVARCHAR(MAX)'),
	       @CordX    = @X.query('//Location').value('(Location/@latitude)[1]', 'FLOAT'),
	       @CordY    = @X.query('//Location').value('(Location/@longitude)[1]', 'FLOAT'),
	       @PhotoFileId   = @X.query('//Photo').value('(Photo/@fileid)[1]', 'NVARCHAR(MAX)'),
	       @VideoFileId   = @X.query('//Video').value('(Video/@fileid)[1]', 'NVARCHAR(MAX)'),
	       @DocumentFileId   = @X.query('//Document').value('(Document/@fileid)[1]', 'NVARCHAR(MAX)');
	
   insert into logs (x) values (@x); 

   IF @UssdCode = '*1*2*1#'
	BEGIN
	   SELECT @Message = (
	      SELECT o.NAME + ' ' + r.NAME + CHAR(10)
	        FROM Organ o, Robot r
	       WHERE o.OGID = r.ORGN_OGID
	         AND ( o.NAME LIKE N'%'+ @MenuText +N'%'
	            OR o.ORGN_DESC LIKE N'%'+ @MenuText +N'%'
	            OR r.NAME LIKE N'%'+ @MenuText +N'%'
	            OR o.KEY_WORD LIKE N'%'+ @MenuText +N'%'
	         )
	         AND o.STAT = '002'
	         AND r.STAT = '002'
	       ORDER BY o.OGID, r.RBID
	         FOR XML PATH('')
	   );
	END
	ELSE IF @UssdCode = '*1*1*1#' -- ثبت شماره تلفن اشتراک
	BEGIN
	   IF NOT EXISTS(
		SELECT *
		  FROM Service_Robot
		 WHERE CHAT_ID = @ChatID
	       AND ROBO_RBID = 11
		   AND ISNULL(Cell_Phon, @MenuText) = @MenuText
	   )
	   BEGIN
		 INSERT INTO Service_Robot_Public (Srbt_Serv_File_No, Srbt_Robo_Rbid, Rwno, Cell_Phon, Chat_Id)
		 SELECT Serv_File_No, Robo_Rbid, 0, @MenuText, @Chatid
		   FROM Service_Robot
		  WHERE Chat_Id = @ChatId
		 	AND Robo_Rbid = 11;
	   END
	   ELSE
	   BEGIN
		   UPDATE Service_Robot_Public
			  SET CELL_PHON = @MenuText
			WHERE CHAT_ID = @ChatID
			  AND SRBT_ROBO_RBID = 11
			  AND RWNO = (
				Select MAX(Rwno) 
				  FROM Service_Robot_Public T 
				 WHERE T.SRBT_SERV_FILE_NO = SRBT_SERV_FILE_NO
				   AND T.SRBT_ROBO_RBID = SRBT_ROBO_RBID
				   AND T.CHAT_ID = @ChatId
			  );
		END
		  	
	   SELECT @Message = 
	      (N'اطلاعات شماره تلفن شما برای فعال سازی ثبت گردید.');
	END
	ELSE IF @UssdCode = '*1*1*2#' -- ثبت موقعیت جغرافیایی اشتراک
	BEGIN
		IF NOT (@CordX = 0 AND @CordY = 0)
		BEGIN
			UPDATE Service_Robot_Public
			   SET CORD_X = @CordX
				  ,CORD_Y = @CordY
			WHERE CHAT_ID = @ChatID
			  AND SRBT_ROBO_RBID = 11
			  AND RWNO = (
				Select MAX(Rwno) 
				  FROM Service_Robot_Public T 
				 WHERE T.SRBT_SERV_FILE_NO = SRBT_SERV_FILE_NO
				   AND T.SRBT_ROBO_RBID = SRBT_ROBO_RBID
				   AND T.CHAT_ID = @ChatId
			  );

		   SELECT @Message = 
			  (N'اطلاعات مختصات جغرافیایی شما در سیستم ثبت گردید');
		END
		ELSE
			SELECT @Message = 
			  (N'لطفا اطلاعات مختصات جغرافیایی خود را درست وارد نمایید. برای ارسال باید از گزینه الحاق و بعد گزینه ارسال مکان استفاده کنید');
	END
	ELSE IF @UssdCode = '*1*1#'
	BEGIN
		IF @ChildUssdCode = '*1*1*3#'
		BEGIN			
			SELECT @XTemp = (
				-- Last Location
				SELECT [order] AS '@order'
					  ,CONVERT(varchar(30), Cord_X, 128) As '@cordx'
					  ,CONVERT(varchar(30), Cord_Y, 128) AS '@cordy'
					  ,CellPhon AS '@cellphon'
				  FROM (
				 SELECT 1 AS [order]
				       ,Cord_X 
					   ,Cord_Y 
					   ,N' شماره تلفن ' + Cell_Phon + N' با آدرس بالا ثبت شده است.' AS CellPhon
				   FROM Service_Robot 
				  WHERE Chat_ID = @ChatId 
				    AND Robo_Rbid = 11 
					AND SRPB_RWNO IS NOT NULL) A
				    FOR XML PATH('Location'), ROOT('Locations')
			);
			SET @XTemp.modify('insert attribute order {"2"} into (//Locations)[1]');

			SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
		END
	END
	ELSE IF @UssdCode = '*1*1*3#'
	BEGIN
		IF @ChildUssdCode = '*1*1*3*1#'
		BEGIN
			SELECT @XTemp = (
				-- Last Location
				 SELECT Rwno AS '@order'
				       ,CONVERT(varchar(30), Cord_X, 128) AS '@cordx'
					   ,CONVERT(varchar(30), Cord_Y, 128) AS '@cordy'
					   ,N' شماره تلفن ' + Cell_Phon + N' با آدرس بالا ثبت شده است.' AS '@cellphon'
				   FROM Service_Robot_Public A
				  WHERE Chat_ID = @ChatId 
				    AND A.Srbt_Robo_Rbid = 11 
					AND Cord_X is not null
					And Cord_Y is not null
				    FOR XML PATH('Location'), ROOT('Locations')
			);
			SET @XTemp.modify('insert attribute order {"2"} into (//Locations)[1]');

			SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
		END
	END
	ELSE IF @UssdCode IN ( '*0*3#' ) -- اطلاعات مربوط به ثبت نظرسنجی
	BEGIN
	   IF 1!=1 AND EXISTS (
	      SELECT * 
	        FROM dbo.Service_Robot
	       WHERE CHAT_ID = @ChatId
	         AND ROBO_RBID = 24
	         AND SRPB_RWNO IS NULL
	   )
	   BEGIN
	      SET @Message = N'کاربر گرامی برای شما کد اشتراک ثبت نشده. لطفا برای ثبت هر گونه اطلاعات در سیستم ابتدا کد اشتراک خود را فعال کنید';
	   END
	   ELSE
	   BEGIN
		  IF EXISTS(
			SELECT *
			  FROM [Order] o, Order_Detail od, Service_Robot Sr
			WHERE O.SRBT_SERV_FILE_NO = Sr.Serv_File_No
	        AND O.SRBT_ROBO_RBID = Sr.Robo_Rbid
			  AND o.Code = Od.Ordr_Code
			  AND O.Ordr_Type = '002'
			  AND Sr.Chat_ID = @ChatId
			  AND Sr.Robo_Rbid = 24
			  AND Od.Elmn_Type = '001'
			  --AND Od.Ordr_Desc = @MenuText
			  AND Od.BASE_USSD_CODE = @UssdCode
		  )
		  BEGIN
			SET @Message = N'🙂 کاربر گرامی شما قبلا برای این فرد در نظر سنجی شرکت کرده اید';
			GOTO L$EndSP;
		  END
		  
		  IF NOT EXISTS(
		     SELECT *
			    FROM [Order] o, Service_Robot Sr
			   WHERE O.SRBT_SERV_FILE_NO = Sr.Serv_File_No
	           AND O.SRBT_ROBO_RBID = Sr.Robo_Rbid
			     AND O.Ordr_Type = '006' -- سوال
			     AND Sr.Chat_ID = @ChatId
			     AND Sr.Robo_Rbid = 24		   
		  )
		  BEGIN
		   SET @Message = N'🙂 کاربر گرامی برای ثبت نظرسنجی بایستی حداقل یک سوال پرسیده شده باشد که از جانب مشاورین پاسخ داده شده تا بتوانید به جواب آنها در نظر سنجی شرکت کنید';
			GOTO L$EndSP;
		  END
		  
		  IF EXISTS(
		      SELECT *
			     FROM [Order] o, Service_Robot Sr
			   WHERE O.SRBT_SERV_FILE_NO = Sr.Serv_File_No
	           AND O.SRBT_ROBO_RBID = Sr.Robo_Rbid
			     AND O.Ordr_Type = '006' -- سوال
			     AND Sr.Chat_ID = @ChatId
			     AND Sr.Robo_Rbid = 24
			     AND NOT EXISTS(
			        SELECT *
			          FROM [Order] oi
			         WHERE oi.Ordr_Type = '007' -- پاسخ سوال
			           AND oi.Chat_ID = @ChatId
			           AND oi.SRBT_ROBO_RBID = 24
			           AND Oi.ORDR_CODE = o.Code
			     )
		  )
		  BEGIN
			SET @Message = N'🙂 کاربر گرامی برای ثبت نظرسنجی بایستی از جانب مشاورین پاسخ ارسال شود تا بتوانید به جواب آنها در نظر سنجی شرکت کنید';
			GOTO L$EndSP;
		  END

	      INSERT INTO dbo.[Order]
	              ( SRBT_SERV_FILE_NO ,
	                SRBT_ROBO_RBID ,
	                SRBT_SRPB_RWNO ,
	                ORDR_TYPE ,
	                STRT_DATE ,
	                ORDR_STAT
	              )
	       SELECT SERV_FILE_NO,
	              24,
	              SRPB_RWNO,
	              '002',
	              GETDATE(),
	              '001' -- ثبت مرحله اولیه
	         FROM dbo.Service_Robot
	        WHERE CHAT_ID = @chatid
	          AND ROBO_RBID = 24;
	      
	      DECLARE @OrdrCode BIGINT
	             ,@OrdrType VARCHAR(3);
	      
	      SELECT @OrdrCode = MAX(CODE),
	             @OrdrType = ORDR_TYPE
	        FROM dbo.[Order] o, dbo.Service_Robot sr
	       WHERE o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	         AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
	         AND sr.CHAT_ID = @ChatId
	         AND Sr.ROBO_RBID = 24
	         AND o.ORDR_TYPE = '002'
	         GROUP BY ORDR_TYPE;
	      
	      INSERT dbo.Order_Detail
	              ( ORDR_CODE ,
	                ELMN_TYPE ,
	                ORDR_DESC ,
	                NUMB, 
	                BASE_USSD_CODE,
	                SUB_USSD_CODE
	              )
	      VALUES  ( @OrdrCode , -- ORDR_CODE - bigint
	                @ElmnType , -- ELMN_TYPE - varchar(3)
	                CASE @ElmnType 
	                  WHEN '001' THEN @MenuText
	                  WHEN '005' THEN CONVERT(VARCHAR(max), @CordX, 128) + ',' + CONVERT(VARCHAR(max), @CordY, 128)
	                  WHEN '002' THEN @PhotoFileId
	                  WHEN '003' THEN @VideoFileId
	                  WHEN '004' THEN @DocumentFileId
	                END, -- ORDR_DESC - nvarchar(max)
	                0,  -- NUMB - int
	                @UssdCode,
	                @ChildUssdCode
	              );
	      SELECT @XMessage = 
	      (
	         SELECT @OrdrCode AS '@code'
	               ,24 AS '@roborbid'
	               ,@OrdrType '@type'
	         FOR XML PATH('Order'), ROOT('Process')
	      )
	      EXEC Send_Order_To_Personal_Robot_Job @XMessage;
	      SET @Message = N'😊👌 کاربر گرامی اطلاعات شما در سیستم با موفقیت ثبت شد';
	    END;
	   
	END
	ELSE IF @UssdCode = '*5*2#' -- ثبت انتقادات و پیشنهادات
	BEGIN
		BEGIN
		  IF (UPPER(@MenuText) IN ( '/START' ) OR LEN(@MenuText) <= 10 ) AND @MenuText != N'بازگشت 🔺'
		  BEGIN
		     SET @Message = N'کاربر گرامی متن ورودی شما مجاز به ثبت نیست. برای ثبت اطلاعات باید حداقل بیش از 10 کاراکتر باشد';
			  GOTO L$EndSP;
		  END
		  
		  IF @MenuText = N'بازگشت 🔺'
		  BEGIN
		     SET @Message = N'بازگشت 🔺';
			  GOTO L$EndSP;
		  END

	      INSERT INTO dbo.[Order]
	              ( SRBT_SERV_FILE_NO ,
	                SRBT_ROBO_RBID ,
	                SRBT_SRPB_RWNO ,
	                ORDR_TYPE ,
	                STRT_DATE ,
	                ORDR_STAT,
	                CHAT_ID
	              )
	       SELECT SERV_FILE_NO,
	              24,
	              SRPB_RWNO,
	              '001',
	              GETDATE(),
	              '001', -- ثبت مرحله اولیه
	              @ChatId
	         FROM dbo.Service_Robot
	        WHERE CHAT_ID = @chatid
	          AND ROBO_RBID = 24;
	      
	      /*DECLARE @OrdrCode BIGINT
	             ,@OrdrType VARCHAR(3);*/
	      
	      SELECT @OrdrCode = MAX(CODE),
	             @OrdrType = ORDR_TYPE
	        FROM dbo.[Order] o, dbo.Service_Robot sr
	       WHERE o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	         AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
	         AND sr.CHAT_ID = @ChatId
	         AND Sr.ROBO_RBID = 24
	         AND o.ORDR_TYPE = '001'
	         GROUP BY ORDR_TYPE;
	      
	      INSERT dbo.Order_Detail
	              ( ORDR_CODE ,
	                ELMN_TYPE ,
	                ORDR_DESC ,
	                NUMB, 
	                BASE_USSD_CODE,
	                SUB_USSD_CODE
	              )
	      VALUES  ( @OrdrCode , -- ORDR_CODE - bigint
	                @ElmnType , -- ELMN_TYPE - varchar(3)
	                CASE @ElmnType 
	                  WHEN '001' THEN @MenuText
	                  WHEN '005' THEN CONVERT(VARCHAR(max), @CordX, 128) + ',' + CONVERT(VARCHAR(max), @CordY, 128)
	                  WHEN '002' THEN @PhotoFileId
	                  WHEN '003' THEN @VideoFileId
	                  WHEN '004' THEN @DocumentFileId
	                END, -- ORDR_DESC - nvarchar(max)
	                0,  -- NUMB - int
	                @UssdCode,
	                @ChildUssdCode
	              );
	      SELECT @XMessage = 
	      (
	         SELECT @OrdrCode AS '@code'
	               ,24 AS '@roborbid'
	               ,@OrdrType '@type'
	         FOR XML PATH('Order'), ROOT('Process')
	      )
	      EXEC Send_Order_To_Personal_Robot_Job @XMessage;
	      SET @Message = N'📥از اینکه نکات سازنده ای در اختیار ما گذاشتین ممنونم.';
	    END;
	END
	ELSE IF @UssdCode = '*5*3#' -- ثبت تجربیات شخصی
	BEGIN
		BEGIN
		  IF (UPPER(@MenuText) IN ( '/START' ) OR LEN(@MenuText) <= 10 ) AND @MenuText != N'بازگشت 🔺'
		  BEGIN
		     SET @Message = N'کاربر گرامی متن ورودی شما مجاز به ثبت نیست. برای ثبت اطلاعات باید حداقل بیش از 10 کاراکتر باشد';
			  GOTO L$EndSP;
		  END
		  
		  IF @MenuText = N'بازگشت 🔺'
		  BEGIN
		     SET @Message = N'بازگشت 🔺';
			  GOTO L$EndSP;
		  END

	      INSERT INTO dbo.[Order]
	              ( SRBT_SERV_FILE_NO ,
	                SRBT_ROBO_RBID ,
	                SRBT_SRPB_RWNO ,
	                ORDR_TYPE ,
	                STRT_DATE ,
	                ORDR_STAT,
	                CHAT_ID
	              )
	       SELECT SERV_FILE_NO,
	              24,
	              SRPB_RWNO,
	              '008',
	              GETDATE(),
	              '001', -- ثبت مرحله اولیه
	              @ChatId
	         FROM dbo.Service_Robot
	        WHERE CHAT_ID = @chatid
	          AND ROBO_RBID = 24;
	      
	      /*DECLARE @OrdrCode BIGINT
	             ,@OrdrType VARCHAR(3);*/
	      
	      SELECT @OrdrCode = MAX(CODE),
	             @OrdrType = ORDR_TYPE
	        FROM dbo.[Order] o, dbo.Service_Robot sr
	       WHERE o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	         AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
	         AND sr.CHAT_ID = @ChatId
	         AND Sr.ROBO_RBID = 24
	         AND o.ORDR_TYPE = '008'
	         GROUP BY ORDR_TYPE;
	      
	      INSERT dbo.Order_Detail
	              ( ORDR_CODE ,
	                ELMN_TYPE ,
	                ORDR_DESC ,
	                NUMB, 
	                BASE_USSD_CODE,
	                SUB_USSD_CODE
	              )
	      VALUES  ( @OrdrCode , -- ORDR_CODE - bigint
	                @ElmnType , -- ELMN_TYPE - varchar(3)
	                CASE @ElmnType 
	                  WHEN '001' THEN @MenuText
	                  WHEN '005' THEN CONVERT(VARCHAR(max), @CordX, 128) + ',' + CONVERT(VARCHAR(max), @CordY, 128)
	                  WHEN '002' THEN @PhotoFileId
	                  WHEN '003' THEN @VideoFileId
	                  WHEN '004' THEN @DocumentFileId
	                END, -- ORDR_DESC - nvarchar(max)
	                0,  -- NUMB - int
	                @UssdCode,
	                @ChildUssdCode
	              );
	      SELECT @XMessage = 
	      (
	         SELECT @OrdrCode AS '@code'
	               ,24 AS '@roborbid'
	               ,@OrdrType '@type'
	         FOR XML PATH('Order'), ROOT('Process')
	      )
	      EXEC Send_Order_To_Personal_Robot_Job @XMessage;
	      SET @Message = N'📥از اینکه ما رو برای به اشتراک گذاری تجربیات خود قابل دونستین ممنونم.';
	    END;
	END
	ELSE IF @UssdCode = '*0*1#' -- ثبت پرسش مشتریان
	BEGIN
		BEGIN
		  -- بررسی اینکه شماره تلفن خود را وارد کرده است یا خیر
  		  IF EXISTS(
		    SELECT *
		      FROM dbo.Service_Robot
		     WHERE ROBO_RBID = 24
		       AND CHAT_ID = @ChatID
		       AND (CELL_PHON IS NULL 
		         OR LEN(CELL_PHON) != 12
		       )
		  )
		  BEGIN
		      SET @Message = N'🙂 کاربر گرامی 📞شماره تلفن همراه شما ثبت نگردیده، برای ثبت سوال خود باید شماره همراه خود را در قسمت ⁉️ پرسش و پاسخ گزینه 👤 درخواست کد اشتراک و منوی 📞 ارسال شماره من را فشار دهید';
			   GOTO L$EndSP;
		  End

		  IF (UPPER(@MenuText) IN ( '/START' ) OR LEN(@MenuText) <= 10 ) AND @MenuText != N'بازگشت 🔺'
		  BEGIN
		     SET @Message = N'کاربر گرامی سوال شما مجاز به ثبت نیست. برای ثبت سوال باید حداقل بیش از 10 کاراکتر باشد';
			  GOTO L$EndSP;
		  END
		  
		  IF @MenuText = N'بازگشت 🔺'
		  BEGIN
		     SET @Message = N'بازگشت 🔺';
			  GOTO L$EndSP;
		  END
		  
		  
		  /*IF EXISTS(
			SELECT *
			  FROM [Order] o, Order_Detail od, Service_Robot Sr
			WHERE O.SRBT_SERV_FILE_NO = Sr.Serv_File_No
	          AND O.SRBT_ROBO_RBID = Sr.Robo_Rbid
			  AND o.Code = Od.Ordr_Code
			  AND O.Ordr_Type = '006'
			  AND O.ORDR_STAT = '001'
			  AND Sr.Chat_ID = @ChatId
			  AND Sr.Robo_Rbid = 24
			  AND Od.Elmn_Type = '001'
			  --AND Od.Ordr_Desc = @MenuText
			  AND Od.BASE_USSD_CODE = @UssdCode
		  ) 
		  BEGIN
			  SET @Message = N'🙂 کاربر گرامی برای شما قبلا یک سوال بی پاسخ ثبت شده برای ثبت سوال جدید خود باید منتظر جواب سوال قبلی باشید';
			  GOTO L$EndSP;
		  END*/
		  
		  IF EXISTS(
		      SELECT *
		        FROM dbo.[Order]
		       WHERE CHAT_ID = @ChatID
		         AND SRBT_ROBO_RBID = 24
		         AND ORDR_TYPE = '006'
		         AND ORDR_STAT = '001'
		  )
		  BEGIN
			  SET @Message = N'🙂 کاربر گرامی برای شما قبلا یک سوال بی پاسخ ثبت شده برای ثبت سوال جدید خود باید منتظر جواب سوال قبلی باشید';
			  GOTO L$EndSP;
		  END

	      INSERT INTO dbo.[Order]
	              ( SRBT_SERV_FILE_NO ,
	                SRBT_ROBO_RBID ,
	                SRBT_SRPB_RWNO ,
	                ORDR_TYPE ,
	                STRT_DATE ,
	                ORDR_STAT,
	                CHAT_ID
	              )
	       SELECT SERV_FILE_NO,
	              24,
	              SRPB_RWNO,
	              '006',
	              GETDATE(),
	              '001', -- ثبت مرحله اولیه
	              @ChatId
	         FROM dbo.Service_Robot
	        WHERE CHAT_ID = @chatid
	          AND ROBO_RBID = 24;
	      
	      /*DECLARE @OrdrCode BIGINT
	             ,@OrdrType VARCHAR(3);*/
	      
	      SELECT @OrdrCode = MAX(CODE),
	             @OrdrType = ORDR_TYPE
	        FROM dbo.[Order] o, dbo.Service_Robot sr
	       WHERE o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	         AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
	         AND sr.CHAT_ID = @ChatId
	         AND Sr.ROBO_RBID = 24
	         AND o.ORDR_TYPE = '006'
	         GROUP BY ORDR_TYPE;
	      
	      INSERT dbo.Order_Detail
	              ( ORDR_CODE ,
	                ELMN_TYPE ,
	                ORDR_DESC ,
	                NUMB, 
	                BASE_USSD_CODE,
	                SUB_USSD_CODE
	              )
	      VALUES  ( @OrdrCode , -- ORDR_CODE - bigint
	                @ElmnType , -- ELMN_TYPE - varchar(3)
	                CASE @ElmnType 
	                  WHEN '001' THEN @MenuText
	                  WHEN '005' THEN CONVERT(VARCHAR(max), @CordX, 128) + ',' + CONVERT(VARCHAR(max), @CordY, 128)
	                  WHEN '002' THEN @PhotoFileId
	                  WHEN '003' THEN @VideoFileId
	                  WHEN '004' THEN @DocumentFileId
	                END, -- ORDR_DESC - nvarchar(max)
	                0,  -- NUMB - int
	                @UssdCode,
	                @ChildUssdCode
	              );
	      SELECT @XMessage = 
	      (
	         SELECT @OrdrCode AS '@code'
	               ,24 AS '@roborbid'
	               ,@OrdrType '@type'
	         FOR XML PATH('Order'), ROOT('Process')
	      )
	      EXEC Send_Order_To_Personal_Robot_Job @XMessage;
	      SET @Message = N'📥از اینکه ما رو برای طرح سوالتون قابل دونستین ممنونم. 
📣پاسخ سوال شما بعد از آماده شدن در روزهای آینده براتون ارسال میشه.
‼️ شماره پیگیری سوال شما  ' + CAST(@OrdrCode AS VARCHAR(20)) + N' میباشد' + N'.حداقل 4 هفته زمان پاسخگویی به طول می انجامد';
	    END;
	END
	ELSE IF @UssdCode = '*0*2#' -- پیگیری سوالات پرسیده شده
   BEGIN
      IF @ChildUssdCode = '*0*2*1#'
      BEGIN
         SELECT @XTemp = (
			   -- Last Location
			    SELECT o.Code AS '@order',
			           N'‼️' + CAST(O.CODE AS NVARCHAR(20)) + CHAR(10) +
			           N'🗓' + dbo.GET_MTOS_U(O.STRT_DATE) + CHAR(10) +
			           N'⁉️ متن سوال شما : ' + od.ORDR_DESC
			     FROM [Order] o, Order_Detail od, Service_Robot Sr
			   WHERE O.SRBT_SERV_FILE_NO = Sr.Serv_File_No
	             AND O.SRBT_ROBO_RBID = Sr.Robo_Rbid
			       AND o.Code = Od.Ordr_Code
			       AND O.Ordr_Type = '006' -- طرح سوال
			       --AND O.ORDR_STAT = '001'
			       AND Sr.Chat_ID = @ChatId
			       AND Sr.Robo_Rbid = 24
			       AND Od.Elmn_Type = '001'
			       --AND Od.Ordr_Desc = @MenuText
			       --AND Od.BASE_USSD_CODE = @UssdCode
			       ORDER BY o.CODE
			       FOR XML PATH('Text'), ROOT('Texts')
		   );
		   IF @XTemp IS NOT NULL
		   BEGIN
		      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');		      
		      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
		   END
		   ELSE
		   BEGIN
		      SET @Message = N'از جانب شما برای ما سوالی مطرح نشده';
		      GOTO L$EndSP;		      
		   END
		END
		ELSE IF @ChildUssdCode = '*0*2*2#'
      BEGIN
         SELECT @XTemp = (
			   -- Last Location
			    SELECT TOP 1 o.Code AS '@order',
			           N'‼️' + CAST(O.CODE AS NVARCHAR(20)) + CHAR(10) +
			           N'🗓' + dbo.GET_MTOS_U(O.STRT_DATE) + CHAR(10) +
			           N'⁉️ متن سوال شما : ' + od.ORDR_DESC
			     FROM [Order] o, Order_Detail od, Service_Robot Sr
			   WHERE O.SRBT_SERV_FILE_NO = Sr.Serv_File_No
	             AND O.SRBT_ROBO_RBID = Sr.Robo_Rbid
			       AND o.Code = Od.Ordr_Code
			       AND O.Ordr_Type = '006' -- طرح سوال
			       --AND O.ORDR_STAT = '001'
			       AND Sr.Chat_ID = @ChatId
			       AND Sr.Robo_Rbid = 24
			       AND Od.Elmn_Type = '001'
			       --AND Od.Ordr_Desc = @MenuText
			       --AND Od.BASE_USSD_CODE = @UssdCode
			       ORDER BY o.CODE
			       FOR XML PATH('Text'), ROOT('Texts')
		   );
		   IF @XTemp IS NOT NULL
		   BEGIN
		      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');		      
		      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
		   END
		   ELSE
		   BEGIN
		      SET @Message = N'از جانب شما برای ما سوالی مطرح نشده';
		      GOTO L$EndSP;		      
		   END
		END
   END	
   ELSE IF @UssdCode = '*0*2*2#' AND @ChildUssdCode = ''-- اصلاح سوال ارسالی
   BEGIN
      --SET @OrdrCode = CONVERT(BIGINT, SUBSTRING(@MenuText, 0, CHARINDEX('*', @MenuText, 0)));
      --SET @MenuText = SUBSTRING(@MenuText, CHARINDEX('*', @MenuText, 0) + 1, LEN(@MenuText));

      /*IF EXISTS(
		      SELECT *
			     FROM [Order] o, Service_Robot Sr
			   WHERE O.SRBT_SERV_FILE_NO = Sr.Serv_File_No
	           AND O.SRBT_ROBO_RBID = Sr.Robo_Rbid
			     AND O.Ordr_Type = '006' -- سوال
			     AND Sr.Chat_ID = @ChatId
			     AND Sr.Robo_Rbid = 24
			     AND EXISTS(
			        SELECT *
			          FROM [Order] oi
			         WHERE oi.Ordr_Type = '007' -- پاسخ سوال
			           AND oi.Chat_ID = @ChatId
			           AND oi.SRBT_ROBO_RBID = 24
			           AND Oi.ORDR_CODE = o.Code
			     )
		  )
		  BEGIN
			SET @Message = N'🙂 کاربر گرامی سوالی که از طرف مشاورین پاسخ داده شده باشد قادر به اصلاح و تغییر آن نیستید';
			GOTO L$EndSP;
		  END*/
		  
      UPDATE dbo.Order_Detail
         SET ORDR_DESC = @MenuText
       WHERE /*ORDR_CODE = @OrdrCode
         AND*/ LEN(@MenuText) > 10
         AND EXISTS(
            SELECT *
              FROM dbo.[Order] o1
             WHERE o1.CODE = dbo.Order_Detail.ORDR_CODE
               AND o1.ORDR_STAT = '001'
               AND o1.ORDR_CODE IS NULL
               AND o1.ORDR_TYPE = '006' -- سوال
               AND O1.CHAT_ID = @ChatID
               AND O1.SRBT_ROBO_RBID = 24
               AND NOT EXISTS(
                  SELECT * 
                    FROM dbo.[Order] o2
                   WHERE o1.CODE = o2.ORDR_CODE
                     AND O2.ORDR_TYPE = '007' -- جواب سوال
                     AND O1.CHAT_ID = @ChatID
                     AND O1.SRBT_ROBO_RBID = 24
               )
         );
      
      IF @@ROWCOUNT = 1
         SET @Message = N'😊👍 سوالتون اصلاح شد' + N'کاربر گرامی برای پاسخ گویی به سوال شما حداقل 4 هفته زمان پاسخگویی به طول می انجامد';
      ELSE
         SET @Message = N'😁👎 در ارسال اصلاحی سوال خود خطایی وجود دارد که باید اصلاح کنید'
   END
   ELSE IF @UssdCode = '*0*2*3#' -- نمایش جواب ارسالی سوال
   BEGIN
      SET @OrdrCode = CONVERT(BIGINT, @MenuText); -- کد سوال
      SELECT @Message = (
         SELECT N'🗓' + dbo.GET_MTOS_U(O.STRT_DATE) + CHAR(10) +
                N'🗣' + S.Last_Name + ', ' + S.Frst_Name + CHAR(10) + 
			       N'⁉️ متن جواب سوال شما : ' + od.ORDR_DESC
           FROM dbo.[Order] os, dbo.[Order] o, dbo.Order_Detail Od, dbo.Service_Robot Sr, dbo.Service S
          WHERE O.CODE = od.ORDR_CODE
            AND o.ORDR_CODE = os.CODE
            AND os.CHAT_ID = @ChatId
            AND O.ORDR_CODE = @OrdrCode -- کد سوال
            AND O.ORDR_TYPE = '007' -- کد درخواست پاسخ
            AND O.SRBT_SERV_FILE_NO = Sr.SERV_FILE_NO
            AND O.SRBT_ROBO_RBID = Sr.ROBO_RBID
            AND Sr.SERV_FILE_NO = S.FILE_NO
      );
   END
   ELSE IF @UssdCode = '*1#'
   BEGIN
      SELECT @XTemp = (
         SELECT TOP 10 
                N'‼️' + CAST(Ri.ID AS NVARCHAR(20)) + CHAR(10) +
	             --N'🗓' + dbo.GET_MTOS_U(O.STRT_DATE) + CHAR(10) +
	             N'👈 موضوع : ' + ISNULL(ri.TEXT_TYPE, N'موضوع عمومی') +  CHAR(10) +
	             N'⁉️ متن سوال : ' + SUBSTRING(Ri.TEXT_TITL, 1, 50) + N' ... ' + CHAR(10) +
	             --N'‼️ پاسخ سوال : ' + Ri.TEXT_ANSR + CHAR(10) +
	             + N' 👉👓 ' +
	             Ri.CHNL_URL + CHAR(10) + CHAR(10)
           FROM dbo.Robot_Import Ri
          WHERE TEXT_TITL LIKE N'%' + @MenuText + N'%'
             OR TEXT_ANSR LIKE N'%' + @MenuText + N'%'
             OR TEXT_TYPE LIKE N'%' + @MenuText + N'%'
          ORDER BY Ri.ID
          FOR XML PATH('')   
      );
      
      IF @XTemp IS NOT NULL
	   BEGIN
	      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');		      
	      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
	      --SET @Message = SUBSTRING(@Message,1 , 4096)
	   END
	   ELSE
	   BEGIN
	      SET @Message = N'جستجو نتیجه ای در بر نداشت!';
	      GOTO L$EndSP;		      
	   END
   END
   ELSE IF @ChildUssdCode = '*100*1#'
   BEGIN
      SELECT @XTemp = (
	      -- Last Location
	       SELECT 1 AS '@order',
	          N' تعداد کل مشتریان ' + (
	          SELECT CAST(COUNT(*) AS VARCHAR(20))
	            FROM dbo.Service_Robot 
	           WHERE Robo_Rbid = 24
	        GROUP BY ROBO_RBID
	      ) + CHAR(10) +
	      N' تعداد مشتریان امروز ' + (
	         SELECT CAST(COUNT(*) AS VARCHAR(20))
	            FROM dbo.Service_Robot 
	           WHERE Robo_Rbid = 24
	             AND JOIN_DATE = CAST(GETDATE() AS DATE)
	      ) 
	          FOR XML PATH('Text'), ROOT('Texts')
	          
      );
      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
   END
   ELSE IF @ChildUssdCode = '*100*2#'
   BEGIN
      SELECT @XTemp = (
	      -- Last Location
	       SELECT 1 AS '@order'
	            ,(
	             SELECT TOP 10 
	               --Srv.SRID AS '@order'
	               N'🗓 ' + dbo.GET_MTOS_U(Srv.VIST_DATE) + N' 👤 ' + S.FRST_NAME + N' ' + S.LAST_NAME + CHAR(10)
	               FROM dbo.Service S, dbo.Service_Robot Sr, dbo.Service_Robot_Visit Srv	            
	              WHERE Sr.Robo_Rbid = 24
	                AND S.FILE_NO = Sr.SERV_FILE_NO
	                AND Sr.ROBO_RBID = Srv.SRRB_ROBO_RBID
	                AND Sr.SERV_FILE_NO = Srv.SRRB_SERV_FILE_NO
	             ORDER BY Srv.VIST_DATE DESC
	             FOR XML PATH('')
	          )
	          FOR XML PATH('Text'), ROOT('Texts')
	          
      );
      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
   END
   ELSE IF @ChildUssdCode = '*100*3#'
   BEGIN
      SELECT @XTemp = (
	      -- Last Location
	       SELECT 1 AS '@order'
	            ,(
                   SELECT N'👈 ' + MESG_TEXT + N' 〽️ ' +
                          CAST(COUNT(*) AS VARCHAR(10)) + CHAR(10)
                    FROM [iRoboTech].[dbo].[Service_Robot_Message]
                    WHERE SRBT_ROBO_RBID = 24
                    AND MESG_TEXT NOT IN (N'بازگشت به منوی اصلی', N'🔺 بازگشت', N'/start')
                    AND USSD_CODE = '*1#'
                    GROUP BY MESG_TEXT
                    ORDER BY COUNT(*) desc
	             FOR XML PATH('')
	          )
	          FOR XML PATH('Text'), ROOT('Texts')
	          
      );
      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
   END
   ELSE IF @ChildUssdCode = '*100*4#'
   BEGIN
      SELECT @XTemp = (
	      -- Last Location
	       SELECT 1 AS '@order'
	            ,(
                   SELECT N'👈 ' + MESG_TEXT + N' 〽️ ' +
                          CAST(COUNT(*) AS VARCHAR(10)) + CHAR(10)
                    FROM [iRoboTech].[dbo].[Service_Robot_Message] Srm, dbo.Menu_Ussd m
                    WHERE srm.SRBT_ROBO_RBID = 24
                    AND srm.SRBT_ROBO_RBID = m.ROBO_RBID
                    AND srm.MESG_TEXT NOT IN (N'بازگشت به منوی اصلی', N'🔺 بازگشت', N'/start')
                    AND srm.MESG_TEXT = m.MENU_TEXT
                    --AND srm.USSD_CODE = '*1#'
                    GROUP BY MESG_TEXT
                    ORDER BY COUNT(*) desc
	             FOR XML PATH('')
	          )
	          FOR XML PATH('Text'), ROOT('Texts')
	          
      );
      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
   END
   ELSE IF @ChildUssdCode = '*100*5#'
   BEGIN
      SELECT @XTemp = (
          SELECT 1 AS '@order'
               ,(
                SELECT 
                  N' 👤 ' + S.FRST_NAME + N' ' + S.LAST_NAME + N' 📞 ' + CASE WHEN sr.CELL_PHON IS NULL THEN N' 😔 ' ELSE Sr.CELL_PHON + N' 😊 ' END + CHAR(10)
                  FROM dbo.Service S, dbo.Service_Robot Sr
                 WHERE Sr.Robo_Rbid = 24
                   AND S.FILE_NO = Sr.SERV_FILE_NO
                   AND sr.CELL_PHON IS NOT NULL
                FOR XML PATH('')
             )
             FOR XML PATH('Text'), ROOT('Texts')
          
     );
     SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
     --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

     SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
   END

   ELSE IF @UssdCode = '*0*4#'
   BEGIN
      
      DECLARE C$Items CURSOR FOR
         SELECT Item FROM dbo.SplitString(@MenuText, '*');
      SET @Index = 0;
      OPEN [C$Items];
      L$FetchC$Item:
      FETCH NEXT FROM [C$Items] INTO @Item;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndC$Item;
      
      IF @Index = 0
         SET @NameService = @Item;
      ELSE IF @Index = 1
         SET @CellPhon = @Item;
      ELSE IF @Index = 2
         SET @ServAddres = @Item;         
      
      SET @Index += 1;
      GOTO L$FetchC$Item;
      L$EndC$Item:
      CLOSE [C$Items];
      DEALLOCATE [C$Items];
      
      IF @CellPhon IS NULL --OR LEN(@CellPhon) != 13
      BEGIN
         SELECT @Message = 
	      (N'اطلاعات ارسال درست نمی باشد. لطفا نسخه تلگرام خود را بروزرسانی کنید. و بعد از برای ارسال شماره خود اقدام کنید. با تشکر');   
	      GOTO L$EndSP;
      END
      
      IF EXISTS(
         SELECT *
           FROM dbo.Service_Robot_Public
          WHERE CHAT_ID = @ChatID
            AND SRBT_ROBO_RBID = 24
            AND CELL_PHON IS NULL
      )
      BEGIN
         UPDATE dbo.Service_Robot_Public
            SET CELL_PHON = @CellPhon
               ,NAME = @NameService
               ,SERV_ADRS = @ServAddres
               ,CORD_X = 0
               ,CORD_Y = 0
          WHERE CHAT_ID = @ChatID
            AND SRBT_ROBO_RBID = 24
            AND CELL_PHON IS NULL;
      END      
      ELSE
      BEGIN      
         INSERT INTO Service_Robot_Public (Srbt_Serv_File_No, Srbt_Robo_Rbid, Rwno, Cell_Phon, Chat_Id, SERV_ADRS, NAME, CORD_X, CORD_Y)
		    SELECT Serv_File_No, Robo_Rbid, 0, @CellPhon, @Chatid, @ServAddres, @NameService, 0, 0
		      FROM Service_Robot
		     WHERE Chat_Id = @ChatId
		 	   AND Robo_Rbid = 24;		
		END 
		
		SELECT @Message = 
	      (N'اطلاعات شماره تلفن شما برای فعال سازی ثبت گردید.');   
   END
   L$EndSP:
	SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END
GO
