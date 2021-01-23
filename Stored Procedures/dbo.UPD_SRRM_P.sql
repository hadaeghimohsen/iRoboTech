SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_SRRM_P]
	-- Add the parameters for the stored procedure here
	@SRBT_SERV_FILE_NO BIGINT,
	@SRBT_ROBO_RBID BIGINT,
	@RWNO BIGINT,
	@SRMG_RWNO BIGINT,
	@MESG_TEXT NVARCHAR(max),
	@SEND_STAT VARCHAR(3),
   @FILE_ID VARCHAR(200),
	@FILE_PATH NVARCHAR(MAX),
	@MESG_TYPE VARCHAR(3),
	@LAT FLOAT,
	@LON FLOAT,
	@CONT_CELL_PHON VARCHAR(11)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>62</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 62 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   IF EXISTS(
      SELECT *
        FROM dbo.Service_Robot_Replay_Message
       WHERE SRBT_SERV_FILE_NO = @SRBT_SERV_FILE_NO
         AND SRBT_ROBO_RBID = @SRBT_ROBO_RBID
         AND RWNO = @RWNO
         AND SEND_STAT = '004' -- ارسال شده
   )
   BEGIN
      RAISERROR ( N'پیام های ارسالی برای مشترکین قادر به ویرایش نیستند!', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END 
   
   UPDATE dbo.Service_Robot_Replay_Message
      SET MESG_TEXT = @MESG_TEXT
         ,SEND_STAT = @SEND_STAT
         ,FILE_ID = @FILE_ID
         ,FILE_PATH = @FILE_PATH
         ,MESG_TYPE = @MESG_TYPE
         ,LAT = @LAT
         ,LON = @LON
         ,CONT_CELL_PHON = @CONT_CELL_PHON
    WHERE SRBT_SERV_FILE_NO = @SRBT_SERV_FILE_NO
      AND SRBT_ROBO_RBID = @SRBT_ROBO_RBID
      AND RWNO = @RWNO
      AND SEND_STAT != '004' -- ارسال شده         
END
GO
