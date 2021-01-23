SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_ORDR_P]
    @Code BIGINT ,
    @Srbt_Serv_File_No BIGINT ,
    @Srbt_Robo_Rbid BIGINT ,
    @Srbt_Srpb_Rwno INT ,
    @Prob_Serv_File_No BIGINT ,
    @Prob_Robo_Rbid BIGINT ,
    @Chat_Id BIGINT ,
    @Ordr_Code BIGINT ,
    @Ordr_Numb BIGINT ,
    @Serv_Ordr_Rwno BIGINT ,
    @Ownr_Name NVARCHAR(250) ,
    @Ordr_Type VARCHAR(3) ,
    @Strt_Date DATETIME ,
    @End_Date DATETIME ,
    @Ordr_Stat VARCHAR(3) ,
    @How_Ship VARCHAR(3),
    @Cord_X FLOAT ,
    @Cord_Y FLOAT ,
    @Cell_Phon VARCHAR(13) ,
    @Tell_Phon VARCHAR(11) ,
    @Serv_Adrs NVARCHAR(1000) ,
    @Arch_Stat VARCHAR(3) ,
    @Serv_Job_Apbs_Code BIGINT ,
    @Serv_Intr_Apbs_Code BIGINT ,
    @Mdfr_Stat VARCHAR(3),
    @Crtb_Send_Stat VARCHAR(3),
    @Crtb_Mail_No VARCHAR(20),
    @Crtb_Mail_Subj NVARCHAR(250),
    @Apbs_Code BIGINT,
    @Expn_Amnt BIGINT,
    @Extr_Prct BIGINT,
    @Sorc_Cord_X FLOAT,
    @Sorc_Cord_Y FLOAT,
    @Sorc_Post_Adrs NVARCHAR(1000),
    @Sorc_Cell_Phon VARCHAR(11),
    @Sorc_Tell_Phon VARCHAR(11),
    @Sorc_Emal_Adrs VARCHAR(250),
    @Sorc_Web_Site VARCHAR(250),
    @Sub_Sys INT,
    @Ordr_Desc NVARCHAR(4000)
AS
BEGIN
   --  بررسی اینکه شماره سفارش قبلا ثبت نشده باشد
   --IF EXISTS(
   --   SELECT * 
   --     FROM dbo.[Order]
   --    WHERE SRBT_ROBO_RBID = @Srbt_Robo_Rbid
   --      AND CODE <> @Code
   --      AND ORDR_NUMB = @Ordr_Numb
   --)
   --BEGIN
   --   RAISERROR(N'این شماره سفارش قبلا در سیستم شما ثبت شده است، لطفا بررسی و اصلاح کنید', 16, 1);
   --   RETURN;
   --END

    UPDATE  dbo.[Order]
    SET     SRBT_SERV_FILE_NO = @Srbt_Serv_File_No ,
            SRBT_ROBO_RBID = @Srbt_Robo_Rbid ,
            SRBT_SRPB_RWNO = @Srbt_Srpb_Rwno ,
            PROB_SERV_FILE_NO = @Prob_Serv_File_No ,
            PROB_ROBO_RBID = @Prob_Robo_Rbid ,
            CHAT_ID = @Chat_Id ,
            ORDR_CODE = @Ordr_Code ,
            ORDR_NUMB = @Ordr_Numb ,
            SERV_ORDR_RWNO = @Serv_Ordr_Rwno ,
            OWNR_NAME = @Ownr_Name ,
            ORDR_TYPE = @Ordr_Type ,
            STRT_DATE = @Strt_Date ,
            END_DATE = @End_Date ,
            ORDR_STAT = @Ordr_Stat ,
            HOW_SHIP = @How_Ship,
            CORD_X = @Cord_X ,
            CORD_Y = @Cord_Y ,
            CELL_PHON = @Cell_Phon ,
            TELL_PHON = @Tell_Phon ,
            SERV_ADRS = @Serv_Adrs ,
            ARCH_STAT = @Arch_Stat ,
            SERV_JOB_APBS_CODE = @Serv_Job_Apbs_Code ,
            SERV_INTR_APBS_CODE = @Serv_Intr_Apbs_Code ,
            MDFR_STAT = @Mdfr_Stat,
            CRTB_SEND_STAT = @Crtb_Send_Stat,
            CRTB_MAIL_NO = @Crtb_Mail_No,
            CRTB_MAIL_SUBJ = @Crtb_Mail_Subj,
            APBS_CODE = @Apbs_Code,
            EXPN_AMNT = @Expn_Amnt,
            EXTR_PRCT = @Extr_Prct,
            SORC_CORD_X = @Sorc_Cord_X,
            SORC_CORD_Y = @Sorc_Cord_Y,
            SORC_POST_ADRS = @Sorc_Post_Adrs,
            SORC_CELL_PHON = @Sorc_Cell_Phon,
            SORC_TELL_PHON = @Sorc_Tell_Phon,
            SORC_EMAL_ADRS = @Sorc_Emal_Adrs,
            SORC_WEB_SITE = @Sorc_Web_Site,
            SUB_SYS = @Sub_Sys,
            ORDR_DESC = @Ordr_Desc
    WHERE   CODE = @Code;
END;
GO
