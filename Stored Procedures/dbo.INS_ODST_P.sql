SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_ODST_P]
    @Ordr_Code BIGINT,
    @Apbs_Code BIGINT,
    @Stat_Date DATETIME,
    @Stat_Desc NVARCHAR(MAX),
    @Amnt BIGINT,
    @Amnt_Type VARCHAR(3),
    @Rcpt_Mtod VARCHAR(3),
    @Sorc_Card_Numb VARCHAR(16),
    @Dest_Card_Numb VARCHAR(16),
    @Txid VARCHAR(266),
    @Txfe_Prct SMALLINT,
    @Txfe_Calc_Amnt BIGINT,
    @Txfe_Amnt BIGINT,
    @Conf_Stat VARCHAR(3),
    @Conf_Date DATETIME,
    @Conf_Desc NVARCHAR(1000)
AS
BEGIN
    INSERT INTO dbo.Order_State
            ( ORDR_CODE ,
              APBS_CODE ,
              CODE ,
              STAT_DATE ,
              STAT_DESC ,
              AMNT,
              AMNT_TYPE, 
              RCPT_MTOD,
              SORC_CARD_NUMB,
              DEST_CARD_NUMB,
              TXID,
              TXFE_PRCT,
              TXFE_CALC_AMNT,
              TXFE_AMNT,
              CONF_STAT,
              CONF_DATE,
              CONF_DESC,
              FILE_TYPE
            )
    VALUES  ( @Ordr_Code , -- ORDR_CODE - bigint
              @Apbs_Code , -- APBS_CODE - bigint
              0 , -- CODE - bigint
              @Stat_Date , -- STAT_DATE - datetime
              @Stat_Desc ,  -- STAT_DESC - nvarchar(max)
              @Amnt ,
              @Amnt_Type,
              @Rcpt_Mtod,
              @Sorc_Card_Numb,
              @Dest_Card_Numb,
              @Txid,
              @Txfe_Prct,
              @Txfe_Calc_Amnt,
              @Txfe_Amnt,
              @Conf_Stat,
              @Conf_Date,
              @Conf_Desc,
              '001'
            );
END;
GO
