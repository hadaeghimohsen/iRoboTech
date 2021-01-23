SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_JOB_P]
	-- Add the parameters for the stored procedure here
	@ROBO_RBID BIGINT,
	@CODE BIGINT,
   @ORDR_TYPE VARCHAR(3),
   @JOB_DESC NVARCHAR(250),
   @IS_FRST_FIRE VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>28</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 28 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   UPDATE dbo.Job
      SET ORDR_TYPE = @ORDR_TYPE
         ,JOB_DESC = @JOB_DESC
         ,IS_FRST_FIRE = @IS_FRST_FIRE
    WHERE ROBO_RBID = @ROBO_RBID
      AND Code = @CODE;         
END
GO
