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
 PROCEDURE [dbo].[HamraheShabake_Analisis_Message_P]
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
           @Name NVARCHAR(100),
           @Numb NVARCHAR(100),
           @Index BIGINT = 0,
           @Token VARCHAR(100),
           @Rbid BIGINT;
	
	SELECT @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]', 'VARCHAR(250)'),
	       @Token = @X.query('/Robot').value('(Robot/@token)[1]', 'VARCHAR(100)'),
	       @ChildUssdCode = @X.query('//Message').value('(Message/@childussd)[1]', 'VARCHAR(250)'),    
	       @ChatID   = @X.query('//Message').value('(Message/@chatid)[1]', 'BIGINT'),	       
	       @ElmnType   = @X.query('//Message').value('(Message/@elmntype)[1]', 'VARCHAR(3)'),	       
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

   IF @UssdCode IN ( '*0#', '*1*1#', '*1*2#', '*2#' )
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
         SET @Name = @Item;
      ELSE IF @Index = 1
         SET @Numb = @Item;
      
      SET @Index += 1;
      GOTO L$FetchC$Item;
      L$EndC$Item:
      CLOSE [C$Items];
      DEALLOCATE [C$Items];
      
      -- CHECK Validation
      IF @Name IS NULL OR @Numb IS NULL
      BEGIN
         SET @Message = N'کاربر گرامی اطلاعات را درست وارد نکرده اید لطفا طبق دستورالعمل اطلاعات را وارد کنید';
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
	              @Rbid,
	              SRPB_RWNO,
	              '010',
	              GETDATE(),
	              '001' -- ثبت مرحله اولیه
	         FROM dbo.Service_Robot
	        WHERE CHAT_ID = @chatid
	          AND ROBO_RBID = @Rbid;
	      
      DECLARE @OrdrCode BIGINT
             ,@OrdrType VARCHAR(3);
      
      SELECT @OrdrCode = MAX(CODE),
             @OrdrType = ORDR_TYPE
        FROM dbo.[Order] o, dbo.Service_Robot sr
       WHERE o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
         AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
         AND sr.CHAT_ID = @ChatId
         AND Sr.ROBO_RBID = @Rbid
         AND o.ORDR_TYPE = '010'
         GROUP BY ORDR_TYPE;
      
      INSERT dbo.Order_Detail
              ( ORDR_CODE ,
                ELMN_TYPE ,
                ORDR_DESC ,
                NUMB ,
                ORDR_CMNT
              )
      VALUES  ( @OrdrCode , -- ORDR_CODE - bigint
                @ElmnType , -- ELMN_TYPE - varchar(3)
                CASE @ElmnType 
                  WHEN '001' THEN @Name
                  WHEN '005' THEN CONVERT(VARCHAR(max), @CordX, 128) + ',' + CONVERT(VARCHAR(max), @CordY, 128)
                  WHEN '002' THEN @PhotoFileId
                  WHEN '003' THEN @VideoFileId
                  WHEN '004' THEN @DocumentFileId
                END, -- ORDR_DESC - nvarchar(max)
                @Numb , -- NUMB - int
                CASE @UssdCode
                  WHEN '*0#' THEN N'معرفی کانال واتس آپ'
                  WHEN '*1*1#' THEN N'معرفی کانال تلگرام'
                  WHEN '*1*2#' THEN N'معرفی گروه تلگرام'
                  WHEN '*2#' THEN N'معرفی کانال اینستاگرام'                  
                END
              );
      
      SELECT @XMessage = 
      (
         SELECT @OrdrCode AS '@code'
               ,@Rbid AS '@roborbid'
               ,@OrdrType '@type'
         FOR XML PATH('Order'), ROOT('Process')
      )
      EXEC Send_Order_To_Personal_Robot_Job @XMessage;
      
      SET @Message = N'کاربر گرامی پیام شما در سیستم با موفقیت ثبت شد';
   END   
	
	L$EndSP:
	SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END
GO
