SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[STR_COPY_U](@Str NVARCHAR(MAX), @Cont INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
   DECLARE @i INT = 1
          ,@Result NVARCHAR(MAX) = N'';
   
   WHILE @Cont >= @i
   BEGIN
      SET @Result += @Str;
      SET @i += 1;
   END
   
   RETURN @Result;
END ;
GO
