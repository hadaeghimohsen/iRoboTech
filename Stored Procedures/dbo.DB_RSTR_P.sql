SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[DB_RSTR_P]
	@X XML
AS
BEGIN
   DECLARE @BackupFile NVARCHAR(MAX);
   SELECT @BackupFile = @X.query('//Restore').value('(Restore/@backupfile)[1]', 'NVARCHAR(MAX)');
	RESTORE DATABASE iRoboTech FROM  DISK = @BackupFile WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 2
END
GO
