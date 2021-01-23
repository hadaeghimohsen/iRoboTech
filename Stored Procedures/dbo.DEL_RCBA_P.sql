SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_RCBA_P]
	@Code BIGINT	
AS
BEGIN
	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
			,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>81</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
	EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
	IF @AP = 0 
	BEGIN
		RAISERROR ( N'خطا - عدم دسترسی به ردیف 81 سطوح امینتی', -- Message text.
				16, -- Severity.
				1 -- State.
				);
		RETURN;
	END

	IF NOT EXISTS(
		SELECT *
		  FROM dbo.[Order] o, dbo.Robot_Card_Bank_Account a
		 WHERE a.CODE = @Code
		   AND a.CARD_NUMB = o.DEST_CARD_NUMB_DNRM		   
	)
	BEGIN 
		DELETE dbo.Robot_Card_Bank_Account
		 WHERE CODE = @Code;
	END 
	ELSE
    BEGIN
		UPDATE dbo.Robot_Card_Bank_Account
		   SET ACNT_STAT = '001'
		 WHERE CODE = @Code;
	END 
END
GO
