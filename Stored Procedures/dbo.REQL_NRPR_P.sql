SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[REQL_NRPR_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   BEGIN TRY   
	   BEGIN TRANSACTION [T$REQ_NRPR_P]
	   SET NOCOUNT ON;
	   
   	DECLARE @Rbid BIGINT,
   	        @TarfCode VARCHAR(100),
   	        @TarfText NVARCHAR(250),
   	        @ExpnPric BIGINT,
   	        @ExtrPrct BIGINT,
   	        @BuyPric BIGINT,
   	        @UnitCode BIGINT,
   	        @BrndCode BIGINT,
   	        @GropCode BIGINT,
   	        @Qnty REAL;
   	
      DECLARE @docHandle INT;	
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;

   	DECLARE C$Products CURSOR
      FOR
      SELECT  *
      FROM    OPENXML(@docHandle, N'//Table')
      WITH (
        Rbid BIGINT './RBID',
        Tarf_Code VARCHAR(100) './TARF_CODE',
        Tarf_Text NVARCHAR(250) './TARF_TEXT',
        Expn_Pric REAL './EXPN_PRIC',
        Extr_Prct BIGINT './EXTR_PRCT',
        Buy_Pric REAL './BUY_PRIC',
        Unit_Code BIGINT './UNIT_CODE',
        Brnd_Code BIGINT './BRND_CODE',
        Grop_Code BIGINT './GROP_CODE',
        Qnty REAL './QNTY'
      )
      ORDER BY Tarf_Code;
      
      OPEN [C$Products];
      L$LoopC$Products:
      FETCH [C$Products] INTO @Rbid, @TarfCode, @TarfText, @ExpnPric, @ExtrPrct, @BuyPric, @UnitCode, @BrndCode, @GropCode, @Qnty;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoopC$Products;
      
      -- اگر محصول از قبل درون سیستم وجود داشته باشد
      IF EXISTS ( 
         SELECT * 
           FROM dbo.Robot_Product rp 
          WHERE rp.ROBO_RBID = @Rbid 
            AND rp.TARF_CODE = @TarfCode 
      ) GOTO L$LoopC$Products;
      
      -- Exec Procedure For Save And Insert Products
      EXEC dbo.INS_RBPR_P @ROBO_RBID = @Rbid, -- bigint
         @TARF_CODE = @TarfCode, -- varchar(100)
         @EXPN_PRIC_DNRM = @ExpnPric, -- bigint
         @EXTR_PRCT_DNRM = @ExtrPrct, -- bigint
         @BUY_PRIC = @BuyPric,
         @UNIT_APBS_CODE = @UnitCode, -- bigint
         @PROD_FETR = @TarfText, -- nvarchar(max)
         @TARF_TEXT_DNRM = @TarfText, -- nvarchar(250)
         @TARF_ENGL_TEXT = N'', -- nvarchar(250)
         @BRND_CODE_DNRM = @BrndCode, -- bigint
         @GROP_CODE_DNRM = @GropCode, -- bigint
         @GROP_JOIN_DNRM = '', -- varchar(50)
         @DELV_DAY_DNRM = 0, -- smallint
         @DELV_HOUR_DNRM = 0, -- smallint
         @DELV_MINT_DNRM = 0, -- smallint
         @MAKE_DAY_DNRM = 0, -- smallint
         @MAKE_HOUR_DNRM = 0, -- smallint
         @MAKE_MINT_DNRM = 0, -- smallint
         @RELS_TIME = '2020-08-19 07:59:52', -- datetime
         @STAT = '002', -- varchar(3)
         @MAX_SALE_DAY_NUMB_DNRM = 0.0, -- real
         @ALRM_MIN_NUMB_DNRM = 0.0, -- real
         @PROD_TYPE_DNRM = '002', -- varchar(3)
         @MIN_ORDR_DNRM = 0.0, -- real
         @MADE_IN_DNRM = '', -- varchar(3)
         @GRNT_STAT_DNRM = '001', -- varchar(3)
         @GRNT_NUMB_DNRM = 0, -- int
         @GRNT_TIME_DNRM = '', -- varchar(3)
         @GRNT_TYPE_DNRM = '', -- varchar(3)
         @GRNT_DESC_DNRM = N'', -- nvarchar(4000)
         @WRNT_STAT_DNRM = '001', -- varchar(3)
         @WRNT_NUMB_DNRM = 0, -- int
         @WRNT_TIME_DNRM = '', -- varchar(3)
         @WRNT_TYPE_DNRM = '', -- varchar(3)
         @WRNT_DESC_DNRM = N'', -- nvarchar(4000)
         @WEGH_AMNT_DNRM = 0.0, -- real
         @NUMB_TYPE = '001',
         @PROD_LIFE_STAT = '001',
         @PROD_SUPL_LOCT_STAT = '001',
         @PROD_SUPL_LOCT_DESC = N'',
         @RESP_SHIP_COST_TYPE = '000',
         @APRX_SHIP_COST_AMNT = 0,
         @Crnc_Calc_Stat = '001',
         @Crnc_Expn_Amnt = NULL; -- varchar(3)
      
      INSERT INTO dbo.Service_Robot_Seller_Product_Store ( SRSP_CODE ,CODE ,STOR_DATE ,NUMB ,MAKE_DATE ,EXPR_DATE )
      SELECT TOP 1 p.CODE, dbo.GNRT_NVID_U(), GETDATE(), @Qnty, GETDATE(), DATEADD(YEAR, 1, GETDATE())
        FROM dbo.Service_Robot_Seller_Product p
       WHERE TARF_CODE = @TarfCode;
      
      GOTO L$LoopC$Products;
      L$EndLoopC$Products:
      CLOSE [C$Products];
      DEALLOCATE [C$Products];   
   	
   	EXEC sp_xml_removedocument @docHandle;
	   COMMIT TRANSACTION [T$REQ_NRPR_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1 );
	   ROLLBACK TRANSACTION [T$REQ_NRPR_P];
	END CATCH
END
GO
