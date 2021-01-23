SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_RBKN_P]
	-- Add the parameters for the stored procedure here   
	@ROBO_RBID BIGINT,
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
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>56</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 56 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT INTO dbo.Robot_Import
           ( ROBO_RBID ,
             TEXT_TYPE ,
             SNDR ,
             TEXT_TITL ,
             TEXT_ANSR ,
             CHNL_URL ,
             STAT
           )
   VALUES  ( @ROBO_RBID , -- ROBO_RBID - bigint
             @TEXT_TYPE , -- TEXT_TYPE - nvarchar(max)
             @SNDR , -- SNDR - nvarchar(max)
             @TEXT_TITL , -- TEXT_TITL - nvarchar(max)
             @TEXT_ANSR , -- TEXT_ANSR - nvarchar(max)
             @CHNL_URL , -- CHNL_URL - varchar(max)
             @STAT
           );
END
GO
