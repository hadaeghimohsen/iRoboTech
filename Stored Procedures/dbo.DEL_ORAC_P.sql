SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[DEL_ORAC_P]
   @Code BIGINT  
AS 
BEGIN
   DELETE dbo.Order_Access
    WHERE CODE = @Code;
END;
GO
