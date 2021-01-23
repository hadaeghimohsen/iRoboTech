SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_RCBA_P]
	@Robo_Rbid BIGINT,
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
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>79</Privilege><Sub_Sys>12</Sub_Sys></AP>';	
	EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
	IF @AP = 0 
	BEGIN
		RAISERROR ( N'خطا - عدم دسترسی به ردیف 79 سطوح امینتی', -- Message text.
				16, -- Severity.
				1 -- State.
				);
		RETURN;
	END

	INSERT INTO dbo.Robot_Card_Bank_Account
	(
	    ROBO_RBID,
	    CODE,
	    CARD_NUMB,
	    SHBA_NUMB,
	    ACNT_TYPE,
	    ACNT_OWNR,
	    ACNT_DESC,
	    ORDR_TYPE,
	    ACNT_STAT,
	    IDPY_ADRS
	)
	VALUES
	(   @Robo_Rbid,        -- ROBO_RBID - bigint
	    0,                 -- CODE - bigint
	    @Card_Numb,        -- CARD_NUMB - varchar(16)
	    @Shba_Numb,        -- SHBA_NUMB - varchar(100)
	    @Acnt_Type,        -- ACNT_TYPE - varchar(3)
	    @Acnt_Ownr,       -- ACNT_OWNR - nvarchar(250)
	    @Acnt_Desc,       -- ACNT_DESC - nvarchar(1000)
	    @Ordr_Type,        -- ORDR_TYPE - varchar(3)
	    @Acnt_Stat,        -- ACNT_STAT - varchar(3)
	    @Idpy_Adrs
	    );
END
GO
