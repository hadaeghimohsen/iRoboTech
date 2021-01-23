SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_ODRT_P]
   @Ordr_Code BIGINT,
   @Elmn_Type VARCHAR(3),
   @Ordr_Desc NVARCHAR(MAX),
   @Expn_Pric BIGINT,
   @Extr_Prct BIGINT,
   @Tax_Prct INT,
   @Off_Prct REAL,
   @Numb REAL,
   @Base_Ussd_Code VARCHAR(250),
   @Sub_Ussd_Code VARCHAR(250),
   @Ordr_Cmnt NVARCHAR(4000),
   @Ordr_Imag IMAGE,
   @Imag_Path NVARCHAR(4000),
   @Mime_Type VARCHAR(100),
   @Ghit_Code BIGINT,
   @Ghit_Min_Date DATETIME,
   @Ghit_Max_Date DATETIME
AS BEGIN
   INSERT INTO dbo.Order_Detail
           ( ORDR_CODE ,
             ELMN_TYPE ,
             ORDR_DESC ,
             EXPN_PRIC,
             EXTR_PRCT,
             TAX_PRCT,
             OFF_PRCT,
             NUMB ,
             BASE_USSD_CODE ,
             SUB_USSD_CODE ,
             ORDR_CMNT ,
             ORDR_IMAG ,
             IMAG_PATH ,
             MIME_TYPE ,
             GHIT_CODE ,
             GHIT_MIN_DATE ,
             GHIT_MAX_DATE 
           )
   VALUES  ( @Ordr_Code , -- ORDR_CODE - bigint
             @Elmn_Type , -- ELMN_TYPE - varchar(3)
             @Ordr_Desc , -- ORDR_DESC - nvarchar(max)
             @Expn_Pric,
             @Extr_Prct,
             @Tax_Prct,
             @Off_Prct,
             @Numb , -- NUMB - int
             @Base_Ussd_Code , -- BASE_USSD_CODE - varchar(250)
             @Sub_Ussd_Code , -- SUB_USSD_CODE - varchar(250)
             @Ordr_Cmnt , -- ORDR_CMNT - nvarchar(4000)
             @Ordr_Imag , -- ORDR_IMAG - image
             @Imag_Path , -- IMAG_PATH - nvarchar(4000)
             @Mime_Type , -- MIME_TYPE - varchar(100)
             @Ghit_Code, -- GHIT_CODE - bigint
             @Ghit_Min_Date , -- GHIT_MIN_DATE - datetime
             @Ghit_Max_Date  -- GHIT_MAX_DATE - datetime
           );
END;
GO
