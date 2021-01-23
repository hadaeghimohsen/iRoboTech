SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DBL_DEL_GEXP_P]
    @Code BIGINT
AS
BEGIN
    EXEC iScsc.dbo.DEL_GEXP_P @Code = @Code -- bigint    
END
GO
