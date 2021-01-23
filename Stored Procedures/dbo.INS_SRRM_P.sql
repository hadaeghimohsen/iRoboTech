SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_SRRM_P]
	-- Add the parameters for the stored procedure here
	@SRBT_SERV_FILE_NO BIGINT,
	@SRBT_ROBO_RBID BIGINT,
	@RWNO BIGINT,
	@SRMG_RWNO BIGINT,
	@Ordt_Ordr_Code BIGINT,
	@Ordt_Rwno BIGINT,
	@MESG_TEXT NVARCHAR(MAX),
	@FILE_ID VARCHAR(200),
	@FILE_PATH NVARCHAR(MAX),
	@MESG_TYPE VARCHAR(3),
	@LAT FLOAT,
	@LON FLOAT,
	@CONT_CELL_PHON VARCHAR(11)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>61</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 61 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   IF @Ordt_Ordr_Code = 0 
   BEGIN
      SET @Ordt_Ordr_Code = NULL;
      SET @Ordt_Rwno = NULL;
   END
   
   IF @SRMG_RWNO = 0
      SET @SRMG_RWNO = NULL;
   
   DECLARE @SendStat VARCHAR(3) = '002';
   IF @SRMG_RWNO IS NULL AND @Ordt_Ordr_Code IS NULL AND @Ordt_Rwno IS NULL
      SET @SendStat = '005';
   
   
   INSERT INTO dbo.Service_Robot_Replay_Message
           ( SRBT_SERV_FILE_NO ,
             SRBT_ROBO_RBID ,
             SRMG_RWNO ,
             ORDT_ORDR_CODE,
             ORDT_RWNO,
             RWNO ,             
             RPLY_DATE ,
             MESG_TEXT ,
             SEND_STAT ,
             FILE_ID ,
             FILE_PATH ,
             MESG_TYPE ,
             LAT ,
             LON ,
             CONT_CELL_PHON
           )
   VALUES  ( @SRBT_SERV_FILE_NO , -- SRBT_SERV_FILE_NO - bigint
             @SRBT_ROBO_RBID , -- SRBT_ROBO_RBID - bigint
             @SRMG_RWNO , -- SRMG_RWNO - bigint
             @Ordt_Ordr_Code,
             @Ordt_Rwno,
             0 , -- RWNO - bigint
             GETDATE() , -- RPLY_DATE - datetime
             @MESG_TEXT , -- MESG_TEXT - nvarchar(max)
             @SendStat ,  -- SEND_STAT - varchar(3)
             @FILE_ID ,
             @FILE_PATH ,
             @MESG_TYPE ,
             @LAT ,
             @LON ,
             @CONT_CELL_PHON
           );
END
GO
