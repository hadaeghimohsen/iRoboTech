SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[GET_TIME_U](@MDate DATETIME = NULL)
RETURNS MyDate
AS
BEGIN
	Declare @Hour			smallint
	Declare @Minute			smallint

	Select @Hour=DATEPART(hh,ISNULL(@MDate, GETDATE()))
	Select @Minute=DATEPART(mi,ISNULL(@MDate, GETDATE()))

	Declare @TimeStr	nvarchar(5)
	Select @TimeStr=''
	if(@Hour<10)
		Select @TimeStr=@TimeStr+'0'
	Select @TimeStr=@TimeStr+Cast(@Hour as nvarchar(2))
	if(@Minute<10)
		Select @TimeStr=@TimeStr+':0'+Cast(@minute as nvarchar(2))
	else 
		Select @TimeStr=@TimeStr+':'+Cast(@minute as nvarchar(2))
	
	return @TimeStr
END

;

GO
