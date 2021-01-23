SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_SRGP_P]
	-- Add the parameters for the stored procedure here
	@GROP_GPID BIGINT,
	@SRBT_SERV_FILE_NO BIGINT,
	@SRBT_ROBO_RBID BIGINT,
	@STAT VARCHAR(3),
	@Dflt_Stat VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>47</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 47 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   IF @STAT = '' OR @STAT IS NULL
      SET @STAT = '002'
   
   IF @Dflt_Stat = '' OR @DFLT_STAT IS NULL
      SET @DFLT_STAT = '001'
   
   -- پایان دسترسی
   INSERT INTO dbo.Service_Robot_Group
           ( SRBT_SERV_FILE_NO ,
             SRBT_ROBO_RBID ,
             GROP_GPID ,
             STAT ,
             DFLT_STAT
           )
   VALUES  ( @SRBT_SERV_FILE_NO , -- SRBT_SERV_FILE_NO - bigint
             @SRBT_ROBO_RBID , -- SRBT_ROBO_RBID - bigint
             @GROP_GPID , -- GROP_GPID - bigint
             @STAT ,  -- STAT - varchar(3)
             @Dflt_Stat
           );
   
   IF @Dflt_Stat = '002'
      UPDATE dbo.Service_Robot_Group
         SET DFLT_STAT = '001'
       WHERE SRBT_SERV_FILE_NO = @SRBT_SERV_FILE_NO
         AND SRBT_ROBO_RBID = @SRBT_ROBO_RBID
         AND GROP_GPID != @GROP_GPID;
END
GO
