SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Set_Personal_Robot_Job_Order]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	
	DECLARE @PrjbCode BIGINT
	       ,@OrdrCode BIGINT
	       ,@OrdrStat VARCHAR(3);
	
	SELECT @PrjbCode = @X.query('//PJBO').value('(PJBO/@prjbcode)[1]', 'BIGINT'),
	       @OrdrCode = @X.query('//PJBO').value('(PJBO/@ordrcode)[1]', 'BIGINT'),
	       @OrdrStat = @X.query('//PJBO').value('(PJBO/@ordrstat)[1]', 'VARCHAR(3)');
	       
	UPDATE dbo.Personal_Robot_Job_Order
	   SET ORDR_STAT = @OrdrStat
	 WHERE PRJB_CODE = @PrjbCode
	   AND ORDR_CODE = @OrdrCode;
	
	-- اگر یک درخواست در زمان های مختلفی نیاز هست پیام های مختلفی به آن الحاق کنیم مشخص شود که تا به الان چه پیام هایی ارسال شده
	UPDATE dbo.Order_Detail
	   SET SEND_STAT = '002'
	 WHERE ORDR_CODE = @OrdrCode;
	
END
GO
