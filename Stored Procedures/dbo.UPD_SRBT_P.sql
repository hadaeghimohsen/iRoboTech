SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_SRBT_P]
	-- Add the parameters for the stored procedure here
	@SERV_FILE_NO BIGINT,
	@ROBO_RBID BIGINT,
	@GRPH_GHID BIGINT,
	@STAT VARCHAR(3),
	@CHAT_ID BIGINT,
	@CELL_PHON VARCHAR(13),
	@CORD_X FLOAT,
	@CORD_y FLOAT,
	@SERV_ADRS NVARCHAR(1000),
	@NATL_CODE VARCHAR(11),
	@NAME NVARCHAR(100),
	@JOIN_DATE DATE,
	@REGN_PRVN_CNTY_CODE VARCHAR(3),
	@REGN_PRVN_CODE VARCHAR(3),
	@REGN_CODE VARCHAR(3),
	@RDUS_SRCH BIGINT,
	@REF_CHAT_ID BIGINT,
	@EXPR_DATE DATETIME,
	@Real_Frst_Name NVARCHAR(250),
	@Real_Last_Name NVARCHAR(250),
	@Comp_Name NVARCHAR(250),
	@Othr_Cell_Phon VARCHAR(11),
	@Othr_Serv_Addr NVARCHAR(MAX),
	@Srbt_Desc NVARCHAR(MAX),
	@Mrkt_Stat VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>43</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 43 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   UPDATE dbo.Service_Robot
      SET STAT = @STAT
         ,CHAT_ID = @CHAT_ID
         ,CELL_PHON = @CELL_PHON
         ,CORD_X = @CORD_X
         ,CORD_Y  = @CORD_y
         ,SERV_ADRS = @SERV_ADRS
         ,NATL_CODE = @NATL_CODE
         ,NAME = @NAME
         ,JOIN_DATE = @JOIN_DATE
         ,REGN_PRVN_CNTY_CODE = @REGN_PRVN_CNTY_CODE
         ,REGN_PRVN_CODE = @REGN_PRVN_CODE
         ,REGN_CODE = @REGN_CODE
         ,RDUS_SRCH = @RDUS_SRCH
         ,REF_CHAT_ID = @REF_CHAT_ID
         ,EXPR_DATE = @EXPR_DATE
         ,GRPH_GHID = @GRPH_GHID
         ,REAL_FRST_NAME = @Real_Frst_Name
         ,REAL_LAST_NAME = @Real_Last_Name
         ,COMP_NAME = @Comp_Name
         ,OTHR_CELL_PHON = @Othr_Cell_Phon
         ,OTHR_SERV_ADDR = @Othr_Serv_Addr
         ,SRBT_DESC = @Srbt_Desc
         ,MRKT_STAT = @Mrkt_Stat
   WHERE SERV_FILE_NO = @SERV_FILE_NO
     AND ROBO_RBID = @ROBO_RBID;
END
GO
