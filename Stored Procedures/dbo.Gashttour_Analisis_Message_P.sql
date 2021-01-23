SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Gashttour_Analisis_Message_P]
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

   IF @UssdCode = '*100*1*1#'
   BEGIN
      IF NOT EXISTS (
         SELECT *
           FROM Organ_Picture
          WHERE ORGN_OGID = 11
            AND FILE_ID = @FileId
      )
      BEGIN
         INSERT INTO Organ_Picture(ORGN_OGID, IMAG_DESC, IMAG_TYPE, [FILE_ID])
         VALUES(11, N'تورهای داخلی', '003', @FileId);
         
         SET @Message = 'عکس با موفقیت در قسمت تورهای داخلی ذخیره گردید.';
      END
   END
   ELSE IF @UssdCode = '*100*1*2#'
   BEGIN
      IF NOT EXISTS (
         SELECT *
           FROM Organ_Picture
          WHERE ORGN_OGID = 11
            AND FILE_ID = @FileId
      )
      BEGIN
         INSERT INTO Organ_Picture(ORGN_OGID, IMAG_DESC, IMAG_TYPE, [FILE_ID])
         VALUES(11, N'تورهای خارجی', '005', @FileId);
         
         SET @Message = 'عکس با موفقیت در قسمت تورهای خارجی ذخیره گردید.';
      END
   END

   IF @UssdCode = '*100*1*3#'
   BEGIN
      IF NOT EXISTS (
         SELECT *
           FROM Organ_Picture
          WHERE ORGN_OGID = 11
            AND FILE_ID = @FileId
      )
      BEGIN
         INSERT INTO Organ_Picture(ORGN_OGID, IMAG_DESC, IMAG_TYPE, [FILE_ID])
         VALUES(11, N'کادر شرکت', '004', @FileId);
         
         SET @Message = 'عکس با موفقیت در قسمت کادر شرکت ذخیره گردید.';
      END
   END

	
	SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END
GO
