SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[GET_CDTD_U]()
RETURNS MyDateDetail
AS
BEGIN
	Declare @DateTimeStr	MyDateDetail
	Declare @Hour			smallint
	Declare @Minute			smallint
	Declare @Second			smallint		
	
	Select @Hour=DATEPART(hh,getDate())
	Select @Minute=DATEPART(mi,GetDate())
	Select @Second=DATEPART(ss,getDate())

	DECLARE @TimeStr		nvarchar(20)
	SELECT @TimeStr=dbo.GET_PSTR_U(@Hour,2)+':'+dbo.GET_PSTR_U(@Minute,2)+':'+dbo.GET_PSTR_U(@Second,2)

	Select @DateTimeStr=dbo.GET_MTOS_U(GetDate())+' '+@TimeStr
	return @DateTimeStr
END
GO
