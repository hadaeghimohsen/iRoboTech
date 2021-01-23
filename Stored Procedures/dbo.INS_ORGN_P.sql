SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[INS_ORGN_P]
	-- Add the parameters for the stored procedure here
	@Regn_Prvn_Cnty_Code VARCHAR(3),
	@Regn_Prvn_Code VARCHAR(3),
	@Regn_Code VARCHAR(3),
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
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>17</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 17 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT INTO dbo.Organ
           ( REGN_PRVN_CNTY_CODE ,
             REGN_PRVN_CODE ,
             REGN_CODE ,
             NAME ,
             ORGN_DESC ,
             CORD_X ,
             CORD_Y ,
             STAT ,
             KEY_WORD ,
             GOGL_MAP
           )
   VALUES  ( @Regn_Prvn_Cnty_Code, -- REGN_PRVN_CNTY_CODE - varchar(3)
             @Regn_Prvn_Code , -- REGN_PRVN_CODE - varchar(3)
             @Regn_Code , -- REGN_CODE - varchar(3)
             @Name , -- NAME - nvarchar(250)
             @Orgn_Desc , -- ORGN_DESC - nvarchar(max)
             @Cord_X , -- CORD_X - float
             @Cord_Y , -- CORD_Y - float
             @Stat , -- STAT - varchar(3)
             @Key_Word , -- KEY_WORD - nvarchar(max)
             @Gogl_Map  -- GOGL_MAP - nvarchar(500)
           );
END
GO
