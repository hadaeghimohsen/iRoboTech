SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_GRMU_P]
	-- Add the parameters for the stored procedure here
	@GROP_GPID BIGINT,
	@MNUS_MUID BIGINT,
	@MNUS_ROBO_RBID BIGINT,
	@STAT VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>40</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 40 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT INTO dbo.Group_Menu_Ussd
           ( GROP_GPID ,
             MNUS_MUID ,
             MNUS_ROBO_RBID ,
             STAT 
           )
   VALUES  ( @GROP_GPID , -- GROP_GPID - bigint
             @MNUS_MUID , -- MNUS_MUID - bigint
             @MNUS_ROBO_RBID , -- MNUS_ROBO_RBID - bigint
             @STAT  -- STAT - varchar(3)
           );
END
GO
