SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[INS_GHIT_P]
   @GPHD_GHID BIGINT
  ,@GHDT_DESC NVARCHAR(100)
  ,@Pric BIGINT
  ,@Tax_Prct INT
  ,@Amnt_Type VARCHAR(3)
  ,@Unit_Apbs_Code BIGINT
  ,@Scnd_Numb SMALLINT
  ,@Mint_Numb SMALLINT
  ,@Hors_Numb SMALLINT
  ,@Days_Numb SMALLINT
  ,@Mont_Numb SMALLINT
  ,@Year_Numb SMALLINT
  ,@Stat VARCHAR(3)
  ,@Coef_Stat VARCHAR(3)
  ,@Grmu_Mnus_Robo_Rbid BIGINT
  ,@Grmu_Mnus_Muid BIGINT
  ,@Grmu_Grop_Gpid BIGINT
AS
BEGIN
   INSERT INTO dbo.Group_Header_Item
           ( GPHD_GHID ,
             CODE ,             
             GHDT_DESC ,
             PRIC ,
             TAX_PRCT ,
             AMNT_TYPE ,
             UNIT_APBS_CODE ,
             SCND_NUMB ,
             MINT_NUMB ,
             HORS_NUMB ,
             DAYS_NUMB ,
             MONT_NUMB ,
             YEAR_NUMB ,
             STAT ,
             COEF_STAT ,
             GRMU_MNUS_ROBO_RBID ,
             GRMU_MNUS_MUID ,
             GRMU_GROP_GPID
           )
   VALUES  ( @GPHD_GHID , -- GPHD_GHID - bigint             
             0 ,
             @GHDT_DESC , -- GHDT_DESC - nvarchar(100)
             @Pric , -- PRIC - bigint
             ISNULL(@Tax_Prct, 0) ,
             @Amnt_Type ,
             @Unit_Apbs_Code ,
             @Scnd_Numb , -- SCND_NUMB - smallint
             @Mint_Numb , -- MINT_NUMB - smallint
             @Hors_Numb , -- HORS_NUMB - smallint
             @Days_Numb , -- DAYS_NUMB - smallint
             @Mont_Numb , -- MONT_NUMB - smallint
             @Year_Numb , -- YEAR_NUMB - smallint
             @Stat , -- STAT - varchar(3)
             @Coef_Stat ,  -- COEF_STAT - varchar(3)
             @Grmu_Mnus_Robo_Rbid,
             @Grmu_Mnus_Muid,
             @Grmu_Grop_Gpid
           );
END;
GO
