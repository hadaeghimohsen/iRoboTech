SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 CREATE FUNCTION [dbo].[STR_FRMT_U]
(
  @FrmtStr NVARCHAR(4000) ,
  @Parm NVARCHAR(4000)
)
RETURNS NVARCHAR(MAX)
 AS
 BEGIN
    DECLARE @Message NVARCHAR(400) ,
        @Delimiter CHAR(1);
    DECLARE @ParamTable TABLE
    (
      ID INT IDENTITY(0, 1) ,
      Paramter NVARCHAR(1000)
    );
    SELECT  @Message = @FrmtStr ,
            @Delimiter = ',';
        WITH    CTE ( StartPos, EndPos )
                  AS ( SELECT   1 ,
                                CHARINDEX(@Delimiter, @Parm)
                       UNION ALL
                       SELECT   EndPos + ( LEN(@Delimiter) ) ,
                                CHARINDEX(@Delimiter, @Parm,
                                          EndPos + ( LEN(@Delimiter) ))
                       FROM     CTE
                       WHERE    EndPos > 0
                     )
        INSERT  INTO @ParamTable
                (
                  Paramter
                )
                SELECT  [ID] = SUBSTRING(@Parm, StartPos,
                                         CASE WHEN EndPos > 0
                                              THEN EndPos - StartPos
                                              ELSE 4000
                                         END)
                FROM    CTE;
    UPDATE  @ParamTable
    SET     @Message = REPLACE(@Message, '{' + CONVERT(VARCHAR, ID) + '}',
                               ISNULL(Paramter, N''));
    RETURN @Message;
 END;
GO
