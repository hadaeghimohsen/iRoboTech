SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[GET_LPAD_U]
(
    @string NVARCHAR(MAX), -- Initial string
    @length INT,          -- Size of final string
    @pad NCHAR             -- Pad character
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN REPLICATE(@pad, @length - LEN(@string)) + @string;
END
GO
