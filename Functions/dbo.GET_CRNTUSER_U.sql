SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_CRNTUSER_U]
(
	@X XML
)
RETURNS NVARCHAR(250)
AS
BEGIN
   DECLARE @ActnType VARCHAR(3)
          ,@UserDb  VARCHAR(250);
   /*
      ActnType {
         001 -- Database User
         002 -- Current Applicaion User
         003 -- Customer Application User
      }
   */
   SELECT @ActnType = @X.query('User').value('(User/@actntype)[1]', 'VARCHAR(3)')
         ,@UserDb   = @X.query('User').value('(User/@userdb)[1]', 'VARCHAR(250)');
   IF @ActnType = '001'
	   RETURN UPPER(SUSER_NAME());
	ELSE IF @ActnType = '002'
	   RETURN (SELECT TitleFa FROM iProject.DataGuard.[User] WHERE UPPER(USERDB) = UPPER(SUSER_NAME()));
	ELSE IF @ActnType = '003'
	   RETURN (SELECT TitleFa FROM iProject.DataGuard.[User] WHERE UPPER(USERDB) = UPPER(@UserDb));
	RETURN '';
END
GO
