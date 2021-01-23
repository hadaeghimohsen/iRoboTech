SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[STR_TRNS_U]
(
       @String   Nvarchar(MAX), 
       @FromChar Nvarchar(200), 
       @ToChar   Nvarchar(200)
)
RETURNS Nvarchar(MAX)
AS
BEGIN
        DECLARE @result as Nvarchar(MAX) = NULL
        DECLARE @currentChar as nchar(1) = NULL
        DECLARE @CurrentIndexFounded as int = 0
        DECLARE @CurrentIndexString as int = 0

        IF(@FromChar IS NULL OR @ToChar IS NULL)
        BEGIN
            return cast('Parameters @FromChar and @ToChar must contains 1 caracter minimum' as int);
        END
        --ELSE IF(DATALENGTH(@FromChar) <> DATALENGTH(@ToChar) OR DATALENGTH(@FromChar) = 0)
        --BEGIN
        --    return cast('Parameters @FromChar and @ToChar must contain the same number of characters (at least 1 character)' as int);
        --END

       IF(@String IS NOT NULL) 
       BEGIN
            SET  @result = '';
            WHILE(@CurrentIndexString < DATALENGTH(@String))
            BEGIN 
                    SET @CurrentIndexString = @CurrentIndexString + 1;
                    SET @currentChar = SUBSTRING(@String, @CurrentIndexString, 1);
                    SET @CurrentIndexFounded  = CHARINDEX(@currentChar COLLATE SQL_Latin1_General_CP1_CI_AS, @FromChar COLLATE SQL_Latin1_General_CP1_CI_AS);
                    IF(@CurrentIndexFounded > 0)
                    BEGIN
                            SET @result = @result + SUBSTRING(@ToChar, @CurrentIndexFounded, 1) ;
                    END
                    ELSE
                    BEGIN
                            SET @result = @result +  @currentChar;
                    END
             END
       END
       return @result
END
GO
