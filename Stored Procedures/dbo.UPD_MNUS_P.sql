SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_MNUS_P]
	-- Add the parameters for the stored procedure here
	@ROBO_RBID BIGINT,
	@MUID BIGINT,
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
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>38</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 38 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   UPDATE dbo.Menu_Ussd
      SET MNUS_MUID = @MNUS_MUID
         ,ROOT_MENU = @ROOT_MENU
         ,ORDR = @ORDR
         ,USSD_CODE = @USSD_CODE
         ,MENU_TEXT = @MENU_TEXT
         ,MNUS_DESC = @MNUS_DESC
         ,CMND_FIRE = @CMND_FIRE
         ,STAT = @STAT
         ,STEP_BACK = @STEP_BACK
         ,STEP_BACK_USSD_CODE = @STEP_BACK_USSD_CODE
         ,CMND_PLAC = @CMND_PLAC
         ,ROW = @ROW
         ,CLMN = @CLMN
         ,CMND_TYPE = @CMND_TYPE
         ,UPLD_FILE_PATH = @UPLD_FILE_PATH
         ,MNUS_USSD_CODE = @MNUS_USSD_CODE
         ,EXST_NUMB = @EXST_NUMB
         ,MENU_TYPE = ISNULL(@MENU_TYPE, '001')
         ,DEST_TYPE = @DEST_TYPE
         ,PATH_TEXT = @PATH_TEXT
         ,CMND_TEXT = @CMND_TEXT
         ,PARM_TEXT = @PARM_TEXT
         ,POST_EXEC = @POST_EXEC
         ,TRGR_TEXT = @TRGR_TEXT
   WHERE ROBO_RBID = @ROBO_RBID
     AND MUID = @MUID;
END
GO
