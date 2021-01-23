SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE
 PROCEDURE [dbo].[SoorenSoft_Analisis_Message_P]
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
           @MimeType VARCHAR(100),
           @FileName NVARCHAR(250),
           @FileExt VARCHAR(10),
           @Item NVARCHAR(1000),
           @Name NVARCHAR(100),
           @Numb NVARCHAR(100),
           @Index BIGINT = 0,
           @Token VARCHAR(100),
           @Rbid BIGINT;
	
	--INSERT INTO dbo.logs(x)	VALUES(@x);
	
	SELECT @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]', 'VARCHAR(250)'),
	       @Token = @X.query('/Robot').value('(Robot/@token)[1]', 'VARCHAR(100)'),
	       @ChildUssdCode = @X.query('//Message').value('(Message/@childussd)[1]', 'VARCHAR(250)'),    
	       @ChatID   = @X.query('//Message').value('(Message/@chatid)[1]', 'BIGINT'),	       
	       @ElmnType   = @X.query('//Message').value('(Message/@elmntype)[1]', 'VARCHAR(3)'),	       
	       @MimeType   = @X.query('//Message').value('(Message/@mimetype)[1]', 'VARCHAR(100)'),	       
	       @FileName   = @X.query('//Message').value('(Message/@filename)[1]', 'NVARCHAR(250)'),	       
	       @FileExt   = @X.query('//Message').value('(Message/@fileext)[1]', 'VARCHAR(10)'),	       
	       @MenuText = @X.query('//Text').value('.', 'NVARCHAR(250)'),
	       @CordX    = @X.query('//Location').value('(Location/@latitude)[1]', 'FLOAT'),
	       @CordY    = @X.query('//Location').value('(Location/@longitude)[1]', 'FLOAT'),
	       @PhotoFileId   = @X.query('//Photo').value('(Photo/@fileid)[1]', 'NVARCHAR(MAX)'),
	       @VideoFileId   = @X.query('//Video').value('(Video/@fileid)[1]', 'NVARCHAR(MAX)'),
	       @DocumentFileId   = @X.query('//Document').value('(Document/@fileid)[1]', 'NVARCHAR(MAX)');
	
	SELECT @Rbid = RBID
	  FROM dbo.Robot
	 WHERE TKON_CODE = @Token;
   --insert into logs (x) values (@x); 

   IF @UssdCode IN ( '*0#' )
   BEGIN
      DECLARE @OrdrCode BIGINT
             ,@OrdrType VARCHAR(3);

      SELECT @OrdrCode = MAX(CODE)
        FROM dbo.[Order]
       WHERE SRBT_ROBO_RBID = @Rbid
         AND CHAT_ID = @ChatID
         AND ORDR_TYPE = '006'
         AND ORDR_STAT = '001';
      
      IF @MenuText = N'*#' 
         GOTO L$EndMessage;
      
      IF @OrdrCode IS NULL         
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
	                 @Rbid,
	                 SRPB_RWNO,
	                 '006',
	                 GETDATE(),
	                 '001' -- ثبت مرحله اولیه
	            FROM dbo.Service_Robot
	           WHERE CHAT_ID = @chatid
	             AND ROBO_RBID = @Rbid;
	   END;   
      
      SELECT @OrdrCode = MAX(CODE),
             @OrdrType = ORDR_TYPE
        FROM dbo.[Order] o, dbo.Service_Robot sr
       WHERE o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
         AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
         AND sr.CHAT_ID = @ChatId
         AND Sr.ROBO_RBID = @Rbid
         AND o.ORDR_TYPE = '006'
         GROUP BY ORDR_TYPE;
      
      INSERT dbo.Order_Detail
              ( ORDR_CODE ,
                ELMN_TYPE ,
                MIME_TYPE ,
                FILE_NAME ,
                FILE_EXT ,
                ORDR_DESC ,
                NUMB ,
                ORDR_CMNT,
                BASE_USSD_CODE
              )
      VALUES  ( @OrdrCode , -- ORDR_CODE - bigint
                @ElmnType , -- ELMN_TYPE - varchar(3)
                @MimeType ,
                @FileName ,
                @FileExt ,
                CASE @ElmnType 
                  WHEN '001' THEN @MenuText
                  WHEN '005' THEN CONVERT(VARCHAR(max), @CordX, 128) + ',' + CONVERT(VARCHAR(max), @CordY, 128)
                  WHEN '002' THEN @PhotoFileId
                  WHEN '003' THEN @VideoFileId
                  WHEN '004' THEN @DocumentFileId
                END, -- ORDR_DESC - nvarchar(max)
                @Numb , -- NUMB - int
                @MenuText,
                @UssdCode
              );
      
      L$EndMessage:
      IF @MenuText = N'*#' 
      BEGIN
         UPDATE dbo.[Order]
            SET ORDR_STAT = '004'
          WHERE CODE = @OrdrCode;
         
         DECLARE @OrdrNumb BIGINT
                ,@ServOrdrRwno BIGINT;
         
         SELECT @OrdrNumb = ORDR_NUMB
               ,@ServOrdrRwno = SERV_ORDR_RWNO
               ,@OrdrType = ORDR_TYPE
           FROM dbo.[Order]
          WHERE code = @OrdrCode;
          
         SELECT @XMessage = 
         (
            SELECT @OrdrCode AS '@code'
                  ,@Rbid AS '@roborbid'
                  ,@OrdrType '@type'
            FOR XML PATH('Order'), ROOT('Process')
         )
         EXEC Send_Order_To_Personal_Robot_Job @XMessage;
         
         SET @Message = N'کاربر گرامی پیام شما در سیستم با موفقیت ثبت شد' + CHAR(10) + N' شماره درخواست ' + CAST(@OrdrNumb AS NVARCHAR(32)) + N' جهت پیگیری در سیستم ذخیره گردیده شده است';
      END
      ELSE
         SET @Message = N'📥اطلاعات  ارسالی شما دریافت شد.
