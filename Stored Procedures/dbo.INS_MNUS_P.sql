SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_MNUS_P]
	-- Add the parameters for the stored procedure here
	@ROBO_RBID BIGINT,
	@MNUS_MUID BIGINT,
	@ROOT_MENU VARCHAR(3),
	@ORDR SMALLINT,
	@USSD_CODE VARCHAR(250),
	@MENU_TEXT NVARCHAR(250),
	@MNUS_DESC NVARCHAR(MAX),
	@CMND_FIRE VARCHAR(3),
	@STAT VARCHAR(3),
	@STEP_BACK VARCHAR(3),
	@STEP_BACK_USSD_CODE VARCHAR(250),
	@CMND_PLAC VARCHAR(3),
	@ROW INT,
	@CLMN INT,
	@CMND_TYPE VARCHAR(3),
	@UPLD_FILE_PATH NVARCHAR(1000),
	@MNUS_USSD_CODE VARCHAR(250),
	@EXST_NUMB FLOAT,
	@MENU_TYPE VARCHAR(3),
	@DEST_TYPE VARCHAR(3),
	@PATH_TEXT VARCHAR(250),
	@CMND_TEXT VARCHAR(250),
	@PARM_TEXT NVARCHAR(250),
	@POST_EXEC VARCHAR(250),
	@TRGR_TEXT VARCHAR(250)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>37</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 37 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT INTO dbo.Menu_Ussd
           ( ROBO_RBID ,
             MNUS_MUID ,
             ROOT_MENU ,
             ORDR ,
             USSD_CODE ,
             MENU_TEXT ,
             MNUS_DESC ,
             CMND_FIRE ,
             STAT ,
             STEP_BACK ,
             STEP_BACK_USSD_CODE ,
             CMND_PLAC ,
             ROW ,
             CLMN ,
             CMND_TYPE ,
             UPLD_FILE_PATH ,
             MNUS_USSD_CODE ,
             EXST_NUMB,
             MENU_TYPE,
             DEST_TYPE,
             PATH_TEXT,
             CMND_TEXT,
             PARM_TEXT,
             POST_EXEC, 
             TRGR_TEXT
           )
   VALUES  ( @ROBO_RBID , -- ROBO_RBID - bigint
             @MNUS_MUID , -- MNUS_MUID - bigint
             @ROOT_MENU , -- ROOT_MENU - varchar(3)
             @ORDR , -- ORDR - smallint
             @USSD_CODE , -- USSD_CODE - varchar(250)
             @MENU_TEXT , -- MENU_TEXT - nvarchar(250)
             @MNUS_DESC , -- MNUS_DESC - nvarchar(max)
             @CMND_FIRE , -- CMND_FIRE - varchar(3)
             @STAT , -- STAT - varchar(3)
             @STEP_BACK , -- STEP_BACK - varchar(3)
             @STEP_BACK_USSD_CODE , -- STEP_BACK_USSD_CODE - varchar(250)
             @CMND_PLAC , -- CMND_PLAC - varchar(3)
             @ROW , -- ROW - int
             @CLMN , -- CLMN - int
             @CMND_TYPE , -- CMND_TYPE - varchar(3)
             @UPLD_FILE_PATH , -- UPLD_FILE_PATH - nvarchar(1000)
             @MNUS_USSD_CODE , -- MNUS_USSD_CODE - varchar(250)
             @EXST_NUMB,
             ISNULL(@MENU_TYPE, '001'),
             @DEST_TYPE,
             @PATH_TEXT,
             @CMND_TEXT,
             @PARM_TEXT,
             @POST_EXEC,
             @TRGR_TEXT
           );
END
GO
