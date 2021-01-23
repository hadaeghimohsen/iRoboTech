SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_CDWM_U]
(
	-- Add the parameters for the function here
	@Date DATE
)
RETURNS NVARCHAR(20)
AS
BEGIN
	RETURN 
	   CASE (RIGHT(dbo.GET_MTOS_U(@Date), 2) / 7) + CASE WHEN (RIGHT(dbo.GET_MTOS_U(@Date), 2) % 7) = 0 THEN 0 ELSE 1 end 
	      WHEN 1 THEN N'1) هفته اول'
	      WHEN 2 THEN N'2) هفته دوم'
	      WHEN 3 THEN N'3) هفته سوم'
	      WHEN 4 THEN	N'4) هفته چهارم'
      END 
END
GO
