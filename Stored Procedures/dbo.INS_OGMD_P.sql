SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_OGMD_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	DECLARE @OrgnOgid BIGINT
	       ,@Rbid BIGINT
	       ,@FileId VARCHAR(MAX)
	       ,@TokenCode VARCHAR(100)
	       ,@UssdCode VARCHAR(250)
	       ,@ImagDesc NVARCHAR(MAX)
	       ,@FileType VARCHAR(3)
	       ,@CmndType VARCHAR(250)
	       ,@Ordr INT
          ,@Chatid bigint
          ,@SubSys int;
	
	SELECT @TokenCode = @X.query('//Robot').value('(Robot/@tokencode)[1]', 'VARCHAR(100)')
	      ,@FileId = @X.query('//File').value('(File/@id)[1]', 'VARCHAR(MAX)')
	      ,@UssdCode = @X.query('//File').value('(File/@ussdcode)[1]', 'VARCHAR(250)')
	      ,@FileType = @X.query('//File').value('(File/@filetype)[1]', 'VARCHAR(3)')
	      ,@CmndType = @X.query('//File').value('(File/@cmndtype)[1]', 'VARCHAR(250)')
         ,@Chatid = @X.query('//Robot').value('(Robot/@chatid)[1]', 'BIGINT');
	
	IF LEN(@FileId) = 0 OR LEN(@UssdCode) = 0	
	   RETURN;
	
	SELECT @OrgnOgid = ORGN_OGID
	      ,@Rbid = RBID
	  FROM dbo.Robot
	 WHERE TKON_CODE = @TokenCode;
	
	SELECT @ImagDesc = MENU_TEXT
	  FROM dbo.Menu_Ussd
	 WHERE ROBO_RBID = @Rbid
	   AND USSD_CODE = @UssdCode;
	
	DECLARE @Xp XML;
   -- Cmnd Sample : *#if*0*1*2#
   -- *# if *0*1*2#
   
	-- insert 
	IF @CmndType LIKE 'i%'
	BEGIN
	   -- INSERT FIRST
	   IF(@CmndType = 'if')
	   BEGIN
	      SET @Ordr = 1;
      	SELECT @Xp = (
            SELECT @Rbid AS '@rbid'
                  ,@UssdCode AS '@ussdcode'
                  ,@Ordr AS '@ordrinit'
                  ,@Ordr AS '@strtpos'
              FOR XML PATH('RobotMedia') 
         );

	      EXEC dbo.UPD_MDOD_P @X = @Xp; -- xml	   
	   END
	   -- INSERT LAST
	   ELSE IF(@CmndType = 'il')    
	   BEGIN
	      SELECT @Ordr = ISNULL(MAX(ORDR), 0) + 1
	        FROM dbo.Organ_Media
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode;
	         
	      /*SET @Xp.modify('insert into sql:variable(@Ordr) into (RobotMedia/@ordrinit)[1] ');
	      SET @Xp.modify('insert into sql:variable(@Ordr) into (RobotMedia/@strtpos)[1] ');
	      EXEC dbo.UPD_MDOD_P @X = @Xp; -- xml*/
	   END
	   -- INSERT ANY WHERE
	   ELSE 
	   BEGIN
	      SET @Ordr = CAST(SUBSTRING(@CmndType, 2, LEN(@CmndType)) AS INT);
	      SELECT @Xp = (
            SELECT @Rbid AS '@rbid'
                  ,@UssdCode AS '@ussdcode'
                  ,@Ordr AS '@ordrinit'
                  ,@Ordr AS '@strtpos'
              FOR XML PATH('RobotMedia') 
         );
	      EXEC dbo.UPD_MDOD_P @X = @Xp; -- xml	   
	   END
	   INSERT INTO dbo.Organ_Media ( ORGN_OGID ,ROBO_RBID ,IMAG_DESC ,STAT ,FILE_ID ,SHOW_STRT ,USSD_CODE ,IMAG_TYPE ,ORDR )
	   VALUES  ( @OrgnOgid , @Rbid , @ImagDesc , '002' , @FileId , '001',  @UssdCode ,@FileType ,@Ordr );
	END	
	-- delete
	ELSE IF @CmndType LIKE 'd%'
	BEGIN
	   -- DELETE FIRST
	   IF @CmndType = 'df'
	   BEGIN
	      DELETE dbo.Organ_Media
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode
	         AND ORDR = (
	            SELECT MIN(ORDR)
	              FROM dbo.Organ_Media
	             WHERE ROBO_RBID = @Rbid
	               AND USSD_CODE = @UssdCode
	         );
	   END
	   -- DELETE LAST
	   ELSE IF @CmndType = 'dl'
	   BEGIN
	      DELETE dbo.Organ_Media
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode
	         AND ORDR = (
	            SELECT MAX(ORDR)
	              FROM dbo.Organ_Media
	             WHERE ROBO_RBID = @Rbid
	               AND USSD_CODE = @UssdCode
	         );
	   END
	   -- DELETE ALL USSDCODE
	   ELSE IF @CmndType = 'd#'
	   BEGIN
	      DELETE dbo.Organ_Media
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode;
	   END
	   -- DELETE ANY WHERE
	   ELSE
	   BEGIN
	      SET @Ordr = CAST(SUBSTRING(@CmndType, 2, LEN(@CmndType)) AS INT);
	      DELETE dbo.Organ_Media
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode
	         AND ORDR = @Ordr;
	   END	   
	END
	-- Update
	ELSE IF @CmndType LIKE 'u%'
	BEGIN
	   -- UPDATE FIRST
	   IF @CmndType = 'uf'
	   BEGIN
	      UPDATE dbo.Organ_Media
	         SET file_id = @FileId
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode
	         AND ORDR = (
	            SELECT MIN(ORDR)
	              FROM dbo.Organ_Media
	             WHERE ROBO_RBID = @Rbid
	               AND USSD_CODE = @UssdCode
	         );
	   END
	   -- UPDATE LAST
	   ELSE IF @CmndType = 'ul'
	   BEGIN
	      UPDATE dbo.Organ_Media
	         SET FILE_ID = @FileId
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode
	         AND ORDR = (
	            SELECT MAX(ORDR)
	              FROM dbo.Organ_Media
	             WHERE ROBO_RBID = @Rbid
	               AND USSD_CODE = @UssdCode
	         );
	   END
	   -- UPDATE ALL USSDCODE
	   ELSE IF @CmndType = 'd#'
	   BEGIN
	      UPDATE dbo.Organ_Media
	         SET FILE_ID = @FileId
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode;
	   END
	   -- UPDATE ANY WHERE
	   ELSE
	   BEGIN
	      SET @Ordr = CAST(SUBSTRING(@CmndType, 2, LEN(@CmndType)) AS INT);
	      UPDATE dbo.Organ_Media
	         SET FILE_ID = @FileId
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode
	         AND ORDR = @Ordr;
	   END	   
	END
	-- Active
	ELSE IF @CmndType LIKE 't%'
	BEGIN
	   -- ACTIVE FIRST
	   IF @CmndType = 'tf'
	   BEGIN
	      UPDATE dbo.Organ_Media
	         SET STAT = '002'
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode
	         AND ORDR = (
	            SELECT MIN(ORDR)
	              FROM dbo.Organ_Media
	             WHERE ROBO_RBID = @Rbid
	               AND USSD_CODE = @UssdCode
	         );
	   END
	   -- ACTIVE LAST
	   ELSE IF @CmndType = 'tl'
	   BEGIN
	      UPDATE dbo.Organ_Media
	         SET STAT = '002'
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode
	         AND ORDR = (
	            SELECT MAX(ORDR)
	              FROM dbo.Organ_Media
	             WHERE ROBO_RBID = @Rbid
	               AND USSD_CODE = @UssdCode
	         );
	   END
	   -- ACTIVE ALL USSDCODE
	   ELSE IF @CmndType = 't#'
	   BEGIN
	      UPDATE dbo.Organ_Media
	         SET STAT = '002'
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode;
	   END
	   -- ACTIVE ANY WHERE
	   ELSE
	   BEGIN
	      SET @Ordr = CAST(SUBSTRING(@CmndType, 2, LEN(@CmndType)) AS INT);
	      UPDATE dbo.Organ_Media
	         SET STAT = '002'
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode
	         AND ORDR = @Ordr;
	   END	   
	END
	-- Deactive
	ELSE IF @CmndType LIKE 'f%'
	BEGIN
	   -- DEACTIVE FIRST
	   IF @CmndType = 'ff'
	   BEGIN
	      UPDATE dbo.Organ_Media
	         SET STAT = '001'
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode
	         AND ORDR = (
	            SELECT MIN(ORDR)
	              FROM dbo.Organ_Media
	             WHERE ROBO_RBID = @Rbid
	               AND USSD_CODE = @UssdCode
	         );
	   END
	   -- DEACTIVE LAST
	   ELSE IF @CmndType = 'fl'
	   BEGIN
	      UPDATE dbo.Organ_Media
	         SET STAT = '001'
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode
	         AND ORDR = (
	            SELECT MAX(ORDR)
	              FROM dbo.Organ_Media
	             WHERE ROBO_RBID = @Rbid
	               AND USSD_CODE = @UssdCode
	         );
	   END
	   -- DEACTIVE ALL USSDCODE
	   ELSE IF @CmndType = 'f#'
	   BEGIN
	      UPDATE dbo.Organ_Media
	         SET STAT = '001'
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode;
	   END
	   -- DEACTIVE ANY WHERE
	   ELSE
	   BEGIN
	      SET @Ordr = CAST(SUBSTRING(@CmndType, 2, LEN(@CmndType)) AS INT);
	      UPDATE dbo.Organ_Media
	         SET STAT = '001'
	       WHERE ROBO_RBID = @Rbid
	         AND USSD_CODE = @UssdCode
	         AND ORDR = @Ordr;
	   END	   
	END
   ELSE IF @CmndType IN ('p' /* Profile */, 'e' /* Expense */)
   BEGIN
      /* Sample 
         *#p*05*00#
         *#p*5*00#
         *#e*05*1#
      */
      set @UssdCode = substring(@UssdCode, 2, len(@UssdCode) - 2);      
      select top 1 @SubSys = CAST(item as int) from dbo.SplitString(@UssdCode, '*');
      
      --PRINT @UssdCode;
      
      -- Create parameter for run in RouterCommand SubSys
      SET @Xp = (
         select dbo.GET_PSTR_U(@SubSys, 2) as '@subsys'
               ,'101' as '@cmndcode'
               ,@chatid as '@chatid'
               ,@Rbid AS '@rbid'
               ,(
                  Select @FileId as '@fileid'
                        ,@FileType AS '@filetype'
                        ,@CmndType as '@desttype'
                        ,(select top 1 item from dbo.SplitString(@UssdCode, '*') order by id desc ) as '@dcmtcode'
                        ,'002' as '@actntype' -- update fileid in database
                     FOR XML PATH('Image'), type 
               )
            for xml path('Router_Command')
      );
      --PRINT CONVERT(NVARCHAR(max), @Xp);
      --RETURN;
      
      IF dbo.GET_PSTR_U(@SubSys, 2) = '05'
      BEGIN
         EXEC dbo.RouterdbCommand @Xp, @Xp output
      END
      ELSE IF @SubSys = '12'
      BEGIN
         EXEC dbo.RouterdbCommand @Xp, @Xp output
      END 
      
      PRINT CONVERT(VARCHAR(max), @Xp);
   END   
END
GO
