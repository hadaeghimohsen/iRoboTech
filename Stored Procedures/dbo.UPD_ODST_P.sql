SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_ODST_P]
    @Apbs_Code BIGINT,
    @Code BIGINT,
    @Stat_Date DATETIME,
    @Stat_Desc NVARCHAR(MAX) ,
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
    -- اگر رسید های گرداخت برای درخواست تایید یا عدم تایید زده باشند و تاریخ برای آن در نظر گرفته نشده باشد تاریخ امروز را به صورت اتومات قرار میدهیم
    IF @Amnt_Type = '005' AND @Conf_Stat IN ( '002', '001' ) AND @Conf_Date IS NULL SET @Conf_Date = GETDATE();
    -- اگر رسیدی را دوباره در وضعیت بررسی قرار داده شود باید دوباره تاریخ از نوع ثبت شود
    IF @Amnt_Type = '005' AND @Conf_Stat = '003' SET @Conf_Date = NULL;
          
    UPDATE dbo.Order_State
       SET STAT_DATE = @Stat_Date
          ,STAT_DESC = @Stat_Desc
          ,APBS_CODE = @Apbs_Code
          ,AMNT = @Amnt
          ,AMNT_TYPE = @Amnt_Type
          ,RCPT_MTOD = @Rcpt_Mtod
          ,SORC_CARD_NUMB = @Sorc_Card_Numb
          ,DEST_CARD_NUMB = @Dest_Card_Numb
          ,TXID = @Txid
          ,TXFE_PRCT = @Txfe_Prct
          ,TXFE_CALC_AMNT = @Txfe_Calc_Amnt
          ,TXFE_AMNT = @Txfe_Amnt
          ,CONF_STAT = @Conf_Stat
          ,CONF_DATE = @Conf_Date
          ,CONF_DESC = @Conf_Desc         
     WHERE CODE = @Code;
END;
GO
