SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DEL_ODRT_P]
    @Ordr_Code BIGINT ,
    @Rwno BIGINT
AS
BEGIN
    DELETE  dbo.Order_Detail
    WHERE   ORDR_CODE = @Ordr_Code
            AND RWNO = @Rwno;
          
   
END;
GO
