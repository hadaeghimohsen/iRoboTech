SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_PRBT_P]
	-- Add the parameters for the stored procedure here
	@Serv_File_No BIGINT,
	@Robo_Rbid BIGINT,	
	@Stat VARCHAR(3),
	@Name NVARCHAR(250),
	@Cell_Phon VARCHAR(11),
	@Tell_Phon VARCHAR(11),
	@User_Name VARCHAR(100),
	@Dflt_Aces VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>30</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 30 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT INTO dbo.Personal_Robot
           ( SERV_FILE_NO ,
             ROBO_RBID ,
             STAT ,
             NAME ,
             CELL_PHON ,
             TELL_PHON ,
             USER_NAME ,
             DFLT_ACES
           )
   VALUES  ( @Serv_File_No , -- SERV_FILE_NO - bigint
             @Robo_Rbid , -- ROBO_RBID - bigint
             ISNULL(@Stat, '002') , -- STAT - varchar(3)
             @Name , 
             @Cell_Phon ,
             @Tell_Phon ,
             @User_Name ,
             @Dflt_Aces
           );
END
GO
