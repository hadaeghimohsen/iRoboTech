SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DBL_UPD_GEXP_P]
   @Code BIGINT,
	@Gexp_Code BIGINT,
	@Grop_Type VARCHAR(3),
	@Ordr SMALLINT,
   @Grop_Desc NVARCHAR(250),
	@Stat VARCHAR(3),
	@Link_Join VARCHAR(100)
AS
BEGIN
    EXEC iScsc.dbo.UPD_GEXP_P @Code = @Code,        -- bigint
                              @Gexp_Code = @Gexp_Code,   -- bigint
                              @Grop_Type = @Grop_Type,  -- varchar(3)
                              @Ordr = @Ordr,        -- smallint
                              @Grop_Desc = @Grop_Desc, -- nvarchar(250)
                              @Stat = @Stat,
                              @Link_Join = @Link_Join;        -- varchar(3)    
END
GO
