SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[UPD_PRJB_P]
	-- Add the parameters for the stored procedure here
	@Prbt_Serv_File_No BIGINT,
	@Prbt_Robo_Rbid BIGINT,
	@Job_Code BIGINT,
	@Code BIGINT,
	@Stat VARCHAR(3),
	@Seq_Numb INT,
	@Busy_Type VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>34</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 34 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   UPDATE dbo.Personal_Robot_Job
      SET STAT = @Stat
         ,SEQ_NUMB = @Seq_Numb
         ,BUSY_TYPE = @Busy_Type
         ,JOB_CODE = @Job_Code
         ,Prbt_SERV_FILE_NO = @Prbt_Serv_File_No
    WHERE Prbt_ROBO_RBID = @Prbt_Robo_Rbid
      AND CODE = @Code;
END
GO
