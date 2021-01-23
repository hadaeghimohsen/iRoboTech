SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_TEXT_F]
(
	@X XML
)
RETURNS XML
AS
BEGIN
   /*
      <TemplateToText rbid="" chatid="" pkid="" tmid=""/>
   */
	DECLARE @Rbid BIGINT
	       ,@ChatId BIGINT
	       ,@PkId BIGINT
	       ,@Tmid BIGINT;
	
	SELECT @Rbid = @X.query('TemplateToText').value('(TemplateToText/@rbid)[1]', 'BIGINT')
	      ,@ChatId = @X.query('TemplateToText').value('(TemplateToText/@chatid)[1]', 'BIGINT')
	      ,@PkId = @X.query('TemplateToText').value('(TemplateToText/@pkid)[1]', 'BIGINT')
	      ,@Tmid = @X.query('TemplateToText').value('(TemplateToText/@tmid)[1]', 'BIGINT');
	
	DECLARE @TempText NVARCHAR(4000)
	       ,@RsultText NVARCHAR(4000);
	
	-- 1396/05/31 * اگر گزینه کد قالب را انتخاب نکرده باشیم به احتمال زیاد متن قالب را خودمان انتخاب کرده ایم
	IF @Tmid IS NULL 
	BEGIN
	   SELECT @TempText = @X.query('TemplateToText').value('(TemplateToText/@text)[1]', 'NVARCHAR(4000)');
	   SET @RsultText = @TempText;
	END
	ELSE
	   SELECT @TempText = TEMP_TEXT
	         ,@RsultText = TEMP_TEXT
	     FROM dbo.Template
	    WHERE TMID = @Tmid;
   
   -- Process on Text Template
   DECLARE @PlaceHolder VARCHAR(1)
          ,@NumbOfPlaceHolder INT
          ,@Xp XML;
   
   SET @PlaceHolder = '{';
   SELECT @NumbOfPlaceHolder = (len(@TempText) - len(replace(@TempText,@PlaceHolder,''))) / LEN(@PlaceHolder);
   
   DECLARE @i INT = 0;
   
   DECLARE @PlaceHolderItem VARCHAR(100)
          ,@PlaceHolderValue NVARCHAR(1000)
          ,@StartOpenPosition INT = 0
          ,@StartClosePosition INT = 0;
   WHILE @i < @NumbOfPlaceHolder
   BEGIN
      SELECT @PlaceHolderItem = 
         SUBSTRING(
            @TempText,
            CHARINDEX('{', @TempText, @StartOpenPosition),
            CHARINDEX('}', @TempText, @StartClosePosition) - CHARINDEX('{', @TempText, @StartOpenPosition) + 1
         );
      
      SELECT @Xp = (
         SELECT @Rbid AS '@rbid'
               ,@ChatId AS '@chatid'
               ,@Pkid AS '@pkid'
               ,@PlaceHolderItem AS '@tempitem'
            FOR XML PATH('TemplateItemToText')
      );
      
      SELECT @PlaceHolderValue = dbo.GET_ITMV_F(@Xp);
      -- Replace value of text with template item
      SELECT @RsultText = REPLACE(@RsultText, @PlaceHolderItem, @PlaceHolderValue)
      -- Get Next Position Start {
      SET @StartOpenPosition = CHARINDEX('{', @TempText, @StartOpenPosition) + 1;
      -- Get Next Position Start }
      SET @StartClosePosition = CHARINDEX('}', @TempText, @StartClosePosition) + 1;
      SET @i += 1;
   END;
   
   SELECT @X = (
      SELECT @RsultText
        FOR XML PATH('Result')
   );
	
	RETURN @X;	
END
GO
