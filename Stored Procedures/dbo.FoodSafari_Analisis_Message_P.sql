SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[FoodSafari_Analisis_Message_P]
	@X XML,
	@XResult XML OUT
AS
BEGIN
   DECLARE @UssdCode VARCHAR(250),
           @ChildUssdCode VARCHAR(250),    
           @MenuText NVARCHAR(250),
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
	
	SELECT @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]', 'VARCHAR(250)'),
	       @ChildUssdCode = @X.query('//Message').value('(Message/@childussd)[1]', 'VARCHAR(250)'),    
	       @ChatID   = @X.query('//Message').value('(Message/@chatid)[1]', 'BIGINT'),	       
	       @ElmnType   = @X.query('//Message').value('(Message/@elmntype)[1]', 'VARCHAR(3)'),	       
	       @MenuText = @X.query('//Text').value('.', 'NVARCHAR(250)'),
	       @CordX    = @X.query('//Location').value('(Location/@latitude)[1]', 'FLOAT'),
	       @CordY    = @X.query('//Location').value('(Location/@longitude)[1]', 'FLOAT'),
	       @PhotoFileId   = @X.query('//Photo').value('(Photo/@fileid)[1]', 'NVARCHAR(MAX)'),
	       @VideoFileId   = @X.query('//Video').value('(Video/@fileid)[1]', 'NVARCHAR(MAX)'),
	       @DocumentFileId   = @X.query('//Document').value('(Document/@fileid)[1]', 'NVARCHAR(MAX)');
	
   --insert into logs (x) values (@x); 

   IF @UssdCode = '*3*1#'
   BEGIN
      DECLARE C$Items CURSOR FOR
         SELECT * FROM dbo.SplitString(@MenuText, '*');
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
      
      
      IF EXISTS(
         SELECT *
           FROM dbo.Service_Robot_Public
          WHERE CHAT_ID = @ChatID
            AND SRBT_ROBO_RBID = 323
            AND CELL_PHON IS NULL
      )
      BEGIN
         UPDATE dbo.Service_Robot_Public
            SET CELL_PHON = @CellPhon
               ,NAME = @NameService
               ,SERV_ADRS = @ServAddres
          WHERE CHAT_ID = @ChatID
            AND SRBT_ROBO_RBID = 323
            AND CELL_PHON IS NULL;
      END      
      ELSE
      BEGIN      
         INSERT INTO Service_Robot_Public (Srbt_Serv_File_No, Srbt_Robo_Rbid, Rwno, Cell_Phon, Chat_Id, SERV_ADRS, NAME)
		    SELECT Serv_File_No, Robo_Rbid, 0, @CellPhon, @Chatid, @ServAddres, @NameService
		      FROM Service_Robot
		     WHERE Chat_Id = @ChatId
		 	   AND Robo_Rbid = 323;		
		END 
		
		SELECT @Message = 
	      (N'اطلاعات شماره تلفن شما برای فعال سازی ثبت گردید.');
   END
   ELSE IF @UssdCode = '*3*2#'
   BEGIN
      IF NOT (@CordX = 0 AND @CordY = 0)
		BEGIN
			UPDATE Service_Robot_Public 
			   SET CORD_X = @CordX
				  ,CORD_Y = @CordY
			WHERE CHAT_ID = @ChatID
			  AND SRBT_ROBO_RBID = 323
			  AND RWNO = (
				Select MAX(Rwno) 
				  FROM Service_Robot_Public T 
				 WHERE T.SRBT_SERV_FILE_NO = Service_Robot_Public.SRBT_SERV_FILE_NO
				   AND T.SRBT_ROBO_RBID = Service_Robot_Public.SRBT_ROBO_RBID
				   AND T.CHAT_ID = @ChatId
			  );

		   SELECT @Message = 
			  (N'اطلاعات مختصات جغرافیایی شما در سیستم ثبت گردید');
	   END
   END
   ELSE IF @UssdCode = '*4#'
   BEGIN
      IF @ChildUssdCode = '*4*1#'
	   BEGIN
	      SELECT @XTemp = (
		      -- Last Location
		       SELECT 1 AS '@order',
		          N' تعداد کل مشتریان ' + (
		          SELECT CAST(COUNT(*) AS VARCHAR(20))
		            FROM dbo.Service_Robot 
		           WHERE Robo_Rbid = 323
		        GROUP BY ROBO_RBID
		      ) + CHAR(10) +
		      N' تعداد مشتریان امروز ' + (
		         SELECT CAST(COUNT(*) AS VARCHAR(20))
		            FROM dbo.Service_Robot 
		           WHERE Robo_Rbid = 323
		             AND JOIN_DATE = CAST(GETDATE() AS DATE)
		      ) + CHAR(10) +
		      N' تعداد مشترکین ' + (
		         SELECT CAST(COUNT(*) AS VARCHAR(20))
		            FROM dbo.Service_Robot 
		           WHERE Robo_Rbid = 323
		             AND CELL_PHON IS NOT NULL
		      ) 
		          FOR XML PATH('Text'), ROOT('Texts')
		          
	      );
	      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
	      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')
	      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
	   END
	   ELSE IF @ChildUssdCode = '*4*3#'
	   BEGIN
	      SELECT @XTemp = (
	          SELECT 1 AS '@order'
	               ,(
	                SELECT 
	                  N' 👤 ' + S.FRST_NAME + N' ' + S.LAST_NAME + N' 📞 ' + CASE WHEN sr.CELL_PHON IS NULL THEN N' 😔 ' ELSE Sr.CELL_PHON + N' 😊 ' END + CHAR(10)
	                  FROM dbo.Service S, dbo.Service_Robot Sr
	                 WHERE Sr.Robo_Rbid = 323
	                   AND S.FILE_NO = Sr.SERV_FILE_NO
	                FOR XML PATH('')
	             )
	             FOR XML PATH('Text'), ROOT('Texts')
   	          
         );
         SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
         --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

         SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
	   END
   END
   ELSE IF @UssdCode = '*4*2#'
   BEGIN
      SELECT @XTemp = (
		      -- Last Location
		       SELECT Rwno AS '@order'
		             ,CONVERT(varchar(30), Cord_X, 128) AS '@cordx'
			         ,CONVERT(varchar(30), Cord_Y, 128) AS '@cordy'
			         ,N' شماره تلفن ' + Cell_Phon + N' با آدرس بالا برای ' + A.NAME + N' ذخیره شده است. ' AS '@cellphon'
		         FROM Service_Robot_Public A
		        WHERE /*Chat_ID = @ChatId 
		          AND*/ A.Srbt_Robo_Rbid = 323
		          AND A.CELL_PHON = @MenuText
			       AND Cord_X is not null
			       AND Cord_Y is not null
		          FOR XML PATH('Location'), ROOT('Locations')
	      );
	      SET @XTemp.modify('insert attribute order {"2"} into (//Locations)[1]');
	      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

	      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
   END
   ELSE IF @UssdCode = '*3#'
	BEGIN
	   IF @ChildUssdCode = '*3*3#'
	   BEGIN
		   SELECT @XTemp = (
		      -- Last Location
		       SELECT Rwno AS '@order'
		             ,CONVERT(varchar(30), Cord_X, 128) AS '@cordx'
			         ,CONVERT(varchar(30), Cord_Y, 128) AS '@cordy'
			         ,N' شماره تلفن ' + Cell_Phon + N' با آدرس بالا ثبت شده است.' AS '@cellphon'
		         FROM Service_Robot_Public A
		        WHERE Chat_ID = @ChatId 
		          AND A.Srbt_Robo_Rbid = 323
			      AND Cord_X is not null
			      And Cord_Y is not null
		          FOR XML PATH('Location'), ROOT('Locations')
	      );
	      SET @XTemp.modify('insert attribute order {"2"} into (//Locations)[1]');
	      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

	      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
	   END
	   ELSE IF @ChildUssdCode = '*3*4#'
	   BEGIN
	      SELECT @Message = N'با سلام😃🖐
