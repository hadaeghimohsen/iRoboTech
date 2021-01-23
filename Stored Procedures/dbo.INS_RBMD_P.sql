SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_RBMD_P]
	-- Add the parameters for the stored procedure here
   @ORGN_OGID BIGINT,
	@ROBO_RBID BIGINT,
	@OPID BIGINT,
	@IMAG_DESC NVARCHAR(MAX),
	@STAT VARCHAR(3),
	@IMAG_TYPE VARCHAR(3),
	@FILE_ID VARCHAR(MAX),
	@SHOW_STRT VARCHAR(3),
	@ORDR INT,
	@USSD_CODE VARCHAR(250),
	@PRDC_CODE VARCHAR(50),
	@EXPN_PRIC BIGINT,
	@Rbcn_Type VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>50</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 50 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT INTO dbo.Organ_Media
           ( ORGN_OGID ,
             ROBO_RBID ,
             IMAG_DESC ,
             STAT ,
             IMAG_TYPE ,
             FILE_ID ,
             SHOW_STRT ,
             ORDR ,
             USSD_CODE ,
             PRDC_CODE ,
             EXPN_PRIC ,
             RBCN_TYPE
           )
   VALUES  ( @ORGN_OGID , -- ORGN_OGID - bigint
             @ROBO_RBID , -- ROBO_RBID - bigint
             @IMAG_DESC , -- IMAG_DESC - nvarchar(max)
             @STAT , -- STAT - varchar(3)
             @IMAG_TYPE , -- IMAG_TYPE - varchar(3)
             @FILE_ID , -- FILE_ID - varchar(max)
             @SHOW_STRT , -- SHOW_STRT - varchar(3)
             @ORDR , -- ORDR - int
             @USSD_CODE , -- USSD_CODE - varchar(250)
             @PRDC_CODE , -- PRDC_CODE - varchar(50)
             @EXPN_PRIC,
             @Rbcn_Type
           );
END
GO
