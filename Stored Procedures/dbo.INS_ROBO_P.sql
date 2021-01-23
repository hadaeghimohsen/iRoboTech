SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_ROBO_P]
	-- Add the parameters for the stored procedure here
	@Orgn_Ogid BIGINT,
	@Robo_Rbid BIGINT,
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
	@Ordr_Expr_Time INT
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>20</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 20 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT dbo.Robot
           ( ORGN_OGID ,
             ROBO_RBID,
             COPY_TYPE,
             BOT_TYPE ,
             NAME ,
             TKON_CODE ,             
             CHCK_INTR,
             STAT ,
             BULD_STAT ,
             BULD_FILE_ID,
             SPY_TYPE,
             CRTB_URL,
             DOWN_LOAD_FILE_PATH,
             UP_LOAD_FILE_PATH,
             INVT_FRND,
             HASH_TAG,
             CORD_X,
             CORD_Y,
             POST_ADRS,
             CELL_PHON,
             TELL_PHON,
             EMAL_ADRS,
             WEB_SITE,
             RUN_STAT,
             AMNT_TYPE,
             CNCT_ACNT_APP,
             ACNT_APP_TYPE,
             PAGE_FECH_ROWS, 
             MIN_WITH_DRAW,
             CONF_DURT_DAY,
             AUTO_SHIP_CORI,
             SHOW_INVR_STAT,
			 VIEW_INVR_STAT,
			 FREE_SHIP_INCT_AMNT, 
			 FREE_SHIP_OTCT_AMNT,
			 ORDR_EXPR_STAT,
			 ORDR_EXPR_TIME
           )
   VALUES  ( @Orgn_Ogid , -- ORGN_OGID - bigint
             @Robo_Rbid,
             @Copy_Type,
             @Bot_Type ,
             @Name , -- NAME - varchar(50)
             @Tkon_Code , -- TKON_CODE - varchar(100)             
             0,
             @Stat , -- STAT - varchar(3)
             @Buld_Stat , -- BULD_STAT - varchar(3)
             @Buld_File_Id , -- BULD_FILE_ID - varchar(500)
             @Spy_Type,
             @Crtb_Url,
             @Down_Load_File_Path,
             @Up_Load_File_Path,
             @Invt_Frnd,
             @Hash_Tag,
             @Cord_X,
             @Cord_Y,
             @Post_Adrs,
             @Cell_Phon,
             @Tell_Phon,
             @Emal_Adrs,
             @Web_Site,
             @Run_Stat,
             @Amnt_Type,
             @Cnct_Acnt_App,
             @Acnt_App_Type,
             @Page_Fech_Rows,
             @Min_With_Draw,
             @Conf_Durt_Day,
             @Auto_Ship_Cori,
             @Show_Invr_Stat,
			 @View_Invr_Stat,
			 @Free_Ship_Inct_Amnt,
			 @Free_Ship_Otct_Amnt,
			 @Ordr_Expr_Stat,
			 @Ordr_Expr_Time
           );
END
GO
