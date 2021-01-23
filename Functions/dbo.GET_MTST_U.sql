SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  FUNCTION [dbo].[GET_MTST_U] (@MDate  DateTime)  
RETURNS MyDate
AS  
BEGIN 
		Declare @Hour			smallint
		Declare @Minute			smallint

		Select @Hour=DATEPART(hh,@MDate)
		Select @Minute=DATEPART(mi,@MDate)

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
		Select @MonStr='12',@DayStr='29'

	SET @Farsi_Date =   CAST (@SYear   as VarChar(10)) + '/' +  @MonStr+ '/' + @DayStr

	---------------------------------------------------------------------------------------
	
	Declare @TimeStr	nvarchar(5)
	Select @TimeStr=''
	if(@Hour<10)
		Select @TimeStr=@TimeStr+'0'
	Select @TimeStr=@TimeStr+Cast(@Hour as nvarchar(2))
	if(@Minute<10)
		Select @TimeStr=@TimeStr+':0'+Cast(@minute as nvarchar(2))
	else 
		Select @TimeStr=@TimeStr+':'+Cast(@minute as nvarchar(2))
	Select @Farsi_Date=@Farsi_Date+' '+@TimeStr
	

	Return @Farsi_Date
END

;
GO
