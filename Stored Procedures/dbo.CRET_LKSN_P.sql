SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_LKSN_P]
	@X XML
AS
BEGIN
   BEGIN TRY   
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @ServerName sysname = 'LKS_EXTR_N',
	        @ServerProduct NVARCHAR(128) = 'Server 2008',
	        @Prodiver NVARCHAR(128) = 'SQLNCLI',
	        @DataSource NVARCHAR(4000),
	        @Catalog sysname = 'master',
	        @Userid sysname,
	        @Password sysname;
	
	SELECT @DataSource = @X.query('Link_Server').value('(Link_Server/@datasource)[1]', 'VARCHAR(4000)'),
	       @Userid = @X.query('Link_Server').value('(Link_Server/@userid)[1]', 'SYSNAME'),
	       @Password = @X.query('Link_Server').value('(Link_Server/@password)[1]', 'SYSNAME');
	
	-- اگر نام کاربری تعیین نشده باشد
	IF ISNULL(@Userid , '') = '' OR LEN(@Userid) = 0
	BEGIN
	   SELECT @Userid = [user].USERDB,
	          @Password = PASSDB
	     FROM iProject.DataGuard.[User]
	    WHERE LOWER([user].USERDB) = 'artauser';
	END    
	
	IF EXISTS(SELECT * FROM sys.servers WHERE name = @ServerName)
      EXEC master.sys.sp_dropserver @ServerName,'droplogins'

	
	EXEC master.dbo.sp_addlinkedserver @server = @ServerName, @srvproduct=@ServerProduct, @provider=@Prodiver, @datasrc=@DataSource, @catalog=@Catalog
   EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=@ServerName,@useself=N'False',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
   EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=@ServerName,@useself=N'False',@locallogin=@Userid,@rmtuser=@Userid,@rmtpassword=@Password
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'collation compatible', @optvalue=N'false'
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'data access', @optvalue=N'true'
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'dist', @optvalue=N'false'
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'pub', @optvalue=N'false'
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'rpc', @optvalue=N'true'
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'rpc out', @optvalue=N'true'
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'sub', @optvalue=N'false'
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'connect timeout', @optvalue=N'0'
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'collation name', @optvalue=NULL
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'lazy schema validation', @optvalue=N'false'
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'query timeout', @optvalue=N'0'
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'use remote collation', @optvalue=N'true'
   EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'remote proc transaction promotion', @optvalue=N'true'
	
	PRINT 'Server Created Successfully!';
	
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX);
	   SET @ErorMesg = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	END CATCH    
END
GO
