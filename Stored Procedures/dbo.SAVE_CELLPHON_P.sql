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
CREATE PROCEDURE [dbo].[SAVE_CELLPHON_P] @X XML output
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
        @CellPhon VARCHAR(13);
   
   -- بدست آوردن اطلاعات مشتری برای ثبت شماره تلفن همراه
    SELECT  @ChatId = @X.query('//Service').value('(Service/@chatid)[1]',
                                                  'BIGINT') ,
            @CellPhon = @X.query('//Service').value('(Service/@cellphon)[1]',
                                                    'VARCHAR(13)');
   
    IF NOT EXISTS ( SELECT  *
                    FROM    Service_Robot
                    WHERE   CHAT_ID = @ChatId
                            AND ROBO_RBID = @RoboRbid
                            AND ISNULL(CELL_PHON, @CellPhon) = @CellPhon )
    BEGIN
      INSERT  INTO Service_Robot_Public
      ( SRBT_SERV_FILE_NO ,
       SRBT_ROBO_RBID ,
       RWNO ,
       CELL_PHON ,
       CHAT_ID ,
       CORD_X,
       CORD_Y
      )
      SELECT  SERV_FILE_NO ,
             ROBO_RBID ,
             0 ,
             @CellPhon ,
             @ChatId ,
             0,
             0
      FROM    Service_Robot
      WHERE   CHAT_ID = @ChatId
             AND ROBO_RBID = @RoboRbid;
    END;
    ELSE
    BEGIN
      UPDATE  Service_Robot_Public
      SET     CELL_PHON = @CellPhon
      WHERE   CHAT_ID = @ChatId
        AND SRBT_ROBO_RBID = @RoboRbid
        AND RWNO = ( SELECT MAX(RWNO)
                     FROM   Service_Robot_Public T
                     WHERE  T.SRBT_SERV_FILE_NO = SRBT_SERV_FILE_NO
                            AND T.SRBT_ROBO_RBID = SRBT_ROBO_RBID
                            AND T.CHAT_ID = @ChatId
                   );
    END; 
    
    DECLARE @Message NVARCHAR(max);
    
    SELECT @Message = 
	      (N'اطلاعات شماره تلفن شما برای فعال سازی ثبت گردید.'); 
   
    L$EndSP:   
   SET @X = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @X.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END;
GO
