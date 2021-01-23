SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Send_Order_To_Personal_Robot_Job]
	-- Add the parameters for the stored procedure here
	@X XML
AS
   /*
      <Order code="0" roborbid="1" type="001">
      </Order>
   */
BEGIN
	DECLARE @OrdrCode BIGINT
	       ,@RoboRbid BIGINT
	       ,@OrdrType VARCHAR(3)
	       ,@DirPrjbCode BIGINT;

	
	
	SELECT @OrdrCode = @X.query('//Order').value('(Order/@code)[1]', 'BIGINT')
	      ,@RoboRbid = @X.query('//Order').value('(Order/@roborbid)[1]', 'BIGINT')
	      ,@OrdrType = @X.query('//Order').value('(Order/@type)[1]', 'VARCHAR(3)')
	      ,@DirPrjbCode = @X.query('//Order').value('(Order/@dirprjbcode)[1]', 'BIGINT');
	
	DECLARE @JobCode BIGINT
	       ,@ChatID BIGINT
	       ,@ServFileNo BIGINT
	       ,@PrjbCode BIGINT
	       ,@SeqNumb INT
	       ,@NextSeqNumb INT
	       ,@FirstSeqNumb INT;
	
	SELECT TOP 1 @JobCode = Code
	  FROM Job
	 WHERE ORDR_TYPE = @OrdrType
	   AND ROBO_RBID = @RoboRbid;
	
   -- اگر مشتری در لیست یکی از پرسنل های شرکت باشد پیام به دست همان پرسنل ارسال میشود
	IF EXISTS(
	   SELECT *
	     FROM dbo.Personal_Robot_Job_Service_Robot a, dbo.Personal_Robot_Job b, dbo.Job e, dbo.[Order] c, dbo.Service_Robot d
	    WHERE a.PRJB_CODE = b.CODE
	      AND b.JOB_CODE = e.CODE
	      AND c.ORDR_TYPE = e.ORDR_TYPE
	      AND c.SRBT_SERV_FILE_NO = d.SERV_FILE_NO
	      AND c.SRBT_ROBO_RBID = d.ROBO_RBID
	      AND a.SRBT_SERV_FILE_NO = c.SRBT_SERV_FILE_NO
	      AND a.SRBT_ROBO_RBID = c.SRBT_ROBO_RBID	 
	      AND d.ROBO_RBID = @RoboRbid
	      AND c.CODE = @OrdrCode  
	      AND e.ORDR_TYPE = @OrdrType   
	)
	BEGIN
	   SELECT TOP 1 @PrjbCode = b.CODE
	     FROM dbo.Personal_Robot_Job_Service_Robot a, dbo.Personal_Robot_Job b, dbo.Job e, dbo.[Order] c, dbo.Service_Robot d
	    WHERE a.PRJB_CODE = b.CODE
	      AND b.JOB_CODE = e.CODE
	      AND c.ORDR_TYPE = e.ORDR_TYPE
	      AND c.SRBT_SERV_FILE_NO = d.SERV_FILE_NO
	      AND c.SRBT_ROBO_RBID = d.ROBO_RBID
	      AND a.SRBT_SERV_FILE_NO = c.SRBT_SERV_FILE_NO
	      AND a.SRBT_ROBO_RBID = c.SRBT_ROBO_RBID	      
	      AND d.ROBO_RBID = @RoboRbid
	      AND c.CODE = @OrdrCode  
	      AND e.ORDR_TYPE = @OrdrType;
	   
	   GOTO L$INS_PRJO;
	END
	ELSE IF @DirPrjbCode IS NOT NULL
	BEGIN
	   SET @PrjbCode = @DirPrjbCode;
	   GOTO L$INS_PRJO;
	END
		
	-- اگر شغلی وجود نداشته باشد
	IF @JobCode IS NULL 
	BEGIN
	   -- Check Admin Personal
	   L$CheckAdminPersonal:
	   IF EXISTS(
	      SELECT *
	        FROM dbo.Admin A, dbo.Robot R, dbo.Service_Robot Sr
	       WHERE A.ORGN_OGID = R.ORGN_OGID
	         AND R.RBID = @RoboRbid
	         AND A.SERV_FILE_NO = Sr.SERV_FILE_NO
	         AND R.RBID = Sr.ROBO_RBID
	         AND A.STAT = '002'
	         AND Sr.STAT = '002'
	   )
	   BEGIN	   
	      SELECT TOP 1 @ChatId = Sr.CHAT_ID
	            ,@ServFileNo = Sr.SERV_FILE_NO
	        FROM dbo.Admin A, dbo.Robot R, dbo.Service_Robot Sr
	       WHERE A.ORGN_OGID = R.ORGN_OGID
	         AND R.RBID = @RoboRbid
	         AND A.SERV_FILE_NO = Sr.SERV_FILE_NO
	         AND R.RBID = Sr.ROBO_RBID
	         AND A.STAT = '002'
	         AND Sr.STAT = '002';
   	    
   	    MERGE dbo.Personal_Robot T
   	    USING(SELECT * FROM dbo.Personal_Robot WHERE SERV_FILE_NO = @ServFileNo AND ROBO_RBID = @RoboRbid) S
   	    ON (T.SERV_FILE_NO = S.SERV_FILE_NO AND
   	        T.ROBO_RBID = S.ROBO_RBID)
   	    WHEN NOT MATCHED THEN   	      
	          INSERT ( SERV_FILE_NO ,
	                    ROBO_RBID ,
	                    STAT ,
	                    CHAT_ID
	                  )
	          VALUES  ( @ServFileNo , -- SERV_FILE_NO - bigint
	                    @RoboRbid , -- ROBO_RBID - bigint
	                    '002' , -- STAT - varchar(3)
	                    @ChatId  -- CHAT_ID - bigint
	                  )
	       WHEN MATCHED THEN
	         UPDATE
	            SET STAT = '002'
	               ,Chat_Id = @ChatId;
	      
	      MERGE dbo.Job T
	      USING (SELECT * FROM dbo.Job WHERE ROBO_RBID = @RoboRbid AND ORDR_TYPE = @OrdrType) S
	      ON (T.ROBO_RBID = S.ROBO_RBID AND
	          T.ORDR_TYPE = S.ORDR_TYPE
	      ) 
	      WHEN NOT MATCHED THEN
	         INSERT (ROBO_RBID, ORDR_TYPE, JOB_DESC)
	         VALUES (@roborbid, @OrdrType, (SELECT DOMN_DESC FROM dbo.D$ORDT WHERE VALU = @OrdrType));
	      
	      SELECT TOP 1 @JobCode = Code
	        FROM Job
	       WHERE ORDR_TYPE = @OrdrType
	         AND ROBO_RBID = @RoboRbid;   
	      
	      MERGE dbo.Personal_Robot_Job T
   	    USING(SELECT * FROM dbo.Personal_Robot_Job WHERE PRBT_SERV_FILE_NO = @ServFileNo AND PRBT_ROBO_RBID = @RoboRbid) S
   	    ON (T.Prbt_SERV_FILE_NO = S.Prbt_SERV_FILE_NO AND
   	        T.Prbt_ROBO_RBID = S.Prbt_ROBO_RBID AND
   	        T.JOB_CODE = S.JOB_CODE)
   	    WHEN NOT MATCHED THEN   	      
	          INSERT (  Prbt_SERV_FILE_NO ,
	                    Prbt_ROBO_RBID ,
	                    JOB_CODE,
	                    STAT ,
	                    SEQ_NUMB,
	                    BUSY_TYPE
	                  )
	          VALUES  ( @ServFileNo , -- SERV_FILE_NO - bigint
	                    @RoboRbid , -- ROBO_RBID - bigint
	                    @JobCode,
	                    '002' , -- STAT - varchar(3)
	                    1,
	                    '001'  -- CHAT_ID - bigint
	                  )
	       WHEN MATCHED THEN
	         UPDATE
	            SET STAT = '002';
	       
	       SELECT TOP 1 @PrjbCode = CODE
	         FROM dbo.Personal_Robot_Job
	        WHERE PRBT_SERV_FILE_NO = @ServFileNo
	          AND PRBT_ROBO_RBID = @RoboRbid
	          AND JOB_CODE = @JobCode
	          AND STAT = '002';
	       
		   IF @PrjbCode IS NULL RETURN;
		      
	       INSERT INTO dbo.Personal_Robot_Job_Order
	               ( PRJB_CODE, ORDR_CODE, ORDR_STAT )
	       VALUES  ( @PrjbCode, -- PRJB_CODE - bigint
	                 @OrdrCode,  -- ORDR_CODE - bigint
	                 '001' -- مرحبه اولیه
	                );
	   END;
	   GOTO L$INS_MNTN;
	END
	
	-- بدست آوردن پرسنل برای جوابگویی این گونه درخواست ها      
	IF NOT EXISTS(
	   SELECT *
	     FROM dbo.Personal_Robot_Job
	    WHERE PRBT_ROBO_RBID = @RoboRbid
	      AND JOB_CODE = @JobCode
	      AND STAT = '002'
	) 
	   GOTO L$CheckAdminPersonal;
	
	IF (
	   SELECT COUNT(*)
        FROM dbo.Personal_Robot_Job
       WHERE PRBT_ROBO_RBID = @RoboRbid
         AND JOB_CODE = @JobCode
         AND STAT = '002'
   ) = 1
   BEGIN
      UPDATE dbo.Personal_Robot_Job
         SET BUSY_TYPE = '002'
            ,SEQ_NUMB = 1
       WHERE PRBT_ROBO_RBID = @RoboRbid
         AND JOB_CODE = @JobCode
         AND STAT = '002'
         AND BUSY_TYPE <> '002';
         
      SELECT @PrjbCode = Code
        FROM dbo.Personal_Robot_Job
       WHERE PRBT_ROBO_RBID = @RoboRbid
         AND JOB_CODE = @JobCode
         AND STAT = '002'
         AND BUSY_TYPE = '002';
	END
	ELSE
	BEGIN
	   SELECT TOP 1 @SeqNumb = SEQ_NUMB, @PrjbCode = CODE
        FROM dbo.Personal_Robot_Job
       WHERE PRBT_ROBO_RBID = @RoboRbid
         AND JOB_CODE = @JobCode
         AND STAT = '002'
         AND BUSY_TYPE = '002';
       
       -- آزاد کردن پرسنل
       UPDATE dbo.Personal_Robot_Job
         SET BUSY_TYPE = '001'
        WHERE PRBT_ROBO_RBID = @RoboRbid
         AND JOB_CODE = @JobCode
         AND CODE = @PrjbCode
         AND STAT = '002'
         AND BUSY_TYPE = '002';
       
       SELECT @NextSeqNumb = MAX(SEQ_NUMB)
             ,@FirstSeqNumb = MIN(SEQ_NUMB)
        FROM dbo.Personal_Robot_Job
       WHERE PRBT_ROBO_RBID = @RoboRbid
         AND JOB_CODE = @JobCode
         AND STAT = '002';         
       
       IF(@SeqNumb < @NextSeqNumb)
         UPDATE dbo.Personal_Robot_Job
            SET BUSY_TYPE = '002'
          WHERE PRBT_ROBO_RBID = @RoboRbid
            AND JOB_CODE = @JobCode
            AND STAT = '002'
            AND SEQ_NUMB = (
               SELECT MIN(SEQ_NUMB) 
                 FROM Personal_Robot_Job T 
                WHERE T.PRBT_ROBO_RBID = @RoboRbid
                  AND T.JOB_CODE = @JobCode
                  AND T.STAT = '002'
                  AND T.SEQ_NUMB > @SeqNumb
            );
         ELSE
            UPDATE dbo.Personal_Robot_Job
               SET BUSY_TYPE = '002'
             WHERE PRBT_ROBO_RBID = @RoboRbid
               AND JOB_CODE = @JobCode
               AND STAT = '002'
               AND SEQ_NUMB = @FirstSeqNumb;
	END	
	
	IF @PrjbCode IS NULL RETURN;
   
   L$INS_PRJO:
   
	INSERT INTO dbo.Personal_Robot_Job_Order
	        ( PRJB_CODE, ORDR_CODE, ordr_Stat )
	VALUES  ( @PrjbCode, -- PRJB_CODE - bigint
	          @OrdrCode,  -- ORDR_CODE - bigint
	          '001' -- مرحله اولیه
	          );
	
	L$INS_MNTN:
	-- 1396/08/02 * 12:16PM * اگر در اطلاعات وارد شده از درخواست نام کاربری وارد شده باشد یک پیام برای کاربر هم باید ارسال شود
	DECLARE @Message XML;
	SELECT @Message = (
	   SELECT @OrdrCode AS '@ordrcode',
	          @RoboRbid AS '@roborbid'
	     FOR XML PATH('Mention')
	);
	
	EXEC dbo.SET_MNTN_P @X = @Message -- xml
	
END
GO
