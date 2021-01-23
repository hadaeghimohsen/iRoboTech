SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
create FUNCTION [dbo].[CHK_MOBL_U]
(
	@CellPhon VARCHAR(11)
)
RETURNS INT
AS
BEGIN
	DECLARE @str VARCHAR(MAX)
	DECLARE @validchars VARCHAR(MAX)

	SET @str = @CellPhon
	SET @validchars = '[6-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
	DECLARE @idx INT
	SET @idx = PATINDEX('%'+ @validchars +'%',@str)
	IF @idx > 0 AND 
		(@idx = LEN(@str)-8
		OR PATINDEX(SUBSTRING(@str,@idx+9,1),'[0-9]')=0)
		SET @str=SUBSTRING(@str ,PATINDEX('%'+ @validchars +'%',@str), 10)
	ELSE SET @str = ''
	
	IF (LEN(@str) = 10 AND @str NOT LIKE '0%' AND @str LIKE '9%')
		RETURN 1;
	ELSE 
		RETURN 0;
	
	RETURN 0;
END
GO
