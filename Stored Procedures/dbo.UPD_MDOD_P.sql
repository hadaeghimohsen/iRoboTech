SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[UPD_MDOD_P]
   @X XML
AS
BEGIN
   DECLARE @Rbid BIGINT
          ,@UssdCode VARCHAR(250)
          ,@OrdrInit INT
          ,@StartPosition INT;
   
   SELECT @Rbid = @X.query('RobotMedia').value('(RobotMedia/@rbid)[1]', 'BIGINT')
         ,@UssdCode = @X.query('RobotMedia').value('(RobotMedia/@ussdcode)[1]', 'VARCHAR(250)')
         ,@StartPosition = @X.query('RobotMedia').value('(RobotMedia/@strtpos)[1]', 'INT')
         ,@OrdrInit = @X.query('RobotMedia').value('(RobotMedia/@ordrinit)[1]', 'INT')   
   
   DECLARE @Opid BIGINT
          ,@i INT = @OrdrInit;
   
   DECLARE C$OrganMedia CURSOR FOR
      SELECT OPID
        FROM dbo.Organ_Media
       WHERE ROBO_RBID = @Rbid
         AND USSD_CODE = @UssdCode
         AND ORDR >= @StartPosition
       ORDER BY ORDR;
   
   OPEN [C$OrganMedia];
   L$Begin:
   FETCH NEXT FROM [C$OrganMedia] INTO @Opid
   
   IF @@FETCH_STATUS <> 0
      GOTO L$End;
   
   SET @i += 1;
      
   UPDATE dbo.Organ_Media
      SET ORDR = @i
    WHERE OPID = @Opid;      
   
   GOTO L$Begin;
   L$End:
   CLOSE [C$OrganMedia];
   DEALLOCATE [C$OrganMedia];
END;
GO