😊مفتخریم که ما را به عنوان مکان تفریحی خودتون انتخاب کردین 👈👥 📣 و دوستان خودتون رو با ما آشنا میکنید.
دوست عزیزم با معرفی دوستان خودتون به ما می توانید در 📃 لیست مشتریان ارزنده 😋 ما قرار گیرید و از مزایای 🙏 باشگاه مشتریان ما برخوردار بشید.' + CHAR(10) + 
         N'https://telegram.me/foodsafari_bot?start=' + CAST(@ChatID AS NVARCHAR(20));
	   END
	   ELSE IF @ChildUssdCode = '*3*5#'
	   BEGIN
	      SELECT @XTemp = (
		      -- Last Location
		       SELECT 1 AS '@order',
		          N'👈👫  تعداد دعوتی شما ' + (
		          SELECT CAST(COUNT(*) AS VARCHAR(20))
		            FROM dbo.Service_Robot 
		           WHERE Robo_Rbid = 323
		             AND REF_CHAT_ID = @ChatID
		       ) + N' نفر میباشد '
		          FOR XML PATH('Text'), ROOT('Texts')		          
	      );
	      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
	      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')
	      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
	   END
	END
	ELSE IF @UssdCode = '*0*5#' -- اطلاعات مربوط به ثبت شکایات
	BEGIN
	   IF @MenuText = N'بازگشت 🔺'
	   BEGIN
	     SET @Message = N'بازگشت 🔺';
		  GOTO L$EndSP;
	   END
		  
	   IF EXISTS (
	      SELECT * 
	        FROM dbo.Service_Robot
	       WHERE CHAT_ID = @ChatId
	         AND ROBO_RBID = 323
	         AND SRPB_RWNO IS NULL
	   )
	   BEGIN
	      SET @Message = N'کاربر گرامی برای شما کد اشتراک ثبت نشده. لطفا برای ثبت هر گونه اطلاعات در سیستم ابتدا کد اشتراک خود را فعال کنید';
	   END
	   ELSE
	   BEGIN
	   
	      INSERT INTO dbo.[Order]
	              ( SRBT_SERV_FILE_NO ,
	                SRBT_ROBO_RBID ,
	                SRBT_SRPB_RWNO ,
	                ORDR_TYPE ,
	                STRT_DATE ,
	                ORDR_STAT
	              )
	       SELECT SERV_FILE_NO,
	              323,
	              SRPB_RWNO,
	              '003',
	              GETDATE(),
	              '001' -- ثبت مرحله اولیه
	         FROM dbo.Service_Robot
	        WHERE CHAT_ID = @chatid
	          AND ROBO_RBID = 323;
	      
	      DECLARE @OrdrCode BIGINT
	             ,@OrdrType VARCHAR(3);
	      
	      SELECT @OrdrCode = MAX(CODE),
	             @OrdrType = ORDR_TYPE
	        FROM dbo.[Order] o, dbo.Service_Robot sr
	       WHERE o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	         AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
	         AND sr.CHAT_ID = @ChatId
	         AND Sr.ROBO_RBID = 323
	         AND o.ORDR_TYPE = '003'
	         GROUP BY ORDR_TYPE;
	      
	      INSERT dbo.Order_Detail
	              ( ORDR_CODE ,
	                ELMN_TYPE ,
	                ORDR_DESC ,
	                NUMB
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
	                0  -- NUMB - int
	              );
	      SELECT @XMessage = 
	      (
	         SELECT @OrdrCode AS '@code'
	               ,323 AS '@roborbid'
	               ,@OrdrType '@type'
	         FOR XML PATH('Order'), ROOT('Process')
	      )
	      EXEC Send_Order_To_Personal_Robot_Job @XMessage;
	      SET @Message = N'کاربر گرامی پیام شما در سیستم با موفقیت ثبت شد';
	    END;
	   
	END
	ELSE IF @UssdCode = '*0*4#' -- اطلاعات مربوط به ثبت پیشنهادات
	BEGIN
	   IF @MenuText = N'بازگشت 🔺'
	   BEGIN
	     SET @Message = N'بازگشت 🔺';
		  GOTO L$EndSP;
	   END
		  
	   IF EXISTS (
	      SELECT * 
	        FROM dbo.Service_Robot
	       WHERE CHAT_ID = @ChatId
	         AND ROBO_RBID = 323
	         AND SRPB_RWNO IS NULL
	   )
	   BEGIN
	      SET @Message = N'کاربر گرامی برای شما کد اشتراک ثبت نشده. لطفا برای ثبت هر گونه اطلاعات در سیستم ابتدا کد اشتراک خود را فعال کنید';
	   END
	   ELSE
	   BEGIN
	   
	      INSERT INTO dbo.[Order]
	              ( SRBT_SERV_FILE_NO ,
	                SRBT_ROBO_RBID ,
	                SRBT_SRPB_RWNO ,
	                ORDR_TYPE ,
	                STRT_DATE ,
	                ORDR_STAT
	              )
	       SELECT SERV_FILE_NO,
	              323,
	              SRPB_RWNO,
	              '001', -- پیشنهادات
	              GETDATE(),
	              '001' -- ثبت مرحله اولیه
	         FROM dbo.Service_Robot
	        WHERE CHAT_ID = @chatid
	          AND ROBO_RBID = 323;
	      
	      SELECT @OrdrCode = MAX(CODE),
	             @OrdrType = ORDR_TYPE
	        FROM dbo.[Order] o, dbo.Service_Robot sr
	       WHERE o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	         AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
	         AND sr.CHAT_ID = @ChatId
	         AND Sr.ROBO_RBID = 323
	         AND o.ORDR_TYPE = '001'
	         GROUP BY ORDR_TYPE;
	      
	      INSERT dbo.Order_Detail
	              ( ORDR_CODE ,
	                ELMN_TYPE ,
	                ORDR_DESC ,
	                NUMB
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
	                0  -- NUMB - int
	              );
	      SELECT @XMessage = 
	      (
	         SELECT @OrdrCode AS '@code'
	               ,323 AS '@roborbid'
	               ,@OrdrType '@type'
	         FOR XML PATH('Order'), ROOT('Process')
	      )
	      EXEC Send_Order_To_Personal_Robot_Job @XMessage;
	      SET @Message = N'کاربر گرامی پیام شما در سیستم با موفقیت ثبت شد';
	    END;
	   
	END
	ELSE IF @UssdCode = '*100*1*1#'
   BEGIN
      IF NOT EXISTS (
         SELECT *
           FROM Organ_Media
          WHERE ORGN_OGID = 305
            AND FILE_ID = @PhotoFileId
      )
      BEGIN
         INSERT INTO Organ_Media(ORGN_OGID, IMAG_DESC, IMAG_TYPE, [FILE_ID])
         VALUES(305, N'غذاهای پیتزا علاالدین', '006', @PhotoFileId);
         
         SET @Message = N'عکس با موفقیت در قسمت غذاهای پیتزا علاالدین ذخیره گردید.';
      END
   END
	
	L$EndSP:
	SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END
GO
