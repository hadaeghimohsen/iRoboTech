SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[CHK_CRDT_U]
(
	@BANK_CARD VARCHAR(16)
)
RETURNS BIT
AS
BEGIN
	IF LEN(@BANK_CARD) != 16 RETURN 0;
	
	DECLARE @TSum INT = 0,
	        @TProc INT = 0,
	        @Indx INT = 1;
	
	WHILE @Indx <= 16
	BEGIN
	   SET @TProc = (SUBSTRING(@BANK_CARD, @Indx, 1) * CASE WHEN @Indx % 2 = 0 THEN 1 ELSE 2 END);
	   SET @TSum += CASE WHEN @TProc > 9 THEN @TProc - 9 ELSE @TProc END;
	   SET @Indx += 1;
	END 
	
	IF @TSum % 10 = 0 RETURN 1;
	RETURN 0;
END
GO
