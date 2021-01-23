SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DUP_RBPR_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	   BEGIN TRAN T$DUP_RBPR_P
   	DECLARE @idty BIT
   	       ,@gift BIT
   	       ,@stor BIT
   	       ,@rlat BIT
   	       ,@sprc BIT
   	       ,@altr BIT
   	       ,@dsct BIT
   	       ,@sprt BIT
   	       ,@psam BIT
   	       ,@type VARCHAR(10)
   	       ,@SorcTarfCode VARCHAR(100);
   	
   	SELECT @idty = @X.query('//Duplicate').value('(Duplicate/@idty)[1]','BIT')
   	      ,@gift = @X.query('//Duplicate').value('(Duplicate/@gift)[1]','BIT')
   	      ,@stor = @X.query('//Duplicate').value('(Duplicate/@stor)[1]','BIT')
   	      ,@rlat = @X.query('//Duplicate').value('(Duplicate/@rlat)[1]','BIT')
   	      ,@sprc = @X.query('//Duplicate').value('(Duplicate/@sprc)[1]','BIT')
   	      ,@altr = @X.query('//Duplicate').value('(Duplicate/@altr)[1]','BIT')
   	      ,@dsct = @X.query('//Duplicate').value('(Duplicate/@dsct)[1]','BIT')
   	      ,@sprt = @X.query('//Duplicate').value('(Duplicate/@sprt)[1]','BIT')
   	      ,@psam = @X.query('//Duplicate').value('(Duplicate/@psam)[1]','BIT')
   	      ,@type = @X.query('//Duplicate').value('(Duplicate/@type)[1]','VARCHAR(10)')
   	      ,@SorcTarfCode = @X.query('//Source').value('(Source/@tarfcode)[1]','VARCHAR(100)');
   	
   	DECLARE @ROBORBID bigint ,
	           @CODE bigint ,
	           @EXPNPRICDNRM bigint ,
	           @EXTRPRCTDNRM bigint ,
	           @BUYPRIC bigint ,
	           @UNITAPBSCODE bigint ,
	           @PRODFETR nvarchar(max) ,
	           @TARFTEXTDNRM nvarchar(250) ,
	           @TARFENGLTEXT nvarchar(250) ,
	           @BRNDCODEDNRM bigint ,
	           @GROPCODEDNRM bigint ,
	           @ROOTGROPCODEDNRM bigint ,
	           @GROPJOINDNRM varchar(50) ,
	           @DELVDAYDNRM smallint ,
	           @DELVHOURDNRM smallint ,
	           @DELVMINTDNRM smallint ,
	           @MAKEDAYDNRM smallint ,
	           @MAKEHOURDNRM smallint ,
	           @MAKEMINTDNRM smallint ,
	           @RELSTIME datetime ,
	           @STAT varchar(3) ,
	           @ALRMMINNUMBDNRM real ,
	           @PRODTYPEDNRM varchar(3) ,
	           @MINORDRDNRM real ,
	           @MADEINDNRM varchar(3) ,
	           @GRNTSTATDNRM varchar(3) ,
	           @GRNTNUMBDNRM int ,
	           @GRNTTIMEDNRM varchar(3) ,
	           @GRNTTYPEDNRM varchar(3) ,
	           @GRNTDESCDNRM nvarchar(4000) ,
	           @WRNTSTATDNRM varchar(3) ,
	           @WRNTNUMBDNRM int ,
	           @WRNTTIMEDNRM varchar(3) ,
	           @WRNTTYPEDNRM varchar(3) ,
	           @WRNTDESCDNRM nvarchar(4000) ,
	           @WEGHAMNTDNRM real ,
	           @NUMBTYPE varchar(3) ,
	           @PRODLIFESTAT varchar(3) ,
	           @PRODSUPLLOCTSTAT varchar(3) ,
	           @PRODSUPLLOCTDESC nvarchar(250) ,
	           @RESPSHIPCOSTTYPE varchar(3) ,
	           @APRXSHIPCOSTAMNT bigint;
	   
	   SELECT @ROBORBID = p.ROBO_RBID,
	          @CODE = p.CODE ,
	          @EXPNPRICDNRM = p.EXPN_PRIC_DNRM ,
	          @EXTRPRCTDNRM = p.EXTR_PRCT_DNRM ,
	          @BUYPRIC = p.BUY_PRIC ,
	          @UNITAPBSCODE = p.UNIT_APBS_CODE ,
	          @PRODFETR  = p.PROD_FETR ,
	          @TARFTEXTDNRM = p.TARF_TEXT_DNRM ,
	          @TARFENGLTEXT = p.TARF_ENGL_TEXT ,
	          @BRNDCODEDNRM = p.BRND_CODE_DNRM ,
	          @GROPCODEDNRM = p.GROP_CODE_DNRM ,
	          @ROOTGROPCODEDNRM = p.ROOT_GROP_CODE_DNRM ,
	          @GROPJOINDNRM = p.GROP_JOIN_DNRM ,
	          @DELVDAYDNRM = p.DELV_DAY_DNRM ,
	          @DELVHOURDNRM = p.DELV_HOUR_DNRM ,
	          @DELVMINTDNRM = p.DELV_MINT_DNRM ,
	          @MAKEDAYDNRM = p.MAKE_DAY_DNRM ,
	          @MAKEHOURDNRM = p.MAKE_HOUR_DNRM ,
	          @MAKEMINTDNRM = p.MAKE_MINT_DNRM ,
	          @RELSTIME = p.RELS_TIME ,
	          @STAT = p.STAT ,
	          @ALRMMINNUMBDNRM = p.ALRM_MIN_NUMB_DNRM ,
	          @PRODTYPEDNRM = p.PROD_TYPE_DNRM ,
	          @MINORDRDNRM = p.MIN_ORDR_DNRM ,
	          @MADEINDNRM = p.MADE_IN_DNRM ,
	          @GRNTSTATDNRM = p.GRNT_STAT_DNRM ,
	          @GRNTNUMBDNRM = p.GRNT_NUMB_DNRM ,
	          @GRNTTIMEDNRM = p.GRNT_TIME_DNRM ,
	          @GRNTTYPEDNRM = p.GRNT_TYPE_DNRM ,
	          @GRNTDESCDNRM = p.GRNT_DESC_DNRM ,
	          @WRNTSTATDNRM = p.WRNT_STAT_DNRM ,
	          @WRNTNUMBDNRM = p.WRNT_NUMB_DNRM ,
	          @WRNTTIMEDNRM = p.WRNT_TIME_DNRM ,
	          @WRNTTYPEDNRM = p.WRNT_TYPE_DNRM ,
	          @WRNTDESCDNRM = p.WRNT_DESC_DNRM,
	          @WEGHAMNTDNRM = p.WEGH_AMNT_DNRM,
	          @NUMBTYPE = p.NUMB_TYPE ,
	          @PRODLIFESTAT = p.PROD_LIFE_STAT ,
	          @PRODSUPLLOCTSTAT = p.PROD_SUPL_LOCT_STAT ,
	          @PRODSUPLLOCTDESC = p.PROD_SUPL_LOCT_DESC ,
	          @RESPSHIPCOSTTYPE = p.RESP_SHIP_COST_TYPE ,
	          @APRXSHIPCOSTAMNT = p.APRX_SHIP_COST_AMNT
	     FROM dbo.Robot_Product p
	    WHERE p.TARF_CODE = @SorcTarfCode;
	   
	   DECLARE @ArrayOprt VARCHAR(3) = '001';
	   
	   IF @type = 'single'
	   BEGIN
	      -- New Record;
	      DECLARE @TrgtTarfCode VARCHAR(100);
	      IF @idty = 1
	         SET @TrgtTarfCode = (
	             SELECT MAX(CAST(p.TARF_CODE AS BIGINT)) + 1
	               FROM dbo.Robot_Product p
	              WHERE p.ROBO_RBID = @ROBORBID
	                AND ISNUMERIC(p.TARF_CODE) = 1	              
	         );
	      
	      L$SingleOprt:
	      
	      -- Exec Procedure For Save And Insert Products
         EXEC dbo.INS_RBPR_P @ROBO_RBID = @ROBORBID, -- bigint
               @TARF_CODE = @TrgtTarfCode, -- varchar(100)
               @EXPN_PRIC_DNRM = @EXPNPRICDNRM, -- bigint
               @EXTR_PRCT_DNRM = @EXTRPRCTDNRM, -- bigint
               @BUY_PRIC = @BuyPric,
               @UNIT_APBS_CODE = @UNITAPBSCODE, -- bigint
               @PROD_FETR = @TARFTEXTDNRM, -- nvarchar(max)
               @TARF_TEXT_DNRM = @TARFTEXTDNRM, -- nvarchar(250)
               @TARF_ENGL_TEXT = @TARFENGLTEXT, -- nvarchar(250)
               @BRND_CODE_DNRM = @BRNDCODEDNRM, -- bigint
               @GROP_CODE_DNRM = @GROPCODEDNRM, -- bigint
               @GROP_JOIN_DNRM = @GROPJOINDNRM, -- varchar(50)
               @DELV_DAY_DNRM = @DELVDAYDNRM, -- smallint
               @DELV_HOUR_DNRM = @DELVHOURDNRM, -- smallint
               @DELV_MINT_DNRM = @DELVMINTDNRM, -- smallint
               @MAKE_DAY_DNRM = @MAKEDAYDNRM, -- smallint
               @MAKE_HOUR_DNRM = @MAKEHOURDNRM, -- smallint
               @MAKE_MINT_DNRM = @MAKEMINTDNRM, -- smallint
               @RELS_TIME = @RELSTIME, -- datetime
               @STAT = @STAT, -- varchar(3)
               @MAX_SALE_DAY_NUMB_DNRM = 0, -- real
               @ALRM_MIN_NUMB_DNRM = @ALRMMINNUMBDNRM, -- real
               @PROD_TYPE_DNRM = @PRODTYPEDNRM, -- varchar(3)
               @MIN_ORDR_DNRM = @MINORDRDNRM, -- real
               @MADE_IN_DNRM = @MADEINDNRM, -- varchar(3)
               @GRNT_STAT_DNRM = @GRNTSTATDNRM, -- varchar(3)
               @GRNT_NUMB_DNRM = @GRNTNUMBDNRM, -- int
               @GRNT_TIME_DNRM = @GRNTTIMEDNRM, -- varchar(3)
               @GRNT_TYPE_DNRM = @GRNTTYPEDNRM, -- varchar(3)
               @GRNT_DESC_DNRM = @GRNTDESCDNRM, -- nvarchar(4000)
               @WRNT_STAT_DNRM = @WRNTSTATDNRM, -- varchar(3)
               @WRNT_NUMB_DNRM = @WRNTNUMBDNRM, -- int
               @WRNT_TIME_DNRM = @WRNTTIMEDNRM, -- varchar(3)
               @WRNT_TYPE_DNRM = @WRNTTYPEDNRM, -- varchar(3)
               @WRNT_DESC_DNRM = @WRNTDESCDNRM, -- nvarchar(4000)
               @WEGH_AMNT_DNRM = @WEGHAMNTDNRM, -- real
               @NUMB_TYPE = @NUMBTYPE,
               @PROD_LIFE_STAT = @PRODLIFESTAT,
               @PROD_SUPL_LOCT_STAT = @PRODSUPLLOCTSTAT,
               @PROD_SUPL_LOCT_DESC = @PRODSUPLLOCTDESC,
               @RESP_SHIP_COST_TYPE = @RESPSHIPCOSTTYPE,
               @APRX_SHIP_COST_AMNT = @APRXSHIPCOSTAMNT; -- varchar(3)
         
         SELECT @CODE = p.CODE
            FROM dbo.Robot_Product p
           WHERE p.TARF_CODE = @TrgtTarfCode;
          
         IF @stor = 1  
            INSERT INTO dbo.Service_Robot_Seller_Product_Store ( SRSP_CODE ,CODE ,STOR_DATE ,NUMB ,MAKE_DATE ,EXPR_DATE )
            SELECT sp.CODE, dbo.GNRT_NVID_U(), GETDATE(), NUMB, GETDATE(), DATEADD(YEAR, 1, GETDATE())
              FROM dbo.Service_Robot_Seller_Product_Store p, dbo.Service_Robot_Seller_Product sp
             WHERE p.TARF_CODE_DNRM = @SorcTarfCode
               AND sp.TARF_CODE = @TrgtTarfCode;
         
         IF @gift = 1
            INSERT INTO dbo.Service_Robot_Seller_Product_Gift ( SRSP_CODE ,SSPG_CODE ,CODE ,STAT )
            SELECT sp.CODE, g.SSPG_CODE, dbo.GNRT_NVID_U(), g.STAT
              FROM dbo.Service_Robot_Seller_Product_Gift g, dbo.Service_Robot_Seller_Product sp
             WHERE g.TARF_CODE_DNRM = @SorcTarfCode
               AND sp.TARF_CODE = @TrgtTarfCode;
         
         IF @sprc = 1
            INSERT INTO dbo.Robot_Product_StepPrice ( RBPR_CODE ,RWNO ,STEP_TYPE ,TARF_CODE_QNTY ,CART_SUM_PRIC ,EXPN_PRIC ,STAT )
            SELECT p.CODE, sp.RWNO, sp.STEP_TYPE, sp.TARF_CODE_QNTY, sp.CART_SUM_PRIC, sp.EXPN_PRIC, sp.STAT
              FROM dbo.Robot_Product_StepPrice sp, dbo.Robot_Product p
             WHERE sp.TARF_CODE_DNRM = @SorcTarfCode
               AND p.TARF_CODE = @TrgtTarfCode;
         
         IF @dsct = 1
            INSERT INTO dbo.Robot_Product_Discount ( ROBO_RBID ,RBPR_CODE ,CODE ,TARF_CODE ,OFF_TYPE ,OFF_PRCT ,REMN_TIME ,ACTV_TYPE ,OFF_DESC )
            SELECT p.ROBO_RBID, p.CODE, dbo.GNRT_NVID_U(), p.TARF_CODE, d.OFF_TYPE, d.OFF_PRCT, d.REMN_TIME, d.ACTV_TYPE, d.OFF_DESC
              FROM dbo.Robot_Product_Discount d, dbo.Robot_Product p
             WHERE d.TARF_CODE = @SorcTarfCode
               AND p.TARF_CODE = @TrgtTarfCode;
          
         IF @sprt = 1
            INSERT INTO dbo.Service_Robot_Seller_Partner ( SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,RBPR_CODE ,CODE ,EXPN_PRIC ,EXTR_PRCT ,BUY_PRIC ,STAT )
            SELECT sp.SRBT_SERV_FILE_NO, sp.SRBT_ROBO_RBID, p.CODE, dbo.GNRT_NVID_U(), sp.EXPN_PRIC, sp.EXTR_PRCT, sp.BUY_PRIC, sp.STAT
              FROM dbo.Service_Robot_Seller_Partner sp, dbo.Robot_Product p
             WHERE sp.TARF_CODE_DNRM = @SorcTarfCode
               AND p.TARF_CODE = @TrgtTarfCode;
         
         IF @ArrayOprt = '002'
            GOTO L$ArrayNextOprt;
	   END 
	   ELSE
	   BEGIN
	      SET @ArrayOprt = '002';
	      
	      -- Loop For TarfCodes
         DECLARE @docHandle INT;	
         EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;

         DECLARE C$TarfCodes CURSOR
         FOR
         SELECT *
           FROM OPENXML(@docHandle, N'//Product')
           WITH (        
              TarfCode VARCHAR(100) '@tarfcode'
           );
         
         OPEN [C$TarfCodes];
         L$Loop$C$TarfCodes:
         FETCH [C$TarfCodes] INTO @TrgtTarfCode;
         
         IF @@FETCH_STATUS <> 0
            GOTO L$EndLoop$C$TarfCodes;
         
         -- اگر محصول وجود نداشته باشد
         IF NOT EXISTS (SELECT * FROM dbo.Robot_Product rp WHERE rp.ROBO_RBID = @ROBORBID AND rp.TARF_CODE = @TrgtTarfCode)
         BEGIN
            GOTO L$SingleOprt;
            L$ArrayNextOprt:
         END
         
         GOTO L$Loop$C$TarfCodes;
         L$EndLoop$C$TarfCodes:
         CLOSE [C$TarfCodes];
         DEALLOCATE [C$TarfCodes];
	   END 
	           
      COMMIT TRAN [T$DUP_RBPR_P]
	END TRY
	BEGIN CATCH
      DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK TRAN [T$DUP_RBPR_P];	
	END CATCH
END
GO
