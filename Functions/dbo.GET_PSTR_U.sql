SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[GET_PSTR_U](
  @Num  int
 ,@Len  smallint)
  RETURNS nvarchar(50)
AS
  BEGIN
    DECLARE @ZeroStr   nvarchar(50)
    SELECT
    @ZeroStr = '0'

    WHILE (LEN(@ZeroStr) < @Len)
    BEGIN
      SELECT
      @ZeroStr = @ZeroStr + '0'
    END

    DECLARE @Str   nvarchar(50)
    SELECT
    @Str     = @ZeroStr + CAST(@Num as nvarchar(50))
    RETURN RIGHT(
             @Str
            ,@Len)
  END

;
GO
