SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_RBKN_P]
	-- Add the parameters for the stored procedure here   
	@ROBO_RBID BIGINT,
	@ID BIGINT,
	@TEXT_TYPE NVARCHAR(MAX),
	@SNDR NVARCHAR(MAX),
	@TEXT_TITL NVARCHAR(MAX),
	@TEXT_ANSR NVARCHAR(MAX),
	@CHNL_URL VARCHAR(MAX),
	@STAT VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>57</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 57 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   UPDATE dbo.Robot_Import
      SET STAT = @STAT
         ,TEXT_TYPE = @TEXT_TYPE
         ,SNDR = @SNDR
         ,TEXT_TITL = @TEXT_TITL
         ,TEXT_ANSR = @TEXT_ANSR
         ,CHNL_URL = @CHNL_URL
     WHERE ROBO_RBID = @ROBO_RBID
       AND ID = @ID;
END
GO
