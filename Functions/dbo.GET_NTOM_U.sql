SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_NTOM_U]
(
	@Numb BIGINT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	RETURN REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @Numb), 1), '.00', '');
END
GO
