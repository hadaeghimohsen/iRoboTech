SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_ROBO_P]
	-- Add the parameters for the stored procedure here
	@Orgn_Ogid BIGINT,	
	@Robo_Rbid BIGINT,
	@Rbid BIGINT,
	@Copy_Type VARCHAR(3),
	@Bot_Type VARCHAR(3),
	@Name NVARCHAR(50),
	@Tkon_Code VARCHAR(100),
	@Stat VARCHAR(3),
	@Buld_Stat VARCHAR(3),
	@Buld_File_Id VARCHAR(500),
	@Spy_Type VARCHAR(3),
	@Crtb_Url VARCHAR(1000),
	@Down_Load_File_Path VARCHAR(1000),
	@Up_Load_File_Path VARCHAR(1000),
	@Invt_Frnd NVARCHAR(MAX),
	@Hash_Tag NVARCHAR(1000),
	@Cord_X FLOAT,
	@Cord_Y FLOAT,
	@Post_Adrs NVARCHAR(1000),
	@Cell_Phon VARCHAR(11),
	@Tell_Phon VARCHAR(11),
	@Emal_Adrs VARCHAR(250),
	@Web_Site VARCHAR(250),
	@Run_Stat VARCHAR(3),
	@Amnt_Type VARCHAR(3),
	@Cnct_Acnt_App VARCHAR(3),
	@Acnt_App_Type VARCHAR(3),
	@Page_Fech_Rows INT,
	@Min_With_Draw BIGINT,
	@Conf_Durt_Day INT,
	@Auto_Ship_Cori VARCHAR(3),
	@Show_Invr_Stat VARCHAR(3),
	@View_Invr_Stat VARCHAR(3),
	@Free_Ship_Inct_Amnt BIGINT,
	@Free_Ship_Otct_Amnt BIGINT,
	@Ordr_Expr_Stat VARCHAR(3),
	@Ordr_Expr_Time INT,
	@Locl_Srvr_Conn_Strn VARCHAR(1000),
	@Web_Srvr_Conn_Strn VARCHAR(1000),
	@Noti_Ordr_Ship_Stat VARCHAR(3),
	@Noti_Sond_Ordr_Ship_Path NVARCHAR(4000),
	@Noti_Ordr_Rcpt_Stat VARCHAR(3),
	@Noti_Sond_Ordr_Rcpt_Path NVARCHAR(4000),
	@Noti_Ordr_Recp_Stat VARCHAR(3),
	@Noti_Sond_Ordr_Recp_Path NVARCHAR(4000),
	@Chck_Regs_Strt VARCHAR(3),
	@Crnc_Calc_Stat VARCHAR(3),
	@Rbcr_Code BIGINT,
	@Crnc_Amnt_Dnrm BIGINT,
	@Crnc_Auto_Updt_Stat VARCHAR(3),
	@Crnc_Cycl_Auto_Updt INT,
	@Extr_Sorc_Stat VARCHAR(3),
	@Slct_Srvr_Type VARCHAR(3),
	@Crnc_How_Updt_Stat VARCHAR(3),
	@Max_Card_To_Card_Amnt BIGINT
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>21</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 21 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   UPDATE dbo.Robot
      SET NAME = @Name
         ,ROBO_RBID = @Robo_Rbid
         ,COPY_TYPE = @Copy_Type
         ,BOT_TYPE = @Bot_Type
         ,TKON_CODE = @Tkon_Code
         ,STAT = @Stat
         ,BULD_STAT = @Buld_Stat
         ,BULD_FILE_ID = @Buld_File_Id
         ,ORGN_OGID = @Orgn_Ogid
         ,SPY_TYPE = @Spy_Type
         ,CRTB_URL = @Crtb_Url
         ,DOWN_LOAD_FILE_PATH = @Down_Load_File_Path
         ,UP_LOAD_FILE_PATH = @Up_Load_File_Path
         ,INVT_FRND = @Invt_Frnd
         ,HASH_TAG = @Hash_Tag
         ,CORD_X = @Cord_X
         ,CORD_Y = @Cord_Y
         ,POST_ADRS = @Post_Adrs
         ,CELL_PHON = @Cell_Phon
         ,TELL_PHON = @Tell_Phon
         ,EMAL_ADRS = @Emal_Adrs
         ,WEB_SITE = @Web_Site
         ,RUN_STAT = @Run_Stat
         ,AMNT_TYPE = @Amnt_Type
         ,CNCT_ACNT_APP = @Cnct_Acnt_App
         ,ACNT_APP_TYPE = @Acnt_App_Type
         ,PAGE_FECH_ROWS = @Page_Fech_Rows
         ,MIN_WITH_DRAW = @Min_With_Draw
         ,CONF_DURT_DAY = @Conf_Durt_Day
         ,AUTO_SHIP_CORI = @Auto_Ship_Cori
         ,SHOW_INVR_STAT = @Show_Invr_Stat
		   ,VIEW_INVR_STAT = @View_Invr_Stat
		   ,FREE_SHIP_INCT_AMNT = @Free_Ship_Inct_Amnt
		   ,FREE_SHIP_OTCT_AMNT = @Free_Ship_Otct_Amnt
		   ,ORDR_EXPR_STAT = @Ordr_Expr_Stat
		   ,ORDR_EXPR_TIME = @Ordr_Expr_Time
		   ,LOCL_SRVR_CONN_STRN = @Locl_Srvr_Conn_Strn
		   ,WEB_SRVR_CONN_STRN = @Web_Srvr_Conn_Strn
		   ,EXTR_SORC_STAT = @Extr_Sorc_Stat
		   ,SLCT_SRVR_TYPE = @Slct_Srvr_Type
		   ,NOTI_ORDR_SHIP_STAT = @Noti_Ordr_Ship_Stat
		   ,NOTI_SOND_ORDR_SHIP_PATH = @Noti_Sond_Ordr_Ship_Path
		   ,NOTI_ORDR_RCPT_STAT = @Noti_Ordr_Rcpt_Stat
		   ,NOTI_SOND_ORDR_RCPT_PATH = @Noti_Sond_Ordr_Rcpt_Path
		   ,NOTI_ORDR_RECP_STAT = @Noti_Ordr_Recp_Stat
		   ,NOTI_SOND_ORDR_RECP_PATH = @Noti_Sond_Ordr_Recp_Path
		   ,CHCK_REGS_STRT = @Chck_Regs_Strt
		   ,CRNC_CALC_STAT = @Crnc_Calc_Stat
		   ,RBCR_CODE = @Rbcr_Code
		   ,CRNC_AMNT_DNRM = @Crnc_Amnt_Dnrm
		   ,CRNC_AUTO_UPDT_STAT = @Crnc_Auto_Updt_Stat
		   ,CRNC_CYCL_AUTO_UPDT = @Crnc_Cycl_Auto_Updt
		   ,CRNC_HOW_UPDT_STAT = @Crnc_How_Updt_Stat
		   ,MAX_CARD_TO_CARD_AMNT = @Max_Card_To_Card_Amnt
    WHERE RBID = @Rbid;
END
GO
