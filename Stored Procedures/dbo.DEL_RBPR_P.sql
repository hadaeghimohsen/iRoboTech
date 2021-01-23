SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_RBPR_P]
	@CODE bigint
AS
BEGIN
	BEGIN TRY
    BEGIN TRAN [T$DEL_RBPR_P]
      DELETE dbo.Robot_Product
       WHERE CODE = @CODE;
    COMMIT TRAN [T$DEL_RBPR_P]     
    END TRY
    BEGIN CATCH
      DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1 );
      ROLLBACK TRAN [T$DEL_RBPR_P]
    END CATCH
END
GO
