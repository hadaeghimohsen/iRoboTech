SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Analisis_Message_P]
	@X XML,
	@XResult XML OUT
AS
BEGIN
	DECLARE @UssdCode VARCHAR(250),
	        @MenuText NVARCHAR(250),
	        @Token    VARCHAR(100),
	        @Ogid     BIGINT,
	        @Rbid     BIGINT,
           @Message NVARCHAR(MAX);
	
	-- Convert Persian Number Input to Latin Number
	SET @X = dbo.STR_TRNS_U(CONVERT(NVARCHAR(MAX),@X), N'۱۲۳۴۵۶۷۸۹۰', N'1234567890');
	
	SELECT @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]', 'VARCHAR(250)'),
	       @MenuText = @X.query('//Text').value('.', 'NVARCHAR(250)'),
	       @Token = @X.query('//Robot').value('(Robot/@token)[1]', 'VARCHAR(100)');
	
	SELECT @Ogid = o.OGID, @Rbid = r.RBID FROM Organ o, Robot r WHERE o.OGID = r.ORGN_OGID AND r.TKON_CODE = @Token;
	
	IF @Ogid = 13 
	   EXEC dbo.AnarSoft_Analisis_Message_P @X = @X, @XResult = @XResult OUT;
	ELSE IF @Ogid = 2
      EXEC dbo.Makanyab_Analisis_Message_P @X = @X, @XResult = @XResult OUT;
   ELSE IF @Ogid = 3
      EXEC dbo.SoorenSoft_Analisis_Message_P @X = @X, @XResult = @XResult OUT;
   ELSE IF @Ogid = 5
      EXEC dbo.ParsHotel_Analisis_Message_P @X = @X, @XResult = @XResult OUT;
   ELSE IF @Ogid = 24
      EXEC dbo.Alaeddien_Analisis_Message_P @X = @X, @XResult = @XResult OUT;
   ELSE IF @Ogid = 11
      EXEC dbo.Gashttour_Analisis_Message_P @X = @X, @XResult = @XResult OUT;
   ELSE IF @Ogid = 25
      EXEC dbo.EightFastFood_Analisis_Message_P @X = @X, @XResult = @XResult OUT;
   ELSE IF @Ogid = 26
      EXEC dbo.SenatorGallery_Analisis_Message_P @X = @X, @XResult = @XResult OUT;   
   ELSE IF @Ogid = 30
      EXEC dbo.Baharnekou_Analisis_Message_P @X = @X, @XResult = @XResult OUT;   
   ELSE IF @Ogid = 305
      EXEC dbo.FoodSafari_Analisis_Message_P @X = @X, @XResult = @XResult OUT;   
   ELSE IF @Ogid = 360
      EXEC dbo.Mahzar_Analisis_Message_P @X = @X, @XResult = @XResult OUT;   
   ELSE IF @Ogid = 361
      EXEC dbo.SalamonFood_Analisis_Message_P @X = @X, @XResult = @XResult OUT;   
   ELSE IF @Ogid = 362
      EXEC dbo.HamraheShabake_Analisis_Message_P @X = @X, @XResult = @XResult OUT;  
   ELSE IF @Ogid = 363
      EXEC dbo.YaldaDecoration_Analisis_Message_P @X = @X, @XResult = @XResult OUT;   
   ELSE IF @Ogid = 366
   BEGIN
      IF @Rbid IN ( 391, 399 )
         EXEC dbo.ArtaSportGym_Analisis_Message_P @X = @X, @XResult = @XResult OUT;      
      ELSE IF @Rbid = 401
         EXEC dbo.AnarShop_Analisis_Message_P @X = @X, @XResult = @XResult OUT -- xml         
   END 
   ELSE IF @Ogid = 369
      EXEC dbo.WoodLock_Analisis_Message_P @X = @X, @XResult = @XResult OUT ;
   ELSE IF @Ogid = 371
      EXEC dbo.JelveKhaneMan_Analisis_Message_P @X = @X, @XResult = @XResult OUT;
      

END
GO
