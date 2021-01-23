SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[UPD_ORGN_P]
	-- Add the parameters for the stored procedure here
	@Regn_Prvn_Cnty_Code VARCHAR(3),
	@Regn_Prvn_Code VARCHAR(3),
	@Regn_Code VARCHAR(3),
	@Ogid BIGINT,
	@Name NVARCHAR(250),
	@Orgn_Desc NVARCHAR(max),
	@Cord_X FLOAT,
	@Cord_Y FLOAT,
	@Stat VARCHAR(3),
	@Key_Word NVARCHAR(max),
	@Gogl_Map NVARCHAR(500)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>18</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 18 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   UPDATE dbo.Organ
      SET REGN_PRVN_CNTY_CODE = @Regn_Prvn_Cnty_Code
         ,REGN_PRVN_CODE = @Regn_Prvn_Code
         ,REGN_CODE = @Regn_Code
         ,NAME = @Name
         ,ORGN_DESC = @Orgn_Desc
         ,CORD_X = @Cord_X
         ,CORD_Y = @Cord_Y
         ,STAT = @Stat
         ,KEY_WORD = @Key_Word
         ,GOGL_MAP = @Gogl_Map
   WHERE OGID = @Ogid;
END
GO
