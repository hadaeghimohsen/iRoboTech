SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_PRJB_P]
	-- Add the parameters for the stored procedure here
	@Prbt_Serv_File_No BIGINT,
	@Prbt_Robo_Rbid BIGINT,
	@Job_Code BIGINT,
	@Stat VARCHAR(3),
	@Seq_Numb INT,
	@Busy_Type VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>33</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 33 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT dbo.Personal_Robot_Job
           ( PRBT_SERV_FILE_NO ,
             PRBT_ROBO_RBID ,
             JOB_CODE ,
             STAT ,
             SEQ_NUMB ,
             BUSY_TYPE 
           )
   VALUES  ( @Prbt_Serv_File_No , -- PRBT_SERV_FILE_NO - bigint
             @Prbt_Robo_Rbid , -- PRBT_ROBO_RBID - bigint
             @Job_Code , -- JOB_CODE - bigint
             ISNULL(@Stat, '002') , -- STAT - varchar(3)
             ISNULL(@Seq_Numb, 1) , -- SEQ_NUMB - int
             ISNULL(@Busy_Type, '002')  -- BUSY_TYPE - varchar(3)
           );   
END
GO
