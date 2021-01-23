SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[RunnerdbCommand]
	@X XML,
	@xRet XML OUTPUT
AS
BEGIN
   BEGIN TRY
   BEGIN TRAN RUNR_DBCM_T12
	DECLARE @CmndCode VARCHAR(10)
	       ,@CmndDesc NVARCHAR(100)
	       ,@CmndStat VARCHAR(3) = '002';
   
   SELECT @CmndCode = @X.query('Router_Command').value('(Router_Command/@cmndcode)[1]', 'VARCHAR(10)');   
   
   -- base variable
   DECLARE @OrdrCode BIGINT,
           @Rbid BIGINT = @X.query('Router_Command').value('(Router_Command/@rbid)[1]', 'BIGINT'),
           @TarfCode VARCHAR(100) = @X.query('//Image').value('(Image/@dcmtcode)[1]', 'VARCHAR(100)'),
           @FileId VARCHAR(MAX) = @X.query('//Image').value('(Image/@fileid)[1]', 'VARCHAR(MAX)'),
           @FileType VARCHAR(3) = @X.query('//Image').value('(Image/@filetype)[1]', 'VARCHAR(3)');
   
   IF @CmndCode = '101'
   BEGIN
      -- Save Product Image Preview
      INSERT INTO dbo.Robot_Product_Preview ( RBPR_CODE ,CODE ,ORDR ,FILE_ID ,FILE_TYPE , FILE_DESC, STAT )
      SELECT rp.CODE, dbo.GNRT_NVID_U(), 0, @FileId, @FileType, rp.TARF_TEXT_DNRM, '002'
        FROM dbo.Robot_Product rp
       WHERE rp.ROBO_RBID = @rbid
         AND rp.TARF_CODE = @TarfCode
         AND NOT EXISTS (
             SELECT *
               FROM dbo.Robot_Product_Preview rpp
              WHERE rp.CODE = rpp.RBPR_CODE
                AND rpp.FILE_ID = @FileId
         );
      
      SET @xRet = (
          SELECT '002' AS '@rsltcode',
                 'successful' AS '@rsltdesc',
                 @@ROWCOUNT AS '@rowefct'
             FOR XML PATH('Router_Command')
      );           
   END 
   ELSE IF @CmndCode = '1000'
   BEGIN
      -- Log Event
      DECLARE @LogText NVARCHAR(MAX);
      
      SELECT @OrdrCode = @X.query('Router_Command').value('(Router_Command/@refcode)[1]', 'BIGINT')
            ,@LogText = @X.query('Router_Command').value('(Router_Command/@logtext)[1]', 'NVARCHAR(MAX)')
      
      INSERT INTO dbo.Order_State (ORDR_CODE ,CODE ,STAT_DATE ,STAT_DESC, AMNT_TYPE )
      VALUES (@OrdrCode , 0, GETDATE(), @LogText, '004');      
      
      SET @xRet = (
         SELECT '001' AS '@needrecall'               
            FOR XML PATH('Router_Command')
      );
   END 
   ELSE IF @CmndCode = '2000'
   BEGIN
      -- Successfully All Action on Order by destination subsys
      SELECT @OrdrCode = @X.query('Router_Command').value('(Router_Command/@refcode)[1]', 'BIGINT');
      UPDATE dbo.[Order]
         SET ARCH_STAT = '002'
       WHERE CODE = @OrdrCode;
       
      SET @xRet = (
         SELECT '001' AS '@needrecall'               
            FOR XML PATH('Router_Command')
      );
   END 
   
   COMMIT TRAN RUNR_DBCM_T12;
   RETURN 1;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      --RAISERROR ( @ErrorMessage, -- Message text.
      --         16, -- Severity.
      --         1 -- State.
      --         );
      SELECT 0 AS CODE, @ErrorMessage AS MESG;
      ROLLBACK TRAN RUNR_DBCM_T12;
   END CATCH
END
GO
