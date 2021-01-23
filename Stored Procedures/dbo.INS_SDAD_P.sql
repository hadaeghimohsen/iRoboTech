SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_SDAD_P]
	-- Add the parameters for the stored procedure here
	@ROBO_RBID BIGINT,
	@ORDR_CODE BIGINT,
	@ID BIGINT,
	@PAKT_TYPE VARCHAR(3),
	@FILE_ID VARCHAR(200),
	@TRGT_PROC_STAT VARCHAR(3),
	@TEXT_MESG NVARCHAR(max),
	@INLN_KEYB_DNRM XML
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>65</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 65 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   -- چک کردن اینکه آیا می توان رکورد را حذف کنیم
   INSERT INTO dbo.Send_Advertising
           ( ROBO_RBID ,
             ORDR_CODE,
             ID ,
             PAKT_TYPE ,
             TEXT_MESG ,
             FILE_ID ,
             STAT,
             TRGT_PROC_STAT,
             INLN_KEYB_DNRM
           )
   VALUES  ( @ROBO_RBID , -- ROBO_RBID - bigint
             @ORDR_CODE,
             0 , -- ID - bigint
             @PAKT_TYPE , -- PAKT_TYPE - varchar(3)
             @TEXT_MESG , -- TEXT_MESG - nvarchar(max)
             @FILE_ID , -- FILE_ID - varchar(200)
             '002',  -- STAT - varchar(3)
             @TRGT_PROC_STAT,
             @INLN_KEYB_DNRM
           );
END
GO
