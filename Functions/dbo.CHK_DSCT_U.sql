SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[CHK_DSCT_U]
(
	@X XML
)
RETURNS VARCHAR(3)
AS
BEGIN
	DECLARE @Dcid BIGINT = @X.query('//Service_Robot_Discount_Card').value('(Service_Robot_Discount_Card/@dcid)[1]', 'BIGINT'),
	        @ChatId BIGINT = @X.query('//Service_Robot_Discount_Card').value('(Service_Robot_Discount_Card/@chatid)[1]', 'BIGINT'),
	        @Rbid BIGINT = @X.query('//Service_Robot_Discount_Card').value('(Service_Robot_Discount_Card/@rbid)[1]', 'BIGINT'),
	        @OrdrCode BIGINT = @X.query('//Service_Robot_Discount_Card').value('(Service_Robot_Discount_Card/@ordrcode)[1]', 'BIGINT'),
	        @Result VARCHAR(3) = '000';
	
	-- آیا قبلا این کد تخفیف استفاده شده یا خیر
	IF EXISTS(
	   SELECT *
	     FROM dbo.Order_State os
	    WHERE os.DISC_DCID = @Dcid
	      AND os.ORDR_CODE != @OrdrCode
	      AND os.AMNT_TYPE = '002' -- تخفیف
	      AND os.CONF_STAT = '002' -- کد تخفیف تایید شده باشد
	      AND NOT EXISTS ( -- گزینه درصد تخفیف همکار به ازای هر بار ثبت سفارش محاسبه میشود و از بین نمیرود
	          SELECT *
	            FROM dbo.Service_Robot_Discount_Card dc
	           WHERE dc.DCID = @Dcid
	             AND dc.OFF_TYPE = '008'
	             AND dc.OFF_KIND = '004'
	      )
	)
	BEGIN
	   RETURN '001';
	END
	
	-- ایا کد تخفیف اعتبار دارد یا خیر 
	IF NOT EXISTS(
	   SELECT *
	     FROM dbo.Service_Robot_Discount_Card a, dbo.[Order] o
	    WHERE a.DCID = @Dcid
	      AND o.CODE = @OrdrCode
	      AND a.VALD_TYPE = '002'
	      AND (
	          ( a.OFF_KIND = '001' /* تخفیف عادی */ AND ( a.EXPR_DATE >= GETDATE() ) AND EXISTS(SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE AND ISNULL(od.OFF_PRCT, 0) = 0) ) OR 
	          ( a.OFF_KIND = '002' /* تخفیف چرخونه شانس */ AND ( a.EXPR_DATE >= GETDATE() AND a.FROM_AMNT <= (o.DEBT_DNRM) ) ) OR
	          ( a.OFF_KIND = '004' /* تخفیف عادی ویژه همکار فروش */ )
	      )
	)
	BEGIN
	   RETURN '001';
	END 
	
	-- بن تخفیف معتبر میباشد
	RETURN '002';
END
GO
