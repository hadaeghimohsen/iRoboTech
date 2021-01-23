SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  FUNCTION [dbo].[GET_MTOS_U] (@MDate  DATETIME)  
RETURNS Varchar(10)
AS  
BEGIN 
	   DECLARE @SYear  as Integer
	   DECLARE @SMonth  as Integer
	   DECLARE @SDay  as Integer
	   DECLARE @AllDays  as float
	   DECLARE @ShiftDays  as float
	   DECLARE @OneYear  as float
	   DECLARE @LeftDays  as float
	   DECLARE @YearDay  as Integer
	   DECLARE @Farsi_Date  as Varchar(100) 
	   SET @MDate=@MDate-CONVERT(char,@MDate,114)

	  SET @ShiftDays=466699   +2
	  SET @OneYear= 365.24199


	   SET @SYear = 0
	   SET @SMonth = 0
	   SET @SDay = 0
	   SET @AllDays  = CAst(@Mdate as Real)

	   SET @AllDays = @AllDays + @ShiftDays

	  SET @SYear = (@AllDays / @OneYear) --trunc
	  SET @LeftDays = @AllDays - @SYear * @OneYear

	  if (@LeftDays < 0.5)
	  begin
		SET @SYear=@SYear+1
		SET @LeftDays = @AllDays - @SYear * @OneYear
	  end;

	  SET @YearDay = @LeftDays --trunc
	  if (@LeftDays - @YearDay) >= 0.5 
		SET @YearDay=@YearDay+1

	  if ((@YearDay / 31) > 6 )
	  begin
		SET @SMonth = 6
		SET @YearDay=@YearDay-(6 * 31)
		SET @SMonth= @SMonth+( @YearDay / 30)
		if (@YearDay % 30) <> 0 
		  SET @SMonth=@SMonth+1
		SET @YearDay=@YearDay-((@SMonth - 7) * 30)
	  end 
	  else
	  begin
		SET @SMonth = @YearDay / 31
		if (@YearDay % 31) <> 0 
		  SET @SMonth=@SMonth+1 
		SET @YearDay=@YearDay-((@SMonth - 1) * 31)
	  end
	  SET @SDay = @YearDay
	  SET @SYear=@SYear+1

	Declare @MonStr	nvarchar(5)
	Declare @DayStr	nvarchar(5)

	Select @MonStr=CAST (@SMonth   as VarChar(5))
	Select @DayStr=CAST (@SDay  as VarChar(5))

	if(Len(@MonStr)<2)Select @MonStr='0'+@MonStr
	if(Len(@DayStr)<2)Select @DayStr='0'+@DayStr

	if(LEN(@MonStr)>2)
	BEGIN
		Select @SYear=@SYear-2
		Select @MonStr='12',@DayStr='30'
	END

	SET @Farsi_Date =   CAST (@SYear   as VarChar(10)) + '/' +  @MonStr+ '/' + @DayStr
	Return @Farsi_Date
END

;
GO
