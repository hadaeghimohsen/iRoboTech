SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_RCBA_P]
	@Code BIGINT,
	@Card_Numb VARCHAR(16),
	@Shba_Numb VARCHAR(100),
	@Acnt_Type VARCHAR(3),
	@Acnt_Ownr NVARCHAR(250),
	@Acnt_Desc NVARCHAR(1000),
	@Ordr_Type VARCHAR(3),
	@Acnt_Stat VARCHAR(3),
	@Idpy_Adrs VARCHAR(250)
AS
BEGIN
	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
			,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>80</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
	EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
	IF @AP = 0 
	BEGIN
		RAISERROR ( N'خطا - عدم دسترسی به ردیف 80 سطوح امینتی', -- Message text.
				16, -- Severity.
				1 -- State.
				);
		RETURN;
	END

	UPDATE dbo.Robot_Card_Bank_Account
	   SET CARD_NUMB = @Card_Numb,
	       SHBA_NUMB = @Shba_Numb,
		    ACNT_TYPE = @Acnt_Type,
		    ACNT_OWNR = @Acnt_Ownr,
		    ACNT_DESC = @Acnt_Desc,
		    ORDR_TYPE = @Ordr_Type,
		    ACNT_STAT = @Acnt_Stat,
		    IDPY_ADRS = @Idpy_Adrs
	 WHERE CODE = @Code;
END
GO
