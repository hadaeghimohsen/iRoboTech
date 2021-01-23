SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_URLF_P]
	-- Add the parameters for the stored procedure here
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
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>69</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 69 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT INTO dbo.User_RobotListener_Fgac
           ( USER_NAME ,
             HOST_NAME ,
             STAT ,
             STRT_DATE ,
             END_DATE ,
             ACES_TYPE 
           )
   VALUES  ( @USER_NAME, -- USER_NAME - varchar(250)
             @HOST_NAME , -- HOST_NAME - varchar(50)
             ISNULL(@STAT, '002') , -- STAT - varchar(3)
             @STRT_DATE , -- STRT_DATE - date
             @END_DATE , -- END_DATE - date
             @ACES_TYPE  -- ACES_TYPE - varchar(3)             
           );
END
GO
