SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[REQL_NGPE_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   BEGIN TRY   
	   BEGIN TRANSACTION [T$REQL_NGPE_P]
	   SET NOCOUNT ON;
	   
   	DECLARE @MGCode VARCHAR(100),
   	        @SGCode VARCHAR(100),
   	        @GropDesc NVARCHAR(250),
   	        @GropType VARCHAR(3);
   	
   	-- Local Var 
   	DECLARE @GexpCode BIGINT,
   	        @LinkJoin VARCHAR(100);
   	
      DECLARE @docHandle INT;	
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;

   	DECLARE C$GroupExpense CURSOR
      FOR
      SELECT  *
      FROM    OPENXML(@docHandle, N'//Table')
      WITH (
        MgCode VARCHAR(100) './MG_CODE',
        SgCode VARCHAR(100) './SG_CODE',
        Grop_Desc NVARCHAR(250) './GROP_DESC',
        Grop_Type VARCHAR(3) './GROP_TYPE'
      );
      
      OPEN [C$GroupExpense];
      L$LoopC$GroupExpense:
      FETCH [C$GroupExpense] INTO @MGCode, @SGCode, @GropDesc, @GropType;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoopC$GroupExpense;
         
      -- اول مشخص کنیم که این مربوط به سرگروه ها میباشد یا خیر
      IF(@MGCode IS NULL OR @MGCode = '' OR LEN(@MGCode) = 0 )
      BEGIN
         -- رکورد باید جدید باشد
         IF EXISTS ( 
            SELECT * 
              FROM dbo.V#Group_Expense ge
             WHERE ge.GROP_DESC = @GropDesc
               AND ge.GROP_TYPE = @GropType
               AND ISNULL(ge.LINK_JOIN, '0') = CASE WHEN @SGCode IS NULL OR @SGCode = '' OR LEN(@SGCode) = 0 THEN '0' ELSE @SGCode END 
         ) GOTO L$LoopC$GroupExpense;         
         
         EXEC iScsc.dbo.INS_GEXP_P @Gexp_Code = NULL, -- bigint
            @Grop_Type = @GropType, -- varchar(3)
            @Ordr = 0, -- smallint
            @Grop_Desc = @GropDesc, -- nvarchar(250)
            @Stat = '002', -- varchar(3)
            @Link_Join = @SGCode -- varchar(100)      
      END 
      ELSE IF (@MGCode IS NOT NULL)
      BEGIN
         -- رکورد باید جدید باشد
         IF EXISTS ( 
            SELECT * 
              FROM dbo.V#Group_Expense ge
             WHERE ge.GROP_DESC = @GropDesc
               AND ge.GROP_TYPE = @GropType
               AND ge.LINK_JOIN = @MGCode + @SGCode
         ) GOTO L$LoopC$GroupExpense;
         
         SELECT @GexpCode = ge.CODE
           FROM dbo.V#Group_Expense ge
          WHERE ge.LINK_JOIN = @MGCode
            AND ge.GROP_TYPE = @GropType
            AND CAST(ge.CRET_DATE AS DATE) = CAST(GETDATE() AS DATE);
         
         SET @LinkJoin = @MGCode + @SGCode;
         
         EXEC iScsc.dbo.INS_GEXP_P @Gexp_Code = @GexpCode, -- bigint
            @Grop_Type = @GropType, -- varchar(3)
            @Ordr = 0, -- smallint
            @Grop_Desc = @GropDesc, -- nvarchar(250)
            @Stat = '002', -- varchar(3)
            @Link_Join = @LinkJoin -- varchar(100)      
      END 
      
      GOTO L$LoopC$GroupExpense;
      L$EndLoopC$GroupExpense:
      CLOSE [C$GroupExpense];
      DEALLOCATE [C$GroupExpense];   
   	
   	EXEC sp_xml_removedocument @docHandle;
	   COMMIT TRANSACTION [T$REQL_NGPE_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1 );
	   ROLLBACK TRANSACTION [T$REQL_NGPE_P];
	END CATCH
END
GO