لطفا بعد از اتمام درخواست ارسالی عبارت 👈 #* را وارد کنید تا کارشناس به شما پاسخ دهد.';
      
   END 
   ELSE IF @UssdCode = '*1#'
   BEGIN
      DECLARE @FrstName NVARCHAR(250),
              @LastName NVARCHAR(250),
              @CompanyName NVARCHAR(250),
              @CellPhon NVARCHAR(11),
              @Ghid BIGINT;

      DECLARE C$Items CURSOR FOR
         SELECT Item FROM dbo.SplitString(@MenuText, '*');
      SET @Index = 0;
      OPEN [C$Items];
      L$FetchC$Item:
      FETCH NEXT FROM [C$Items] INTO @Item;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndC$Item;
      
      IF @Index = 0
         SET @FrstName = @Item;
      ELSE IF @Index = 1
         SET @LastName = @Item;
      ELSE IF @Index = 2
         SET @CompanyName = @Item;
      ELSE IF @Index = 3
         SET @CellPhon = @Item;         
      
      SET @Index += 1;
      GOTO L$FetchC$Item;
      L$EndC$Item:
      CLOSE [C$Items];
      DEALLOCATE [C$Items];
      
      IF NOT EXISTS(
         SELECT *
           FROM dbo.Group_Header
          WHERE GRPH_DESC = @CompanyName          
      )
      BEGIN
         INSERT INTO dbo.Group_Header
                 ( GRPH_DESC 
                 )
         VALUES  ( @CompanyName  -- GRPH_DESC - nvarchar(250)
                 );
         
         
      END
      
      SELECT @Ghid = GHID
        FROM dbo.Group_Header
       WHERE GRPH_DESC = @CompanyName;               
      
      IF EXISTS(
         SELECT *
           FROM dbo.Service_Robot_Public
          WHERE CHAT_ID = @ChatID
            AND SRBT_ROBO_RBID = @Rbid
            AND CELL_PHON IS NULL
      )
      BEGIN
         UPDATE dbo.Service_Robot_Public
            SET CELL_PHON = @CellPhon
               ,NAME = @LastName + N', ' + @FrstName               
               ,SERV_ADRS = ''
          WHERE CHAT_ID = @ChatID
            AND SRBT_ROBO_RBID = @Rbid
            AND CELL_PHON IS NULL;
      END      
      ELSE
      BEGIN      
         INSERT INTO Service_Robot_Public (Srbt_Serv_File_No, Srbt_Robo_Rbid, Rwno, Cell_Phon, Chat_Id, SERV_ADRS, NAME, CORD_X, CORD_Y)
		    SELECT Serv_File_No, Robo_Rbid, 0, @CellPhon, @Chatid, '', @LastName + N', ' + @FrstName, 0, 0
		      FROM Service_Robot
		     WHERE Chat_Id = @ChatId
		 	   AND Robo_Rbid = @Rbid;		
		END 
		
		UPDATE dbo.Service_Robot
		   SET GRPH_GHID = @Ghid
		WHERE CHAT_ID = @ChatID
		  AND ROBO_RBID = @Rbid;
		   
		SELECT @Message = 
	      (N'اطلاعات شماره تلفن شما برای فعال سازی ثبت گردید.');
   END  
	
	L$EndSP:
	SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END
GO
