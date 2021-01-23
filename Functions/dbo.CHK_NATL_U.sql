SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[CHK_NATL_U] ( @NatlCode VARCHAR(10))
RETURNS SMALLINT
AS
BEGIN
   DECLARE @C INT
      	 ,@N INT
      	 ,@R INT

   IF (
   	LEN(@NatlCode) <> 10
   	OR @NatlCode = '0000000000'
   	OR @NatlCode = '1111111111'
   	OR @NatlCode = '2222222222'
   	OR @NatlCode = '3333333333'
   	OR @NatlCode = '4444444444'
   	OR @NatlCode = '5555555555'
   	OR @NatlCode = '6666666666'
   	OR @NatlCode = '7777777777'
   	OR @NatlCode = '8888888888'
   	OR @NatlCode = '9999999999'
   	)
   BEGIN
      RETURN 0;
   END
   ELSE
   BEGIN
   	SET @C = cast(SUBSTRING(@NatlCode, 10, 1) as int)

   	SET @N = (cast(SUBSTRING(@NatlCode, 1, 1) as int) * 10) +
   		(cast(SUBSTRING(@NatlCode, 2, 1) as int) * 9) +
   		(cast(SUBSTRING(@NatlCode, 3, 1) as int) * 8) +
   		(cast(SUBSTRING(@NatlCode, 4, 1) as int) * 7) +
   		(cast(SUBSTRING(@NatlCode, 5, 1) as int) * 6) +
   		(cast(SUBSTRING(@NatlCode, 6, 1) as int) * 5) +
   		(cast(SUBSTRING(@NatlCode, 7, 1) as int) * 4) +
   		(cast(SUBSTRING(@NatlCode, 8, 1) as int) * 3) +
   		(cast(SUBSTRING(@NatlCode, 9, 1) as int) * 2)

   	SET @R = @N % 11
   	
   	IF ((@R = 0 AND @R = @C) OR (@R = 1 AND @C = 1) OR (@R > 1 AND @C = 11 - @R))
   		RETURN 1;
   	ELSE
   		RETURN 0;
   END
   RETURN 0;
END
GO
