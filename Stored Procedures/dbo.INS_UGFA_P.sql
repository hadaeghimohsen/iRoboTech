SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[INS_UGFA_P]
	-- Add the parameters for the stored procedure here
	@Orgn_Ogid BIGINT,
	@Sys_User VARCHAR(255)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>24</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 24 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT INTO dbo.User_Organ_Fgac
           ( FGA_CODE ,
             ORGN_OGID ,
             SYS_USER ,
             REC_STAT ,
             VALD_TYPE 
           )
   VALUES  ( 0 , -- FGA_CODE - bigint
             @Orgn_Ogid , -- ORGN_OGID - bigint
             @Sys_User , -- SYS_USER - varchar(255)
             '002' , -- REC_STAT - varchar(3)
             '002'  -- VALD_TYPE - varchar(3)
           );
END
GO
