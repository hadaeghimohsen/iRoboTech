SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[GET_SUBS_U](@SubStr varchar(8000), @MainText Text)  
RETURNS  int
AS 
BEGIN
  DECLARE @StrCount int
  DECLARE @StrPos int
  
  SET @StrCount = 0
  SET @StrPos = 0
  SET @StrPos = CHARINDEX( @SubStr, @MainText, @StrPos)
  
  WHILE @StrPos > 0
  BEGIN
    SET @StrCount = @StrCount + 1
    SET @StrPos = CHARINDEX( @SubStr, @MainText, @StrPos+1)
  END
  
  RETURN  @StrCount  
END
 
 
GO
