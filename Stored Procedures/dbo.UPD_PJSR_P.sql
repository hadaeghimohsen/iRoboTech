SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_PJSR_P]
	-- Add the parameters for the stored procedure here
	@Code BIGINT,
	@Stat VARCHAR(3)
AS
BEGIN
	UPDATE dbo.Personal_Robot_Job_Service_Robot
	   SET STAT = @Stat
	 WHERE CODE = @Code;
END
GO
