SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
-- =============================================  
-- Author:  <Author,,Name>  
-- Create date: <Create Date,,>  
-- Description: <Description,,>  
-- =============================================  
CREATE PROCEDURE [dbo].[Proccess_Message_P] @X XML, @XResult XML OUT
AS /*  
      <Robot token="211586642:AAE4P_tgkpdLhvNFVQ3K4BKrn6GuwsmH0AA">  
        <Message ussd="" chatid="41500009">  
          <Text>آدرس شرکت توزيع برق استان فارس</Text>  
          <From frstname="محسن" lastname="حدايقي" username="" id="41500009" />  
          <Location latitude="0" longitude="0" />  
        </Message>  
      </Robot>  
   */  
BEGIN  
   BEGIN TRY  
      BEGIN TRAN POINT1;  
 /* اولین مرحله برای پاسخ دهی به جواب ها باید مشترک را در جدول مشترکین اضافه نمود */  
      DECLARE @FileNo BIGINT ,
         @CellPhon VARCHAR(11) ,
         @FrstName NVARCHAR(100) ,
         @LastName NVARCHAR(100) ,
         @UserName VARCHAR(100) ,
         @ChatId BIGINT ,
         @RefChatId BIGINT;
   
      IF @XResult IS NULL
         SET @XResult = '<Respons>No Message</Respons>';  
 
 -- Convert Persian Number Input to Latin Number
      SET @X = dbo.STR_TRNS_U(CONVERT(NVARCHAR(MAX), @X), N'۱۲۳۴۵۶۷۸۹۰', N'1234567890');
           
      SELECT   @FrstName = @X.query('//From').value('(From/@frstname)[1]', 'NVARCHAR(100)') ,
               @LastName = @X.query('//From').value('(From/@lastname)[1]', 'NVARCHAR(100)') ,
               @UserName = @X.query('//From').value('(From/@username)[1]', 'VARCHAR(100)') ,
               @ChatId = @X.query('//From').value('(From/@id)[1]', 'BIGINT') ,
               @RefChatId = @X.query('//Message').value('(Message/@refchatid)[1]', 'BIGINT');  
   
      IF NOT EXISTS ( SELECT  *
                      FROM    [Service]
                      WHERE   CHAT_ID = @ChatId )
      BEGIN  
         INSERT   INTO [Service] (FRST_NAME ,LAST_NAME ,USER_NAME ,CHAT_ID ,STAT)
         VALUES   (@FrstName ,@LastName ,@UserName ,@ChatId ,'002');  
      END;  
      ELSE
      BEGIN  
         UPDATE   [Service]
         SET      FRST_NAME = @FrstName ,
                  LAST_NAME = @LastName ,
                  USER_NAME = @UserName
         WHERE    CHAT_ID = @ChatId;  
      END;  
 
 /* دومین مرحله برای پاسخ دهی به جواب ها باید مشترک را در جدول ربات مربوطه اضافه نمود */  
   
      SELECT @FileNo = FILE_NO FROM [Service] S WHERE S.CHAT_ID = @ChatId;  
   
      DECLARE @Token VARCHAR(100) , @Rbid BIGINT;  
   
      SELECT   @Token = @X.query('//Robot').value('(Robot/@token)[1]', 'VARCHAR(100)');  
   
      SELECT   @Rbid = RBID FROM Robot WHERE TKON_CODE = @Token;
 
 -- 1398/11/08 * اگر ربات وابسته و از مرجع خاصی اطلاعات خود را بخواد بردارد
      IF EXISTS ( SELECT   *
                  FROM     dbo.Robot
                  WHERE    TKON_CODE = @Token
                           AND COPY_TYPE = '002'
                           AND ROBO_RBID IS NOT NULL )
      BEGIN
         SELECT   @Rbid = ROBO_RBID
         FROM     dbo.Robot
         WHERE    TKON_CODE = @Token;      
  
         SELECT   @Token = TKON_CODE
         FROM     dbo.Robot
         WHERE    RBID = @Rbid;
      END; 
 
    
      IF NOT EXISTS ( SELECT  *
                      FROM    Service_Robot Sr ,
                              Robot R
                      WHERE   R.RBID = Sr.ROBO_RBID
                              AND R.TKON_CODE = @Token
                              AND Sr.CHAT_ID = @ChatId )
      BEGIN
         IF @RefChatId = 0
            SET @RefChatId = NULL;
      
         INSERT   INTO Service_Robot (SERV_FILE_NO ,ROBO_RBID ,STAT ,CHAT_ID ,JOIN_DATE ,REF_CHAT_ID)
         VALUES   (@FileNo ,@Rbid ,'002' ,@ChatId ,GETDATE() ,@RefChatId);  

         INSERT   INTO dbo.Service_Robot_Public (SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,RWNO ,CHAT_ID ,CORD_X ,CORD_Y)
         VALUES   ( @FileNo ,@Rbid ,0 , @ChatId ,0 ,0);
      END;
 
 -- 1395/12/08 * مشخص کردن اینکه آیا این فرد می تواند از قابلیت های ربات استفاده کند
      IF EXISTS ( SELECT   *
                  FROM     Service_Robot
                  WHERE    ROBO_RBID = @Rbid
                           AND SERV_FILE_NO = @FileNo
                           AND STAT = '001' -- غیرفعال
         )
      BEGIN
         SELECT   @XResult = ( SELECT  N'❗️ با عرض پوزش سرور بله قادر به پاسخگویی به شما مشترک عزیز نمی باشد.' AS 'Description' ,
                                       '' AS 'UssdCode' ,
                                       '001' AS 'ReadyToFire' ,
                                       '' AS 'CommandRunPlace' ,
                                       '0' AS 'Row' ,
                                       '1' AS 'Column'
                             FOR
                               XML PATH('Menu') ,
                                   ROOT('Respons')
                             );
         GOTO L$CommitTran;           
      END;
 
      IF NOT EXISTS ( SELECT  *
                      FROM    dbo.Service_Robot_Visit
                      WHERE   SRRB_SERV_FILE_NO = @FileNo
                              AND SRRB_ROBO_RBID = @Rbid
                              AND CAST(VIST_DATE AS DATE) = CAST(GETDATE() AS DATE) )
         INSERT   INTO dbo.Service_Robot_Visit (SRRB_SERV_FILE_NO ,SRRB_ROBO_RBID ,VIST_DATE)
         VALUES   (@FileNo ,@Rbid ,GETDATE());
   
 /* سومین مرحله برای پاسخ دهی به جواب ها باید مشترک را در جدول گروه های دسترسی عمومی که به صورت اتوماتیک به منوهای ربات اضافه نمود */  
   
      INSERT INTO Service_Robot_Group (SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,GROP_GPID ,STAT)
      SELECT @FileNo ,@Rbid , g.GPID , '002'      
        FROM [Group] g
       WHERE g.AUTO_JOIN = '002'
         AND g.ROBO_RBID = @Rbid
         AND NOT EXISTS ( SELECT *
                          FROM   Service_Robot_Group
                          WHERE  SRBT_SERV_FILE_NO = @FileNo
                                 AND SRBT_ROBO_RBID = @Rbid
                                 AND GROP_GPID = g.GPID );  

 /*INSERT INTO Service_Robot_Group (SRBT_SERV_FILE_NO, SRBT_ROBO_RBID, GROP_GPID, STAT)  
 SELECT @FileNo, @Rbid, g.GPID, '002'  
   FROM [Group] g  
  WHERE g.ADMN_ORGN = '002'  
    AND EXISTS(  
       SELECT *  
         FROM [Admin] A, Organ O, Robot R  
        WHERE A.SERV_FILE_NO = @FileNo  
          AND A.ORGN_OGID = O.OGID            
          AND O.OGID = R.ORGN_OGID  
          AND R.RBID = @Rbid  
          AND A.STAT = '002'  
          AND O.STAT = '002'  
          AND R.STAT = '002'  
    )  
    AND NOT EXISTS(  
       SELECT *  
         FROM Service_Robot_Group  
        WHERE SRBT_SERV_FILE_NO = @FileNo  
          AND SRBT_ROBO_RBID = @Rbid  
          AND GROP_GPID = g.GPID  
    );;  
   */  
      DECLARE @ContactFrstName NVARCHAR(100) ,
         @ContactID BIGINT ,
         @CantactPhoneNumber VARCHAR(13);  
     
      SELECT   @ContactFrstName = @X.query('//Contact').value('(Contact/@frstname)[1]', 'NVARCHAR(100)') ,
               @ContactID = @X.query('//Contact').value('(Contact/@id)[1]', 'BIGINT') ,
               @CantactPhoneNumber = @X.query('//Contact').value('(Contact/@phonnumb)[1]', 'VARCHAR(13)');  
   
      SELECT   @CantactPhoneNumber = CASE LEN(@CantactPhoneNumber)
                                       WHEN 11 THEN @CantactPhoneNumber
                                       WHEN 13 THEN '0' + SUBSTRING(@CantactPhoneNumber, 4, LEN(@CantactPhoneNumber))
                                     END;  
     
     
      IF /*LEN(@ContactFrstName) = LEN(@FrstName + N' ' + @LastName) AND*/ NOT EXISTS ( SELECT  *
                                                                                        FROM    [Service]
                                                                                        WHERE   FILE_NO = @FileNo
                                                                                                AND ISNULL(CELL_PHON, '') = @CantactPhoneNumber )
      BEGIN  
         IF @CantactPhoneNumber IS NOT NULL
         BEGIN  
            UPDATE   [Service]
            SET      CELL_PHON = @CantactPhoneNumber
            WHERE    FILE_NO = @FileNo;  
            
            -- 1399/08/21 * بررسی بیشتر
            --INSERT   INTO Service_Robot_Group (SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,GROP_GPID ,STAT)
            --SELECT   @FileNo ,@Rbid ,g.GPID ,'002'
            --FROM     [Group] g
            --WHERE    g.AUTO_JOIN = '001'
            --         AND g.ROBO_RBID = @Rbid
            --         AND NOT EXISTS ( SELECT *
            --                          FROM   Service_Robot_Group
            --                          WHERE  SRBT_SERV_FILE_NO = @FileNo
            --                                 AND SRBT_ROBO_RBID = @Rbid
            --                                 AND GROP_GPID = g.GPID );  
         END;     
      END;             
     
   /* چهارمین مرحله برای پاسخ دهی به جواب ها باید متن ارسالی توسط مشترک را در جدول منوهای ربات جستجو کرد و پیام نهایی را به مشترک برگرداند */  
      DECLARE @UssdCode VARCHAR(250) ,
         @MenuText NVARCHAR(250) ,
         @OrginalMenuText NVARCHAR(250) ,
         @Muid BIGINT ,
         @MesgId BIGINT ,
         @CmndType VARCHAR(3);  
     
      SELECT   @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]', 'VARCHAR(250)') ,
               @MesgId = @X.query('//Message').value('(Message/@mesgid)[1]', 'BIGINT') ,
               @MenuText = @X.query('//Message/Text').value('.', 'NVARCHAR(250)');  
      SET @OrginalMenuText = @MenuText;  
      
      -- 1399/05/04 * اگر درخواست منوی اصلی را داشته باشیم      
      --IF @MenuText = 'defaultmenu'      
      
   -- Check UssdCode From MenuText  
      DECLARE @UssdCodeFromMenuText NVARCHAR(250) ,
         @Data NVARCHAR(MAX);  

      INSERT   INTO dbo.Service_Robot_Message (SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,RWNO ,MESG_TEXT ,MESG_ID ,USSD_CODE)
      VALUES   (@FileNo ,@Rbid ,0 ,@MenuText ,@MesgId ,@UssdCode);

     
      BEGIN  
         SET @UssdCodeFromMenuText = REPLACE(RTRIM(@MenuText), ' ', '');  
      -- *1*1#45646,464,78$  
         PRINT @UssdCodeFromMenuText;  
         IF @UssdCodeFromMenuText LIKE '*%'
         BEGIN  
           
            SET @UssdCodeFromMenuText = SUBSTRING(@UssdCodeFromMenuText, 1, CHARINDEX('#', @UssdCodeFromMenuText));  
            PRINT @UssdCodeFromMenuText;  
            IF EXISTS ( SELECT   *
                        FROM     Menu_Ussd Mu
                        WHERE    Mu.STAT = '002'
                                 AND Mu.MENU_TYPE = '001' -- keyboard markup
                                 AND Mu.ROBO_RBID = @Rbid
                                 AND USSD_CODE = @UssdCodeFromMenuText )
            BEGIN  
              
               SELECT   @UssdCode = Mu.USSD_CODE ,
                        @MenuText = Mu.MENU_TEXT ,
                        @Muid = Mu.MUID
               FROM     Menu_Ussd Mu
               WHERE    Mu.STAT = '002'
                        AND Mu.ROBO_RBID = @Rbid
                        AND Mu.MENU_TYPE = '001' -- keyboard markup
                        AND USSD_CODE = @UssdCodeFromMenuText;  
              
               IF NOT EXISTS ( SELECT  *
                               FROM    Service_Robot_Group Srg ,
                                       Group_Menu_Ussd Gmu
                               WHERE   Srg.GROP_GPID = Gmu.GROP_GPID
                                       AND Srg.SRBT_SERV_FILE_NO = @FileNo
                                       AND Srg.SRBT_ROBO_RBID = @Rbid
                                       AND Srg.STAT = '002'
                                       AND Gmu.STAT = '002' )
               BEGIN  
                  SELECT   @UssdCode = '' ,
                           @MenuText = '';  
                 
               END;  
              
            END;  
         END;  
      END;  
     
      IF @MenuText = N'بازگشت به منوی اصلی'
         SET @UssdCode = NULL;  
      IF @UssdCode = '*#'
         OR LEN(@UssdCode) = 0
         SET @UssdCode = NULL;     
      IF @UssdCode IS NULL
         AND @MenuText = N'🔺 بازگشت'
         SET @MenuText = N'بازگشت به منوی اصلی';  
     
      IF @UssdCode IS NULL
         AND ( SELECT   COUNT(*)
               FROM     Service_Robot_Group Srg ,
                        Group_Menu_Ussd Gmu ,
                        Menu_Ussd Mu
               WHERE    Srg.SRBT_SERV_FILE_NO = @FileNo
                        AND Srg.SRBT_ROBO_RBID = @Rbid
                        AND Srg.GROP_GPID = Gmu.GROP_GPID
                        AND Srg.STAT = '002'
                        AND Gmu.MNUS_MUID = Mu.MUID
                        AND Gmu.STAT = '002'
                        AND Mu.MENU_TYPE = '001' -- keyboard markup
                        AND Mu.MENU_TEXT = @MenuText
                        AND Mu.STAT = '002'
             ) = 1
      BEGIN  
         SELECT   @UssdCode = Mu.USSD_CODE
         FROM     Service_Robot_Group Srg ,
                  Group_Menu_Ussd Gmu ,
                  Menu_Ussd Mu
         WHERE    Srg.SRBT_SERV_FILE_NO = @FileNo
                  AND Srg.SRBT_ROBO_RBID = @Rbid
                  AND Srg.GROP_GPID = Gmu.GROP_GPID
                  AND Srg.STAT = '002'
                  AND Gmu.MNUS_MUID = Mu.MUID
                  AND Gmu.STAT = '002'
                  AND Mu.MENU_TYPE = '001' -- keyboard markup
                  AND Mu.MENU_TEXT = @MenuText
                  AND Mu.STAT = '002';  
      END;  
      ELSE
         IF (
              @UssdCode IS NOT NULL
              AND ( SELECT COUNT(*)
                    FROM   Service_Robot_Group Srg ,
                           Group_Menu_Ussd Gmu ,
                           Menu_Ussd Mu
                    WHERE  Srg.SRBT_SERV_FILE_NO = @FileNo
                           AND Srg.SRBT_ROBO_RBID = @Rbid
                           AND Srg.GROP_GPID = Gmu.GROP_GPID
                           AND Srg.STAT = '002'
                           AND Gmu.MNUS_MUID = Mu.MUID
                           AND Gmu.STAT = '002'
                           AND Mu.MENU_TYPE = '001' -- keyboard markup 
                           AND Mu.USSD_CODE = @UssdCode
                           AND Mu.STAT = '002'
                  ) = 0
            )
            OR ( @MenuText = N'بازگشت به منوی اصلی' )
         BEGIN  
            L$BackMainMenu:  
            SELECT   @XResult = ( SELECT  N'🔦 لطفا گزینه مورد نظر خود را انتخاب نمایید.' AS 'Description' ,
                                          '' AS 'UssdCode' ,
                                          '001' AS 'ReadyToFire' ,
                                          '' AS 'CommandRunPlace' ,
                                          '0' AS 'Row' ,
                                          '1' AS 'Column'
                                FOR
                                  XML PATH('Menu') ,
                                      ROOT('Respons')
                                );        
          
            DECLARE MenuItem CURSOR
            FOR
            SELECT   Mu.MENU_TEXT ,
                     Mu.CMND_TYPE
            FROM     Service_Robot_Group Srg ,
                     Group_Menu_Ussd Gmu ,
                     Menu_Ussd Mu
            WHERE    Srg.SRBT_SERV_FILE_NO = @FileNo
                     AND Srg.SRBT_ROBO_RBID = @Rbid
                     AND Srg.GROP_GPID = Gmu.GROP_GPID
                     AND Srg.STAT = '002'
                     AND Gmu.MNUS_MUID = Mu.MUID
                     AND Mu.ROBO_RBID = Srg.SRBT_ROBO_RBID
                     AND Gmu.STAT = '002'
                     AND Mu.MENU_TYPE = '001' -- keyboard markup
                     AND Mu.ROOT_MENU = '002'
                     AND Mu.STAT = '002'
            ORDER BY ORDR;
       
       -- 1398/11/09 * اگر منوی تکراری در لیست وجود داشته باشد
            DECLARE @MenuTextTemp NVARCHAR(250) ,
               @CmndTypeTemp VARCHAR(3);
         
            OPEN MenuItem;  
            L$FNRMenuItem1:  
            FETCH NEXT FROM MenuItem INTO @MenuText, @CmndType;  
         
            IF @@FETCH_STATUS <> 0
               GOTO L$CMenuItem1;  
       
            IF @MenuText = @MenuTextTemp
               AND @CmndType = @CmndTypeTemp
               GOTO L$FNRMenuItem1;
         
            IF @CmndType IS NULL
               SET @CmndType = '000';
       
            SET @XResult.modify('insert <Text type="{sql:variable("@CmndType")}">{sql:variable("@MenuText")}</Text> as last into (/Respons/Menu)[1]');  
       
            SELECT   @MenuTextTemp = @MenuText ,
                     @CmndTypeTemp = @CmndType;
         
            GOTO L$FNRMenuItem1;  
            L$CMenuItem1:  
            CLOSE MenuItem;  
            DEALLOCATE MenuItem;  
                
            GOTO L$CommitTran;  
         END;    
      
      IF @UssdCode IS NOT NULL
         AND ( SELECT   COUNT(*)
               FROM     Service_Robot_Group Srg ,
                        Group_Menu_Ussd Gmu ,
                        Menu_Ussd Mu
               WHERE    Srg.SRBT_SERV_FILE_NO = @FileNo
                        AND Srg.SRBT_ROBO_RBID = @Rbid
                        AND Srg.GROP_GPID = Gmu.GROP_GPID
                        AND Srg.STAT = '002'
                        AND Gmu.MNUS_MUID = Mu.MUID
                        AND Gmu.STAT = '002'
                        AND Mu.MENU_TYPE = '001' -- keyboard markup
                        AND Mu.STEP_BACK = '002'
                        AND Mu.MENU_TEXT = @MenuText
                        AND Mu.MNUS_MUID IN ( SELECT  Mut.MUID
                                              FROM    Menu_Ussd Mut
                                              WHERE   Mut.ROBO_RBID = @Rbid
                                                      AND Mut.MENU_TYPE = '001' -- keyboard markup
                                                      AND (
                                                            @UssdCode IS NULL
                                                            OR Mut.USSD_CODE = @UssdCode
                                                          ) )
                        AND Mu.STAT = '002'
             ) = 1
      BEGIN  
         SELECT   @UssdCode = Mu.STEP_BACK_USSD_CODE
         FROM     Service_Robot_Group Srg ,
                  Group_Menu_Ussd Gmu ,
                  Menu_Ussd Mu
         WHERE    Srg.SRBT_SERV_FILE_NO = @FileNo
                  AND Srg.SRBT_ROBO_RBID = @Rbid
                  AND Srg.GROP_GPID = Gmu.GROP_GPID
                  AND Srg.STAT = '002'
                  AND Gmu.MNUS_MUID = Mu.MUID
                  AND Gmu.STAT = '002'
                  AND Mu.MENU_TYPE = '001' -- keyboard markup
                  AND Mu.STEP_BACK = '002'
                  AND Mu.MENU_TEXT = @MenuText
                  AND Mu.MNUS_MUID IN ( SELECT  Mut.MUID
                                        FROM    Menu_Ussd Mut
                                        WHERE   Mut.ROBO_RBID = @Rbid
                                                AND Mut.MENU_TYPE = '001' -- keyboard markup 
                                                AND Mut.USSD_CODE = @UssdCode )
                  AND Mu.STAT = '002';   
         
         SELECT   @MenuText = Mu.MENU_TEXT
         FROM     Service_Robot_Group Srg ,
                  Group_Menu_Ussd Gmu ,
                  Menu_Ussd Mu
         WHERE    Srg.SRBT_SERV_FILE_NO = @FileNo
                  AND Srg.SRBT_ROBO_RBID = @Rbid
                  AND Srg.GROP_GPID = Gmu.GROP_GPID
                  AND Srg.STAT = '002'
                  AND Gmu.MNUS_MUID = Mu.MUID
                  AND Gmu.STAT = '002'
                  AND Mu.MENU_TYPE = '001' -- keyboard markup
                  AND Mu.USSD_CODE = @UssdCode
                  AND Mu.STAT = '002';     
      END;  
      
      IF @UssdCode IS NOT NULL
         AND ( SELECT   COUNT(*)
               FROM     Service_Robot_Group Srg ,
                        Group_Menu_Ussd Gmu ,
                        Menu_Ussd Mu
               WHERE    Srg.SRBT_SERV_FILE_NO = @FileNo
                        AND Srg.SRBT_ROBO_RBID = @Rbid
                        AND Srg.GROP_GPID = Gmu.GROP_GPID
                        AND Srg.STAT = '002'
                        AND Gmu.MNUS_MUID = Mu.MUID
                        AND Gmu.STAT = '002'  
          --AND Mu.STEP_BACK = '002'  
                        AND Mu.MENU_TYPE = '001' -- keyboard markup
                        AND Mu.MENU_TEXT = @MenuText
                        AND Mu.MNUS_MUID IN ( SELECT  Mut.MUID
                                              FROM    Menu_Ussd Mut
                                              WHERE   Mut.ROBO_RBID = @Rbid
                                                      AND Mut.MENU_TYPE = '001' -- keyboard markup
                                                      AND (
                                                            @UssdCode IS NULL
                                                            OR Mut.USSD_CODE = @UssdCode
                                                          ) )
                        AND Mu.STAT = '002'
             ) = 1
      BEGIN  
         SELECT   @UssdCode = Mu.USSD_CODE ,
                  @MenuText = Mu.MENU_TEXT
         FROM     Service_Robot_Group Srg ,
                  Group_Menu_Ussd Gmu ,
                  Menu_Ussd Mu
         WHERE    Srg.SRBT_SERV_FILE_NO = @FileNo
                  AND Srg.SRBT_ROBO_RBID = @Rbid
                  AND Srg.GROP_GPID = Gmu.GROP_GPID
                  AND Srg.STAT = '002'
                  AND Gmu.MNUS_MUID = Mu.MUID
                  AND Gmu.STAT = '002'  
          --AND Mu.STEP_BACK = '002'  
                  AND Mu.MENU_TYPE = '001' -- keyboard markup
                  AND Mu.MENU_TEXT = @MenuText
                  AND Mu.MNUS_MUID IN ( SELECT  Mut.MUID
                                        FROM    Menu_Ussd Mut
                                        WHERE   Mut.ROBO_RBID = @Rbid
                                                AND Mut.MENU_TYPE = '001' -- keyboard markup
                                                AND (
                                                      @UssdCode IS NULL
                                                      OR Mut.USSD_CODE = @UssdCode
                                                    ) )
                  AND Mu.STAT = '002';     
      END;  
      
      IF @UssdCode IS NULL
      BEGIN        
         GOTO L$BackMainMenu;      
      END;  
    
      IF @UssdCode IS NOT NULL
         AND @MenuText = N'🔺 بازگشت'
      BEGIN      
         IF ( SELECT LEN(@UssdCode) - LEN(REPLACE(@UssdCode, '*', ''))
            ) > 1
         BEGIN
            SET @UssdCode = REVERSE(@UssdCode);
            SET @UssdCode = REVERSE('#' + SUBSTRING(@UssdCode, CHARINDEX('*', @UssdCode, CHARINDEX('*', @UssdCode) + 1) + 1, LEN(@UssdCode)));
         END;
         SELECT   @MenuText = MENU_TEXT
         FROM     dbo.Menu_Ussd
         WHERE    ROBO_RBID = @Rbid
                  AND MENU_TYPE = '001' -- keyboard markup
                  AND USSD_CODE = @UssdCode;
      END;
      
      SELECT   @XResult = ( SELECT  Mu.MNUS_DESC AS 'Description' ,
                                    Mu.USSD_CODE AS 'UssdCode' ,
                                    Mu.CMND_FIRE AS 'ReadyToFire' ,
                                    Mu.CMND_PLAC AS 'CommandRunPlace' ,
                                    '0' AS 'Row' ,
                                    Mu.CLMN AS 'Column'
                            FROM    Service_Robot_Group Srg ,
                                    Group_Menu_Ussd Gmu ,
                                    Menu_Ussd Mu
                            WHERE   Srg.SRBT_SERV_FILE_NO = @FileNo
                                    AND Srg.SRBT_ROBO_RBID = @Rbid
                                    AND Srg.GROP_GPID = Gmu.GROP_GPID
                                    AND Srg.STAT = '002'
                                    AND Gmu.MNUS_MUID = Mu.MUID
                                    AND Gmu.STAT = '002'
                                    AND Mu.MENU_TYPE = '001' -- keyboard markup
                                    AND Mu.USSD_CODE = @UssdCode
                                    AND Mu.STAT = '002'
                          FOR
                            XML PATH('Menu') ,
                                ROOT('Respons')
                          );  
    
    -- 1398/12/08 * اگر دکمه ای که در آن هستیم گزینه های 
    -- CMND_FIRE = '002' & CMND_PLAC = '002'
    -- باشد در این قسمت اگر متنی وارد کرده باشیم که هیچ کدام از دکمه های این زیر مجموعه نباشد می توانیم منوهای 
    -- همین منوی اصلی را برگردانیم در حال حاضر فقط دکمه بازگشت و بازگشت به منوی اصلی را داریم
    -- ولی با این روش جدید دوباره منوی منوی اصلی را بازیابی میکنیم
    --IF EXISTS(
    --   SELECT *
    --     FROM dbo.Menu_Ussd mua
    --    WHERE mua.ROBO_RBID = @Rbid
    --      AND mua.USSD_CODE = @UssdCode
    --      AND mua.CMND_FIRE = '002'
    --      AND mua.CMND_PLAC = '002'
    --      AND NOT EXISTS(
    --          SELECT *
    --            FROM dbo.Menu_Ussd mub
    --           WHERE mua.MUID = mub.MNUS_MUID
    --             AND mub.STAT = '002'
    --             AND mub.MNUS_DESC = @MenuText                
    --      )
    --)
    --BEGIN
    --  SELECT @MenuText = MENU_TEXT
    --    FROM dbo.Menu_Ussd
    --   WHERE ROBO_RBID = @Rbid
    --     AND USSD_CODE = @UssdCode;
    --END 
      
      DECLARE MenuItem CURSOR
      FOR
      SELECT   Mu.MENU_TEXT ,
               Mu.CMND_TYPE
      FROM     Service_Robot_Group Srg ,
               Group_Menu_Ussd Gmu ,
               Menu_Ussd Mu
      WHERE    Srg.SRBT_SERV_FILE_NO = @FileNo
               AND Srg.SRBT_ROBO_RBID = @Rbid
               AND Srg.GROP_GPID = Gmu.GROP_GPID
               AND Srg.STAT = '002'
               AND Gmu.MNUS_MUID = Mu.MUID
               AND Mu.ROBO_RBID = Srg.SRBT_ROBO_RBID
               AND Gmu.STAT = '002'
               AND Mu.MENU_TYPE = '001' -- keyboard markup
               AND Mu.MNUS_MUID IN ( SELECT  Mut.MUID
                                     FROM    Menu_Ussd Mut
                                     WHERE   Mut.ROBO_RBID = @Rbid
                                             AND Mut.MENU_TYPE = '001' -- keyboard markup
                                             AND (
                                                   @UssdCode IS NULL
                                                   OR Mut.USSD_CODE = @UssdCode
                                                 )
                                             AND (
                                                   @UssdCode IS NULL
                                                   OR (
                                                        @MenuText IS NOT NULL
                                                        AND Mut.MENU_TEXT = @MenuText
                                                      )
                                                 ) )
               AND Mu.STAT = '002'
      ORDER BY ORDR;  
    
      SELECT   @MenuTextTemp = NULL ,
               @CmndTypeTemp = NULL;
      
      OPEN MenuItem;  
      L$FNRMenuItem2:  
      FETCH NEXT FROM MenuItem INTO @MenuText, @CmndType;  
      
      IF @@FETCH_STATUS <> 0
         GOTO L$CMenuItem2;  
    
      IF @MenuTextTemp = @MenuText
         AND @CmndTypeTemp = @CmndType
         GOTO L$FNRMenuItem2;
    
      IF @CmndType IS NULL
         SET @CmndType = '000';
      
      SET @XResult.modify('insert <Text type="{sql:variable("@CmndType")}">{sql:variable("@MenuText")}</Text> as last into (/Respons/Menu)[1]');  
    
      SELECT   @MenuTextTemp = @MenuText ,
               @CmndTypeTemp = @CmndType;    
      
      GOTO L$FNRMenuItem2;  
      L$CMenuItem2:  
      CLOSE MenuItem;  
      DEALLOCATE MenuItem;  
      
      IF (
           (
             EXISTS ( SELECT  *
                      FROM    Service_Robot_Group Srg ,
                              Group_Menu_Ussd Gmu ,
                              Menu_Ussd Mu
                      WHERE   Srg.SRBT_SERV_FILE_NO = @FileNo
                              AND Srg.SRBT_ROBO_RBID = @Rbid
                              AND Srg.GROP_GPID = Gmu.GROP_GPID
                              AND Srg.STAT = '002'
                              AND Gmu.MNUS_MUID = Mu.MUID
                              AND Gmu.STAT = '002'
                              AND Mu.MENU_TYPE = '001' -- keyboard markup
                              AND Mu.STEP_BACK = '002'
                              AND Mu.MNUS_MUID IN ( SELECT  Mut.MUID
                                                    FROM    Menu_Ussd Mut
                                                    WHERE   Mut.ROBO_RBID = @Rbid
                                                            AND Mut.MENU_TYPE = '001' -- keyboard markup
                                                            AND (
                                                                  @UssdCode IS NULL
                                                                  OR Mut.USSD_CODE = @UssdCode
                                                                ) )
                              AND Mu.STAT = '002' )
             AND NOT EXISTS ( SELECT   *
                              FROM     Service_Robot_Group Srg ,
                                       Group_Menu_Ussd Gmu ,
                                       Menu_Ussd Mu
                              WHERE    Srg.SRBT_SERV_FILE_NO = @FileNo
                                       AND Srg.SRBT_ROBO_RBID = @Rbid
                                       AND Srg.GROP_GPID = Gmu.GROP_GPID
                                       AND Srg.STAT = '002'
                                       AND Gmu.MNUS_MUID = Mu.MUID
                                       AND Gmu.STAT = '002'
                                       AND Mu.MENU_TYPE = '001' -- keyboard markup
                                       AND Mu.MENU_TEXT = @MenuText
                                       AND Mu.STAT = '002' )
           )
           OR ( EXISTS ( SELECT  *
                         FROM    Service_Robot_Group Srg ,
                                 Group_Menu_Ussd Gmu ,
                                 Menu_Ussd Mu
                         WHERE   Srg.SRBT_SERV_FILE_NO = @FileNo
                                 AND Srg.SRBT_ROBO_RBID = @Rbid
                                 AND Srg.GROP_GPID = Gmu.GROP_GPID
                                 AND Srg.STAT = '002'
                                 AND Gmu.MNUS_MUID = Mu.MUID
                                 AND Gmu.STAT = '002'
                                 AND Mu.MENU_TEXT = @OrginalMenuText
                                 AND Mu.MENU_TYPE = '001' -- keyboard markup
                                 AND Mu.USSD_CODE != @UssdCode
                                 AND Mu.STAT = '002'
                                 AND EXISTS ( SELECT  *
                                              FROM    dbo.Menu_Ussd mt
                                              WHERE   Mu.ROBO_RBID = mt.ROBO_RBID
                                                      AND mt.USSD_CODE = @UssdCode
                                                      AND mt.STAT = '002'
                                                      AND mt.MENU_TYPE = '001' -- keyboard markup
                                                      AND mt.CMND_FIRE = '002'
                                                      AND mt.CMND_PLAC = '002' ) ) )
         )
      BEGIN
         IF NOT EXISTS ( SELECT  t.c.query('.') AS Result
                         FROM    @XResult.nodes('//Text') AS t ( c )
                         WHERE   t.c.query('.').value('.', 'NVARCHAR(250)') LIKE N'🔺 بازگشت' )
         BEGIN
            SET @MenuText = N'🔺 بازگشت';  
            SET @XResult.modify('insert <Text type="000">{sql:variable("@MenuText")}</Text> as last into (/Respons/Menu)[1]');  
         END;
      END;  
      
      SET @MenuText = N'بازگشت به منوی اصلی';  
      IF @XResult IS NOT NULL
         SET @XResult.modify('insert <Text type="000">{sql:variable("@MenuText")}</Text> as last into (/Respons/Menu)[1]');  
      
      L$CommitTran:              
      COMMIT TRAN POINT1;  
   END TRY  
   BEGIN CATCH  
      CLOSE MenuItem;  
      DEALLOCATE MenuItem;  
      DECLARE @SqlErrM NVARCHAR(MAX);  
      SELECT   @SqlErrM = ERROR_MESSAGE();  
      RAISERROR(@SqlErrM, 16, 1);  
      ROLLBACK TRAN POINT1;  
   END CATCH;  
END;  
  
GO
