SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_CRDT_U]
(
	@CardNumb VARCHAR(16)
)
RETURNS VARCHAR(19)
AS
BEGIN
	RETURN SUBSTRING(@CardNumb, 1, 4) + '-' + 
          SUBSTRING(@CardNumb, 5, 4) + '-' +
          SUBSTRING(@CardNumb, 9, 4) + '-' +
          SUBSTRING(@CardNumb, 13, 4);
END
GO
