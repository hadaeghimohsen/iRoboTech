SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[GET_NTOS_U](@pNumber AS VARCHAR(100))
RETURNS NVARCHAR(2500)
AS
BEGIN
	IF LEN(ISNULL(@pNumber, '')) = 0  RETURN NULL

	IF (PATINDEX('%[^0-9.-]%', @pNumber) > 0)
	   OR (LEN(@pNumber) -LEN(REPLACE(@pNumber, '-', '')) > 1)
	   OR (LEN(@pNumber) -LEN(REPLACE(@pNumber, '.', '')) > 1)
	   OR (CHARINDEX('-', @pNumber) > 1)
		RETURN 'خطا'
	
	IF PATINDEX('%[^0]%', @pNumber) = 0  RETURN N'صفر'
	IF (CHARINDEX('.', @pNumber) = 1) SET @pNumber='0'+@pNumber
	
	DECLARE @Negative  AS VARCHAR(5) = '';
	IF LEFT(@pNumber, 1) = '-'
	BEGIN
	    SET @pNumber = SUBSTRING(@pNumber, 2, 100)
	    SET @Negative  = N'منفی '
	END
	---------------------------------------------------------------------
	DECLARE @NumberTitle TABLE (val  INT,Title NVARCHAR(100));	
	INSERT INTO @NumberTitle (val,Title)
	VALUES(0, '')
		,(1, N'یک') ,(2, N'دو')	,(3, N'سه')	,(4, N'چهار')
		,(5, N'پنج'),(6, N'شش'),(7, N'هفت'),(8, N'هشت')
		,(9, N'نه'),(10, N'ده'),(11, N'یازده'),(12, N'دوازده')
		,(13, N'سیزده'),(14, N'چهارده')	,(15, N'پانزده'),(16, N'شانزده')
		,(17, N'هفده'),(18, N'هجده'),(19, N'نوزده'),(20, N'بیست')
		,(30, N'سی'),(40, N'چهل'),(50, N'پنجاه'),(60, N'شصت')
		,(70, N'هفتاد'),(80, N'هشتاد'),(90, N'نود'),(100, N'صد')
		,(200, N'دویست'),(300, N'سیصد'),(400, N'چهارصد'),(500, N'پانصد')
		,(600, N'ششصد'),(700, N'هفتصد'),(800, N'هشتصد'),(900, N'نهصد')
	
	DECLARE @PositionTitle TABLE (id  INT,Title NVARCHAR(100));			
	INSERT INTO @PositionTitle (id,title)
	VALUES (1, N'')	,(2, N'هزار'),(3, N'میلیون'),(4, N'میلیارد'),(5, N'تریلیون')
		,(6, N'کوادریلیون'),(7, N'کوینتیلیون'),(8, N'سیکستیلون'),(9, N'سپتیلیون')
		,(10, N'اکتیلیون'),(11, N'نونیلیون'),(12, N'دسیلیون')
		,(13, N'آندسیلیون'),(14, N'دودسیلیون'),(15, N'تریدسیلیون')
		,(16, N'کواتردسیلیون'),(17, N'کویندسیلیون'),(18, N'سیکسدسیلیون')
		,(19, N'سپتندسیلیون'),(20, N'اکتودسیلیوم'),(21, N'نومدسیلیون')		
	
	DECLARE @DecimalTitle TABLE (id  INT,Title NVARCHAR(100));		
	INSERT INTO @DecimalTitle (id,Title)
	VALUES( 1 ,N'دهم' ),(2 , N'صدم'),(3 , N'هزارم')
		,(4 , N'ده-هزارم'),(5 , N'صد-هزارم'),(6 , N'میلیون ام')
		,(7 , N'ده-میلیون ام'),(8 , N'صد-میلیون ام'),(9 , N'میلیاردم')
		,(10 , N'ده-میلیاردم')
	---------------------------------------------------------------------
	DECLARE @IntegerNumber NVARCHAR(100),
			@DecimalNumber NVARCHAR(100),
			@PointPosition INT =case CHARINDEX(N'.', @pNumber) WHEN 0 THEN LEN(@pNumber)+1 ELSE CHARINDEX(N'.', @pNumber) END
			
	SET @IntegerNumber= LEFT(@pNumber, @PointPosition - 1)
	SET @DecimalNumber= '?' + SUBSTRING(@pNumber, @PointPosition + 1, LEN(@pNumber))
	SET @DecimalNumber=  SUBSTRING(@DecimalNumber,2, len(@DecimalNumber )-PATINDEX('%[^0]%', REVERSE (@DecimalNumber)))

	SET @pNumber= @IntegerNumber
	---------------------------------------------------------------------
	DECLARE @Number AS INT
	DECLARE @MyNumbers TABLE (id INT IDENTITY(1, 1), Val1 INT, Val2 INT, Val3 INT)
	
	WHILE (@pNumber) <> '0'
	BEGIN
	    SET @number = CAST(SUBSTRING(@pNumber, LEN(@pNumber) -2, 3)AS INT)	
	    
		INSERT INTO @MyNumbers
		SELECT (@Number % 1000) -(@Number % 100),
		CASE 
			WHEN @Number % 100 BETWEEN 10 AND 19 THEN @Number % 100
			ELSE (@Number % 100) -(@Number % 10)
		END,
		CASE 
			WHEN @Number % 100 BETWEEN 10 AND 19 THEN 0
			ELSE @Number % 10
		END
	    
	    IF LEN(@pNumber) > 2
	        SET @pNumber = LEFT(@pNumber, LEN(@pNumber) -3)
	    ELSE
	        SET @pNumber = '0'
	END
	---------------------------------------------------------------------	
	DECLARE @Str AS NVARCHAR(2000) = '';

	SELECT @Str += REPLACE(REPLACE(LTRIM(RTRIM(nt1.Title + ' ' + nt2.Title + ' ' + nt3.title)),'  ',' '),' ', N' و ')
	       + ' ' + pt.title + N' و '
	FROM   @MyNumbers  AS mn
	       INNER JOIN @PositionTitle pt
	            ON  pt.id = mn.id
	       INNER JOIN @NumberTitle nt1
	            ON  nt1.val = mn.Val1
	       INNER JOIN @NumberTitle nt2
	            ON  nt2.val = mn.Val2
	       INNER JOIN @NumberTitle nt3
	            ON  nt3.val = mn.Val3
	WHERE  (nt1.val + nt2.val + nt3.val > 0)
	ORDER BY pt.id DESC
	
	IF @IntegerNumber='0'  
		SET @Str=CASE WHEN PATINDEX('%[^0]%', @DecimalNumber) > 0 THEN @Negative ELSE '' END + N'صفر'
	ELSE
		SET @Str = @Negative  + LEFT (@Str, LEN(@Str) -2)
		
    DECLARE @PTitle NVARCHAR(100)=ISNULL((SELECT Title FROM @DecimalTitle WHERE id=LEN(@DecimalNumber)),'')
	SET @Str += ISNULL(N' ممیز '+[dbo].[GET_NTOS_U](@DecimalNumber) +' '+@PTitle,'')
	RETURN @Str
END	
 
GO
