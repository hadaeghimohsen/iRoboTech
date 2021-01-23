SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_ORDR_P]
   @Srbt_Serv_File_No BIGINT,
   @Srbt_Robo_Rbid BIGINT,
   @Srbt_Srpb_Rwno INT,
   @Prob_Serv_File_No BIGINT,
   @Prob_Robo_Rbid BIGINT,
   @Chat_Id BIGINT,
   @Ordr_Code BIGINT,
   @Ordr_Numb BIGINT,
   @Serv_Ordr_Rwno BIGINT,
   @Ownr_Name NVARCHAR(250),
   @Ordr_Type VARCHAR(3),
   @Strt_Date DATETIME,
   @End_Date DATETIME,
   @Ordr_Stat VARCHAR(3),
   @Cord_X FLOAT,
   @Cord_Y FLOAT,
   @Cell_Phon VARCHAR(13),
   @Tell_Phon VARCHAR(11),
   @Serv_Adrs NVARCHAR(1000),
   @Arch_Stat VARCHAR(3),
   @Serv_Job_Apbs_Code BIGINT,
   @Serv_Intr_Apbs_Code BIGINT,
   @Mdfr_Stat VARCHAR(3),
   @Crtb_Send_Stat VARCHAR(3),
   @Apbs_Code BIGINT,
   @Expn_Amnt BIGINT,
   @Extr_Prct BIGINT,
   @Sub_Sys INT
AS
BEGIN
   --  بررسی اینکه شماره سفارش قبلا ثبت نشده باشد
   IF EXISTS(
      SELECT * 
        FROM dbo.[Order]
       WHERE (SRBT_ROBO_RBID = @Srbt_Robo_Rbid OR PROB_ROBO_RBID = @Prob_Robo_Rbid)
         AND ORDR_NUMB = @Ordr_Numb
   )
   BEGIN
      RAISERROR(N'این شماره سفارش قبلا در سیستم شما ثبت شده است، لطفا بررسی و اصلاح کنید', 16, 1);
      RETURN;
   END
   
   INSERT INTO dbo.[Order]
           ( SRBT_SERV_FILE_NO ,
             SRBT_ROBO_RBID ,
             SRBT_SRPB_RWNO ,
             PROB_SERV_FILE_NO ,
             PROB_ROBO_RBID ,
             CHAT_ID ,
             ORDR_CODE ,
             CODE ,
             ORDR_NUMB ,
             SERV_ORDR_RWNO ,
             OWNR_NAME ,
             ORDR_TYPE ,
             STRT_DATE ,
             END_DATE ,
             ORDR_STAT ,
             CORD_X ,
             CORD_Y ,
             CELL_PHON ,
             TELL_PHON ,
             SERV_ADRS ,
             ARCH_STAT ,
             SERV_JOB_APBS_CODE ,
             SERV_INTR_APBS_CODE ,
             MDFR_STAT ,
             CRTB_SEND_STAT,
             APBS_CODE ,
             EXPN_AMNT ,
             EXTR_PRCT ,
             SUB_SYS
           )
   VALUES  ( @SRBT_SERV_FILE_NO ,
             @SRBT_ROBO_RBID ,
             @SRBT_SRPB_RWNO ,
             @PROB_SERV_FILE_NO ,
             @PROB_ROBO_RBID ,
             @CHAT_ID ,
             @ORDR_CODE ,
             0,             
             @ORDR_NUMB ,
             @SERV_ORDR_RWNO ,
             @OWNR_NAME ,
             @ORDR_TYPE ,
             @STRT_DATE ,
             @END_DATE ,
             @ORDR_STAT ,
             @CORD_X ,
             @CORD_Y ,
             @CELL_PHON ,
             @Tell_Phon ,
             @SERV_ADRS ,
             @ARCH_STAT ,
             @SERV_JOB_APBS_CODE ,
             @SERV_INTR_APBS_CODE ,
             @Mdfr_Stat,
             ISNULL(@Crtb_Send_Stat, '001'), -- ارسال نشده
             @Apbs_Code,
             @Expn_Amnt,
             @Extr_Prct,
             @Sub_Sys
           );
END;
   
   
GO
