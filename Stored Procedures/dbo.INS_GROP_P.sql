SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_GROP_P]
	-- Add the parameters for the stored procedure here
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
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>44</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 44 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT INTO dbo.[Group]
           ( ROBO_RBID ,
             NAME ,
             STAT ,
             AUTO_JOIN ,
             ADMN_ORGN ,
             OFF_PRCT
           )
   VALUES  ( @ROBO_RBID , -- ROBO_RBID - bigint
             @NAME , -- NAME - nvarchar(200)
             @STAT , -- STAT - varchar(3)
             @AUTO_JOIN , -- AUTO_JOIN - varchar(3)
             @ADMN_ORGN ,  -- ADMN_ORGN - varchar(3)
             ISNULL(@Off_Prct, 0)
           );
      
END
GO
