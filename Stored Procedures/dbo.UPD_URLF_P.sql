SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_URLF_P]
	-- Add the parameters for the stored procedure here
	@FGA_CODE BIGINT,
	@USER_NAME VARCHAR(250),
	@HOST_NAME VARCHAR(50),
	@STAT VARCHAR(3),
	@STRT_DATE DATE,
	@END_DATE DATE,
	@ACES_TYPE VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>70</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 70 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   IF @ACES_TYPE = '001'
   BEGIN
      SELECT @STRT_DATE = NULL, @END_DATE = NULL;
   END 
   -- پایان دسترسی
   UPDATE dbo.User_RobotListener_Fgac
      SET USER_NAME = @USER_NAME
         ,HOST_NAME = @HOST_NAME
         ,STAT = @STAT
         ,STRT_DATE = @STRT_DATE
         ,END_DATE = @END_DATE
         ,ACES_TYPE = @ACES_TYPE
    WHERE FGA_CODE = @FGA_CODE;
END
GO
