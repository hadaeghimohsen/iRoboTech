SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_RBID_U]
(
	@X XML
)
RETURNS BIGINT
AS
BEGIN
	Declare @TokenCode varchar(250)
	       ,@Rbid Bigint;
	
	Select @TokenCode = @X.query('Robot').value('(Robot/@tkoncode)[1]', 'VARCHAR(250)');
	   
	Select @Rbid = RBID
	  FROM Robot
	 WHEre TKON_CODE = @TokenCode;
   
   Return @Rbid;   

END
GO
