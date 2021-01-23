SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[GET_CDTS_U]
(
	-- Add the parameters for the function here
	@DateTime VARCHAR(10)
)
RETURNS NVarchar(50)
AS
BEGIN
	-- Declare the return variable here
	Declare @MonthNumber int;
	
	Set @MonthNumber = CONVERT(int, SUBSTRING(@DateTime,6,2));
	
	Declare @MonthString NVarchar(10);
	Select
	   @MonthString = 
	      Case @MonthNumber
	         When 1 Then N'فروردین'
	         When 2 Then N'اردیبهشت'
	         When 3 Then N'خرداد'
	         When 4 Then N'تیر'
	         When 5 Then N'مرداد'
	         When 6 Then N'شهریور'
	         When 7 Then N'مهر'
	         When 8 Then N'آبان'
	         When 9 Then N'آذر'
	         When 10 Then N'دی'
	         When 11 Then N'بهمن'
	         When 12 Then N'اسفند'
	      End
	
	Return SubString(@DateTime, 9, 2) + ' ' + @MonthString + ' ' + SubString(@DateTime, 1, 4);

END

;
GO
