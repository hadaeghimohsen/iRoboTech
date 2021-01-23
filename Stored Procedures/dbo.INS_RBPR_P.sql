SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_RBPR_P]
    @ROBO_RBID BIGINT,
    --@CODE bigint  ,
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
    @MAX_SALE_DAY_NUMB_DNRM REAL,
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
    @Crnc_Calc_Stat VARCHAR(3),
    @Crnc_Expn_Amnt MONEY
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN T$INS_RBPR_P;
        DECLARE @Xtemp XML,
                @ServFileNo BIGINT,
                @SrbsCode BIGINT;

        SET @Xtemp =
        (
            SELECT 5 AS '@subsys',
                   '103' AS '@cmndcode',        -- عملیات جامع ذخیره سازی
                   12 AS '@refsubsys',          -- محل ارجاعی
                   'appuser' AS '@execaslogin', -- توسط کدام کاربری اجرا شود               
                   @TARF_TEXT_DNRM AS '@tarfname',
                   @TARF_CODE AS '@tarfcode'
            FOR XML PATH('Router_Command')
        );
        EXEC dbo.RouterdbCommand @X = @Xtemp,           -- xml
                                 @xRet = @Xtemp OUTPUT; -- xml

        IF @Xtemp.query('//Router_Command').value('(Router_Command/@rsltcode)[1]', 'VARCHAR(3)') = '002'
        BEGIN
            EXEC dbo.EXEC_JOBS_P @X = NULL; -- xml
            
            -- پیدا کردن کد محصول
            SELECT TOP 1 
                   @TARF_CODE = TARF_CODE
              FROM dbo.Robot_Product
             WHERE ROBO_RBID = @ROBO_RBID
               AND TARF_TEXT_DNRM = @TARF_TEXT_DNRM
               AND CRET_BY = UPPER(SUSER_NAME())
             ORDER BY CRET_DATE DESC;
            
            -- بروزرسانی جدول کالا با گزینه های دیگری که وجود داره
            SET @Xtemp = (
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
        END;
        ELSE
        BEGIN
            RAISERROR(N'در ثبت اطلاعات مشکلی به وجود آمده است', 16, 1);
        END;

        -- اگر فروشنده ای وجود نداشته باشد
        IF NOT EXISTS
        (
            SELECT *
            FROM dbo.Service_Robot sr,
                 dbo.Service_Robot_Seller s
            WHERE sr.ROBO_RBID = s.SRBT_ROBO_RBID
                  AND sr.SERV_FILE_NO = s.SRBT_SERV_FILE_NO
                  AND sr.ROBO_RBID = @ROBO_RBID
        )
        BEGIN
            IF EXISTS
            (
                SELECT *
                FROM dbo.[Group] g,
                     dbo.Service_Robot_Group srg
                WHERE g.ROBO_RBID = @ROBO_RBID
                      AND g.GPID = 131
                      AND g.GPID = srg.GROP_GPID
                      AND g.ROBO_RBID = srg.SRBT_ROBO_RBID
            )
            BEGIN
                -- دسترسی مدیر فروشگاه مشخص شده
                SELECT TOP 1
                       @ServFileNo = srg.SRBT_SERV_FILE_NO
                FROM dbo.[Group] g,
                     dbo.Service_Robot_Group srg
                WHERE g.ROBO_RBID = @ROBO_RBID
                      AND g.GPID = 131
                      AND g.GPID = srg.GROP_GPID
                      AND g.ROBO_RBID = srg.SRBT_ROBO_RBID;
                -- حال در مرحله بعدی مشخص میکنیم که آیا رکورد مدیر فروشگاه ثبت شده یا خیر
                INSERT INTO dbo.Service_Robot_Seller
                (
                    SRBT_SERV_FILE_NO,
                    SRBT_ROBO_RBID,
                    CODE,
                    CONF_STAT,
                    CONF_DATE
                )
                SELECT sr.SERV_FILE_NO,
                       sr.ROBO_RBID,
                       dbo.GNRT_NVID_U(),
                       '002',
                       GETDATE()
                FROM dbo.Service_Robot sr
                WHERE sr.SERV_FILE_NO = @ServFileNo
                      AND sr.ROBO_RBID = @ROBO_RBID;
            END;
            ELSE
            BEGIN
                RAISERROR(N'مدیر فروشگاه مشخص نشده', 16, 1);
            END;
        END;

        -- بدست آوردن اطلاعات مربوط به مدیر فروشگاه
        SELECT TOP 1 @SrbsCode = CODE
        FROM dbo.Service_Robot_Seller
        WHERE SRBT_ROBO_RBID = @ROBO_RBID;

        INSERT INTO dbo.Service_Robot_Seller_Product
        (
            SRBS_CODE,CODE,TARF_CODE,DELV_DAY,DELV_HOUR,DELV_MINT,MAKE_DAY,MAKE_HOUR,MAKE_MINT,
            ALRM_MIN_NUMB,PROD_TYPE,MIN_ORDR,
            MADE_IN,GRNT_STAT,GRNT_NUMB,GRNT_TIME,GRNT_TYPE, GRNT_DESC,WRNT_STAT,WRNT_NUMB,WRNT_TIME,WRNT_TYPE,WRNT_DESC,
            WEGH_AMNT
        )
        VALUES(
            @SRBSCODE,dbo.GNRT_NVID_U(),@TARF_CODE,@DELV_DAY_DNRM,@DELV_HOUR_DNRM,@DELV_MINT_DNRM,@MAKE_DAY_DNRM,@MAKE_HOUR_DNRM,@MAKE_MINT_DNRM,
            @ALRM_MIN_NUMB_DNRM,@PROD_TYPE_DNRM,@MIN_ORDR_DNRM,
            @MADE_IN_DNRM,@GRNT_STAT_DNRM,@GRNT_NUMB_DNRM,@GRNT_TIME_DNRM,@GRNT_TYPE_DNRM, @GRNT_DESC_DNRM,@WRNT_STAT_DNRM,@WRNT_NUMB_DNRM,@WRNT_TIME_DNRM,@WRNT_TYPE_DNRM,@WRNT_DESC_DNRM,
            @WEGH_AMNT_DNRM
        );        

        UPDATE rp
           SET rp.UNIT_APBS_CODE = @UNIT_APBS_CODE,
               rp.TARF_ENGL_TEXT = @TARF_ENGL_TEXT,
               rp.PROD_FETR = @PROD_FETR,
               rp.STAT = @STAT,
               rp.RELS_TIME = @RELS_TIME,
               rp.NUMB_TYPE = @NUMB_TYPE,
               rp.BUY_PRIC = @BUY_PRIC,
               rp.PROD_LIFE_STAT = ISNULL(@PROD_LIFE_STAT, '001'),
               rp.PROD_SUPL_LOCT_STAT = ISNULL(@PROD_SUPL_LOCT_STAT, '001'),
               rp.PROD_SUPL_LOCT_DESC = @PROD_SUPL_LOCT_DESC,
               rp.RESP_SHIP_COST_TYPE = ISNULL(@RESP_SHIP_COST_TYPE, '001'),
               rp.APRX_SHIP_COST_AMNT = @APRX_SHIP_COST_AMNT,
               rp.CRNC_CALC_STAT = @Crnc_Calc_Stat,
               rp.CRNC_EXPN_AMNT = @Crnc_Expn_Amnt
          FROM dbo.Robot_Product rp
         WHERE rp.ROBO_RBID = @ROBO_RBID
           AND TARF_CODE = @TARF_CODE;        

        COMMIT TRAN [T$INS_RBPR_P];
    END TRY
    BEGIN CATCH
   	    DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR ( @ErorMesg, 16, 1 );        
        ROLLBACK TRAN [T$INS_RBPR_P];
    END CATCH;
END;
GO
