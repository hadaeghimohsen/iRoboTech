SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[REQW_URPR_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   BEGIN TRY   
	   BEGIN TRANSACTION [T$REQW_URPR_P]
   	
   	DECLARE @Rbid BIGINT,
   	        @CODE bigint,
              @TARF_CODE varchar(100) ,              
              @EXPN_PRIC_DNRM bigint ,
              @EXTR_PRCT_DNRM bigint ,
              @BUY_PRIC BIGINT,
              @UNIT_APBS_CODE bigint ,
              @PROD_FETR nvarchar(max) ,
              @TARF_TEXT_NEW NVARCHAR(250),
              @TARF_TEXT_DNRM nvarchar(250) ,
              @TARF_ENGL_NEW NVARCHAR(250),
              @TARF_ENGL_TEXT nvarchar(250) ,
              @BRND_CODE_NEW bigint ,
              @BRND_CODE_DNRM bigint ,
              @GROP_CODE_NEW bigint ,              
              @GROP_CODE_DNRM bigint ,
              @GROP_JOIN_DNRM varchar(50) ,
              @DELV_DAY_DNRM smallint ,
              @DELV_HOUR_DNRM smallint ,
              @DELV_MINT_DNRM smallint ,
              @MAKE_DAY_DNRM smallint ,
              @MAKE_HOUR_DNRM smallint ,
              @MAKE_MINT_DNRM smallint ,
              @RELS_TIME datetime ,
              @STAT varchar(3) ,
              @ALRM_MIN_NUMB_DNRM real ,
              @PROD_TYPE_DNRM varchar(3) ,
              @MIN_ORDR_DNRM real ,
              @MADE_IN_DNRM varchar(3) ,
              @GRNT_STAT_DNRM varchar(3) ,
              @GRNT_NUMB_DNRM int ,
              @GRNT_TIME_DNRM varchar(3) ,
              @GRNT_TYPE_DNRM varchar(3) ,
              @GRNT_DESC_DNRM nvarchar(4000) ,
              @WRNT_STAT_DNRM varchar(3) ,
              @WRNT_NUMB_DNRM int ,
              @WRNT_TIME_DNRM varchar(3) ,
              @WRNT_TYPE_DNRM varchar(3) ,
              @WRNT_DESC_DNRM nvarchar(4000) ,
              @WEGH_AMNT_NEW real ,
              @WEGH_AMNT_DNRM real ,
              @NUMB_TYPE varchar(3), 
              @Qnty REAL,
              @ProdLifeStat VARCHAR(3),
              @ProdSuplLoctStat VARCHAR(3),
              @ProdSuplLoctDesc NVARCHAR(250),
              @RespShipCostType VARCHAR(3),
              @AprxShipCostAmnt BIGINT,
              @CRNC_CALC_STAT VARCHAR(3),
              @CRNC_EXPN_AMNT MONEY,
              @BAR_CODE VARCHAR(100);
   	
      DECLARE @docHandle INT;	
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;

   	DECLARE C$Products CURSOR
      FOR
      SELECT rp.ROBO_RBID, rp.CODE , rp.TARF_CODE  ,rp.EXPN_PRIC_DNRM  ,rp.EXTR_PRCT_DNRM, rp.BUY_PRIC, rp.UNIT_APBS_CODE  ,
             rp.PROD_FETR  ,rp.TARF_TEXT_DNRM ,rp.TARF_ENGL_TEXT ,rp.BRND_CODE_DNRM  ,rp.GROP_CODE_DNRM  ,rp.GROP_JOIN_DNRM  ,
             rp.DELV_DAY_DNRM  ,rp.DELV_HOUR_DNRM  ,rp.DELV_MINT_DNRM  ,rp.MAKE_DAY_DNRM  ,rp.MAKE_HOUR_DNRM  ,rp.MAKE_MINT_DNRM  ,
             rp.RELS_TIME  ,rp.STAT  ,rp.ALRM_MIN_NUMB_DNRM  ,rp.PROD_TYPE_DNRM  ,rp.MIN_ORDR_DNRM  ,rp.MADE_IN_DNRM  ,
             rp.GRNT_STAT_DNRM  ,rp.GRNT_NUMB_DNRM  ,rp.GRNT_TIME_DNRM  ,rp.GRNT_TYPE_DNRM  ,rp.GRNT_DESC_DNRM  ,
             rp.WRNT_STAT_DNRM  ,rp.WRNT_NUMB_DNRM  ,rp.WRNT_TIME_DNRM  ,rp.WRNT_TYPE_DNRM  ,rp.WRNT_DESC_DNRM  ,
             rp.WEGH_AMNT_DNRM  ,rp.NUMB_TYPE , rc.Tarf_Text, rc.Tarf_Engl, rc.Wegh_Amnt, ge.CODE AS Grop_Code,
             rp.PROD_LIFE_STAT, rp.PROD_SUPL_LOCT_STAT,
             rp.PROD_SUPL_LOCT_DESC, rp.RESP_SHIP_COST_TYPE, rp.APRX_SHIP_COST_AMNT, rp.CRNC_CALC_STAT, rp.CRNC_EXPN_AMNT, rp.BAR_CODE
      FROM dbo.Robot_Product rp, dbo.V#Group_Expense ge, OPENXML(@docHandle, N'//Table')
      WITH (
        Rbid BIGINT './RBID',
        Tarf_Code VARCHAR(100) './TARF_CODE',
        Tarf_Text NVARCHAR(250) './TARF_TEXT',
        Tarf_Engl NVARCHAR(250) './TARF_ENGL',
        Wegh_Amnt REAL './WEGH_AMNT',
        Grop_Code BIGINT './GROP_CODE'
      ) Rc
      WHERE rp.TARF_CODE = rc.Tarf_Code
        AND rp.ROBO_RBID = rc.Rbid
        AND ge.LINK_JOIN = rc.Grop_Code
      ORDER BY Tarf_Code;
      
      OPEN [C$Products];
      L$LoopC$Products:
      FETCH [C$Products] INTO 
         @Rbid ,@CODE ,@TARF_CODE  ,@EXPN_PRIC_DNRM  ,@EXTR_PRCT_DNRM, @BUY_PRIC ,@UNIT_APBS_CODE  ,
         @PROD_FETR  ,@TARF_TEXT_DNRM ,@TARF_ENGL_TEXT ,@BRND_CODE_DNRM  ,@GROP_CODE_DNRM  ,@GROP_JOIN_DNRM  ,
         @DELV_DAY_DNRM  ,@DELV_HOUR_DNRM  ,@DELV_MINT_DNRM  ,@MAKE_DAY_DNRM  ,@MAKE_HOUR_DNRM  ,@MAKE_MINT_DNRM  ,
         @RELS_TIME  ,@STAT  ,@ALRM_MIN_NUMB_DNRM  ,@PROD_TYPE_DNRM  ,@MIN_ORDR_DNRM  ,@MADE_IN_DNRM  ,
         @GRNT_STAT_DNRM  ,@GRNT_NUMB_DNRM  ,@GRNT_TIME_DNRM  ,@GRNT_TYPE_DNRM  ,@GRNT_DESC_DNRM  ,
         @WRNT_STAT_DNRM  ,@WRNT_NUMB_DNRM  ,@WRNT_TIME_DNRM  ,@WRNT_TYPE_DNRM  ,@WRNT_DESC_DNRM  ,
         @WEGH_AMNT_DNRM  ,@NUMB_TYPE , @TARF_TEXT_NEW, @TARF_ENGL_NEW, @WEGH_AMNT_NEW, @GROP_CODE_NEW,
         @ProdLifeStat, @ProdSuplLoctStat,
         @ProdSuplLoctDesc, @RespShipCostType, @AprxShipCostAmnt, @CRNC_CALC_STAT, @CRNC_EXPN_AMNT, @BAR_CODE ;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoopC$Products;
      
      IF(@TARF_TEXT_DNRM != @TARF_TEXT_NEW OR @TARF_ENGL_TEXT != @TARF_ENGL_NEW OR @GROP_CODE_DNRM != @GROP_CODE_NEW OR @WEGH_AMNT_DNRM != @WEGH_AMNT_NEW)   
      BEGIN 
         -- Exec Procedure For Save And Insert Products
         EXEC dbo.UPD_RBPR_P @CODE = @CODE, -- bigint
            @ROBO_RBID = @Rbid, -- bigint
            @TARF_CODE = @TARF_CODE, -- varchar(100)
            @EXPN_PRIC_DNRM = @EXPN_PRIC_DNRM, -- bigint
            @EXTR_PRCT_DNRM = @EXTR_PRCT_DNRM, -- bigint
            @BUY_PRIC = @BUY_PRIC,
            @UNIT_APBS_CODE = @UNIT_APBS_CODE, -- bigint
            @PROD_FETR = @PROD_FETR, -- nvarchar(max)
            @TARF_TEXT_DNRM = @TARF_TEXT_NEW, -- nvarchar(250)
            @TARF_ENGL_TEXT = @TARF_ENGL_NEW, -- nvarchar(250)
            @BRND_CODE_DNRM = @BRND_CODE_DNRM, -- bigint
            @GROP_CODE_DNRM = @GROP_CODE_NEW,  -- bigint
            @GROP_JOIN_DNRM = @GROP_JOIN_DNRM, -- varchar(50)
            @DELV_DAY_DNRM = @DELV_DAY_DNRM, -- smallint
            @DELV_HOUR_DNRM = @DELV_HOUR_DNRM, -- smallint
            @DELV_MINT_DNRM = @DELV_MINT_DNRM, -- smallint
            @MAKE_DAY_DNRM = @MAKE_DAY_DNRM, -- smallint
            @MAKE_HOUR_DNRM = @MAKE_HOUR_DNRM, -- smallint
            @MAKE_MINT_DNRM = @MAKE_MINT_DNRM, -- smallint
            @RELS_TIME = @RELS_TIME, -- datetime
            @STAT = @STAT, -- varchar(3)
            @ALRM_MIN_NUMB_DNRM = @ALRM_MIN_NUMB_DNRM, -- real
            @PROD_TYPE_DNRM = @PROD_TYPE_DNRM, -- varchar(3)
            @MIN_ORDR_DNRM = @MIN_ORDR_DNRM, -- real
            @MADE_IN_DNRM = @MADE_IN_DNRM, -- varchar(3)
            @GRNT_STAT_DNRM = @GRNT_STAT_DNRM, -- varchar(3)
            @GRNT_NUMB_DNRM = @GRNT_NUMB_DNRM, -- int
            @GRNT_TIME_DNRM = @GRNT_TIME_DNRM, -- varchar(3)
            @GRNT_TYPE_DNRM = @GRNT_TYPE_DNRM, -- varchar(3)
            @GRNT_DESC_DNRM = @GRNT_DESC_DNRM, -- nvarchar(4000)
            @WRNT_STAT_DNRM = @WRNT_STAT_DNRM, -- varchar(3)
            @WRNT_NUMB_DNRM = @WRNT_NUMB_DNRM, -- int
            @WRNT_TIME_DNRM = @WRNT_TIME_DNRM, -- varchar(3)
            @WRNT_TYPE_DNRM = @WRNT_TYPE_DNRM, -- varchar(3)
            @WRNT_DESC_DNRM = @WRNT_DESC_DNRM, -- nvarchar(4000)
            @WEGH_AMNT_DNRM = @WEGH_AMNT_NEW, -- real
            @NUMB_TYPE = @NUMB_TYPE,
            @PROD_LIFE_STAT = @ProdLifeStat,
            @PROD_SUPL_LOCT_STAT = @ProdSuplLoctStat,
            @PROD_SUPL_LOCT_DESC = @ProdSuplLoctDesc,
            @RESP_SHIP_COST_TYPE = @RespShipCostType,
            @APRX_SHIP_COST_AMNT = @AprxShipCostAmnt,
            @CRNC_CALC_STAT = @CRNC_CALC_STAT,
            @CRNC_EXPN_AMNT = @CRNC_EXPN_AMNT,
            @BAR_CODE = @BAR_CODE; -- varchar(3) -- varchar(3) -- varchar(3)
      END 
      
      --PRINT @TARF_CODE + N' ' + CAST(@Qnty AS VARCHAR(10)) + N' ' + CAST(@CODE AS VARCHAR(30))
      -- بروزرسانی جدول موجودی کالا
      --UPDATE ps
      --   SET ps.NUMB = ISNULL(p.SALE_NUMB_DNRM, 0) + @Qnty -- (p.SALE_CART_NUMB_DNRM)
      --  FROM dbo.Service_Robot_Seller_Product p, dbo.Service_Robot_Seller_Product_Store ps
      -- WHERE p.RBPR_CODE = @CODE
      --   AND p.CODE = ps.SRSP_CODE;
      
      --PRINT @@ROWCOUNT
         
      GOTO L$LoopC$Products;
      L$EndLoopC$Products:
      CLOSE [C$Products];
      DEALLOCATE [C$Products];   
   	
   	--PRINT 'Weldone'
   	
   	EXEC sp_xml_removedocument @docHandle;
	   COMMIT TRANSACTION [T$REQW_URPR_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1 );
	   ROLLBACK TRANSACTION [T$REQW_URPR_P];
	END CATCH
END
GO
