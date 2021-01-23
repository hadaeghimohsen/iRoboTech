SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE 
 PROCEDURE [dbo].[JelveKhaneMan_Analisis_Message_P] @X XML, @XResult XML OUT
AS
BEGIN
    DECLARE @UssdCode VARCHAR(250) ,
        @ChildUssdCode VARCHAR(250) ,
        @MenuText NVARCHAR(MAX) ,
        @Message NVARCHAR(MAX) ,
        @XMessage XML ,
        @XTemp XML ,
        @ChatID BIGINT ,
        @SrbtServFileNo BIGINT,
        @CordX FLOAT ,
        @CordY FLOAT ,
        @CellPhon VARCHAR(13) ,
        @PhotoFileId VARCHAR(MAX) ,
        @VideoFileId VARCHAR(MAX) ,
        @DocumentFileId VARCHAR(MAX) ,
        @AudioFileId VARCHAR(MAX) ,
        @FileId VARCHAR(MAX) ,
        @ElmnType VARCHAR(3) ,
        @Item NVARCHAR(1000) ,
        @Name NVARCHAR(100) ,
        @Numb NVARCHAR(100) ,
        @MimeType VARCHAR(100) ,
        @Index BIGINT = 0 ,
        @Token VARCHAR(100) ,
        @Rbid BIGINT,
        @SuprGrop VARCHAR(100),
        @ContArtc FLOAT,
        @Visit INT = 0;
	 
    SELECT  @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]', 'VARCHAR(250)') ,
            @Token = @X.query('/Robot').value('(Robot/@token)[1]', 'VARCHAR(100)') ,
            @ChildUssdCode = @X.query('//Message').value('(Message/@childussd)[1]','VARCHAR(250)') ,
            @ChatID = @X.query('//Message').value('(Message/@chatid)[1]','BIGINT') ,
            @ElmnType = @X.query('//Message').value('(Message/@elmntype)[1]', 'VARCHAR(3)') ,
            @MimeType = @X.query('//Message').value('(Message/@mimetype)[1]','VARCHAR(100)') ,
            @MenuText = @X.query('//Text').value('.', 'NVARCHAR(MAX)') ,
            @CellPhon = @X.query('//Contact').value('(Contact/@phonnumb)[1]', 'VARCHAR(13)') ,            
            @CordX = @X.query('//Location').value('(Location/@latitude)[1]', 'FLOAT') ,
            @CordY = @X.query('//Location').value('(Location/@longitude)[1]', 'FLOAT') ,
            @PhotoFileId = @X.query('//Photo').value('(Photo/@fileid)[1]', 'NVARCHAR(MAX)') ,
            @VideoFileId = @X.query('//Video').value('(Video/@fileid)[1]', 'NVARCHAR(MAX)') ,
            @DocumentFileId = @X.query('//Document').value('(Document/@fileid)[1]', 'NVARCHAR(MAX)'),
            @AudioFileId = @X.query('//Audio').value('(Audio/@fileid)[1]', 'NVARCHAR(MAX)');
	 
	 SELECT @CellPhon = CASE LEN(@CellPhon) 
	                         WHEN 11 THEN @CellPhon 
	                         WHEN 12 THEN '0' + SUBSTRING(@CellPhon, 3, LEN(@CellPhon)) 
	                         WHEN 13 THEN '0' + SUBSTRING(@CellPhon, 4, LEN(@CellPhon)) 
	                    END
	 
    SELECT  @Rbid = RBID
    FROM    dbo.Robot
    WHERE   TKON_CODE = @Token;
    
    SET @MenuText = REPLACE(@MenuText, N'ی', N'ي');
    
    -- گزارش موجودی کالا
    IF @ChildUssdCode IN(
       -- پرده
       '*0*0*0*0#',
       -- لمینت
       '*0*1*0*0#', '*0*1*1*0#',
       -- کاغذ دیواری
       '*0*2*0*0#', '*0*2*1*0#', '*0*2*2*0#', '*0*2*3*0#', '*0*2*4*0#', '*0*2*5*0#',
       '*0*2*6*0#', '*0*2*7*0#', '*0*2*8*0#', '*0*2*9*0#', '*0*2*10*0#', '*0*2*11*0#',
       -- پوستر
       '*0*3*0*0#', '*0*3*1*0#', '*0*3*2*0#', '*0*3*3*0#', '*0*3*4*0#', '*0*3*5*0#',
       '*0*3*6*0#', '*0*3*7*0#', '*0*3*8*0#', '*0*3*9*0#', '*0*3*10*0#'       
    )
    BEGIN
      SELECT @Message = (
         SELECT N'موجودی کالا : ' + CONVERT(NVARCHAR(max), EXST_NUMB)
           FROM dbo.Menu_Ussd
          WHERE ROBO_RBID = @Rbid
            AND USSD_CODE = @ChildUssdCode
      );
    END  
    /*ELSE IF @UssdCode = '*0*4#'  
    BEGIN
      SELECT @Message = (
         SELECT mur.MENU_TEXT + CHAR(10) + N'موجودی کالا : ' + CONVERT(NVARCHAR(max), muc.EXST_NUMB) + CHAR(10)
           FROM dbo.Menu_Ussd mur, dbo.Menu_Ussd muc
          WHERE mur.ROBO_RBID = muc.ROBO_RBID
            AND mur.ROBO_RBID = @Rbid
            AND mur.MUID = muc.MNUS_MUID
            AND muc.EXST_NUMB >= 0
            AND mur.MENU_TEXT LIKE N'%' + @MenuText + N'%'
            FOR XML PATH('')          
      );      
    END */
    -- نمایش کد تلگرام
    ELSE IF @UssdCode = '*2#' AND @ChildUssdCode = '*2*1#'
    BEGIN
      SET @Message = N'کد تلگرامی شما ' + CONVERT(NVARCHAR(14), @ChatID) + N' می باشد';
    END
    -- ثبت از طریق شماره موبایل از سمت تلگرام
    ELSE IF @UssdCode = '*2*1#' AND @ChildUssdCode = '*2*1*0#'
    BEGIN    
      BEGIN TRY
         IF EXISTS(
            SELECT *
              FROM dbo.Service_Robot_Public
             WHERE CHAT_ID = @ChatID
               AND SRBT_ROBO_RBID = @Rbid
               AND CELL_PHON IS NULL
         )
         BEGIN
            UPDATE dbo.Service_Robot_Public
               SET CELL_PHON = @CellPhon
                  --,NAME = @NameService
                  --,SERV_ADRS = @ServAddres
             WHERE CHAT_ID = @ChatID
               AND SRBT_ROBO_RBID = @Rbid
               AND CELL_PHON IS NULL;
         END      
         ELSE
         BEGIN      
            INSERT INTO Service_Robot_Public (Srbt_Serv_File_No, Srbt_Robo_Rbid, Rwno, Cell_Phon, Chat_Id, SERV_ADRS, NAME, CORD_X, CORD_Y)
		       SELECT Serv_File_No, Robo_Rbid, 0, @CellPhon, @Chatid, NULL, NULL, 0, 0
		         FROM Service_Robot
		        WHERE Chat_Id = @ChatId
		 	      AND Robo_Rbid = @Rbid
		 	      AND NOT EXISTS(
		 	         SELECT * 
		 	           FROM dbo.Service_Robot_Public
		 	          WHERE SRBT_ROBO_RBID = @Rbid
		 	            AND SRBT_SERV_FILE_NO = SERV_FILE_NO
		 	            AND CHAT_ID = @ChatID
		 	            AND CELL_PHON = @CellPhon		 	         
		 	      );		
		   END 
         SELECT @XTemp = (
            SELECT @Token AS '@token'                
                  ,'002' AS 'Order/@dfltaces'
                  ,'012' AS 'Order/@type'
                  ,'001' AS 'Order/@elmntype'
                  ,@UssdCode AS 'Order/@ussdcode'
                  ,@ChildUssdCode AS 'Order/@childussdcode'
                  ,(SELECT N'کاربری با کد تلگرامی ' +
                           CAST(CHAT_ID AS VARCHAR(20)) + N' با شماره موبایل ' + CELL_PHON + N' پروفایل خود را در سیستم ثبت کردند '
                      FROM dbo.Service_Robot                      
                     WHERE CHAT_ID = @ChatID
                       AND ROBO_RBID = @Rbid) AS 'Order'
           FOR XML PATH('Robot')
         );
         
         -- ثبت پیام به مدیریت باشگاه
         EXEC dbo.SEND_PJRB_P @X = @XTemp -- xml
         
         SELECT @Message = N'اطلاعات شماره تلفن شما برای فعال سازی ثبت گردید.';
            
       END TRY
       BEGIN CATCH
         DECLARE @SqlErm NVARCHAR(MAX);
         SELECT @SqlErm = ERROR_MESSAGE();
         RAISERROR (@SqlErm, 16, 1);
         SET @Message = N'شماره موبایل ارسالی قابل ثبت در سیستم نیست، لطفا با قسمت امور اداری هماهنگی به عمل آورید';
       END CATCH   
    END
    ELSE IF @UssdCode = '*2*1#' AND @ChildUssdCode = '*2*1*1#'
    BEGIN
      SELECT @Message = (
         SELECT N'کد تلگرامی 👈 ' + CAST(CHAT_ID AS VARCHAR(20)) + CHAR(10) +
                N'شماره موبایل 👈 ' + ISNULL(CELL_PHON, '***') + CHAR(10) + 
                N'کد ملی 👈 ' + ISNULL(NATL_CODE, '***') + CHAR(10) + 
                N'نام 👈 ' + ISNULL(REAL_FRST_NAME, '***') + CHAR(10) +
                N'نام خانوادگی 👈 ' + ISNULL(REAL_LAST_NAME, '***') + CHAR(10) +
                N'نام شرکت 👈 ' + ISNULL(COMP_NAME, '***') + CHAR(10) +
                N'شماره همراه 👈 ' + ISNULL(OTHR_CELL_PHON, '***') + CHAR(10) +
                N'آدرس اول 👈 ' + ISNULL(SERV_ADRS, '***') + CHAR(10) + 
                N'آدرس دوم 👈 ' + ISNULL(OTHR_SERV_ADDR, '***') + CHAR(10) + 
                N'توضیحات 👈 ' + ISNULL(SRBT_DESC, '***') + CHAR(10)                
           FROM dbo.Service_Robot
          WHERE ROBO_RBID = @Rbid
            AND CHAT_ID = @ChatID
      );
    END  
    ELSE IF @ChildUssdCode = '*1*0#'
    BEGIN
      SELECT @XTemp = (
	      -- Last Location
	       SELECT 1 AS '@order',
	          N' تعداد کل مشتریان ' + (
	          SELECT CAST(COUNT(*) AS VARCHAR(20))
	            FROM dbo.Service_Robot 
	           WHERE Robo_Rbid = @Rbid
	        GROUP BY ROBO_RBID
	      ) + CHAR(10) +
	      N' تعداد مشتریان امروز ' + (
	         SELECT CAST(COUNT(*) AS VARCHAR(20))
	            FROM dbo.Service_Robot 
	           WHERE Robo_Rbid = @Rbid
	             AND JOIN_DATE = CAST(GETDATE() AS DATE)
	      ) 
	          FOR XML PATH('Text'), ROOT('Texts')
	          
      );
      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
   END
   ELSE IF @ChildUssdCode = '*1*1#'
   BEGIN
      SELECT @XTemp = (
	      -- Last Location
	       SELECT 1 AS '@order'
	            ,(
	             SELECT TOP 10 
	               --Srv.SRID AS '@order'
	               N'🗓 ' + dbo.GET_MTOS_U(Srv.VIST_DATE) + N' 👤 ' + S.FRST_NAME + N' ' + S.LAST_NAME + CHAR(10)
	               FROM dbo.Service S, dbo.Service_Robot Sr, dbo.Service_Robot_Visit Srv	            
	              WHERE Sr.Robo_Rbid = @Rbid
	                AND S.FILE_NO = Sr.SERV_FILE_NO
	                AND Sr.ROBO_RBID = Srv.SRRB_ROBO_RBID
	                AND Sr.SERV_FILE_NO = Srv.SRRB_SERV_FILE_NO
	             ORDER BY Srv.VIST_DATE DESC
	             FOR XML PATH('')
	          )
	          FOR XML PATH('Text'), ROOT('Texts')
	          
      );
      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
   END
   ELSE IF @ChildUssdCode = '*1*2#'
   BEGIN
      SELECT @XTemp = (
	      -- Last Location
	       SELECT 1 AS '@order'
	            ,(
                   SELECT N'👈 ' + MESG_TEXT + N' 〽️ ' +
                          CAST(COUNT(*) AS VARCHAR(10)) + CHAR(10)
                    FROM [iRoboTech].[dbo].[Service_Robot_Message]
                    WHERE SRBT_ROBO_RBID = @Rbid
                    AND MESG_TEXT NOT IN (N'بازگشت به منوی اصلی', N'🔺 بازگشت', N'/start')
                    AND USSD_CODE = '*1#'
                    GROUP BY MESG_TEXT
                    ORDER BY COUNT(*) desc
	             FOR XML PATH('')
	          )
	          FOR XML PATH('Text'), ROOT('Texts')
	          
      );
      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
   END
   ELSE IF @ChildUssdCode = '*1*3#'
   BEGIN
      SELECT @XTemp = (
	      -- Last Location
	       SELECT 1 AS '@order'
	            ,(
                   SELECT N'👈 ' + MESG_TEXT + N' 〽️ ' +
                          CAST(COUNT(*) AS VARCHAR(10)) + CHAR(10)
                    FROM [iRoboTech].[dbo].[Service_Robot_Message] Srm, dbo.Menu_Ussd m
                    WHERE srm.SRBT_ROBO_RBID = @Rbid
                    AND srm.SRBT_ROBO_RBID = m.ROBO_RBID
                    AND srm.MESG_TEXT NOT IN (N'بازگشت به منوی اصلی', N'🔺 بازگشت', N'/start')
                    AND srm.MESG_TEXT = m.MENU_TEXT
                    --AND srm.USSD_CODE = '*1#'
                    GROUP BY MESG_TEXT
                    ORDER BY COUNT(*) desc
	             FOR XML PATH('')
	          )
	          FOR XML PATH('Text'), ROOT('Texts')
	          
      );
      SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
      --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
   END
   ELSE IF @ChildUssdCode = '*1*4#'
   BEGIN
      SELECT @XTemp = (
          SELECT 1 AS '@order'
               ,(
                SELECT 
                  N' 👤 ' + S.FRST_NAME + N' ' + S.LAST_NAME + N' 📞 ' + CASE WHEN sr.CELL_PHON IS NULL THEN N' 😔 ' ELSE Sr.CELL_PHON + N' 😊 ' END + CHAR(10)
                  FROM dbo.Service S, dbo.Service_Robot Sr
                 WHERE Sr.Robo_Rbid = @Rbid
                   AND S.FILE_NO = Sr.SERV_FILE_NO
                   AND sr.CELL_PHON IS NOT NULL
                FOR XML PATH('')
             )
             FOR XML PATH('Text'), ROOT('Texts')
          
     );
     SET @XTemp.modify('insert attribute order {"1"} into (//Texts)[1]');
     --SET @XMessage.modify('insert sql:variable("@XTemp") as last into (/)[1]')

     SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
    END  
    -- ارسال پیام در قسمت مدیریت
    ELSE IF @UssdCode = '*1*5*0#' -- ارسال برای همه مشترکین
    BEGIN
      IF @ElmnType = '001'
         EXEC dbo.INS_SDAD_P @ROBO_RBID = @Rbid, -- bigint
             @ID = 0, -- bigint
             @PAKT_TYPE = '001', -- varchar(3)
             @FILE_ID = NULL, -- varchar(200)
             @TEXT_MESG = @MenuText; -- nvarchar(max)
      ELSE IF @ElmnType = '002'
         EXEC dbo.INS_SDAD_P @ROBO_RBID = @Rbid, -- bigint
             @ID = 0, -- bigint
             @PAKT_TYPE = '002', -- varchar(3)
             @FILE_ID = @PhotoFileId, -- varchar(200)
             @TEXT_MESG = @MenuText; -- nvarchar(max)
      ELSE IF @ElmnType = '003'
         EXEC dbo.INS_SDAD_P @ROBO_RBID = @Rbid, -- bigint
             @ID = 0, -- bigint
             @PAKT_TYPE = '003', -- varchar(3)
             @FILE_ID = @VideoFileId, -- varchar(200)
             @TEXT_MESG = @MenuText; -- nvarchar(max)
      ELSE IF @ElmnType = '004'
         EXEC dbo.INS_SDAD_P @ROBO_RBID = @Rbid, -- bigint
             @ID = 0, -- bigint
             @PAKT_TYPE = '004', -- varchar(3)
             @FILE_ID = @DocumentFileId, -- varchar(200)
             @TEXT_MESG = @MenuText; -- nvarchar(max)
      ELSE IF @ElmnType = '006'
         EXEC dbo.INS_SDAD_P @ROBO_RBID = @Rbid, -- bigint
             @ID = 0, -- bigint
             @PAKT_TYPE = '006', -- varchar(3)
             @FILE_ID = @AudioFileId, -- varchar(200)
             @TEXT_MESG = @MenuText; -- nvarchar(max)
      
      DECLARE @Said BIGINT;
      
      SELECT @Said = MAX(ID)
        FROM dbo.Send_Advertising
       WHERE PAKT_TYPE = @ElmnType
         AND CRET_BY = UPPER(SUSER_NAME())
         AND STAT = '002';
      
      UPDATE dbo.Send_Advertising
         SET STAT = '005'
       WHERE ID = @Said;
       
      SELECT @Message = N'پیام شما برای همه مشترکین ربات با موفقیت ثبت شد لطفا دکمه بازگشت جهت ارسال پیام را فشار دهید';
    END
    ELSE IF @UssdCode = '*1*5*1#' -- ارسال برای همه نمایندگان فروش
    BEGIN
      DECLARE C$SERV001 CURSOR FOR
         SELECT CHAT_ID, sr.SERV_FILE_NO
           FROM dbo.Service_Robot sr
          WHERE ROBO_RBID = @Rbid
            AND EXISTS(
                SELECT *
                  FROM dbo.Service_Robot_Group srg
                 WHERE sr.SERV_FILE_NO = srg.SRBT_SERV_FILE_NO
                   AND sr.ROBO_RBID = srg.SRBT_ROBO_RBID
                   AND srg.GROP_GPID = 126
                   AND srg.STAT = '002'
            );
      
      OPEN [C$SERV001];
      L$Loop_Serv001:
      FETCH [C$SERV001] INTO @ChatID, @SrbtServFileNo;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoop_Serv001;
      
      IF @ElmnType = '002'
         SET @FileId = @PhotoFileId
      ELSE IF @ElmnType = '003'
         SET @FileId = @VideoFileId
      ELSE IF @ElmnType = '004'
         SET @FileId = @DocumentFileId
      ELSE IF @ElmnType = '006'
         SET @FileId = @AudioFileId;
      
      IF @SrbtServFileNo IS NOT NULL
      BEGIN
         EXEC dbo.INS_SRRM_P @SRBT_SERV_FILE_NO = @SrbtServFileNo, -- bigint
             @SRBT_ROBO_RBID = @Rbid, -- bigint
             @RWNO = 0, -- bigint
             @SRMG_RWNO = NULL, -- bigint
             @Ordt_Ordr_Code = NULL, -- bigint
             @Ordt_Rwno = NULL, -- bigint
             @MESG_TEXT = @MenuText, -- nvarchar(max)
             @FILE_ID = @FileId, -- varchar(200)
             @FILE_PATH = NULL, -- nvarchar(max)
             @MESG_TYPE = @ElmnType, -- varchar(3)
             @LAT = NULL, -- float
             @LON = NULL, -- float
             @CONT_CELL_PHON = NULL; -- varchar(11)      
      END;
      
      GOTO L$Loop_Serv001;
      L$EndLoop_Serv001:
      CLOSE [C$SERV001];
      DEALLOCATE [C$SERV001];
      
      SELECT @Message = N'پیام شما برای همه اعضا باشگاه با موفقیت ثبت شد لطفا دکمه بازگشت جهت ارسال پیام را فشار دهید';
    END
    -- وضعیت موجودی کالا
    ELSE IF @UssdCode = '*1*6*0#' -- کالا موجود می باشد
    BEGIN
      UPDATE dbo.Organ_Media
         SET IMAG_DESC = (
			 SELECT m.MENU_TEXT
			   FROM dbo.Menu_Ussd m
			  WHERE m.ROBO_RBID = @Rbid
			    AND ( ( @MenuText LIKE 'update(*%#)' AND 'update(' + m.USSD_CODE + ')' = @MenuText ) OR 
                        m.MENU_TEXT = @MenuText )
         ) + CHAR(10) + CHAR(10) + N'✅ کالای مورد نظر شما موجود می باشد.' + CHAR(10) + CHAR(10) + N'@Jelve_Khane_Man_Bot'
       WHERE ROBO_RBID = @Rbid
         AND EXISTS(
             SELECT *
               FROM dbo.Menu_Ussd m
              WHERE m.ROBO_RBID = dbo.Organ_Media.ROBO_RBID
                AND m.USSD_CODE = dbo.Organ_Media.USSD_CODE
                AND ( ( @MenuText LIKE 'update(*%#)' AND 'update(' + m.USSD_CODE + ')' = @MenuText ) OR 
                        m.MENU_TEXT = @MenuText )
                AND m.STAT = '002'                
         );
         
      IF @@ROWCOUNT = 1
         SET @Message = N'اطلاعات موجودی کالای مورد نظر شما بروز رسانی شد';
      ELSE IF @@ROWCOUNT = 0
         SET @Message = N'چنین کالایی در سیستم شما تعریف نشده'
      ELSE IF @@ROWCOUNT > 1
         SET @Message = N'بروز خطا در سامانه بروزرسانی لطفا بررسی کنید که از کالای مورد نظر فقط یک ردیف در جدول اطلاعات پایه وجود داشته باشد';
    END
    ELSE IF @UssdCode = '*1*6*1#' -- موجودی کالا محدود می باشد
    BEGIN
      UPDATE dbo.Organ_Media
         SET IMAG_DESC = (
			 SELECT m.MENU_TEXT
			   FROM dbo.Menu_Ussd m
			  WHERE m.ROBO_RBID = @Rbid
			    AND ( ( @MenuText LIKE 'update(*%#)' AND 'update(' + m.USSD_CODE + ')' = @MenuText ) OR 
                        m.MENU_TEXT = @MenuText )
         ) + CHAR(10) + CHAR(10) + 
         N'⚠️ موجودی کالا محدود می باشد.' 
         + CHAR(10) + CHAR(10) + N'@Jelve_Khane_Man_Bot'		
       WHERE ROBO_RBID = @Rbid
         AND EXISTS(
             SELECT *
               FROM dbo.Menu_Ussd m
              WHERE m.ROBO_RBID = dbo.Organ_Media.ROBO_RBID
                AND m.USSD_CODE = dbo.Organ_Media.USSD_CODE
                AND ( ( @MenuText LIKE 'update(*%#)' AND 'update(' + m.USSD_CODE + ')' = @MenuText ) OR 
                        m.MENU_TEXT = @MenuText )
                AND m.STAT = '002'                
         );
         
      IF @@ROWCOUNT = 1
         SET @Message = N'اطلاعات موجودی کالای مورد نظر شما بروز رسانی شد';
      ELSE IF @@ROWCOUNT = 0
         SET @Message = N'چنین کالایی در سیستم شما تعریف نشده'
      ELSE IF @@ROWCOUNT > 1
         SET @Message = N'بروز خطا در سامانه بروزرسانی لطفا بررسی کنید که از کالای مورد نظر فقط یک ردیف در جدول اطلاعات پایه وجود داشته باشد';
    END
    ELSE IF @UssdCode = '*1*6*2#' -- کالا موجود نمی باشد
    BEGIN
      UPDATE dbo.Organ_Media
         SET IMAG_DESC = (
			 SELECT m.MENU_TEXT
			   FROM dbo.Menu_Ussd m
			  WHERE m.ROBO_RBID = @Rbid
			    AND ( ( @MenuText LIKE 'update(*%#)' AND 'update(' + m.USSD_CODE + ')' = @MenuText ) OR 
                        m.MENU_TEXT = @MenuText )
         ) + CHAR(10) + CHAR(10) + N'⛔️ کالای مورد نظر شما موجود نمی باشد.' + CHAR(10) + CHAR(10) + N'@Jelve_Khane_Man_Bot'
       
       WHERE ROBO_RBID = @Rbid
         AND EXISTS(
             SELECT *
               FROM dbo.Menu_Ussd m
              WHERE m.ROBO_RBID = dbo.Organ_Media.ROBO_RBID
                AND m.USSD_CODE = dbo.Organ_Media.USSD_CODE
                AND ( ( @MenuText LIKE 'update(*%#)' AND 'update(' + m.USSD_CODE + ')' = @MenuText ) OR 
                        m.MENU_TEXT = @MenuText )
                AND m.STAT = '002'                
         );
         
      IF @@ROWCOUNT = 1
         SET @Message = N'اطلاعات موجودی کالای مورد نظر شما بروز رسانی شد';
      ELSE IF @@ROWCOUNT = 0
         SET @Message = N'چنین کالایی در سیستم شما تعریف نشده'
      ELSE IF @@ROWCOUNT > 1
         SET @Message = N'بروز خطا در سامانه بروزرسانی لطفا بررسی کنید که از کالای مورد نظر فقط یک ردیف در جدول اطلاعات پایه وجود داشته باشد';
    END
    ELSE IF @UssdCode = '*0*4#' -- جستجو
    BEGIN
      SELECT @XTemp = (
         SELECT om.FILE_ID AS '@fileid'
               ,om.IMAG_DESC AS '@caption'
               ,ROW_NUMBER() OVER ( ORDER BY om.OPID ) AS '@order'
           FROM dbo.Menu_Ussd m ,dbo.Organ_Media om
          WHERE m.ROBO_RBID = om.ROBO_RBID
            AND m.USSD_CODE = om.USSD_CODE
            AND m.ROBO_RBID = @Rbid
            AND m.MENU_TEXT LIKE @MenuText
            AND m.STAT = '002'
            AND m.CMND_TYPE = '002'
            AND om.FILE_ID IS NOT NULL
            FOR XML PATH('Image'), ROOT('Images')
      );
      
      SET @XTemp.modify('insert attribute order {"1"} into (//Images)[1]');
      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
       -- اینجا بخاطر اینکه متن 
       -- XML 
       -- که ساخته شده خراب نشود بخاطر اون عبارت زمان که آخر پیام اضافه میشود
      GOTO L$EndSP; 
    END
    
    
    SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    
    L$EndSP:
    SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
    SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END;

GO
