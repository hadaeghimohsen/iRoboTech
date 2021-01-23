SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[INS_RBDC_P]
	-- Add the parameters for the stored procedure here
   @ORGN_OGID BIGINT,
	@ROBO_RBID BIGINT,
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
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>53</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 53 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT INTO dbo.Organ_Description
           ( ORGN_OGID ,
             ROBO_RBID ,
             ITEM_DESC ,
             ITEM_VALU ,
             ORDR ,
             STAT ,
             SHOW_STRT ,
             USSD_CODE
           )
   VALUES  ( @ORGN_OGID , -- ORGN_OGID - bigint
             @ROBO_RBID , -- ROBO_RBID - bigint
             @ITEM_DESC , -- ITEM_DESC - nvarchar(250)
             @ITEM_VALU , -- ITEM_VALU - nvarchar(max)
             @ORDR , -- ORDR - int
             @STAT , -- STAT - varchar(3)
             @SHOW_STRT , -- SHOW_STRT - varchar(3)
             @USSD_CODE  -- USSD_CODE - varchar(250)             
           );
END
GO
