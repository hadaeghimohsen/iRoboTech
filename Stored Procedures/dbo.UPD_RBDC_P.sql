SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[UPD_RBDC_P]
	-- Add the parameters for the stored procedure here
   @ORGN_OGID BIGINT,
	@ROBO_RBID BIGINT,
	@ODID BIGINT,
	@ITEM_DESC NVARCHAR(250),
	@ITEM_VALU NVARCHAR(MAX),
	@STAT VARCHAR(3),
	@SHOW_STRT VARCHAR(3),
	@ORDR INT,
	@USSD_CODE VARCHAR(250)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>54</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 54 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   UPDATE dbo.Organ_Description
      SET ITEM_DESC = @ITEM_DESC
         ,ITEM_VALU = @ITEM_VALU
         ,ORDR = @ORDR
         ,STAT = @STAT
         ,SHOW_STRT = @SHOW_STRT
         ,USSD_CODE = @USSD_CODE
    WHERE ORGN_OGID = @ORGN_OGID
      AND ROBO_RBID = @ROBO_RBID
      AND ODID = @ODID;
END
GO
