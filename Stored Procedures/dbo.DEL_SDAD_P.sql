SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_SDAD_P]
	-- Add the parameters for the stored procedure here
	@ROBO_RBID BIGINT,
	@ID BIGINT
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>67</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 67 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   -- چک کردن اینکه آیا می توان رکورد را حذف کنیم
   IF EXISTS(
      SELECT * 
        FROM dbo.Send_Advertising
       WHERE ROBO_RBID = @ROBO_RBID
         AND ID = @ID
         AND ( STAT = '004' -- ارسال شده باشد
          OR ( STAT = '005' -- در صف ارسال باشد و حداقل یک پیام به صورت موفقیت آمیز به دست مشترک رسیده باشد
           AND EXISTS(
                  SELECT * 
                    FROM dbo.Service_Robot_Send_Advertising a
                   WHERE a.SRBT_ROBO_RBID = @ROBO_RBID
                     AND a.SDAD_ID = ID
                     AND a.SEND_STAT = '004'
               )
           )
         )
   )
   BEGIN
      RAISERROR ( N'پیام های ارسال شده و یا در صف ارسال که حداقل برای یک نفر به صورت کامل ارسال شده باشد دیگر قادر به حذف نیستید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END;
   
   -- حذف رکورد   
   DELETE dbo.Send_Advertising
    WHERE ROBO_RBID = @ROBO_RBID
      AND ID = @ID;    
END
GO
