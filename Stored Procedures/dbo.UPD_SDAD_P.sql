SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_SDAD_P]
	-- Add the parameters for the stored procedure here
	@ROBO_RBID BIGINT,
	@ORDR_CODE BIGINT,
	@ID BIGINT,
	@PAKT_TYPE VARCHAR(3),
	@FILE_ID VARCHAR(200),
	@TEXT_MESG NVARCHAR(max),
	@ORDR INT,
	@STAT VARCHAR(3),
	@TRGT_PROC_STAT VARCHAR(3),
	@INLN_KEYB_DNRM XML
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>66</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 66 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   -- چک کردن اینکه آیا می توان رکورد را بروزرسانی کنیم
   IF EXISTS(
      SELECT * 
        FROM dbo.Send_Advertising
       WHERE ROBO_RBID = @ROBO_RBID
         AND ID = @ID
         AND ( STAT = '004' -- ارسال شده باشد
          /*OR ( STAT = '005' -- در صف ارسال باشد و حداقل یک پیام به صورت موفقیت آمیز به دست مشترک رسیده باشد
           AND EXISTS(
                  SELECT * 
                    FROM dbo.Service_Robot_Send_Advertising a
                   WHERE a.SRBT_ROBO_RBID = @ROBO_RBID
                     AND a.SDAD_ID = ID
                     AND a.SEND_STAT = '004'
               )
           )*/
         )
   )
   BEGIN
      RAISERROR ( N'پیام های ارسال شده و یا در صف ارسال که حداقل برای یک نفر به صورت کامل ارسال شده باشد دیگر قادر به ویرایش نیستید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END;
   
   UPDATE dbo.Send_Advertising
      SET PAKT_TYPE = @PAKT_TYPE
         ,FILE_ID = @FILE_ID
         ,TEXT_MESG = @TEXT_MESG
         ,ORDR = @ORDR
         ,STAT = @STAT
         ,TRGT_PROC_STAT = @TRGT_PROC_STAT
         ,ORDR_CODE = @ORDR_CODE
         ,INLN_KEYB_DNRM = @INLN_KEYB_DNRM
    WHERE ROBO_RBID = @ROBO_RBID
      AND ID = @ID;
END
GO
