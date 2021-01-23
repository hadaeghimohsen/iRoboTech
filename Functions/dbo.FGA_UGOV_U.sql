SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mohsen, Hadaeghi
-- Create date: 1394/09/17
-- Description: تابع دسترسی به سطوح ردیف جداول
-- =============================================
create FUNCTION [dbo].[FGA_UGOV_U] ()
RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE @FGA_USER_ORGANS VARCHAR(MAX);
	SELECT @FGA_USER_ORGANS = (
	   SELECT CAST(A.ORGN_OGID AS VARCHAR(MAX)) + ','
	     FROM dbo.User_Organ_Fgac A, dbo.Organ C
	    WHERE UPPER(A.SYS_USER) = UPPER(SUSER_NAME())	      
	      AND A.ORGN_OGID = C.OGID
	      AND A.REC_STAT = '002' -- رکورد فعال باشد
	      AND A.VALD_TYPE = '002' -- رکورد معتبر و قابل نمایش باشد
	      FOR XML PATH('')
	);
	RETURN ISNULL(LEFT(@FGA_USER_ORGANS, LEN(@FGA_USER_ORGANS) - 1), '0');
END
GO
