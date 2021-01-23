SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
   Save Cellphone for Service
   <Robot token="">
      <Order type="001" chatid="">               
         ...
      </Order>
   </Robot>
*/
CREATE PROCEDURE [dbo].[SAVE_ORDR_P] 
   @X XML OUTPUT  
AS
BEGIN
    DECLARE @RoboToken VARCHAR(100), @RoboRbid BIGINT;
   
   -- بدست آوردن توکن ربات
    SELECT  @RoboToken = @X.query('Robot').value('(Robot/@token)[1]', 'VARCHAR(100)');
   
   -- بدست آوردن شماره ربات
    SELECT  @RoboRbid = RBID
    FROM    dbo.Robot
    WHERE   TKON_CODE = @RoboToken;
   
    DECLARE @ChatId BIGINT ,
        @OrdrType VARCHAR(3),
        @OrdrDesc NVARCHAR(MAX),
        @ElmnTYpe VARCHAR(3),
        @Fileid VARCHAR(MAX),
        @UssdCode VARCHAR(250),
        @ChildUssdCode VARCHAR(250);
   
   -- بدست آوردن اطلاعات مشتری برای ثبت شماره تلفن همراه
    SELECT  @ChatId = @X.query('//Order').value('(Order/@chatid)[1]', 'BIGINT') ,
            @OrdrType = @X.query('//Order').value('(Order/@type)[1]', 'VARCHAR(3)'),
            @ElmnTYpe = @X.query('//Order').value('(Order/@elmntype)[1]', 'VARCHAR(3)'),
            @FileId = @X.query('//Order').value('(Order/@fileid)[1]', 'VARCHAR(250)'),
            @UssdCode = @X.query('//Order').value('(Order/@ussdcode)[1]', 'VARCHAR(250)'),
            @ChildUssdCode = @X.query('//Order').value('(Order/@childussdcode)[1]', 'VARCHAR(250)'),
            @OrdrDesc = @X.query('//Order').value('.', 'NVARCHAR(MAX)');
   
    DECLARE @Message NVARCHAR(max);   

	  IF (UPPER(@OrdrDesc) IN ( '/START' ) OR LEN(@OrdrDesc) <= 10 ) AND @OrdrDesc != N'بازگشت 🔺'
	  BEGIN
	     SET @Message = N'کاربر گرامی متن ورودی شما مجاز به ثبت نیست. برای ثبت اطلاعات باید حداقل بیش از 10 کاراکتر باشد';
		  GOTO L$EndSP;
	  END
	  
	  IF @OrdrDesc = N'بازگشت 🔺'
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
              @RoboRbid,
              SRPB_RWNO,
              @OrdrType,
              GETDATE(),
              '001', -- ثبت مرحله اولیه
              @ChatId
         FROM dbo.Service_Robot
        WHERE CHAT_ID = @chatid
          AND ROBO_RBID = @RoboRbid;
      
      DECLARE @OrdrCode BIGINT;
      
      SELECT @OrdrCode = MAX(CODE),
             @OrdrType = ORDR_TYPE
        FROM dbo.[Order] o, dbo.Service_Robot sr
       WHERE o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
         AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
         AND sr.CHAT_ID = @ChatId
         AND Sr.ROBO_RBID = @RoboRbid
         AND o.ORDR_TYPE = @OrdrType
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
                  WHEN '001' THEN @OrdrDesc
                  --WHEN '005' THEN CONVERT(VARCHAR(max), @CordX, 128) + ',' + CONVERT(VARCHAR(max), @CordY, 128)
                  WHEN '002' THEN @Fileid
                  WHEN '003' THEN @FileId
                  WHEN '004' THEN @FileId
                END, -- ORDR_DESC - nvarchar(max)
                0,  -- NUMB - int
                @UssdCode,
                @ChildUssdCode
              );
      
      DECLARE @XMessage XmL
      SELECT @XMessage = 
      (
         SELECT @OrdrCode AS '@code'
               ,@RoboRbid AS '@roborbid'
               ,@OrdrType '@type'
         FOR XML PATH('Order'), ROOT('Process')
      )
      EXEC Send_Order_To_Personal_Robot_Job @XMessage;
      SET @Message = N'📥 اطلاعات با موفقید ثبت شد';
   
   L$EndSP:   
   SET @X = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @X.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
	    
END;
GO
