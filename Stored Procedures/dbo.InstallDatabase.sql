SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InstallDatabase]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   BEGIN TRY
   DECLARE @Emptydb VARCHAR(3);
   SELECT @Emptydb = @X.query('//Params').value('(Params/@emptydb)[1]', 'VARCHAR(3)');
   
   IF @Emptydb = '002'
   BEGIN
      DELETE dbo.Menu_Ussd WHERE ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Service_Robot_Group WHERE SRBT_ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Service_Robot_Public WHERE SRBT_ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Service_Robot_Visit WHERE SRRB_ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Service_Robot_Send_Advertising WHERE SRBT_ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Service_Robot_Replay_Message WHERE SRBT_ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Service_Robot_Message WHERE SRBT_ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Robot_Spy_Group_Message_Detail
      DELETE dbo.Robot_Spy_Group_Message 
      DELETE dbo.Service_Robot_Upload WHERE SRBT_ROBO_RBID NOT IN (391, 401);
      DELETE dbo.[Order];
      DELETE dbo.Wallet WHERE SRBT_ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Service_Robot WHERE ROBO_RBID NOT IN (391, 401);
      DELETE dbo.[Group] WHERE ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Personal_Robot_Job WHERE PRBT_ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Job WHERE ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Organ_Media WHERE ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Send_Advertising WHERE ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Robot_Spy_Group
      DELETE dbo.Robot_Import WHERE ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Order_Access WHERE PROB_ROBO_RBID NOT IN (391, 401);
      DELETE dbo.[Order] WHERE PROB_ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Personal_Robot WHERE ROBO_RBID NOT IN (391, 401);
      DELETE dbo.Robot WHERE RBID NOT IN (391, 401);
      DELETE dbo.Organ_Category WHERE ORGN_OGID != 366;
      DELETE dbo.Admin 
      DELETE dbo.Organ_Representation WHERE ORGN_OGID != 366;
      DELETE dbo.Organ WHERE OGID != 366;
      DELETE dbo.Robot_Product_Discount;
      DELETE dbo.Robot_Product;
      DELETE dbo.Robot_Instagram WHERE PAGE_OWNR_TYPE = '002';
      DELETE dbo.Service_Robot;
      DELETE dbo.Service;
   END 
   
   -- Delete And Empty Database

   -- Save Host Info
   IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'iProject')
	BEGIN
	   RAISERROR (N'iProject Database is not install, Please First Install iProject', 16, 1);
	   RETURN -1;
	END 
	   
   BEGIN TRAN T_INSTALLDB;
   
   /*
   '<Request Rqtp_Code="ManualSaveHostInfo">
      <Database>iProject</Database>
      <Dbms>SqlServer</Dbms>
      <User>scott</User>
      <Computer name="DESKTOP-LB0GKTR" 
                ip="192.168.158.1" 
                mac="00:50:56:C0:00:01" 
                cpu="BFEBFBFF000206A7" />
    </Request>'
   */
   
   DECLARE  @RqtpCode      VARCHAR(30)
           ,@ComputerName VARCHAR(50)
           ,@IPAddress    VARCHAR(15)
           ,@MacAddress   VARCHAR(17)
           ,@Cpu      VARCHAR(30)
           ,@UserName     VARCHAR(250)
           ,@UserId       BIGINT
           ,@DatabaseTest VARCHAR(3)
           ,@InstallLicenseKey NVARCHAR(4000);
   
   SELECT @ComputerName = @X.query('//Computer').value('(Computer/@name)[1]', 'VARCHAR(50)')
         ,@Cpu = @X.query('//Computer').value('(Computer/@cpu)[1]', 'VARCHAR(30)')
         ,@DatabaseTest = @X.query('//Params').value('(Params/@databasetest)[1]', 'VARCHAR(3)')
         ,@InstallLicenseKey = @X.query('//Params').value('(Params/@licensekey)[1]', 'NVARCHAR(4000)');
   
   -- Save Datasource and Connection
   IF NOT EXISTS(
      SELECT * 
        FROM iProject.Report.DataSource 
       WHERE (
         (@DatabaseTest = '002' AND Database_Alias = 'iRoboTech001') OR 
         (@DatabaseTest = '001' AND Database_Alias = 'iRoboTech')
       )
   )   
   BEGIN   
      IF @DatabaseTest = '001'
         INSERT INTO iProject.Report.DataSource
         ( ID ,ShortCut ,DatabaseServer ,IPAddress ,Port ,
           Database_Alias ,[Database] ,UserID ,Password ,TitleFa ,
           IsDefault ,IsActive ,IsVisible ,SUB_SYS 
         )
         VALUES  
         ( 6 ,6 ,1 ,@ComputerName,0 , 
           'iRoboTech' ,'iRoboTech' ,'' , '' , N'اطلاعات اصلی' , 
           1 , 1 , 1 , 12  );
      ELSE
         INSERT INTO iProject.Report.DataSource
         ( ID ,ShortCut ,DatabaseServer ,IPAddress ,Port ,
           Database_Alias ,[Database] ,UserID ,Password ,TitleFa ,
           IsDefault ,IsActive ,IsVisible ,SUB_SYS 
         )
         VALUES  
         ( 7 ,7 ,1 ,@ComputerName,0 , 
           'iRoboTech' ,'iRoboTech001' ,'' , '' , N'اطلاعات تستی' , 
           1 , 1 , 1 , 12  ); 
   END 
   
   DECLARE @XT XML;
   IF @DatabaseTest = '001'
   begin
      SELECT @XT = (
         SELECT 'ManualSaveHostInfo' AS '@Rqtp_Code'
               ,'installing' AS '@SystemStatus'
               ,'iRoboTech' AS 'Database'
               ,'SqlServer' AS 'Dbms'
               ,'artauser' AS 'User'               
               ,@X.query('//Computer').value('(Computer/@name)[1]', 'VARCHAR(50)') AS 'Computer/@name'
               ,@X.query('//Computer').value('(Computer/@mac)[1]', 'VARCHAR(17)') AS 'Computer/@mac'
               ,@X.query('//Computer').value('(Computer/@ip)[1]', 'VARCHAR(15)') AS 'Computer/@ip'
               ,@X.query('//Computer').value('(Computer/@cpu)[1]', 'VARCHAR(30)') AS 'Computer/@cpu'
           FOR XML PATH('Request')
      );
      
      EXEC iProject.DataGuard.SaveHostInfo @X = @XT;
   END    
   ELSE 
   BEGIN
      SELECT @XT = (
         SELECT 'ManualSaveHostInfo' AS '@Rqtp_Code'
               ,'installing' AS '@SystemStatus'
               ,'iRoboTech' AS 'Database'
               ,'SqlServer' AS 'Dbms'
               ,'demo' AS 'User'               
               ,@X.query('//Computer').value('(Computer/@name)[1]', 'VARCHAR(50)') AS 'Computer/@name'
               ,@X.query('//Computer').value('(Computer/@mac)[1]', 'VARCHAR(17)') AS 'Computer/@mac'
               ,@X.query('//Computer').value('(Computer/@ip)[1]', 'VARCHAR(15)') AS 'Computer/@ip'
               ,@X.query('//Computer').value('(Computer/@cpu)[1]', 'VARCHAR(30)') AS 'Computer/@cpu'
           FOR XML PATH('Request')
      );
      
      EXEC iProject.DataGuard.SaveHostInfo @X = @XT;
   END;
   
   UPDATE iProject.DataGuard.Sub_System SET STAT = '002', INST_STAT = '002', CLNT_LICN_DESC = NULL, SRVR_LICN_DESC = NULL, LICN_TYPE = NULL, LICN_TRIL_DATE = NULL, INST_LICN_DESC = @InstallLicenseKey WHERE SUB_SYS IN (12);   
   
   IF @DatabaseTest = '001'
      INSERT INTO iProject.Global.Access_User_Datasource
      ( USER_ID ,DSRC_ID ,STAT ,ACES_TYPE ,
        HOST_NAME )
      SELECT id, 6, '002', '001', @Cpu
        FROM iProject.DataGuard.[User] u
       WHERE ShortCut IN (16, 21)
         AND NOT EXISTS(
             SELECT *
               FROM iProject.Global.Access_User_Datasource a
              WHERE a.USER_ID = u.ID
                AND a.DSRC_ID = 6
         );
   ELSE
      INSERT INTO iProject.Global.Access_User_Datasource
      ( USER_ID ,DSRC_ID ,STAT ,ACES_TYPE ,
        HOST_NAME )
      SELECT id, 7, '002', '001', @Cpu
        FROM iProject.DataGuard.[User] u
       WHERE ShortCut IN (22)
         AND NOT EXISTS(
             SELECT *
               FROM iProject.Global.Access_User_Datasource a
              WHERE a.USER_ID = u.ID
                AND a.DSRC_ID = 7
         );
   
   COMMIT TRAN T_INSTALLDB;
   END TRY
   BEGIN CATCH 
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T_INSTALLDB;
   END CATCH
END
GO
