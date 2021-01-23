SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[REQL_DRPR_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION [T$REQ_DRPR_F]
	SET NOCOUNT ON
	
	COMMIT TRANSACTION [T$REQ_DRPR_F]
	END TRY
	BEGIN CATCH
	   ROLLBACK TRANSACTION [T$REQ_DRPR_F]
	END CATCH
END
GO
