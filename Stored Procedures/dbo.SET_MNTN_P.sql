SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE PROCEDURE [dbo].[SET_MNTN_P]
	@X XML
AS
BEGIN
   /*
      <TemplateToText fileno="" tmid=""/>
   */
	DECLARE @OrdrCode BIGINT
	       ,@RoboRbid BIGINT
	       ,@PrjbCode BIGINT
	       ,@OrdrType VARCHAR(3)
	       ,@Text NVARCHAR(4000);
	
	SELECT @OrdrCode = @X.query('//Mention').value('(Mention/@ordrcode)[1]', 'BIGINT')
	      ,@RoboRbid = @X.query('//Mention').value('(Mention/@roborbid)[1]', 'BIGINT');
	
	SELECT @Text = (
	   SELECT ORDR_DESC + CHAR(10)
	     FROM dbo.Order_Detail
	    WHERE ORDR_CODE = @OrdrCode
	      AND ELMN_TYPE = '001'
	      FOR XML PATH('')
	);
	
	SELECT @OrdrType = ORDR_TYPE
	  FROM dbo.[Order]
	 WHERE CODE = @OrdrCode;
	
   -- Process on Text Template
   DECLARE @PlaceHolder VARCHAR(2)
          ,@NumbOfPlaceHolder INT
          ,@Xp XML;
   
   SET @PlaceHolder = N'@';
   SELECT @NumbOfPlaceHolder = (len(@Text) - len(replace(@Text,@PlaceHolder,''))) / LEN(@PlaceHolder);
   
   DECLARE @i INT = 0;
   
   DECLARE @PlaceHolderItem NVARCHAR(100)
          ,@StartOpenPosition INT = 0
          ,@StartClosePosition INT = 0;
   WHILE @i < @NumbOfPlaceHolder
   BEGIN
      SELECT @PlaceHolderItem = 
         SUBSTRING(
            @Text,
            CHARINDEX(N'@', @Text, @StartOpenPosition),
            CHARINDEX(N'#', @Text, @StartClosePosition) - CHARINDEX(N'@', @Text, @StartOpenPosition) + 1
         );
      
      -- بدست آوردن کاربری که پیام برای آن باید ارسال شود
      SELECT TOP 1 @PrjbCode = prj.CODE
        FROM dbo.Personal_Robot pr, dbo.Personal_Robot_Job prj, dbo.Job j      
       WHERE pr.SERV_FILE_NO = prj.PRBT_SERV_FILE_NO
         AND pr.ROBO_RBID = prj.PRBT_ROBO_RBID
         AND prj.JOB_CODE = j.CODE
         AND j.ORDR_TYPE = @OrdrType
         AND pr.ROBO_RBID = @RoboRbid
         AND pr.USER_NAME + '#' = @PlaceHolderItem;
      
      -- Save Message For Personel 
      IF @PrjbCode IS NOT NULL AND NOT EXISTS(
         SELECT *
           FROM dbo.Personal_Robot_Job_Order
          WHERE PRJB_CODE = @PrjbCode
            AND ORDR_CODE = @OrdrCode
      )
      BEGIN
         INSERT INTO dbo.Personal_Robot_Job_Order
                 ( PRJB_CODE ,
                   ORDR_CODE ,
                   ORDR_STAT 
                 )
         VALUES  ( @PrjbCode , -- PRJB_CODE - bigint
                   @OrdrCode , -- ORDR_CODE - bigint
                   '001'  -- ORDR_STAT - varchar(3)
                 );
      end
      
      
      -- Get Next Position Start {
      SET @StartOpenPosition = CHARINDEX(N'@', @Text, @StartOpenPosition) + 1;
      -- Get Next Position Start }
      SET @StartClosePosition = CHARINDEX(N'#', @Text, @StartClosePosition) + 1;
      SET @i += 1;
   END;  
END
GO
