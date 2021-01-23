SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[INS_ORAC_P]
   @Ordr_Code BIGINT
  ,@Prob_Serv_File_No BIGINT
  ,@Prob_Robo_Rbid BIGINT
  ,@Recd_Stat VARCHAR(3)
AS 
BEGIN
   INSERT INTO dbo.Order_Access
           ( ORDR_CODE ,
             PROB_SERV_FILE_NO ,
             PROB_ROBO_RBID ,
             CODE ,
             RECD_STAT 
           )
   VALUES  ( @Ordr_Code , -- ORDR_CODE - bigint
             @Prob_Serv_File_No , -- SRBT_SERV_FILE_NO - bigint
             @Prob_Robo_Rbid , -- SRBT_ROBO_RBID - bigint
             0 , -- CODE - bigint
             @Recd_Stat  -- RECD_STAT - varchar(3)
           );
END;
GO
