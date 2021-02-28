SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SAVE_SRBT_P]
   @X XML,
   @XRet XML OUTPUT
AS 
BEGIN
   BEGIN TRY
   BEGIN TRAN [T$SAVE_SRBT_P]
   --
   DECLARE @FrstName NVARCHAR(250),
           @LastName NVARCHAR(250),
           @CellPhon VARCHAR(13),
           @NatlCode VARCHAR(10),
           @RefChatid BIGINT,
           @PostAdrs NVARCHAR(1000),
           @CordX FLOAT,
           @CordY FLOAT,
           @ChatId BIGINT,
           @SubSys INT,
           @Rbid BIGINT,
           @ActnType VARCHAR(3),
           @UssdCode VARCHAR(250),
           @CmndText VARCHAR(250),
           @ParmText NVARCHAR(250),
           @PostExec VARCHAR(250),
           @TrgrText VARCHAR(250);           
   
   SELECT @FrstName = @X.query('//Service').value('(Service/@frstname)[1]', 'NVARCHAR(250)')
         ,@LastName = @X.query('//Service').value('(Service/@lastname)[1]', 'NVARCHAR(250)')
         ,@CellPhon = @X.query('//Service').value('(Service/@cellphon)[1]', 'VARCHAR(13)')
         ,@NatlCode = @X.query('//Service').value('(Service/@natlcode)[1]', 'VARCHAR(10)')
         ,@RefChatid = @X.query('//Service').value('(Service/@refchatid)[1]', 'BIGINT')
         ,@PostAdrs = @X.query('//Service').value('(Service/@postadrs)[1]', 'NVARCHAR(1000)')
         ,@CordX    = @X.query('//Service').value('(Service/@cordx)[1]', 'FLOAT')
         ,@CordY    = @X.query('//Service').value('(Service/@cordy)[1]', 'FLOAT')
         ,@ChatId   = @X.query('//Service').value('(Service/@chatid)[1]', 'BIGINT')
         ,@SubSys   = @X.query('//Service').value('(Service/@subsys)[1]', 'INT')
         ,@Rbid     = @X.query('//Service').value('(Service/@rbid)[1]', 'BIGINT')
         ,@ActnType = @X.query('//Service').value('(Service/@actntype)[1]', 'VARCHAR(3)')
         ,@UssdCode = @X.query('//Service').value('(Service/@ussdcode)[1]', 'VARCHAR(250)')
         ,@CmndText = @X.query('//Service').value('(Service/@cmndtext)[1]', 'VARCHAR(250)')
         ,@ParmText = @X.query('//Service').value('(Service/@parmtext)[1]', 'NVARCHAR(250)')
         ,@PostExec = @X.query('//Service').value('(Service/@postexec)[1]', 'VARCHAR(250)')
         ,@TrgrText= @X.query('//Service').value('(Service/@trgrtext)[1]', 'VARCHAR(250)');

   
   -- انجام عملیات ثبت و ذخیره سازی اطلاعات
   -- ذخیره سازی اسم ، فامیل، کد ملی، شماره تلفن
   IF @ActnType = '001'
   BEGIN
      IF @SubSys = 5
      BEGIN
         IF EXISTS(SELECT * FROM iScsc.dbo.Fighter f WHERE f.CHAT_ID_DNRM = @ChatId)
         BEGIN
            SET @XRet = (
               SELECT 'failed' AS '@rsltdesc',
                      '001' AS '@rsltcode',
                      N'❗️ کد دستگاه شما *' + CAST(@ChatId AS NVARCHAR(30)) + N'* میباشد، با این شماره قبلا درون اتوماسیون ثبت شده اید، لطفا از منوی اعضا درخواست ثبت دوره جدید خود را انجام دهید'
                  FOR XML PATH('Message'), ROOT('Result')
            );
            GOTO L$EndSp;
         END
      END   

      IF dbo.CHK_MOBL_U(@CellPhon) = 0
      BEGIN
         SET @XRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ شماره موبایل *' + @CellPhon + N'* وارد شده درست نمی باشد' + CHAR(10) + 
                   N'لطفا در ورود اطلاعات خود دقت فرمایید'
               FOR XML PATH('Message'), ROOT('Result')
         );
         GOTO L$EndSp;
      END
      
      -- اگر مشتری ایرانی باشد چک کردن کد ملی لازم و ضروری میباشد
      IF @CmndText = 'reguser'            
         IF dbo.CHK_NATL_U(@NatlCode) = 0
         BEGIN
            SET @XRet = (
               SELECT 'failed' AS '@rsltdesc',
                      '001' AS '@rsltcode',
                      N'⛔️ کد ملی *' + @NatlCode + N'* وارد شده درست نمی باشد' + CHAR(10) + 
                      N'لطفا در ورود اطلاعات خود دقت فرمایید'
                  FOR XML PATH('Message'), ROOT('Result')
            );
            GOTO L$EndSp;
         END
      
      -- ثبت اطلاعات درون جدول مشتریان ربات
      -- Service_Robot, Service_Robot_Public
      UPDATE dbo.Service_Robot
         SET REAL_FRST_NAME = @FrstName
            ,REAL_LAST_NAME = @LastName
            ,CELL_PHON = @CellPhon
            ,OTHR_CELL_PHON = @CellPhon
            ,NATL_CODE = @NatlCode
            ,NAME = @FrstName + N' ' + @LastName
       WHERE CHAT_ID = @ChatId
         AND ROBO_RBID = @Rbid;
      
      UPDATE srp
         SET srp.Cell_Phon = @CellPhon
            ,srp.CORD_X = 0
            ,srp.CORD_Y = 0
            ,srp.NAME = @FrstName + N' ' + @LastName
        FROM dbo.Service_Robot_Public srp, dbo.Service_Robot sr
       WHERE srp.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
         AND srp.SRBT_ROBO_RBID = sr.ROBO_RBID
         AND srp.RWNO = ISNULL(sr.SRPB_RWNO, srp.RWNO)
         AND sr.CHAT_ID = @ChatId
         AND sr.ROBO_RBID = @Rbid;
   
      SET @XRet = (
         SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                N'💾 اطلاعات با موفقیت ثبت شده' + CHAR(10) + 
                N'📲 کد دستگاه شما : *' + CAST(@ChatId AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                N'نام : *' + sr.REAL_FRST_NAME + N'*' + CHAR(10) + 
                N'فامیل : *' + sr.REAL_LAST_NAME + N'*' + CHAR(10) + 
                N'شماره موبایل : *' + sr.OTHR_CELL_PHON + N'*' + CHAR(10) + 
                N'کد ملی : *' + sr.NATL_CODE + N'*' 
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.CHAT_ID = @ChatId
            FOR XML PATH('Message'), ROOT('Result')         
      );   
   END
   -- ذخیره سازی اطلاعات معرف
   ELSE IF @ActnType = '002'
   BEGIN
      UPDATE dbo.Service_Robot
         SET REF_CHAT_ID = @RefChatId,
             REF_SERV_FILE_NO = (SELECT sr.SERV_FILE_NO FROM Service_Robot sr WHERE ROBO_RBID = @Rbid AND CHAT_ID = @RefChatid),
             REF_ROBO_RBID = @Rbid
       WHERE ROBO_RBID = @Rbid
         AND CHAT_ID = @ChatID;
      
      SELECT @XRet = (
         SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                N'🎉 دوست عزیز شما در 👥 گروه' + CHAR(10) +
                N'*' + sr.NAME + N'* با کد *' + CAST(@RefChatid AS NVARCHAR(30)) + N'* قرار گرفتید.' + CHAR(10) + 
                N'کد شما برای معرفی دوستان خوب *' + CAST(@ChatID AS NVARCHAR(30)) + N'* می باشد' + CHAR(10) +
                N'با تشکر از شما'
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.CHAT_ID = @RefChatId
           FOR XML PATH('Message'), ROOT('Result')
      );
   END 
   -- ذخیره سازی اطلاعات آدرس و موقعیت مکانی
   ELSE IF @ActnType = '003'
   BEGIN
      MERGE dbo.Service_Robot_Public T
      USING (SELECT * FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId) S
      ON (t.SRBT_ROBO_RBID = @Rbid AND 
          t.CHAT_ID = s.CHAT_ID AND 
          (
            (ISNULL(t.SERV_ADRS, '') = '' AND ISNULL(t.CORD_X, 0) = 0 AND ISNULL(t.CORD_Y, 0) = 0) OR
            (ISNULL(t.SERV_ADRS, '') = '' AND ISNULL(t.CORD_X, 0) != 0 AND ISNULL(t.CORD_Y, 0) != 0) OR
            (ISNULL(t.SERV_ADRS, '') != '' AND ISNULL(t.CORD_X, 0) = 0 AND ISNULL(t.CORD_Y, 0) = 0)
          ))
      WHEN MATCHED THEN
         UPDATE SET
            t.SERV_ADRS = CASE ISNULL(@PostAdrs, '') WHEN '' THEN t.SERV_ADRS ELSE @PostAdrs END,
            t.CORD_X    = CASE ISNULL(@CordX, 0) WHEN 0 THEN t.CORD_X ELSE @CordX END ,
            T.CORD_Y    = CASE ISNULL(@CordY, 0) WHEN 0 THEN T.CORD_Y ELSE @CordY END
      WHEN NOT MATCHED THEN 
         INSERT (SRBT_SERV_FILE_NO, SRBT_ROBO_RBID, RWNO, CHAT_ID, CELL_PHON, NAME, SERV_ADRS, CORD_X, CORD_Y)
         VALUES (s.SERV_FILE_NO, s.ROBO_RBID, 0, @ChatId, ISNULL(s.CELL_PHON, S.OTHR_CELL_PHON), s.NAME, @PostAdrs, @CordX, @CordY);
         
      SET @XRet = (
         SELECT TOP 1 
                'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                N'💾 اطلاعات ورودی آدرس شما با موفقیت ثبت شد' + CHAR(10) + 
                N'📲 کد دستگاه شما : *' + CAST(@ChatId AS NVARCHAR(30)) + N'*' + CHAR(10) + CHAR(10) + 
                N'ردیف آدرس : *' + CAST(p.RWNO AS NVARCHAR(10)) + N'*' + CHAR(10) +
                N'وضعیت آدرس : ' + CASE WHEN p.SERV_ADRS IS NULL OR p.CORD_X IS NULL OR p.CORD_Y IS NULL THEN N'⭕️ *آدرس ناقص می باشد*' + CHAR(10) + 
                                           CASE WHEN p.Serv_Adrs IS NULL THEN N'⚠️ *آدرس متنی شما وارد نشده*'
                                                WHEN p.Cord_X IS NULL OR p.Cord_Y IS NULL THEN N'⚠️ *موقعیت مکانی آدرس شما وارد نشده* ' + CHAR(10) +
                                                                                               N'💡 موقعیت مکانی خود را با استفاده از دکمه ➕ ارسال کنید'
                                           END 
                                        ELSE N'✅ *آدرس کامل می باشد* ' + CHAR(10) + 
                                             N'⚠️ *لطفا از مطابقت آدرس متنی با موقعیت مکانی خود اطمینان حاصل نمایید*' + CHAR(10) + 
                                             N'💡 در صورت عدم مطابقت، نسبت به *حذف* یا *تکمیل* آدرس های *⭕ ناقص* از طریق قسمت *🛠️مدیریت آدرسها* اقدام نمایید'
                                   END + CHAR(10) + CHAR(10) + 
                N'نام : *' + sr.REAL_FRST_NAME + N'*' + CHAR(10) + 
                N'فامیل : *' + sr.REAL_LAST_NAME + N'*' + CHAR(10) + 
                N'شماره موبایل : *' + sr.OTHR_CELL_PHON + N'*' + CHAR(10) + 
                N'کد ملی : *' + sr.NATL_CODE + N'*' + CHAR(10) + 
                N'آدرس پستی : *' + ISNULL(p.SERV_ADRS, '---') + N'*' + CHAR(10) + 
                N'موقعیت مکانی : * X : ' + CAST(ISNULL(p.CORD_X, 0) AS NVARCHAR(30)) + N' Y : ' + CAST(ISNULL(p.CORD_Y, 0) AS NVARCHAR(30)) + N'*' + CHAR(10) +
                CASE WHEN p.CORD_X IS NOT NULL AND p.CORD_Y IS NOT NULL THEN dbo.STR_FRMT_U(N'📍 [موقعیت مکانی](https://www.google.com/maps?q=loc:{0},{1})', CAST(p.CORD_X AS VARCHAR(30)) + ',' + CAST(p.CORD_Y AS VARCHAR(30))) + CHAR(10) ELSE N'' END + 
                CASE WHEN p.SERV_ADRS IS NULL OR p.CORD_X IS NULL OR p.CORD_Y IS NULL THEN 
                          N'⚠️ در صورتی که آدرس شما *⭕ ناقص* باشد، ثبت هر گونه _آدرس جدید_ با این _آدرس_ *تداخل* خواهد داشت' + CHAR(10) + 
                          N'💡 آدرس فوق را *تکمیل* کرده و یا در غیر اینصورت جهت *حذف* این آدرس از طریق قسمت *🛠️ مدیریت آدرسها* اقدام نمایید' + CHAR(10)
                     ELSE N''
                END 
           FROM dbo.Service_Robot sr, dbo.Service_Robot_Public p
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.CHAT_ID = @ChatId
            AND sr.ROBO_RBID = p.SRBT_ROBO_RBID
            AND sr.SERV_FILE_NO = p.SRBT_SERV_FILE_NO
          ORDER BY p.CRET_DATE DESC
            FOR XML PATH('Message'), ROOT('Result')         
      );
   END
   -- بازیابی اطلاعات آدرس های مشتری
   ELSE IF @ActnType = '004'
   BEGIN
      SET @XRet = (
         SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',                
                N'📲 کد دستگاه شما : *' + CAST(@ChatId AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                N'نام : *' + sr.REAL_FRST_NAME + N'*' + CHAR(10) + 
                N'فامیل : *' + sr.REAL_LAST_NAME + N'*' + CHAR(10) + 
                N'شماره موبایل : *' + sr.OTHR_CELL_PHON + N'*' + CHAR(10) + 
                N'کد ملی : *' + sr.NATL_CODE + N'*' + CHAR(10) + CHAR(10) + 
                N'📌 آدرس های ثبت شده از شما' + CHAR(10) + 
                (
                   SELECT 
                         N'🚩 ردیف : *' + CAST(p.RWNO AS NVARCHAR(10)) + N'*' + CHAR(10) +
                         N'وضعیت آدرس : *' + CASE WHEN p.SERV_ADRS IS NULL OR p.CORD_X IS NULL OR p.CORD_Y IS NULL THEN N'⭕️ آدرس ناقص می باشد' ELSE N'✅ آدرس کامل می باشد' END + N'*'+ CHAR(10) +
                         N'آدرس پستی : *' + ISNULL(p.SERV_ADRS, '---') + N'*' + CHAR(10) + 
                         N'موقعیت مکانی : * X : ' + CAST(ISNULL(p.CORD_X, 0) AS NVARCHAR(30)) + N' Y : ' + CAST(ISNULL(p.CORD_Y, 0) AS NVARCHAR(30)) + N'*' + CHAR(10) +
                         CASE WHEN p.CORD_X IS NOT NULL AND p.CORD_Y IS NOT NULL THEN dbo.STR_FRMT_U(N'📍 [موقعیت مکانی](https://www.google.com/maps?q=loc:{0},{1})', CAST(p.CORD_X AS VARCHAR(30)) + ',' + CAST(p.CORD_Y AS VARCHAR(30))) + CHAR(10) ELSE N'' END + CHAR(10) 
                     FROM dbo.Service_Robot_Public p
                  WHERE p.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                    AND p.SRBT_ROBO_RBID = sr.ROBO_RBID
                    AND p.VALD_TYPE = '002'
                  ORDER BY p.RWNO DESC
                    FOR XML PATH('')
                )
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.CHAT_ID = @ChatId            
            FOR XML PATH('Message'), ROOT('Result')         
      );
   END
   -- بازیابی اطلاعات پروفایل مشتری
   ELSE IF @ActnType = '005' 
   BEGIN
      SET @XRet = (
         SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                N'👤 *اطلاعات من :*' + CHAR(10) + 
                N'📲 کد دستگاه من : *' + CAST(@ChatId AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                CHAR(9) + N'نام : *' + sr.REAL_FRST_NAME + N'*' + CHAR(10) + 
                CHAR(9) + N'فامیل : *' + sr.REAL_LAST_NAME + N'*' + CHAR(10) + 
                CHAR(9) + N'شماره موبایل : *' + sr.OTHR_CELL_PHON + N'*' + CHAR(10) + 
                CHAR(9) + N'کد ملی : *' + sr.NATL_CODE + N'*' + CHAR(10) + 
                CASE WHEN sr.REF_CHAT_ID IS NULL THEN N' '
                     ELSE CHAR(10) + N'👥 *اطلاعات معرف من :* ' + CHAR(10) + (SELECT CHAR(9) + N'نام : *' + srf.NAME + N'*' + CHAR(10) + CHAR(9) + N'موبایل : *' + sr.CELL_PHON + N'*' + CHAR(10) + CHAR(9) + N'کد معرف : *' + CAST(sr.REF_CHAT_ID AS NVARCHAR(30)) + N'*' FROM dbo.Service_Robot srf WHERE srf.ROBO_RBID = @Rbid AND srf.CHAT_ID = sr.REF_CHAT_ID) + CHAR(10) 
                END + CHAR(10) + 
                N'📌 *اطلاعات آدرس من :* ' + CHAR(10) + 
                CHAR(9) + N'تعداد کل آدرسها : *' + CAST(ISNULL(sr.SRPB_RWNO, 0) AS NVARCHAR(10)) + N'*' + CHAR(10) +
                CHAR(9) + N'وضعیت آخرین آدرس : *' + CASE WHEN sr.SERV_ADRS IS NULL OR sr.CORD_X IS NULL OR sr.CORD_Y IS NULL THEN N'⭕️ آدرس ناقص می باشد' ELSE N'✅ آدرس کامل می باشد' END + N'*'+ CHAR(10) +
                CHAR(9) + N'آدرس پستی : *' + ISNULL(sr.SERV_ADRS, N'---') + N'*' + CHAR(10) + 
                CHAR(9) + N'موقعیت مکانی : * X : ' + CAST(ISNULL(sr.CORD_X, 0) AS NVARCHAR(30)) + N' Y : ' + CAST(ISNULL(sr.CORD_Y, 0) AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                CASE WHEN sr.CORD_X IS NOT NULL AND sr.CORD_Y IS NOT NULL THEN dbo.STR_FRMT_U(N'📍 [موقعیت مکانی](https://www.google.com/maps?q=loc:{0},{1})', CAST(sr.CORD_X AS VARCHAR(30)) + ',' + CAST(sr.CORD_Y AS VARCHAR(30))) + CHAR(10) ELSE N'' END 
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.CHAT_ID = @ChatId
            FOR XML PATH('Message'), ROOT('Result')         
      );
   END 
   -- نمایش تعداد زیر مجموعه
   ELSE IF @ActnType = '006'
   BEGIN
      SET @XRet = (
         SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                N'👤 تعداد مجموعه فروش شما' + CHAR(10) + 
                N'📲 کد دستگاه شما : *' + CAST(@ChatId AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                N'👥 تعداد : *' + CAST(COUNT(sr.CHAT_ID) AS NVARCHAR(30)) + N'*' + CHAR(10) 
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.Ref_CHAT_ID = @ChatId
            FOR XML PATH('Message'), ROOT('Result')         
      );
   END 
   ELSE IF @ActnType = '007'
   BEGIN
      SET @XRet = (
         SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                N'👤 اطلاعات مجموعه فروش شما' + CHAR(10) + 
                N'📲 کد دستگاه شما : *' + CAST(@ChatId AS NVARCHAR(30)) + N'*' + CHAR(10) +                 
                ISNULL(
                (
                  SELECT N'نام : *' + sr.NAME + N'*' + CHAR(10) +
                         N'شماره تلفن : *' + sr.CELL_PHON + N'*' + CHAR(10) + 
                         N'کد دستگاه : *' + CAST(sr.CHAT_ID AS NVARCHAR(30)) + N'*' + CHAR(10) +
                         N'تاریخ عضویت : *' + dbo.GET_MTOS_U(sr.JOIN_DATE) + N'*' + CHAR(10)
                    FROM dbo.Service_Robot sr
                   WHERE sr.ROBO_RBID = @Rbid
                     AND sr.Ref_CHAT_ID = @ChatId
                ), N'شما مجموعه فروشی ندارید')
            FOR XML PATH('Message'), ROOT('Result')         
      );
   END
   ELSE IF @ActnType = '008' 
   BEGIN
      SET @XRet = (
         SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                (
                  SELECT './' + @UssdCode + 
                         ';' + @CmndText + 
                         '-' + CASE WHEN @CmndText IN ('slctloc4ordr') THEN @ParmText + ',' + CAST(p.RWNO AS VARCHAR(30)) 
                                    WHEN @CmndText IN ('location::select', 'location::del') THEN CAST(p.RWNO AS VARCHAR(30))                                     
                               END +
                         '$' + ISNULL(@PostExec, '') + 
                         '#' + ISNULL(@TrgrText, '') AS '@data',
                         ROW_NUMBER() OVER ( ORDER BY p.Rwno ) AS '@order',
                         N'📍 ' + p.SERV_ADRS AS "text()"
                    FROM dbo.Service_Robot_Public p
                   WHERE p.SRBT_SERV_FILE_NO = sr.Serv_file_No
                     AND p.SRBT_ROBO_RBID = sr.Robo_Rbid
                     AND p.VALD_TYPE = '002'
                   ORDER BY p.RWNO DESC
                     FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup'), TYPE
                ),
                N'📌 آدرس های ثبت شده برای شما' + CHAR(10) + CHAR(10) + 
                N'👈 لطفا آدرس مورد نظر خود را انتخاب کنید'
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.CHAT_ID = @ChatId
            FOR XML PATH('Message'), ROOT('Result')
      );
   END 
   -- بروزرسانی اطلاعات آدرس و موقعیت مکانی
   ELSE IF @ActnType = '009'
   BEGIN
      UPDATE dbo.Service_Robot_Public
         SET SERV_ADRS = CASE ISNULL(@PostAdrs, '') WHEN '' THEN SERV_ADRS ELSE @PostAdrs END,
             CORD_X    = CASE ISNULL(@CordX, 0) WHEN 0 THEN CORD_X ELSE @CordX END ,
             CORD_Y    = CASE ISNULL(@CordY, 0) WHEN 0 THEN CORD_Y ELSE @CordY END
       WHERE SRBT_ROBO_RBID = @Rbid
         AND CHAT_ID = @ChatId
         AND RWNO = @ParmText;         
         
      SET @XRet = (
         SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                N'💾 اطلاعات ورودی آدرس شما با موفقیت ثبت شد' + CHAR(10) + 
                N'📲 کد دستگاه شما : *' + CAST(@ChatId AS NVARCHAR(30)) + N'*' + CHAR(10) + CHAR(10) + 
                N'ردیف آدرس : *' + CAST(p.RWNO AS NVARCHAR(10)) + N'*' + CHAR(10) +
                N'وضعیت آدرس : ' + CASE WHEN p.SERV_ADRS IS NULL OR p.CORD_X IS NULL OR p.CORD_Y IS NULL THEN N'⭕️ *آدرس ناقص می باشد* ' + CHAR(10) + 
                                              CASE WHEN p.Serv_Adrs IS NULL THEN N'⚠️ *آدرس متنی شما وارد نشده* '
                                                   WHEN p.Cord_X IS NULL OR p.Cord_Y IS NULL THEN N'⚠️ *موقعیت مکانی آدرس شما وارد نشده* ' + CHAR(10) +
                                                                                                  N'💡 موقعیت مکانی خود را با استفاده از دکمه ➕ ارسال کنید'
                                              END 
                                         ELSE N'✅ *آدرس کامل می باشد* ' + CHAR(10) + 
                                              N'⚠️ *لطفا از مطابقت آدرس متنی با موقعیت مکانی خود اطمینان حاصل نمایید*' + CHAR(10) + 
                                              N'💡 در صورت عدم مطابقت، نسبت به *حذف* یا *تکمیل* آدرس های *⭕ ناقص* از طریق قسمت *🛠️مدیریت آدرسها* اقدام نمایید'
                                   END + CHAR(10) + CHAR(10) + 
                N'نام : *' + sr.REAL_FRST_NAME + N'*' + CHAR(10) + 
                N'فامیل : *' + sr.REAL_LAST_NAME + N'*' + CHAR(10) + 
                N'شماره موبایل : *' + sr.OTHR_CELL_PHON + N'*' + CHAR(10) + 
                N'کد ملی : *' + sr.NATL_CODE + N'*' + CHAR(10) + 
                N'آدرس پستی : *' + ISNULL(p.SERV_ADRS, '---') + N'*' + CHAR(10) + 
                N'موقعیت مکانی : * X : ' + CAST(ISNULL(p.CORD_X, 0) AS NVARCHAR(30)) + N' Y : ' + CAST(ISNULL(p.CORD_Y, 0) AS NVARCHAR(30)) + N'*' + CHAR(10) +
                CASE WHEN p.CORD_X IS NOT NULL AND p.CORD_Y IS NOT NULL THEN dbo.STR_FRMT_U(N'📍 [موقعیت مکانی](https://www.google.com/maps?q=loc:{0},{1})', CAST(p.CORD_X AS VARCHAR(30)) + ',' + CAST(p.CORD_Y AS VARCHAR(30))) + CHAR(10) ELSE N'' END + 
                CASE WHEN p.SERV_ADRS IS NULL OR p.CORD_X IS NULL OR p.CORD_Y IS NULL THEN 
                          N'⚠️ در صورتی که آدرس شما *⭕ ناقص* باشد، ثبت هر گونه _آدرس جدید_ با این _آدرس_ *تداخل* خواهد داشت' + CHAR(10) + 
                          N'💡 آدرس فوق را *تکمیل* کرده و یا در غیر اینصورت جهت *حذف* این آدرس از طریق قسمت *🛠️ مدیریت آدرسها* اقدام نمایید' + CHAR(10)
                     ELSE N''
                END 
           FROM dbo.Service_Robot sr, dbo.Service_Robot_Public p
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.CHAT_ID = @ChatId
            AND sr.ROBO_RBID = p.SRBT_ROBO_RBID
            AND sr.SERV_FILE_NO = p.SRBT_SERV_FILE_NO
            AND p.RWNO = @ParmText
            FOR XML PATH('Message'), ROOT('Result')         
      );
   END
   -- ذخیره سازی اطلاعات مشتری از طریق زیر سیستم 5
   ELSE IF @ActnType = '010'
   BEGIN
      IF @SubSys = 5
      BEGIN
         IF NOT EXISTS(SELECT * FROM iScsc.dbo.Fighter f WHERE f.CHAT_ID_DNRM = @ChatId)
         BEGIN
            SET @XRet = (
               SELECT 'failed' AS '@rsltdesc',
                      '001' AS '@rsltcode',
                      N'❗️ کد دستگاه شما *' + CAST(@ChatId AS NVARCHAR(30)) + N'* میباشد، با این شماره درون اتوماسیون ثبت نشده اید، لطفا از منوی لیست اعضا درخواست اصلاح اطلاعات کد بله خود را ثبت کنید و سپس اقدام کنید'
                  FOR XML PATH('Message'), ROOT('Result')
            );
            GOTO L$EndSp;
         END
      END   

      IF dbo.CHK_MOBL_U(@CellPhon) = 0
      BEGIN
         SET @XRet = (
            SELECT 'failed' AS '@rsltdesc',
                   '001' AS '@rsltcode',
                   N'⛔️ شماره موبایل *' + @CellPhon + N'* وارد شده درست نمی باشد' + CHAR(10) + 
                   N'لطفا در ورود اطلاعات خود دقت فرمایید'
               FOR XML PATH('Message'), ROOT('Result')
         );
         GOTO L$EndSp;
      END
      
      -- اگر مشتری ایرانی باشد چک کردن کد ملی لازم و ضروری میباشد
      IF @CmndText = 'reguser'            
         IF dbo.CHK_NATL_U(@NatlCode) = 0
         BEGIN
            SET @XRet = (
               SELECT 'failed' AS '@rsltdesc',
                      '001' AS '@rsltcode',
                      N'⛔️ کد ملی *' + @NatlCode + N'* وارد شده درست نمی باشد' + CHAR(10) + 
                      N'لطفا در ورود اطلاعات خود دقت فرمایید'
                  FOR XML PATH('Message'), ROOT('Result')
            );
            GOTO L$EndSp;
         END
      
      -- ثبت اطلاعات درون جدول مشتریان ربات
      -- Service_Robot, Service_Robot_Public
      UPDATE dbo.Service_Robot
         SET REAL_FRST_NAME = @FrstName
            ,REAL_LAST_NAME = @LastName
            ,CELL_PHON = @CellPhon
            ,OTHR_CELL_PHON = @CellPhon
            ,NATL_CODE = @NatlCode
            ,NAME = @FrstName + N' ' + @LastName
       WHERE CHAT_ID = @ChatId
         AND ROBO_RBID = @Rbid;
      
      UPDATE srp
         SET srp.Cell_Phon = @CellPhon
            ,srp.CORD_X = 0
            ,srp.CORD_Y = 0
            ,srp.NAME = @FrstName + N' ' + @LastName
        FROM dbo.Service_Robot_Public srp, dbo.Service_Robot sr
       WHERE srp.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
         AND srp.SRBT_ROBO_RBID = sr.ROBO_RBID
         AND srp.RWNO = ISNULL(sr.SRPB_RWNO, srp.RWNO)
         AND sr.CHAT_ID = @ChatId
         AND sr.ROBO_RBID = @Rbid;
   
      SET @XRet = (
         SELECT 'successful' AS '@rsltdesc',
                '002' AS '@rsltcode',
                N'💾 اطلاعات با موفقیت ثبت شده' + CHAR(10) + 
                N'📲 کد دستگاه شما : *' + CAST(@ChatId AS NVARCHAR(30)) + N'*' + CHAR(10) + 
                N'نام : *' + sr.REAL_FRST_NAME + N'*' + CHAR(10) + 
                N'فامیل : *' + sr.REAL_LAST_NAME + N'*' + CHAR(10) + 
                N'شماره موبایل : *' + sr.OTHR_CELL_PHON + N'*' + CHAR(10) + 
                N'کد ملی : *' + sr.NATL_CODE + N'*' 
           FROM dbo.Service_Robot sr
          WHERE sr.ROBO_RBID = @Rbid
            AND sr.CHAT_ID = @ChatId
            FOR XML PATH('Message'), ROOT('Result')         
      );   
   END 
   
   --
   L$EndSp:
   COMMIT TRAN [T$SAVE_SRBT_P];
   END TRY
   BEGIN CATCH
      DECLARE @ErorMesg NVARCHAR(MAX);
      SET @ErorMesg = ERROR_MESSAGE();
      SET @XRet = (
          SELECT 'failed' AS '@rsltdesc',
                 '001' AS '@rsltcode',
                 @ErorMesg
             FOR XML PATH('Message'), ROOT('Result')
      );
      RAISERROR(@ErorMesg, 16, 1);
      ROLLBACK TRAN [T$SAVE_SRBT_P];
   END CATCH
END
GO
