SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_GROP_P]
	-- Add the parameters for the stored procedure here
	@GPID BIGINT,
	@ROBO_RBID BIGINT,
	@NAME NVARCHAR(200),
	@STAT VARCHAR(3),
	@AUTO_JOIN VARCHAR(3),
	@ADMN_ORGN VARCHAR(3),
	@Off_Prct INT
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>45</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 45 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   UPDATE dbo.[Group]
      SET NAME = @NAME
         ,STAT = @STAT
         ,AUTO_JOIN = @AUTO_JOIN
         ,ADMN_ORGN = @ADMN_ORGN
         ,OFF_PRCT = ISNULL(@Off_Prct, 0)
    WHERE GPID = @GPID
      AND ROBO_RBID = @ROBO_RBID;
      
END
GO
