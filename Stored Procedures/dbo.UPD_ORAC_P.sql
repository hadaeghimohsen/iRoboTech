SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[UPD_ORAC_P]
   @Code BIGINT  
  ,@Prob_Serv_File_No BIGINT
  ,@Prob_Robo_Rbid BIGINT
  ,@Recd_Stat VARCHAR(3)
AS 
BEGIN
   UPDATE dbo.Order_Access
      SET RECD_STAT = @Recd_Stat
         ,PROB_SERV_FILE_NO = @Prob_Serv_File_No
         ,PROB_ROBO_RBID = @Prob_Robo_Rbid
    WHERE CODE = @Code;
END;
GO
