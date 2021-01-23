SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_CDWD_U]
(
	@Date DATE
)
RETURNS NVARCHAR(10)
AS
BEGIN
	
	RETURN 
	   CASE DATEPART(WEEKDAY, @Date)
	      WHEN 7 THEN N'0) شنبه'
	      WHEN 1 THEN N'1) یکشنبه'
	      WHEN 2 THEN N'2) دوشنبه'
	      WHEN 3 THEN N'3) سه شنبه'
	      WHEN 4 THEN N'4) چهارشنبه'
	      WHEN 5 THEN N'5) پنج شنبه'
	      WHEN 6 THEN N'6) جمعه'
	   END;
END
GO
