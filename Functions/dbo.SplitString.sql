SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[SplitString]
(    
      @Input NVARCHAR(MAX),
      @Character CHAR(1)
)
RETURNS @Output TABLE (
      Item NVARCHAR(1000),
      id BIGINT
)
AS
BEGIN
      DECLARE @StartIndex INT, @EndIndex INT, @Index BIGINT = 1;
 
      SET @StartIndex = 1
      IF SUBSTRING(@Input, LEN(@Input) - 1, LEN(@Input)) <> @Character
      BEGIN
            SET @Input = @Input + @Character
      END
 
      WHILE CHARINDEX(@Character, @Input) > 0
      BEGIN
            SET @EndIndex = CHARINDEX(@Character, @Input)
           
            INSERT INTO @Output(Item, id)
            SELECT RTRIM(LTRIM(SUBSTRING(@Input, @StartIndex, @EndIndex - 1))), @Index;
           
            SET @Input = SUBSTRING(@Input, @EndIndex + 1, LEN(@Input));
            SET @Index += 1;
      END
 
      RETURN
END
GO
