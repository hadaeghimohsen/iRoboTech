SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_PJSR_P]
	-- Add the parameters for the stored procedure here
	@Code BIGINT
AS
BEGIN
	DELETE dbo.Personal_Robot_Job_Service_Robot
	 WHERE CODE = @Code;	 
END
GO
