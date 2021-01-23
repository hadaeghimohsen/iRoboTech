SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_SRRM_P]
	-- Add the parameters for the stored procedure here
	@SRBT_SERV_FILE_NO BIGINT,
	@SRBT_ROBO_RBID BIGINT,
	@RWNO BIGINT
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>63</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 63 سطوح امینتی', -- Message text.
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
      RAISERROR ( N'پیام های ارسالی برای مشترکین قادر به حذف نیستند!', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END 
   
   DELETE dbo.Service_Robot_Replay_Message
    WHERE SRBT_SERV_FILE_NO = @SRBT_SERV_FILE_NO
      AND SRBT_ROBO_RBID = @SRBT_ROBO_RBID
      AND RWNO = @RWNO
      AND SEND_STAT != '004' -- ارسال شده
END
GO
