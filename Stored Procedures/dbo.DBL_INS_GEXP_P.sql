SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DBL_INS_GEXP_P]
	@Gexp_Code BIGINT,
	@Grop_Type VARCHAR(3),
	@Ordr SMALLINT,
    @Grop_Desc NVARCHAR(250),
	@Stat VARCHAR(3)
AS
BEGIN
    EXEC iScsc.dbo.INS_GEXP_P @Gexp_Code = @Gexp_Code,   -- bigint
                              @Grop_Type = @Grop_Type,  -- varchar(3)
                              @Ordr = @Ordr,        -- smallint
                              @Grop_Desc = @Grop_Desc, -- nvarchar(250)
                              @Stat = @Stat;        -- varchar(3)    
END
GO
