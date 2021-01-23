SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[EightFastFood_Analisis_Message_P]
	@X XML,
	@XResult XML OUT
AS
BEGIN
   DECLARE @UssdCode VARCHAR(250),
           @MenuText NVARCHAR(250),
           @Message NVARCHAR(MAX),
           @ChatID BIGINT,
           @CordX  REAL,
           @CordY  REAL,
           @FileId VARCHAR(MAX);
	
	SELECT @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]', 'VARCHAR(250)'),
	       @ChatID   = @X.query('//Message').value('(Message/@chatid)[1]', 'BIGINT'),	       
	       @MenuText = @X.query('//Text').value('.', 'NVARCHAR(250)'),
	       @CordX    = @X.query('//Location').value('(Location/@latitude)[1]', 'REAL'),
	       @CordY    = @X.query('//Location').value('(Location/@longitude)[1]', 'REAL'),
	       @FileId   = @X.query('//Photo').value('(Photo/@fileid)[1]', 'NVARCHAR(MAX)');
   
   PRINT @UssdCode + ' ' + @MenuText;
   
   IF @UssdCode = '*100*1*1#'
   BEGIN
      IF NOT EXISTS (
         SELECT *
           FROM Organ_Picture
          WHERE ORGN_OGID = 25
            AND FILE_ID = @FileId
      )
      BEGIN
         INSERT INTO Organ_Picture(ORGN_OGID, IMAG_DESC, IMAG_TYPE, [FILE_ID])
         VALUES(25, N'غذاهای سالم و خوشمزه', '006', @FileId);
         
         SET @Message = 'عکس با موفقیت در قسمت غذاها ذخیره گردید.';
      END
   END
   ELSE IF @UssdCode = '*2#' AND @MenuText = N'به صورت متنی'
   BEGIN
      SELECT @Message = N'لیست منوی فست فود هشت' + CHAR(10) + (
         SELECT N' کد غذا ( ' + CONVERT(VARCHAR(MAX), [CMD_ID]) + N' ) ' + [CMD_Name] + N' قیمت محصول ' + CAST([CMD_Cost1] AS NVARCHAR(MAX)) + N' ریال ' + CHAR(10)
           FROM [Saffron].[dbo].[Commodity]
            FOR XML PATH('')
      );
   END
	
	SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END
GO
