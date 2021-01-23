SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[TAK_BKUP_P]
	@X XML
AS
BEGIN
   DECLARE @BackUp BIT
          ,@BackupAppExit BIT
          ,@BackupInTred BIT
          ,@BackupOptnPath BIT
          ,@BackupRootPath NVARCHAR(MAX)
          ,@BackupOptnPathAdrs NVARCHAR(MAX);
   DECLARE @BackupType VARCHAR(20);

   
   SELECT @BackupType = @X.query('//Backup').value('(Backup/@type)[1]', 'VARCHAR(20)');

   SELECT @Backup = BACK_UP
         ,@BackupAppExit = BACK_UP_APP_EXIT
         ,@BackupInTred = Back_UP_IN_TRED
         ,@BackupOptnPath = BACK_UP_OPTN_PATH
         ,@BackupRootPath = BACK_UP_ROOT_PATH
         ,@BackupOptnPathAdrs = BACK_UP_OPTN_PATH_ADRS
     FROM Settings   
   
   ---------------------
   SET NOCOUNT ON

   -- 1 - Variable declaration
   DECLARE @DBName sysname
   DECLARE @DataPath nvarchar(500)
   DECLARE @LogPath nvarchar(500)
   DECLARE @DirTree TABLE (subdirectory nvarchar(255), depth INT)

   SET @DBName = 'iRoboTech_' + @BackupType + '_' + UPPER(SUSER_NAME()) + '_' + REPLACE(dbo.GET_MTOS_U(GETDATE()), '/', '') + '_' + REPLACE(SUBSTRING(dbo.GET_CDTD_U(), LEN(dbo.GET_CDTD_U()) - 7, 10 ), ':', '') + '.bak';
   -- 2 - Initialize variables
   IF @BackupOptnPath = 1
      SET @DataPath = @BackupOptnPathAdrs + '\Backup'
   ELSE
      SET @DataPath = @BackupRootPath 

   -- 3 - @DataPath values
   INSERT INTO @DirTree(subdirectory, depth)
   EXEC master.sys.xp_dirtree @DataPath

   -- 4 - Create the @DataPath directory
   IF NOT EXISTS (SELECT 1 FROM @DirTree)
   EXEC master.dbo.xp_create_subdir @DataPath
   
   SET @DataPath = @DataPath + '\' + @DBName;
   SET NOCOUNT OFF
   ---------------------
   IF @BackupOptnPath = 1  
   BEGIN
      --SET @BackupOptnPathAdrs = @BackupOptnPathAdrs + '\Backup\iRoboTech.bak'
	   BACKUP DATABASE [iRoboTech] TO  DISK = @DataPath WITH NOFORMAT, INIT,  NAME = N'iRoboTech-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
	END
	ELSE
	BEGIN
	   --SET @BackupOptnPathAdrs = @BackupRootPath + '\Backup\iRoboTech.bak'
	   BACKUP DATABASE [iRoboTech] TO  DISK = @DataPath WITH NOFORMAT, INIT,  NAME = N'iRoboTech-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
	END
END
GO
