SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GET_CSOR_P]
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION T$GET_CSOR_P
	
	DECLARE @RbcsCode BIGINT,
	        @Data NVARCHAR(500),
	        @RbcrCode BIGINT,
	        @CrncName NVARCHAR(50),
	        @CrntAmnt BIGINT,
	        @PrctChng VARCHAR(30),
	        @MaxAmnt BIGINT,
	        @MinAmnt BIGINT,
	        @RoboRbcrCode BIGINT,
	        @Rbid BIGINT;
      
      SELECT @RbcsCode = @X.query('Robot_Currency_Source').value('(Robot_Currency_Source/@code)[1]', 'BIGINT');
      
      SELECT @RoboRbcrCode = r.RBCR_CODE,
             @Rbid = r.RBID
        FROM dbo.Robot r, dbo.Robot_Currency_Source s
       WHERE r.RBID = s.ROBO_RBID
         AND s.CODE = @RbcsCode
         AND r.CRNC_AUTO_UPDT_STAT = '002';

      DECLARE @docHandle INT;	
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;

      DECLARE C$Currencies CURSOR
      FOR
      SELECT Data
        FROM OPENXML(@docHandle, N'//Currency')
        WITH (        
           Data NVARCHAR(500) '@data'
        );
	   
	   OPEN [C$Currencies];
	   L$Loop$Currencies:
	   FETCH [C$Currencies] INTO @Data;
	   
	   IF @@FETCH_STATUS <> 0
         GOTO L$EndLoop$Currencies;
	   
	   SELECT TOP 5 
	          @CrncName = CASE id WHEN 2 THEN Item ELSE @CrncName END,
	          @CrntAmnt = CASE id WHEN 3 THEN REPLACE(Item, ',', '') ELSE @CrntAmnt END,
	          @PrctChng = CASE id WHEN 4 THEN Item ELSE @PrctChng END,
	          @MaxAmnt  = CASE id WHEN 5 THEN REPLACE(Item, ',', '') ELSE @MaxAmnt END,
	          @MinAmnt  = CASE id WHEN 6 THEN REPLACE(Item, ',', '') ELSE @MinAmnt END
	     FROM dbo.SplitString(@Data, '#')
	    WHERE Item != '';
	   
	   MERGE dbo.Robot_Currency T
	   USING (SELECT @CrncName AS CRNC_NAME) S
	   ON (t.RBCS_CODE = @RbcsCode AND 
	       t.CRNC_NAME = S.CRNC_NAME)
	   WHEN NOT MATCHED THEN 
	      INSERT (RBCS_CODE, code, CRNC_NAME)
	      VALUES(@RbcsCode, 0, @CrncName);
	   
	   SELECT @RbcrCode = CODE
	     FROM dbo.Robot_Currency
	    WHERE RBCS_CODE = @RbcsCode
	      AND CRNC_NAME = @CrncName;
	   
	   IF NOT EXISTS (
	      SELECT * 
	        FROM dbo.Robot_Currency rc 
	       WHERE rc.CODE = @RbcrCode 
	         AND rc.CRNC_NAME = @CrncName 
	         AND rc.CRNT_AMNT_DNRM = @CrntAmnt 
	         AND rc.PRCT_CHNG_DNRM = @PrctChng 
	         AND rc.MAX_AMNT_DNRM = @MaxAmnt
	         AND rc.MIN_AMNT_DNRM = @MinAmnt
	   )
	   BEGIN
	      UPDATE dbo.Robot_Currency SET UPDT_STAT = '002' WHERE CODE = @RbcrCode;
	      INSERT INTO dbo.Robot_Currency_Detail ( RBCR_CODE ,CODE ,CRNT_AMNT ,MAX_AMNT ,MIN_AMNT ,PRCT_CHNG ,LAST_UPDT )
	      VALUES (@RbcrCode, 0, @CrntAmnt, @MaxAmnt, @MinAmnt, @PrctChng, GETDATE());
	   END 
	   
	   IF @RoboRbcrCode IS NOT NULL AND @RbcrCode = @RoboRbcrCode
	   BEGIN
	      UPDATE dbo.Robot
	         SET CRNC_AMNT_DNRM = @CrntAmnt
	       WHERE RBID = @Rbid
	         AND RBCR_CODE = @RbcrCode
	         AND ISNULL(CRNC_AMNT_DNRM, 0) != @CrntAmnt;
	   END
	   
	   GOTO L$Loop$Currencies;
	   L$EndLoop$Currencies:
	   CLOSE [C$Currencies];
	   DEALLOCATE [C$Currencies];
	   
	   EXEC sp_xml_removedocument @docHandle;  
	   -- EndLoop
	   
	   -- اگر تغییر نرخ داشته باشیم باید اطلاع رسانی کنیم
	   IF EXISTS (SELECT * FROM dbo.Robot_Currency rc WHERE rc.UPDT_STAT = '002')
	   BEGIN 
	      -- 1399/11/01 * اطلاع رسانی به مشتریان در انتظار دریافت قیمت ارز
	      DECLARE @XTemp XML;
	      SET @XTemp =
         (
             SELECT @Rbid AS '@rbid',
                    --@ChatID AS 'Order/@chatid',
                    '012' AS 'Order/@type',
                    'alrtchngcrnc' AS 'Order/@oprt'
             FOR XML PATH('Robot')
         );
         EXEC dbo.SEND_MEOJ_P @X = @XTemp, @XRet = @XTemp OUTPUT;
         
         UPDATE dbo.Robot_Currency SET UPDT_STAT = '001';
      END 
	COMMIT TRANSACTION [T$GET_CSOR_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1 );
      ROLLBACK TRAN [T$GET_CSOR_P];
	END CATCH	
END
GO
