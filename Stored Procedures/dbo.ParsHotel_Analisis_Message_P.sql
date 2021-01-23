SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ParsHotel_Analisis_Message_P]
	@X XML,
	@XResult XML OUT
AS
BEGIN
   DECLARE @UssdCode VARCHAR(250),
           @MenuText NVARCHAR(250),
           @Message NVARCHAR(MAX);
	
	SELECT @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]', 'VARCHAR(250)'),
	       @MenuText = @X.query('//Text').value('.', 'NVARCHAR(250)');

   IF @UssdCode = '*1*2*1#'
	BEGIN
	   SELECT @Message = (
	      SELECT o.NAME + ' ' + r.NAME + CHAR(10)
	        FROM Organ o, Robot r
	       WHERE o.OGID = r.ORGN_OGID
	         AND ( o.NAME LIKE N'%'+ @MenuText +N'%'
	            OR o.ORGN_DESC LIKE N'%'+ @MenuText +N'%'
	            OR r.NAME LIKE N'%'+ @MenuText +N'%'
	            OR o.KEY_WORD LIKE N'%'+ @MenuText +N'%'
	         )
	         AND o.STAT = '002'
	         AND r.STAT = '002'
	       ORDER BY o.OGID, r.RBID
	         FOR XML PATH('')
	   );
	END
	ELSE IF @UssdCode = '*1*2*2#'
	BEGIN
	   SELECT 1;
	END
	
	SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END
GO
