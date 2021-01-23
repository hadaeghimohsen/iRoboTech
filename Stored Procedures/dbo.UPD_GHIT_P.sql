SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[UPD_GHIT_P]
   @Code BIGINT
  ,@GPHD_GHID BIGINT
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
   UPDATE dbo.Group_Header_Item
      SET GPHD_GHID = @GPHD_GHID ,
          GHDT_DESC = @GHDT_DESC ,
          PRIC = @PRIC ,
          TAX_PRCT = ISNULL(@Tax_Prct, 0) ,
          AMNT_TYPE = @Amnt_Type ,
          UNIT_APBS_CODE = @Unit_Apbs_Code ,
          SCND_NUMB = @SCND_NUMB ,
          MINT_NUMB = @MINT_NUMB ,
          HORS_NUMB = @HORS_NUMB,
          DAYS_NUMB = @DAYS_NUMB ,
          MONT_NUMB = @MONT_NUMB ,
          YEAR_NUMB = @YEAR_NUMB,
          STAT = @STAT,
          COEF_STAT = @COEF_STAT ,
          GRMU_MNUS_ROBO_RBID = @Grmu_Mnus_Robo_Rbid ,
          GRMU_MNUS_MUID = @Grmu_Mnus_Muid,
          GRMU_GROP_GPID = @Grmu_Grop_Gpid
   WHERE CODE = @Code;
   
END;
GO
