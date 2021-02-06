SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_RBPR_P]
    @CODE BIGINT,
    @ROBO_RBID BIGINT,
    @TARF_CODE VARCHAR(100),
    @EXPN_PRIC_DNRM BIGINT,
    @EXTR_PRCT_DNRM BIGINT,
    @BUY_PRIC BIGINT,
    @UNIT_APBS_CODE BIGINT,
    @PROD_FETR NVARCHAR(MAX),
    @TARF_TEXT_DNRM NVARCHAR(250),
    @TARF_ENGL_TEXT NVARCHAR(250),
    @BRND_CODE_DNRM BIGINT,
    @GROP_CODE_DNRM BIGINT,
    @GROP_JOIN_DNRM VARCHAR(50),
    @DELV_DAY_DNRM SMALLINT,
    @DELV_HOUR_DNRM SMALLINT,
    @DELV_MINT_DNRM SMALLINT,
    @MAKE_DAY_DNRM SMALLINT,
    @MAKE_HOUR_DNRM SMALLINT,
    @MAKE_MINT_DNRM SMALLINT,
    @RELS_TIME DATETIME,
    @STAT VARCHAR(3),
    @ALRM_MIN_NUMB_DNRM REAL,
    @PROD_TYPE_DNRM VARCHAR(3),
    @MIN_ORDR_DNRM REAL,
    @MADE_IN_DNRM VARCHAR(3),
    @GRNT_STAT_DNRM VARCHAR(3),
    @GRNT_NUMB_DNRM INT,
    @GRNT_TIME_DNRM VARCHAR(3),
    @GRNT_TYPE_DNRM VARCHAR(3),
    @GRNT_DESC_DNRM NVARCHAR(4000),
    @WRNT_STAT_DNRM VARCHAR(3),
    @WRNT_NUMB_DNRM INT,
    @WRNT_TIME_DNRM VARCHAR(3),
    @WRNT_TYPE_DNRM VARCHAR(3),
    @WRNT_DESC_DNRM NVARCHAR(4000),
    @WEGH_AMNT_DNRM REAL,
    @NUMB_TYPE VARCHAR(3),
    @PROD_LIFE_STAT VARCHAR(3),
    @PROD_SUPL_LOCT_STAT VARCHAR(3),
    @PROD_SUPL_LOCT_DESC NVARCHAR(250),
    @RESP_SHIP_COST_TYPE VARCHAR(3),
    @APRX_SHIP_COST_AMNT BIGINT,
    @CRNC_CALC_STAT VARCHAR(3),
    @CRNC_EXPN_AMNT MONEY,
    @BAR_CODE VARCHAR(100)
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN [T$UPD_RBPR_P];
        DECLARE @Xtemp XML;

        -- بروزرسانی جدول کالا با گزینه های دیگری که وجود داره
        SET @Xtemp =
        (
            SELECT 5 AS '@subsys',
                   '105' AS '@cmndcode',        -- عملیات جامع ذخیره سازی
                   12 AS '@refsubsys',          -- محل ارجاعی
                   'appuser' AS '@execaslogin', -- توسط کدام کاربری اجرا شود               
                   @TARF_CODE AS '@tarfcode',
                   @TARF_TEXT_DNRM AS '@tarfname',
                   @EXPN_PRIC_DNRM AS '@tarfpric',
                   @EXTR_PRCT_DNRM AS '@tarfextrprct',
                   @BRND_CODE_DNRM AS '@tarfbrndcode',
                   @GROP_CODE_DNRM AS '@tarfgropcode',
                   @GROP_JOIN_DNRM AS '@tarfgropjoin',
                   @PROD_TYPE_DNRM AS '@tarftype'
            FOR XML PATH('Router_Command')
        );
        EXEC dbo.RouterdbCommand @X = @Xtemp,           -- xml
                                 @xRet = @Xtemp OUTPUT; -- xml
        
        UPDATE sp
           SET sp.Delv_Day = @DELV_DAY_DNRM ,
               sp.Delv_Hour = @DELV_HOUR_DNRM ,
               sp.Delv_Mint = @DELV_MINT_DNRM ,
               sp.Make_Day = @MAKE_DAY_DNRM ,
               sp.Make_Hour = @MAKE_HOUR_DNRM ,
               sp.Make_Mint = @MAKE_MINT_DNRM ,
               sp.Alrm_Min_Numb = @ALRM_MIN_NUMB_DNRM ,
               sp.Prod_Type = @PROD_TYPE_DNRM ,
               sp.Min_Ordr = @MIN_ORDR_DNRM ,
               sp.Made_In = @MADE_IN_DNRM ,
               sp.Grnt_Stat = @GRNT_STAT_DNRM ,
               sp.Grnt_Numb = @GRNT_NUMB_DNRM ,
               sp.Grnt_Time = @GRNT_TIME_DNRM ,
               sp.Grnt_Type = @GRNT_TYPE_DNRM ,
               sp.Grnt_Desc = @GRNT_DESC_DNRM ,
               sp.Wrnt_Stat = @WRNT_STAT_DNRM ,
               sp.Wrnt_Numb = @WRNT_NUMB_DNRM ,
               sp.Wrnt_Time = @WRNT_TIME_DNRM ,
               sp.Wrnt_Type = @WRNT_TYPE_DNRM ,
               sp.Wrnt_Desc = @WRNT_DESC_DNRM ,
               sp.Wegh_Amnt = @WEGH_AMNT_DNRM 
          FROM dbo.Service_Robot_Seller s, dbo.Service_Robot_Seller_Product sp
         WHERE s.SRBT_ROBO_RBID = @ROBO_RBID
           AND s.CODE = sp.SRBS_CODE
           AND sp.TARF_CODE = @TARF_CODE;           

        UPDATE rp
           SET rp.UNIT_APBS_CODE = @UNIT_APBS_CODE,
               rp.TARF_ENGL_TEXT = @TARF_ENGL_TEXT,
               rp.PROD_FETR = @PROD_FETR,
               rp.STAT = @STAT,
               rp.RELS_TIME = @RELS_TIME,
               rp.NUMB_TYPE = @NUMB_TYPE,
               rp.BRND_TEXT_DNRM = '',
               rp.GROP_TEXT_DNRM = '',
               rp.BUY_PRIC = @BUY_PRIC,
               rp.PROD_LIFE_STAT = ISNULL(@PROD_LIFE_STAT, '001'),
               rp.PROD_SUPL_LOCT_STAT = ISNULL(@PROD_SUPL_LOCT_STAT, '001'),
               rp.PROD_SUPL_LOCT_DESC = @PROD_SUPL_LOCT_DESC,
               rp.RESP_SHIP_COST_TYPE = ISNULL(@RESP_SHIP_COST_TYPE, '001'),
               rp.APRX_SHIP_COST_AMNT = @APRX_SHIP_COST_AMNT,
               rp.CRNC_CALC_STAT = @CRNC_CALC_STAT,
               rp.CRNC_EXPN_AMNT = @CRNC_EXPN_AMNT,
               rp.BAR_CODE = @BAR_CODE
          FROM dbo.Robot_Product rp
         WHERE rp.ROBO_RBID = @ROBO_RBID
           AND TARF_CODE = @TARF_CODE;

        COMMIT TRAN [T$UPD_RBPR_P];
    END TRY
    BEGIN CATCH
	    DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR ( @ErorMesg, 16, 1 );
        ROLLBACK TRAN [T$UPD_RBPR_P];
    END CATCH;
END;
GO
