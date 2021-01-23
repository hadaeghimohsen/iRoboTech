SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[REQL_NPSP_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   BEGIN TRY
      BEGIN TRANSACTION T$REQ_NPSP_P
      SET NOCOUNT ON;
      
      DECLARE @Rbid BIGINT,
              @TarfCode VARCHAR(100),
              @StepType VARCHAR(3),
              
              @TarfCodeQnty1 REAL,
              @CartSumPric1 BIGINT,
              @ExpnPric1 BIGINT,
              
              @TarfCodeQnty2 REAL,
              @CartSumPric2 BIGINT,
              @ExpnPric2 BIGINT,
              
              @TarfCodeQnty3 REAL,
              @CartSumPric3 BIGINT,
              @ExpnPric3 BIGINT,
              
              @TarfCodeQnty4 REAL,
              @CartSumPric4 BIGINT,
              @ExpnPric4 BIGINT,
              
              @TarfCodeQnty5 REAL,
              @CartSumPric5 BIGINT,
              @ExpnPric5 BIGINT;
      
      DECLARE @docHandle INT;	
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;

	   DECLARE C$ProductStepPrice CURSOR
      FOR
      SELECT  *
      FROM    OPENXML(@docHandle, N'//Table')
      WITH (
        Rbid BIGINT './RBID',
        Tarf_Code VARCHAR(100) './TARF_CODE',
        Step_Type VARCHAR(3) './STEP_TYPE',
        
        Tarf_Code_Qnty1 Real './TARF_CODE_QNTY1',
        Cart_Sum_Pric1 BIGINT './CART_SUM_PRIC1',
        Expn_Pric1 BIGINT './EXPN_PRIC1',
        
        Tarf_Code_Qnty2 Real './TARF_CODE_QNTY2',
        Cart_Sum_Pric2 BIGINT './CART_SUM_PRIC2',
        Expn_Pric2 BIGINT './EXPN_PRIC2',
        
        Tarf_Code_Qnty3 Real './TARF_CODE_QNTY3',
        Cart_Sum_Pric3 BIGINT './CART_SUM_PRIC3',
        Expn_Pric3 BIGINT './EXPN_PRIC3',
        
        Tarf_Code_Qnty4 Real './TARF_CODE_QNTY4',
        Cart_Sum_Pric4 BIGINT './CART_SUM_PRIC4',
        Expn_Pric4 BIGINT './EXPN_PRIC4',
        
        Tarf_Code_Qnty5 Real './TARF_CODE_QNTY5',
        Cart_Sum_Pric5 BIGINT './CART_SUM_PRIC5',
        Expn_Pric5 BIGINT './EXPN_PRIC5'
      )
      ORDER BY Tarf_Code;
      
      OPEN [C$ProductStepPrice];
      L$LoopC$ProductStepPrice:
      FETCH [C$ProductStepPrice] INTO @Rbid, @TarfCode, @StepType,
                                      @TarfCodeQnty1, @CartSumPric1, @ExpnPric1,
                                      @TarfCodeQnty2, @CartSumPric2, @ExpnPric2,
                                      @TarfCodeQnty3, @CartSumPric3, @ExpnPric3,
                                      @TarfCodeQnty4, @CartSumPric4, @ExpnPric4,
                                      @TarfCodeQnty5, @CartSumPric5, @ExpnPric5;
                                      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoopC$ProductStepPrice;
      
      -- Part 1
      INSERT INTO dbo.Robot_Product_StepPrice ( RBPR_CODE ,RWNO ,STEP_TYPE ,TARF_CODE_QNTY ,CART_SUM_PRIC ,EXPN_PRIC ,STAT )
      SELECT rp.CODE, 0, @StepType, @TarfCodeQnty1, @CartSumPric1, @ExpnPric1, '002'
        FROM dbo.Robot_Product rp
       WHERE rp.ROBO_RBID = @Rbid
         AND rp.TARF_CODE = @TarfCode
         AND NOT EXISTS (
             SELECT *
               FROM dbo.Robot_Product_StepPrice sp
              WHERE rp.ROBO_RBID = sp.RBPR_CODE
                AND sp.STEP_TYPE = @StepType
                AND sp.TARF_CODE_QNTY = @TarfCodeQnty1
                AND sp.CART_SUM_PRIC = @CartSumPric1
                AND sp.EXPN_PRIC = @ExpnPric1
         );
      
      -- Part 2
      INSERT INTO dbo.Robot_Product_StepPrice ( RBPR_CODE ,RWNO ,STEP_TYPE ,TARF_CODE_QNTY ,CART_SUM_PRIC ,EXPN_PRIC ,STAT )
      SELECT rp.CODE, 0, @StepType, @TarfCodeQnty2, @CartSumPric2, @ExpnPric2, '002'
        FROM dbo.Robot_Product rp
       WHERE rp.ROBO_RBID = @Rbid
         AND rp.TARF_CODE = @TarfCode
         AND NOT EXISTS (
             SELECT *
               FROM dbo.Robot_Product_StepPrice sp
              WHERE rp.ROBO_RBID = sp.RBPR_CODE
                AND sp.STEP_TYPE = @StepType
                AND sp.TARF_CODE_QNTY = @TarfCodeQnty2
                AND sp.CART_SUM_PRIC = @CartSumPric2
                AND sp.EXPN_PRIC = @ExpnPric2
         );   
      
      -- Part 3
      INSERT INTO dbo.Robot_Product_StepPrice ( RBPR_CODE ,RWNO ,STEP_TYPE ,TARF_CODE_QNTY ,CART_SUM_PRIC ,EXPN_PRIC ,STAT )
      SELECT rp.CODE, 0, @StepType, @TarfCodeQnty3, @CartSumPric3, @ExpnPric3, '002'
        FROM dbo.Robot_Product rp
       WHERE rp.ROBO_RBID = @Rbid
         AND rp.TARF_CODE = @TarfCode
         AND NOT EXISTS (
             SELECT *
               FROM dbo.Robot_Product_StepPrice sp
              WHERE rp.ROBO_RBID = sp.RBPR_CODE
                AND sp.STEP_TYPE = @StepType
                AND sp.TARF_CODE_QNTY = @TarfCodeQnty3
                AND sp.CART_SUM_PRIC = @CartSumPric3
                AND sp.EXPN_PRIC = @ExpnPric3
         );
      
      -- Part 4
      INSERT INTO dbo.Robot_Product_StepPrice ( RBPR_CODE ,RWNO ,STEP_TYPE ,TARF_CODE_QNTY ,CART_SUM_PRIC ,EXPN_PRIC ,STAT )
      SELECT rp.CODE, 0, @StepType, @TarfCodeQnty4, @CartSumPric4, @ExpnPric4, '002'
        FROM dbo.Robot_Product rp
       WHERE rp.ROBO_RBID = @Rbid
         AND rp.TARF_CODE = @TarfCode
         AND NOT EXISTS (
             SELECT *
               FROM dbo.Robot_Product_StepPrice sp
              WHERE rp.ROBO_RBID = sp.RBPR_CODE
                AND sp.STEP_TYPE = @StepType
                AND sp.TARF_CODE_QNTY = @TarfCodeQnty4
                AND sp.CART_SUM_PRIC = @CartSumPric4
                AND sp.EXPN_PRIC = @ExpnPric4
         );
         
      -- Part 5
      INSERT INTO dbo.Robot_Product_StepPrice ( RBPR_CODE ,RWNO ,STEP_TYPE ,TARF_CODE_QNTY ,CART_SUM_PRIC ,EXPN_PRIC ,STAT )
      SELECT rp.CODE, 0, @StepType, @TarfCodeQnty5, @CartSumPric5, @ExpnPric5, '002'
        FROM dbo.Robot_Product rp
       WHERE rp.ROBO_RBID = @Rbid
         AND rp.TARF_CODE = @TarfCode
         AND NOT EXISTS (
             SELECT *
               FROM dbo.Robot_Product_StepPrice sp
              WHERE rp.ROBO_RBID = sp.RBPR_CODE
                AND sp.STEP_TYPE = @StepType
                AND sp.TARF_CODE_QNTY = @TarfCodeQnty5
                AND sp.CART_SUM_PRIC = @CartSumPric5
                AND sp.EXPN_PRIC = @ExpnPric5
         );
      
      GOTO L$LoopC$ProductStepPrice;
      L$EndLoopC$ProductStepPrice:
      CLOSE [C$ProductStepPrice];
      DEALLOCATE [C$ProductStepPrice];
         
      COMMIT TRANSACTION [T$REQ_NPSP_P]
   END TRY
   BEGIN CATCH
      DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1 );
      ROLLBACK TRANSACTION [T$REQ_NPSP_P]
   END CATCH
END
GO
