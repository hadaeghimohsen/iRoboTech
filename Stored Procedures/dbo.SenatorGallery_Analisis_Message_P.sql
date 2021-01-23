SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SenatorGallery_Analisis_Message_P]
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

   IF @UssdCode = '*1*1*1#'
	BEGIN
	   UPDATE Service_Robot
	      SET CELL_PHON = @MenuText
	    WHERE CHAT_ID = @ChatID
	      AND ROBO_RBID = 16;
	   SELECT @Message = 
	      ('اطلاعات شماره تلفن شما برای فعال سازی ثبت گردید.');
	END
	ELSE IF @UssdCode = '*100*0*1#'
	BEGIN
	   UPDATE Service_Robot
	      SET CORD_X = @CordX
	         ,CORD_Y = @CordY
	    WHERE CHAT_ID = @ChatID
	      AND ROBO_RBID = 16;
	   UPDATE Organ
	      SET CORD_X = @CordX
	         ,CORD_Y = @CordY
	    WHERE OGID = 26;
	   SELECT @Message = 
	      ('اطلاعات مختصات جغرافیایی شما در سیستم ثبت گردید');
	END
	ELSE IF @UssdCode = '*100*0*2*1#'
   BEGIN
      IF NOT EXISTS (
         SELECT *
           FROM Organ_Picture
          WHERE ORGN_OGID = 26
            AND FILE_ID = @FileId
      ) AND LEN(@FileId) > 0
      BEGIN
         INSERT INTO Organ_Picture(ORGN_OGID, IMAG_DESC, IMAG_TYPE, [FILE_ID], SHOW_STRT)
         VALUES(26, N'کلکسیون فرش سناتور', '007', @FileId, '002');
         
         SET @Message = 'عکس با موفقیت در قسمت کلکسیون فرش سناتور ذخیره گردید.';
      END
   END

	
	SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END
GO
