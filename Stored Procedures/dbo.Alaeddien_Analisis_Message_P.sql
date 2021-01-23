SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Alaeddien_Analisis_Message_P]
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
           @ElmnType VARCHAR(3);
	
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
	ELSE IF @UssdCode = '*1*2#' 
	BEGIN
		IF @ChildUssdCode = '*1*2*2#'
		BEGIN
			SELECT @Message = (
N'<Texts order="1">
<Text order="1">*منوی جدید*</Text>
<Text order="2">
کد غذا: 1024
مرغ سوخاری 2 تکه 🍗🍗
(مرغ 2 تکه، سالاد کلم، نان، سیب زمینی سرخ کرده)
13500 تومان
</Text>
<Text order="3">
کد غذا: 1025
مرغ سوخاری 3 تکه 🍗🍗🍗
(مرغ 3 تکه، سالاد کلم، نان، سیب زمینی سرخ کرده)
17000 تومان
</Text>
<Text order="4">
کد غذا: 1026
مرغ سوخاری 7 تکه 🍗🍗🍗🍗🍗🍗🍗
(مرغ 7 تکه،2 سالاد کلم، نان، سیب زمینی سرخ کرده)
38000 تومان
</Text>
<Text order="5">
کد غذا: 1027
فیله استریپس 🍤
(4 تکه فیله استریپس، سالاد کلم، نان، سیب زمینی سرخ کرده)
16500 تومان
</Text>
<Text order="6">
کد غذا: 1028
قارچ سوخاری
5500 تومان
</Text>
<Text order="7">
کد غذا: 1029
لازانیا 🍝
16000 تومان
</Text>
<Text order="8">
کد غذا: 1030
ساندویچ تنوری 🌭
16000 تومان
</Text>
</Texts>
');
	   END
	END
	ELSE IF @UssdCode = '*1*1*1#'
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
		  	
	   /*UPDATE Service_Robot
	      SET CELL_PHON = @MenuText
	    WHERE CHAT_ID = @ChatID
	      AND ROBO_RBID = 11;*/
	   SELECT @Message = 
	      (N'اطلاعات شماره تلفن شما برای فعال سازی ثبت گردید.');
	END
	ELSE IF @UssdCode = '*1*1*2#'
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

		   /*UPDATE Service_Robot
			  SET CORD_X = @CordX
				 ,CORD_Y = @CordY
			WHERE CHAT_ID = @ChatID
			  AND ROBO_RBID = 11;*/
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
			-- مشاهده مشخصات
			/*SELECT @XMessage = (
				-- Last Information
				SELECT [order] AS '@order',
				       CellPhon 
				  FROM (
				 SELECT  1 AS [order]
						,N'برای شما دوست عزیز شماره تلفن ' + Cell_Phon + N' ثبت شده است.' AS CellPhon
				   FROM Service_Robot 
				  WHERE Chat_ID = @ChatId 
				    AND Robo_Rbid = 11 
					AND SRPB_RWNO IS NOT NULL					
					
				UNION ALL 
				 SELECT 2 AS [order]
				        ,N'برای شما شماره تلفن تایید نشده ' + Cell_Phon + N' ثبت شده است. برای ثبت نهایی لطفا آدرس مکانی خود را ارسال کنید ' AS CellPhon
				   FROM Service_Robot_Public A
				  WHERE Chat_ID = @ChatId 
				    AND A.Srbt_Robo_Rbid = 11 
					AND RWNO = (
						SELECT MAX(RWNO)
						  FROM Service_Robot_Public B, Service_Robot T
						 WHERE B.CHAT_ID = @ChatID
						   AND B.SRBT_ROBO_RBID = A.SRBT_ROBO_RBID
						   AND B.SRBT_SERV_FILE_NO = A.SRBT_SERV_FILE_NO
						   AND B.Srbt_Robo_Rbid = T.Robo_Rbid
						   AND B.Srbt_Serv_File_No = T.Serv_File_No
						   AND B.Cell_Phon != T.Cell_Phon
					)
					ORDER BY RWNO DESC) A
				    FOR XML PATH('Text'), ROOT('Texts')
			);
			SET @XMessage.modify('insert attribute order {"1"} into (//Texts)[1]');*/
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
					AND SRPB_RWNO IS NOT NULL
				/*UNION ALL 
				 SELECT 2 AS [order]
				       ,CONVERT(varchar(30), Cord_X, 128) AS Cord_X
					   ,CONVERT(varchar(30), Cord_Y, 128) AS Cord_Y
					   ,N' شماره تلفن ' + Cell_Phon + N' با آدرس بالا ثبت شده است.' AS cellphon
				   FROM Service_Robot_Public A
				  WHERE Chat_ID = @ChatId 
				    AND A.Srbt_Robo_Rbid = 11 
					AND RWNO = (
						SELECT MAX(RWNO)
						  FROM Service_Robot_Public B, Service_Robot T
						 WHERE B.CHAT_ID = @ChatID
						   AND B.SRBT_ROBO_RBID = A.SRBT_ROBO_RBID
						   AND B.SRBT_SERV_FILE_NO = A.SRBT_SERV_FILE_NO
						   AND B.Srbt_Robo_Rbid = T.Robo_Rbid
						   AND B.Srbt_Serv_File_No = T.Serv_File_No
						   AND B.Cord_X != T.Cord_X
						   AND B.Cord_Y != T.Cord_Y
					)*/) A
				    FOR XML PATH('Location'), ROOT('Locations')
			);
			SET @XTemp.modify('insert attribute order {"2"} into (//Locations)[1]');
			--SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

			SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
		END
	END
	ELSE IF @UssdCode = '*1*1*3#'
	BEGIN
		IF @ChildUssdCode = '*1*1*3*1#'
		BEGIN
			/*SELECT @XMessage = (
				-- Last Information				
				 SELECT Rwno AS '@order'
				        ,Cell_Phon AS CellPhon
				   FROM Service_Robot_Public A
				  WHERE Chat_ID = @ChatId 
				    AND A.Srbt_Robo_Rbid = 11 					
				    FOR XML PATH('Text'), ROOT('Texts')
			);
			SET @XMessage.modify('insert attribute order {"1"} into (//Texts)[1]');*/
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
			--SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

			SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
		END
	END
	ELSE IF @UssdCode = '*0*4#' -- اطلاعات مربوط به ثبت شکایات
	BEGIN
	   IF EXISTS (
	      SELECT * 
	        FROM dbo.Service_Robot
	       WHERE CHAT_ID = @ChatId
	         AND ROBO_RBID = 11
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
	              11,
	              SRPB_RWNO,
	              '003',
	              GETDATE(),
	              '001' -- ثبت مرحله اولیه
	         FROM dbo.Service_Robot
	        WHERE CHAT_ID = @chatid
	          AND ROBO_RBID = 11;
	      
	      DECLARE @OrdrCode BIGINT
	             ,@OrdrType VARCHAR(3);
	      
	      SELECT @OrdrCode = MAX(CODE),
	             @OrdrType = ORDR_TYPE
	        FROM dbo.[Order] o, dbo.Service_Robot sr
	       WHERE o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
	         AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
	         AND sr.CHAT_ID = @ChatId
	         AND Sr.ROBO_RBID = 11
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
	               ,11 AS '@roborbid'
	               ,@OrdrType '@type'
	         FOR XML PATH('Order'), ROOT('Process')
	      )
	      EXEC Send_Order_To_Personal_Robot_Job @XMessage;
	      SET @Message = N'کاربر گرامی اطلاعات شما در سیستم به موفقیت ثبت شد';
	    END;
	   
	END
	ELSE IF @UssdCode = '*100*1*1#'
   BEGIN
      IF NOT EXISTS (
         SELECT *
           FROM Organ_Media
          WHERE ORGN_OGID = 24
            AND FILE_ID = @PhotoFileId
      )
      BEGIN
         INSERT INTO Organ_Media(ORGN_OGID, IMAG_DESC, IMAG_TYPE, [FILE_ID])
         VALUES(24, N'غذاهای پیتزا علاالدین', '006', @PhotoFileId);
         
         SET @Message = N'عکس با موفقیت در قسمت غذاهای پیتزا علاالدین ذخیره گردید.';
      END
   END
   ELSE IF @ChildUssdCode = '*100*2#'
   BEGIN
      SELECT @XTemp = (
	      -- Last Location
	       SELECT 1 AS '@order',
	          N' تعداد کل مشتریان ' + (
	          SELECT CAST(COUNT(*) AS VARCHAR(20))
	            FROM dbo.Service_Robot 
	           WHERE Robo_Rbid = 11
	        GROUP BY ROBO_RBID
	      ) + CHAR(10) +
	      N' تعداد مشتریان امروز ' + (
	         SELECT CAST(COUNT(*) AS VARCHAR(20))
	            FROM dbo.Service_Robot 
	           WHERE Robo_Rbid = 11
	             AND JOIN_DATE = CAST(GETDATE() AS DATE)
	      ) 
	          FOR XML PATH('Text'), ROOT('Texts')
	          
      );
      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
   END

	
	SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END
GO
