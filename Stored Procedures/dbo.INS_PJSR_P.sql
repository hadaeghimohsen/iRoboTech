SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_PJSR_P]
	-- Add the parameters for the stored procedure here
	@Prjb_Code BIGINT,
   @Srbt_Serv_File_No BIGINT,
   @Srbt_Robo_Rbid BIGINT
AS
BEGIN
	INSERT INTO dbo.Personal_Robot_Job_Service_Robot
	        ( PRJB_CODE ,
	          SRBT_SERV_FILE_NO ,
	          SRBT_ROBO_RBID ,
	          CODE ,
	          STAT 
	        )
	VALUES  ( @Prjb_Code , -- PRJB_CODE - bigint
	          @Srbt_Serv_File_No , -- SRBT_SERV_FILE_NO - bigint
	          @Srbt_Robo_Rbid , -- SRBT_ROBO_RBID - bigint
	          0 , -- CODE - bigint
	          '002'  -- STAT - varchar(3)
	        );
END
GO
