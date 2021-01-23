SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_SRGP_P]
	-- Add the parameters for the stored procedure here
	@GROP_GPID BIGINT,
	@SRBT_SERV_FILE_NO BIGINT,
	@SRBT_ROBO_RBID BIGINT,
	@STAT VARCHAR(3) ,
	@Dflt_Stat VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>48</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 48 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   UPDATE dbo.Service_Robot_Group
      SET STAT = @STAT
         ,DFLT_STAT = @Dflt_Stat
    WHERE SRBT_SERV_FILE_NO = @SRBT_SERV_FILE_NO
      AND SRBT_ROBO_RBID = @SRBT_ROBO_RBID
      AND GROP_GPID = @GROP_GPID;      

   IF @Dflt_Stat = '002'
      UPDATE dbo.Service_Robot_Group
         SET DFLT_STAT = '001'
       WHERE SRBT_SERV_FILE_NO = @SRBT_SERV_FILE_NO
         AND SRBT_ROBO_RBID = @SRBT_ROBO_RBID
         AND GROP_GPID != @GROP_GPID;
END
GO
