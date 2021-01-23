SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[GNRT_NVID_U] ()
RETURNS bigint
WITH EXEC AS CALLER
AS
BEGIN
Declare @ResultNewIdentity Bigint;
--Set @ResultNewIdentity =  Convert(Bigint, Replace(Replace(Replace(dbo.GET_CDTD_U(),'/',''),':',''), ' ', '') + dbo.GET_PSTR_U( DATEPART(ms, GETDATE()) ,3));
SELECT @ResultNewIdentity = ROWID FROM V$RowID;
Set @ResultNewIdentity = Convert(Bigint, Replace(Replace(Replace(dbo.GET_CDTD_U(),'/',''),':',''), ' ', '')) + @ResultNewIdentity;
Return @ResultNewIdentity;
END
GO
