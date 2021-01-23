SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
   Save Cellphone for Service
   <Robot token="">
      <Request rqtpcode="01" rqtpdesc="save cellphone for service">
         <Service chatid="" cellphon="+989033927103"/>
      </Request>
   </Robot>
*/
CREATE PROCEDURE [dbo].[SAVE_CORDXY_P] @X XML
AS
BEGIN
    DECLARE @RoboToken VARCHAR(100) ,
        @RoboRbid BIGINT;
   
   -- بدست آوردن توکن ربات
    SELECT  @RoboToken = @X.query('Robot').value('(Robot/@token)[1]',
                                                 'VARCHAR(100)');
   
   -- بدست آوردن شماره ربات
    SELECT  @RoboRbid = RBID
    FROM    dbo.Robot
    WHERE   TKON_CODE = @RoboToken;
   
    DECLARE @ChatId BIGINT ,
        @CordX FLOAT,
        @CordY Float;
   
   -- بدست آوردن اطلاعات مشتری برای ثبت شماره تلفن همراه
    SELECT  @ChatId = @X.query('//Service').value('(Service/@chatid)[1]',
                                                  'BIGINT') ,
            @CordX = @X.query('//Service').value('(Service/@cordx)[1]', 'FLOAT'),
            @CordY = @X.query('//Service').value('(Service/@cordy)[1]', 'FLOAT');
   
   UPDATE  Service_Robot_Public
   SET     CORD_X = @CordX
          ,CORD_Y = @CordY
   WHERE   CHAT_ID = @ChatId
     AND SRBT_ROBO_RBID = @RoboRbid
     AND RWNO = ( SELECT MAX(RWNO)
                  FROM   Service_Robot_Public T
                  WHERE  T.SRBT_SERV_FILE_NO = SRBT_SERV_FILE_NO
                         AND T.SRBT_ROBO_RBID = SRBT_ROBO_RBID
                         AND T.CHAT_ID = @ChatId
                );

    DECLARE @Message NVARCHAR(max);
    
    SELECT @Message = 
	      (N'اطلاعات آدرس شما ثبت گردید.'); 
   
    L$EndSP:   
   SET @X = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @X.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END;
GO
