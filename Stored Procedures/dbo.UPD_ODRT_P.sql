SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_ODRT_P]
    @Ordr_Code BIGINT ,
    @Rwno BIGINT ,
    @Elmn_Type VARCHAR(3) ,
    @Ordr_Desc NVARCHAR(MAX) ,
    @Expn_Pric BIGINT,
    @Extr_Prct BIGINT,
    @Tax_Prct INT,
    @Off_Prct REAL,
    @Numb REAL ,
    @Base_Ussd_Code VARCHAR(250) ,
    @Sub_Ussd_Code VARCHAR(250) ,
    @Ordr_Cmnt NVARCHAR(4000) ,
    @Ordr_Imag IMAGE ,
    @Imag_Path NVARCHAR(4000) ,
    @Mime_Type VARCHAR(100) ,
    @Ghit_Code BIGINT ,
    @Ghit_Min_Date DATETIME ,
    @Ghit_Max_Date DATETIME
AS
BEGIN
    UPDATE  dbo.Order_Detail
    SET     ELMN_TYPE = @Elmn_Type ,
            ORDR_DESC = @Ordr_Desc ,
            EXPN_PRIC = @Expn_Pric,
            EXTR_PRCT = @Extr_Prct,
            TAX_PRCT = @Tax_Prct,
            OFF_PRCT = @Off_Prct,
            NUMB = @Numb ,
            BASE_USSD_CODE = @Base_Ussd_Code ,
            SUB_USSD_CODE = @Sub_Ussd_Code ,
            ORDR_CMNT = @Ordr_Cmnt ,
            ORDR_IMAG = @Ordr_Imag ,
            IMAG_PATH = @Imag_Path ,
            MIME_TYPE = @Mime_Type ,
            GHIT_CODE = @Ghit_Code ,
            GHIT_MIN_DATE = @Ghit_Min_Date ,
            GHIT_MAX_DATE = @Ghit_Max_Date
    WHERE   ORDR_CODE = @Ordr_Code
            AND RWNO = @Rwno;
END;
GO
