SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[AnarShop_Analisis_Message_P]
    @X XML,
    @XResult XML OUTPUT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION [T$ANAR_SHOP_P];
        DECLARE @UssdCode VARCHAR(250),                @ChildUssdCode VARCHAR(250),                @CallBackQuery VARCHAR(3),
                @MenuText NVARCHAR(MAX),              @ParamText NVARCHAR(MAX),                   @PostExec NVARCHAR(MAX),
                @Trigger NVARCHAR(MAX),               @Message NVARCHAR(MAX),                     @XMessage XML,
                @XTemp XML,                            @ChatID BIGINT,                             @RefChatId BIGINT,
                @TChatId BIGINT,                      @WaltAmnt BIGINT,
                @CordX FLOAT,                          @CordY FLOAT,                               @CellPhon VARCHAR(13),
                @FileName NVARCHAR(MAX),              @FileExt VARCHAR(10),                       @PhotoFileId VARCHAR(MAX),
                @VideoFileId VARCHAR(MAX),            @DocumentFileId VARCHAR(MAX),               @AudioFileId VARCHAR(MAX),
                @FileId VARCHAR(MAX),                 @ElmnType VARCHAR(3),                        @Item NVARCHAR(1000),
                @Name NVARCHAR(250),                   @Numb NVARCHAR(100),                        @MimeType VARCHAR(100),
                @Index BIGINT = 0,                     @Token VARCHAR(100),                        @Rbid BIGINT,
                @AmntType VARCHAR(3),                  @AmntTypeDesc NVARCHAR(20),                 @Pric INT,
                @ExtrPrct INT,                         @Amnt BIGINT,                               @OffPrct REAL,
                @RtngNumbDnrm REAL,                    @RtngContDnrm INT,                          @ProdFetr NVARCHAR(MAX),
                @TarfTextDnrm NVARCHAR(250),           @TarfEnglText NVARCHAR(250),                @RevwContDnrm INT,
                @BrndTextDnrm NVARCHAR(250),           @GropTextDnrm NVARCHAR(250),                @Said BIGINT,
                @SrbtServFileNo BIGINT,                @OrdrCode BIGINT,                           @OrdrRwno BIGINT,
                @RbppCode BIGINT,                      @RsltCode VARCHAR(3),                       @CnctAcntApp VARCHAR(3),
                @AcntAppType VARCHAR(3),               @PageFechRows INT,                          @Page INT = 1,
                @RtngType VARCHAR(3),                  @SrorCode BIGINT,                           @SortType VARCHAR(100),
                @FilterType NVARCHAR(MAX),             @FBCode BIGINT,                             @FGCode BIGINT,
                @FTCode VARCHAR(3),                    @FPCode VARCHAR(3),                         @FDCode VARCHAR(3),
                @FCCode REAL,                          @ResultType VARCHAR(100),                   @QueryStatement NVARCHAR(MAX),
                @ContName NVARCHAR(250),               @ContCellPhon VARCHAR(13),                  @TDirPrjbCode BIGINT,
                @BankCard VARCHAR(16),                 @ShbaNumb VARCHAR(100),                     @TxfeAmnt BIGINT,
                @SysCode VARCHAR(30),                  @OrdrType VARCHAR(3),                       @TarfCode VARCHAR(100),
                @LikeStat VARCHAR(3),                  @AmazNotiStat VARCHAR(3),                   @SgnlNotiStat VARCHAR(3),
                @LikeContDnrm BIGINT,                  @VistContDnrm BIGINT,                       @SaleContDnrm REAL,
                @MinOrdr REAL,                         @GrntStat VARCHAR(3),                       @GrntNumb INT,
                @GrntTime VARCHAR(3),                  @GrntType VARCHAR(3),                       @WrntStat VARCHAR(3),
                @WrntNumb INT,                         @WrntTime VARCHAR(3),                       @WrntType VARCHAR(3),
                @ViewInvrStat VARCHAR(3),              @UnitDescDnrm NVARCHAR(250),                @CrntNumbDnrm REAL,
                @AlrmMinNumbDnrm REAL,                 @V$WhereAreYouFrom VARCHAR(100),            @ServFileNo BIGINT,
                @MakeDayDnrm SMALLINT,                 @MakeHourDnrm SMALLINT,                     @MakeMintDnrm SMALLINT,
                @DelvDayDnrm SMALLINT,                 @DelvHourDnrm SMALLINT,                     @DelvMintDnrm SMALLINT,
                @ProdLifeStat VARCHAR(3),              @ProdSuplLoctStat VARCHAR(3),               @ProdSuplLoctDesc NVARCHAR(250),
                @RespShipCostType VARCHAR(3);

        SELECT @Token = @X.query('/Robot').value('(Robot/@token)[1]', 'VARCHAR(100)'),
               @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]', 'VARCHAR(250)'),
               @ChildUssdCode = @X.query('//Message').value('(Message/@childussd)[1]', 'VARCHAR(250)'),
               @CallBackQuery = @X.query('//Message').value('(Message/@cbq)[1]', 'VARCHAR(3)'),
               @ChatID = @X.query('//Message').value('(Message/@chatid)[1]', 'BIGINT'),
               @ElmnType = @X.query('//Message').value('(Message/@elmntype)[1]', 'VARCHAR(3)'),
               @MimeType = @X.query('//Message').value('(Message/@mimetype)[1]', 'VARCHAR(100)'),
               @FileName = @X.query('//Message').value('(Message/@filename)[1]', 'NVARCHAR(MAX)'),
               @FileExt = @X.query('//Message').value('(Message/@fileext)[1]', 'VARCHAR(10)'),
               @MenuText = @X.query('//Text').value('.', 'NVARCHAR(MAX)'),
               @ParamText = @X.query('//Text').value('(Text/@param)[1]', 'NVARCHAR(MAX)'),
               @PostExec = @X.query('//Text').value('(Text/@postexec)[1]', 'NVARCHAR(MAX)'),
               @Trigger = @X.query('//Text').value('(Text/@trigger)[1]', 'NVARCHAR(MAX)'),
               @CellPhon = @X.query('//Contact').value('(Contact/@phonnumb)[1]', 'VARCHAR(13)'),
               @CordX = @X.query('//Location').value('(Location/@latitude)[1]', 'FLOAT'),
               @CordY = @X.query('//Location').value('(Location/@longitude)[1]', 'FLOAT'),
               @PhotoFileId = @X.query('//Photo').value('(Photo/@fileid)[1]', 'NVARCHAR(MAX)'),
               @VideoFileId = @X.query('//Video').value('(Video/@fileid)[1]', 'NVARCHAR(MAX)'),
               @DocumentFileId = @X.query('//Document').value('(Document/@fileid)[1]', 'NVARCHAR(MAX)'),
               @AudioFileId = @X.query('//Audio').value('(Audio/@fileid)[1]', 'NVARCHAR(MAX)'),
               @ContName = @X.query('//Contact').value('(Contact/@frstname)[1]', 'NVARCHAR(250)'),
               @ContCellPhon = @X.query('//Contact').value('(Contact/@phonnumb)[1]', 'VARCHAR(13)');

        SELECT @CellPhon = CASE LEN(@CellPhon)
                               WHEN 11 THEN
                                   @CellPhon
                               WHEN 12 THEN
                                   '0' + SUBSTRING(@CellPhon, 3, LEN(@CellPhon))
                               WHEN 13 THEN
                                   '0' + SUBSTRING(@CellPhon, 4, LEN(@CellPhon))
                           END;

        SELECT @Rbid = RBID,
               @AmntType = AMNT_TYPE,
               @AmntTypeDesc = a.DOMN_DESC,
               @CnctAcntApp = r.CNCT_ACNT_APP,
               @AcntAppType = r.ACNT_APP_TYPE,
               @PageFechRows = r.PAGE_FECH_ROWS,
               @ViewInvrStat = r.VIEW_INVR_STAT
        FROM dbo.Robot r,
             dbo.[D$AMUT] a
        WHERE TKON_CODE = @Token
              AND r.AMNT_TYPE = a.VALU;

        -- Local Var
        DECLARE @FromDate DATE = GETDATE(),
                @ToDate DATE = GETDATE();

        -- Call Back Query
        IF @CallBackQuery = '002'
        BEGIN
            GOTO L$CallBackQuery;
        END;

        -- 1399/01/03 * تفکیک تاریخ از تا
        IF @UssdCode IN (   '*1*3*0*4#', /* بازه تاریخ گزارش سفارش */
                            '*1*3*1*4#', /* بازه تاریخی گزارش فروش مجموعه */
                            '*1*3*2*4#', /* بازه تاریخی گردش مالی */
                            '*1*3*3*4#'  /* بازه تاریخی دریافت وجه */
                        )
        BEGIN
            BEGIN TRY
                DECLARE C$Items CURSOR FOR
                SELECT Item
                FROM dbo.SplitString(@MenuText, '*');
                SET @Index = 0;
                OPEN [C$Items];
                L$FetchC$Item_DATE:
                FETCH NEXT FROM [C$Items]
                INTO @Item;

                IF @@FETCH_STATUS <> 0
                    GOTO L$EndC$Item_DATE;

                IF @Index = 0
                    SELECT @FromDate = dbo.GET_STOM_U(@Item);
                ELSE IF @Index = 1
                    SELECT @ToDate = dbo.GET_STOM_U(@Item);

                SET @Index += 1;
                GOTO L$FetchC$Item_DATE;
                L$EndC$Item_DATE:
                CLOSE [C$Items];
                DEALLOCATE [C$Items];

                SET @MenuText = NULL;

                -- 1399/01/03 * در این قسمت پرش به واحد مربوطه خودتون
                IF @UssdCode = '*1*3*0*4#'
                    GOTO L$ReportOrder;
                ELSE IF @UssdCode = '*1*3*1*4#'
                    GOTO L$ReportSubsidiarySales;
                ELSE IF @UssdCode = '*1*3*2*4#'
                    GOTO L$ReportWallet;
                ELSE IF @UssdCode = '*1*3*3*4#'
                    GOTO L$ReportWithdrawWallet;

            END TRY
            BEGIN CATCH
                SET @Message = N'تاریخ شروع و پایان به درستی وارد نشده، لطفا بررسی و اصلاح کنید';
            END CATCH;
        END;
        -- زمان های آماده برای سریع
        ELSE IF @UssdCode IN (   '*1*3*0#', /* (1) گزارشات->سفارشات */
                                 '*1*3*1#', /* (2) گزارشات->فروش زیر مجموعه */
                                 '*1*3*2#', /* (3) گزارشات->گردش مالی */
                                 '*1*3*3#'  /* (4) گزارشات -> دریافت وجه */
                             )
                AND @ChildUssdCode IN (   '*1*3*0*0#', '*1*3*0*1#', '*1*3*0*2#', '*1*3*0*3#', /* (1) */
                                          '*1*3*1*0#', '*1*3*1*1#', '*1*3*1*2#', '*1*3*1*3#', /* (2) */
                                          '*1*3*2*0#', '*1*3*2*1#', '*1*3*2*2#', '*1*3*2*3#', /* (3) */
                                          '*1*3*3*0#', '*1*3*3*1#', '*1*3*3*2#', '*1*3*3*3#'  /* (4) */
                                      )
        BEGIN
            SET @MenuText = NULL;
            -- Today **************************************************
            SELECT @FromDate = GETDATE(),
                   @ToDate = GETDATE();

            -- 1399/01/03 * در این قسمت پرش به واحد مربوطه خودتون
            IF @UssdCode = '*1*3*0#'
               AND @ChildUssdCode = '*1*3*0*0#'
                GOTO L$ReportOrder;
            ELSE IF @UssdCode = '*1*3*1#'
                    AND @ChildUssdCode = '*1*3*1*0#'
                GOTO L$ReportSubsidiarySales;
            ELSE IF @UssdCode = '*1*3*2#'
                    AND @ChildUssdCode = '*1*3*2*0#'
                GOTO L$ReportWallet;
            ELSE IF @UssdCode = '*1*3*3#'
                    AND @ChildUssdCode = '*1*3*3*0#'
                GOTO L$ReportWithdrawWallet;

            -- End Today **********************************************

            -- Weekday ************************************************
            SELECT @ToDate = GETDATE(),
                   @FromDate = DATEADD(   DAY,
                                          CASE DATEPART(WEEKDAY, GETDATE())
                                              WHEN 7 THEN
                                                  0
                                              ELSE
                                                  DATEPART(WEEKDAY, GETDATE()) * -1
                                          END,
                                          GETDATE()
                                      );

            -- 1399/01/03 * در این قسمت پرش به واحد مربوطه خودتون
            IF @UssdCode = '*1*3*0#'
               AND @ChildUssdCode = '*1*3*0*1#'
                GOTO L$ReportOrder;
            ELSE IF @UssdCode = '*1*3*1#'
                    AND @ChildUssdCode = '*1*3*1*1#'
                GOTO L$ReportSubsidiarySales;
            ELSE IF @UssdCode = '*1*3*2#'
                    AND @ChildUssdCode = '*1*3*2*1#'
                GOTO L$ReportWallet;
            ELSE IF @UssdCode = '*1*3*3#'
                    AND @ChildUssdCode = '*1*3*3*1#'
                GOTO L$ReportWithdrawWallet;

            -- End Weekday ********************************************

            -- Monthly ************************************************
            SELECT @ToDate = GETDATE(),
                   @FromDate = dbo.GET_STOM_U(LEFT(dbo.GET_MTOS_U(GETDATE()), 7) + '/01');

            -- 1399/01/03 * در این قسمت پرش به واحد مربوطه خودتون
            IF @UssdCode = '*1*3*0#'
               AND @ChildUssdCode = '*1*3*0*2#'
                GOTO L$ReportOrder;
            ELSE IF @UssdCode = '*1*3*1#'
                    AND @ChildUssdCode = '*1*3*1*2#'
                GOTO L$ReportSubsidiarySales;
            ELSE IF @UssdCode = '*1*3*2#'
                    AND @ChildUssdCode = '*1*3*2*2#'
                GOTO L$ReportWallet;
            ELSE IF @UssdCode = '*1*3*3#'
                    AND @ChildUssdCode = '*1*3*3*2#'
                GOTO L$ReportWithdrawWallet;

            -- End Monthly ********************************************

            -- Year ***************************************************
            SELECT @ToDate = GETDATE(),
                   @FromDate = dbo.GET_STOM_U(LEFT(dbo.GET_MTOS_U(GETDATE()), 4) + '/01/01');

            -- 1399/01/03 * در این قسمت پرش به واحد مربوطه خودتون
            IF @UssdCode = '*1*3*0#'
               AND @ChildUssdCode = '*1*3*0*3#'
                GOTO L$ReportOrder;
            ELSE IF @UssdCode = '*1*3*1#'
                    AND @ChildUssdCode = '*1*3*1*3#'
                GOTO L$ReportSubsidiarySales;
            ELSE IF @UssdCode = '*1*3*2#'
                    AND @ChildUssdCode = '*1*3*2*3#'
                GOTO L$ReportWallet;
            ELSE IF @UssdCode = '*1*3*3#'
                    AND @ChildUssdCode = '*1*3*3*3#'
                GOTO L$ReportWithdrawWallet;

            -- End Year ***********************************************         
            SELECT @FromDate = NULL,
                   @ToDate = NULL;
        END;
        ---------------------------------------------------
        -- Menu ::= 🛍 فروشگاه من
        -- Ussd ::= *0#
        -- [
        -- SubMenu ::= 🔎 لیست محصولات
        -- UssdCod ::= *0*0#
        ELSE IF @UssdCode = '*0#'
                AND @ChildUssdCode = '*0*0#'
        BEGIN
            L$ShowProds:
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SET @XTemp =
            (
                SELECT mu.DATA_TEXT_DNRM AS '@data',
                       ROW_NUMBER() OVER (ORDER BY mu.ORDR) AS '@order',
                       mu.MENU_TEXT AS "text()"
                FROM dbo.Menu_Ussd mu
                WHERE mu.ROBO_RBID = @Rbid
                      AND mu.MENU_TYPE = '002' -- InlineQuery
                      AND MU.STAT = '002'
                      AND mu.MNUS_MUID IN
                          (
                              SELECT mut.MUID
                              FROM dbo.Menu_Ussd mut
                              WHERE mut.ROBO_RBID = mu.ROBO_RBID
                                    AND mut.USSD_CODE = @ChildUssdCode
                          )
                ORDER BY mu.ORDR
                FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
            );
            SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            GOTO L$EndSP;
        END;
        -- SubMenu ::= جستجو
        -- UssdCod ::= *0*1#
        ELSE IF @UssdCode = '*0*1#'
        BEGIN
            L$SearchProds:
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            -- Sort Type List      
            -- 1. پربازدیدترین
            -- 2. پرفروش ترین
            -- 3. محبوب ترین      
            -- 4. جدیدترین            
            -- 5. ارزان ترین
            -- 6. گرانترین
            -- 7. سریع ترین ارسال
            -- 8. محصولات موجود
            IF @SortType IS NULL
                SET @SortType = '8';

            SET @FromDate = GETDATE();
            DECLARE @T#SearchProducts TABLE
            (
                DATA VARCHAR(100),
                ORDR INT,
                [TEXT] NVARCHAR(MAX)
            );
            IF @CnctAcntApp = '002'
                IF @AcntAppType = '001'
                BEGIN
                    INSERT INTO @T#SearchProducts
                    (
                        DATA,
                        ORDR,
                        [TEXT]
                    )
                    SELECT N'./' + @UssdCode + N';infoprod-' + CAST(rp.TARF_CODE AS NVARCHAR(100)) + N'$lessinfoprod#' AS DATA,
                           ROW_NUMBER() OVER (ORDER BY rp.TARF_CODE) AS ORDR,
                           CASE 
                                WHEN rp.CRNT_NUMB_DNRM > 0 THEN N'✅ '
                                WHEN rp.CRNT_NUMB_DNRM = 0 THEN N'⛔ '
                           END + SUBSTRING(rp.TARF_TEXT_DNRM, 1, 25) + CASE WHEN LEN(rp.Tarf_Text_Dnrm) > 25 THEN N' ...' ELSE N'' END
                           + dbo.STR_FRMT_U(
                                               N' [ {0} نفر ]',
                                               --dbo.STR_COPY_U(N'⭐️ ', rp.RTNG_NUMB_DNRM) + N','
                                               + REPLACE( CONVERT(NVARCHAR, CONVERT(MONEY, rp.RTNG_CONT_DNRM), 1), '.00', '' )
                                           ) AS [TEXT]
                    FROM dbo.Robot_Product rp
                    WHERE rp.ROBO_RBID = @Rbid
                          AND
                          (
                              rp.TARF_TEXT_DNRM LIKE N'%' + @MenuText + N'%'
                              OR rp.TARF_ENGL_TEXT LIKE N'%' + @MenuText + N'%'
                              OR rp.GROP_TEXT_DNRM LIKE N'%' + @MenuText + N'%'
                              OR rp.BRND_TEXT_DNRM LIKE N'%' + @MenuText + N'%'
                              OR rp.PROD_FETR LIKE N'%' + @MenuText + N'%'
                              OR rp.TARF_CODE LIKE N'%' + @MenuText + N'%'
                          )
                          -- اگر کالا قابل دیدن برای مشتری خاص باشد
                          AND NOT EXISTS (
                              SELECT *
                                FROM dbo.Robot_Product_Limited rpl, dbo.Robot_Limited_Commodity_Group rlcg
                               WHERE rpl.RLCG_CODE = rlcg.CODE
                                 AND rlcg.ROBO_RBID = rp.ROBO_RBID
                                 AND rpl.RBPR_CODE = rp.CODE
                                 AND rpl.STAT = '002'
                                 AND rlcg.STAT = '002'
                                 AND NOT EXISTS (
                                     SELECT *
                                       FROM dbo.Service_Robot_Access_Limited_Group_Product sral
                                      WHERE sral.RLCG_CODE = rlcg.CODE
                                        AND sral.CHAT_ID = @ChatID
                                        AND sral.STAT = '002'                                        
                                 )
                          )
                    ORDER BY CASE @SortType
                                  WHEN '1' THEN rp.VIST_CONT_DNRM
                                  ELSE ( SELECT NULL )
                             END ,
                             CASE @SortType
                                  WHEN '2' THEN rp.SALE_NUMB_DNRM
                                  ELSE ( SELECT NULL )
                             END,
                             CASE @SortType
                                  WHEN '3' THEN rp.LIKE_CONT_DNRM
                                  ELSE ( SELECT NULL )
                             END,
                             CASE @SortType
                                  WHEN '4' THEN rp.CRET_DATE
                                  ELSE ( SELECT NULL )
                             END DESC,
                             CASE @SortType 
                                  WHEN '5' THEN rp.EXPN_PRIC_DNRM
                                  ELSE ( SELECT NULL )
                             END ASC,
                             CASE @SortType
                                  WHEN '6' THEN rp.EXPN_PRIC_DNRM
                                  ELSE (SELECT NULL)
                             END DESC,
                             CASE @SortType
                                  WHEN '7' THEN (rp.DELV_DAY_DNRM + rp.DELV_HOUR_DNRM + rp.DELV_MINT_DNRM)
                                  ELSE ( SELECT NULL )
                             END,
                             CASE @SortType
                                  WHEN '8' THEN rp.CRNT_NUMB_DNRM
                                  ELSE ( SELECT NULL )
                             END DESC;
                END;
            SET @ToDate = GETDATE();

            SET @Message =
            (
                SELECT N'🔍 ' + @MenuText + CHAR(10)
                       + dbo.STR_FRMT_U(
                                           N'حدود {0} نتیجه، ({1} ثانیه)' + N' صفحه {2} ام -  رکورد {3} تا {4}',
                                           REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(T.ORDR)), 1), '.00', '')
                                           + N',' + CAST(DATEDIFF(SECOND, @FromDate, @ToDate) AS NVARCHAR(50)) 
                                           + N',' + CAST(@Page AS NVARCHAR(10)) 
                                           + N',' + CAST(((@Page - 1) * @PageFechRows) + 1 AS NVARCHAR(10))
                                           + N',' + CAST(((((@Page - 1) * @PageFechRows)) + @PageFechRows) AS NVARCHAR(10))
                                       )
                FROM @T#SearchProducts T
                FOR XML PATH('')
            );

            -- اگر جستجو هیچ گونه خروجی در بر نداشته باشد
            IF NOT EXISTS (SELECT * FROM @T#SearchProducts)
            BEGIN
               -- Advance Search
               SET @XTemp = '<InlineKeyboardMarkup order="1"/>';
               -- Static
               SET @X =
               (
                   SELECT dbo.STR_FRMT_U(
                                            './{0};advnfindprod-{1},{2},{3}$del#',
                                            '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                            + CAST(@SortType AS NVARCHAR(2))
                                        ) AS '@data',
                          @Index AS '@order',
                          N'🔍 جستجوی پیشرفته' AS "text()"
                   FOR XML PATH('InlineKeyboardButton')
               );
               SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');               
               SET @Index += 1;
               
               -- Next Step #. More Menu
               -- Static
               SET @X = (
                  SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                         @index AS '@order',
                         N'⛔ بستن' AS "text()"
                     FOR XML PATH('InlineKeyboardButton')
               );
               SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
               SET @Index += 1;
               
               SET @XTemp.modify('insert attribute caption {sql:variable("@Message")} into (//InlineKeyboardMarkup)[1]');               
               SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);           
               
               GOTO L$EndSP;
            END;

            SET @XTemp =
            (
                SELECT T.DATA AS '@data',
                       T.ORDR AS '@order',
                       T.[TEXT] AS "text()"
                FROM @T#SearchProducts T
                WHERE T.ORDR
                BETWEEN ((@Page - 1) * @PageFechRows) + 1 AND ((((@Page - 1) * @PageFechRows)) + @PageFechRows)
                FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
            );
            SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
            SET @XTemp.modify('insert attribute caption {sql:variable("@Message")} into (//InlineKeyboardMarkup)[1]');


            -- [      
            ---- Advance Search
            ---- اضافه کردن صفحه بندی * Next * Perv
            ---- Sort 
            -- ]

            -- اگر تعداد رکورد های درون جدول خروجی بیشتر از صفحه بندی باشد 
            IF @Page * @PageFechRows <=
            (
                SELECT COUNT(*) FROM @T#SearchProducts
            )
            BEGIN
                SET @Index = @PageFechRows + 1;
                -- Next Step #. Next Page
                -- Dynamic
                SET @X =
                (
                    SELECT dbo.STR_FRMT_U(
                                             './{0};findprod-{1},{2},{3}$del#',
                                             '*0*1#,' + @MenuText + N',' + CAST((@Page + 1) AS NVARCHAR(10)) + N','
                                             + CAST(@SortType AS NVARCHAR(2))
                                         ) AS '@data',
                           @Index AS '@order',
                           N'▶️ صفحه بعدی' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );
                SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;
            END;
            -- اضافه کردن دکمه صفحه قبل 
            IF @Page > 1
            BEGIN
                -- Next Step #. Perv Page
                -- Dynamic
                SET @X =
                (
                    SELECT dbo.STR_FRMT_U(
                                             './{0};findprod-{1},{2},{3}$del#',
                                             '*0*1#,' + @MenuText + N',' + CAST((@Page - 1) AS NVARCHAR(10)) + N','
                                             + CAST(@SortType AS NVARCHAR(2))
                                         ) AS '@data',
                           @Index AS '@order',
                           N'◀️ صفحه قبلی' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );
                SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;
            END;
            
            -- اضافه کردن جستجو بر اساس متنی
            -- Static
            SET @X =
            (
                SELECT dbo.STR_FRMT_U(
                                         './{0};findprod-{1},{2},{3}$del#',
                                         '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                         + CAST(@SortType AS NVARCHAR(2))
                                     ) AS '@data',
                       @Index AS '@order',
                       N'🧾 متنی' AS "text()"
                FOR XML PATH('InlineKeyboardButton')
            );
            SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
            SET @Index += 1;
            
            -- اضافه کردن جستجو بر اساس عکس
            -- Static
            SET @X =
            (
                SELECT dbo.STR_FRMT_U(
                                         './{0};findprodbyimag-{1},{2},{3}$del#',
                                         '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                         + CAST(@SortType AS NVARCHAR(2))
                                     ) AS '@data',
                       @Index AS '@order',
                       N'🖼️ عکس' AS "text()"
                FOR XML PATH('InlineKeyboardButton')
            );
            SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
            SET @Index += 1;
            
            -- اضافه کردن جستجو بر اساس تصویری
            -- Static
            SET @X =
            (
                SELECT dbo.STR_FRMT_U(
                                         './{0};findprodbyvideo-{1},{2},{3}$del#',
                                         '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                         + CAST(@SortType AS NVARCHAR(2))
                                     ) AS '@data',
                       @Index AS '@order',
                       N'📺 تصویری' AS "text()"
                FOR XML PATH('InlineKeyboardButton')
            );
            SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
            SET @Index += 1;

            -- اضافه کردن مرتب سازی      
            -- Static
            SET @X =
            (
                SELECT dbo.STR_FRMT_U(
                                         './{0};sortprod-{1},{2},{3}$del#',
                                         '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                         + CAST(@SortType AS NVARCHAR(2))
                                     ) AS '@data',
                       @Index AS '@order',
                       N'📚 مرتب سازی' AS "text()"
                FOR XML PATH('InlineKeyboardButton')
            );
            SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
            SET @Index += 1;

            -- Advance Search
            -- Static
            SET @X =
            (
                SELECT dbo.STR_FRMT_U(
                                         './{0};advnfindprod-{1},{2},{3}$del#',
                                         '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                         + CAST(@SortType AS NVARCHAR(2))
                                     ) AS '@data',
                       @Index AS '@order',
                       N'🔍 جستجوی پیشرفته' AS "text()"
                FOR XML PATH('InlineKeyboardButton')
            );
            SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
            SET @Index += 1;
            
            -- Next Step #. More Menu
            -- Static
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                      @index AS '@order',
                      N'⛔ بستن' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
            SET @Index += 1;

            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
        END;
        -- افزودن کالا به سبد خرید
        ELSE IF @UssdCode = '*0*2#'
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            -- 1399/04/28
            -- اگر مشتری داده ورودی خود را با علام * شروع کند ما بررسی میکنیم که آیا کد وارد شده درون سیستم وجود دارد یا خیر اگر بود اطلاعات مربوط به کالا را نمایش میدیم در غیر اینصورت خطا
            IF @MenuText LIKE N'*%'
            BEGIN
                SELECT @ParamText = SUBSTRING(@MenuText, 2, LEN(@MenuText));
                -- اگر محصول وجود داشته باشد
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.Robot_Product rp
                    WHERE rp.TARF_CODE = @ParamText
                )
                BEGIN
                    select @MenuText = 'infoprod'
                    GOTO L$InfoProd;
                END;
                -- اگر محصول وجود نداشته باشد 
                ELSE
                BEGIN
                    SET @MenuText = @ParamText;
                END;
            END;
            
            -- 1399/07/30
            -- اگر درخواست توسط مسئول پذیرش ارسال شده باشد
            IF EXISTS (SELECT * FROM dbo.[Order] o WHERE o.CODE = @ParamText AND o.ORDR_TYPE = '004')
               SET @OrdrCode = @ParamText;
            ELSE 
               SET @OrdrCode = 0;
               
            -- 1399/08/12 * بروزرسانی اطلاعات از سمت سرور منبع
            SET @XTemp = (
                SELECT @Rbid AS '@rbid',
                       @ChatID AS '@chatid',
                       'infoprod' + ':' + @MenuText AS '@input'                    
                   FOR XML PATH('Action'), ROOT('Link_Server')                       
            );
            EXEC dbo.LKS_EXTR_P @X = @XTemp -- xml

            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       @MenuText AS '@input',
                       @OrdrCode AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml

            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT');
            
            -- Successfull
            IF @RsltCode = '002'
            BEGIN
                SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
                SELECT @Message += CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
                -- اضافه کردن منوهای اولیه مربوط به فاکتور فروش مشتری         
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           CASE @OrdrCode
                               WHEN 0 THEN
                                   'addnewprod'
                               ELSE
                                   'lessinfoinvc'
                           END AS '@cmndtext',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                
                -- بروزرسانی سبد کالا اگر از طریق سفارش انلاین آماده باشد
                UPDATE dbo.[Order]
                   SET STRT_DATE = GETDATE()
                 WHERE CODE = @OrdrCode
                   AND ORDR_CODE IN (
                       SELECT o.CODE
                         FROM dbo.[Order] o
                        WHERE o.ORDR_TYPE = '025'
                          AND o.ORDR_STAT = '016'
                          AND o.CHAT_ID = @ChatID
                   );

                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
            ELSE IF @RsltCode IN ( '003', '004' ) -- اگر کالا موجودی نداشته باشد یا تعداد موجودی کمتر از تعداد درخواستی باشد
            BEGIN
                SELECT @TarfCode = @XTemp.query('//Message').value('(Message/@tarfcode)[1]', 'VARCHAR(100)');
                -- باید ابتدا بررسی کنیم که آیا برای کالای فعلی کالای جایگزین یا سوپر گروه وجود دارد یا خیر
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.Robot_Product_Alternative pa
                    WHERE pa.TARF_CODE_DNRM = @TarfCode
                          AND pa.STAT = '002'
                )
                   OR EXISTS
                (
                    SELECT *
                    FROM dbo.Robot_Product ps,
                         dbo.Robot_Product pt
                    WHERE ps.ROBO_RBID = @Rbid
                          AND ps.ROBO_RBID = pt.ROBO_RBID
                          AND ps.TARF_CODE = @TarfCode
                          AND pt.TARF_CODE != @TarfCode
                          AND ps.GROP_JOIN_DNRM = pt.GROP_JOIN_DNRM
                          AND pt.STAT = '002'
                )
                BEGIN
                    SET @Message
                        = CASE @RsltCode
                              WHEN '003' THEN
                                  N'⚠️ متاسفانه *کالای درخواستی شما* _موجود_ 🚫 نمی باشد.'
                              WHEN '004' THEN
                                  N'⚠️ متاسفانه *تعداد کالای درخواستی شما* _موجود_ 🚫 نمی باشد، لطفا 🔢 *تعداد کالای* خود را ✏️ _اصلاح_ کنید'
                          END + CHAR(10) + CHAR(10)
                          + N'🔵 البته شما می توانید از 🔄  کالاهای *جایگزین* یا کالاهای ↔️ *مشابه* زیر هم استفاده کنید.';
                    -- اضافه کردن منوهای اولیه مربوط به فاکتور فروش مشتری         
                    SET @XTemp =
                    (
                        SELECT @Rbid AS '@rbid',
                               @ChatID AS '@chatid',
                               @UssdCode AS '@ussdcode',
                               'lesslockinvrwas' AS '@cmndtext',
                               @OrdrCode AS '@ordrcode',
                               @TarfCode AS '@tarfcode'
                        FOR XML PATH('RequestInLineQuery')
                    );
                    EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                         @XRet = @XTemp OUTPUT; -- xml

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                    );

                    SET @XMessage =
                    (
                        SELECT TOP 1
                               om.FILE_ID AS '@fileid',
                               om.IMAG_TYPE AS '@filetype',
                               @Message AS '@caption',
                               1 AS '@order'
                        FROM dbo.Organ_Media om
                        WHERE om.ROBO_RBID = @Rbid
                              AND om.RBCN_TYPE = '017'
                              AND om.IMAG_TYPE = '002'
                              AND om.STAT = '002'
                        FOR XML PATH('Complex_InLineKeyboardMarkup')
                    );
                    SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

                    SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
                END;
                ELSE
                BEGIN
                    SET @Message
                        = CASE @RsltCode
                              WHEN '003' THEN
                                  N'⚠️ متاسفانه *کالای درخواستی شما* _موجود_ 🚫 نمی باشد.'
                              WHEN '004' THEN
                                  N'⚠️ متاسفانه *تعداد کالای درخواستی شما* _موجود_ 🚫 نمی باشد، لطفا 🔢 *تعداد کالای* خود را ✏️ _اصلاح_ کنید'
                          END + CHAR(10) + CHAR(10)
                          + N'🔵 البته به محض اینکه موجودی کالا اضافه شد، به شما مشتری عزیز اطلاع رسانی میکنیم.';

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order'
                        --@XTemp
                        FOR XML PATH('InlineKeyboardMarkup')
                    );

                    SET @XMessage =
                    (
                        SELECT TOP 1
                               om.FILE_ID AS '@fileid',
                               om.IMAG_TYPE AS '@filetype',
                               @Message AS '@caption',
                               1 AS '@order'
                        FROM dbo.Organ_Media om
                        WHERE om.ROBO_RBID = @Rbid
                              AND om.RBCN_TYPE = '017'
                              AND om.IMAG_TYPE = '002'
                              AND om.STAT = '002'
                        FOR XML PATH('Complex_InLineKeyboardMarkup')
                    );
                    SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

                    SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
                END;
            END;
            ELSE IF @RsltCode = '001'
            BEGIN
                SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
                SELECT @Message += CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
                -- اضافه کردن منوهای اولیه مربوط به فاکتور فروش مشتری         
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'productnotfound' AS '@cmndtext',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @XMessage =
                (
                    SELECT TOP 1
                           om.FILE_ID AS '@fileid',
                           om.IMAG_TYPE AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                          AND om.RBCN_TYPE = '009'
                          AND om.IMAG_TYPE = '002'
                          AND om.STAT = '002'
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                );
                SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
        END;
        -- UpMenu  ::= نحوه پرداخت
        -- SubMenu ::= کیف پول
        -- UssdCod ::= *0*3#
        ELSE IF @UssdCode = '*0*3#'
                AND @ChildUssdCode = '*0*3*3#'
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SELECT @UssdCode = '*0*3*3#',
                   @MenuText = N'paycart',
                   @ParamText = N'',
                   @PostExec = N'lesswletcart';
            GOTO L$CartOperations;
        END;
        ELSE IF @UssdCode = '*0*3*3#'
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SELECT @ParamText = @MenuText,
                   @MenuText = N'addamntwlet',
                   @PostExec = N'lessaddwlet';
            GOTO L$AddAmountWallet;
        END;
        -- SubMenu ::= نمایش سبد خرید
        -- UssdCod ::= *0*4#
        ELSE IF @UssdCode = '*0#'
                AND @ChildUssdCode = '*0*4#'
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       'show' AS '@input',
                       0 AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml

            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT');

            -- Successfull
            IF @RsltCode = '002'
            BEGIN
                SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
                SELECT @Message += CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
                -- اضافه کردن منوهای اولیه مربوط به فاکتور فروش مشتری         
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           CASE @OrdrCode
                               WHEN 0 THEN
                                   'addnewprod'
                               ELSE
                                   'lessinfoinvc'
                           END AS '@cmndtext',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
        END;

        -- UpMenu  ::= آدرس ارسال
        -- SubMenu ::= ثبت آدرس جدید
        -- UssdCod ::= *0*5*0#
        ELSE IF @UssdCode = '*0*5*0#'
        BEGIN
            -- در این مرحله ما دو گزینه برای دریافت اطلاعات از مشتری درخواست میکنیم
            -- 1. آدرس متنی
            -- در این قسمت ما اطلاعات آدرس متنی را به صورت کامل دریافت میکنیم ولی در آینده برای ویرایش اطلاعات آدرس جزئیات بیشتری از مشتری دریافت میکنیم
            -- 2. آدرس نقشه ای
            SET @UssdCode = '*1*2*0#';
            GOTO L$AddNewAddress;
        END;
        -- UpMenu  ::= آدرس ارسال
        -- SubMenu ::= نمایش آدرس ها
        -- UssdCod ::= *0*5*1#
        ELSE IF @UssdCode = '*0*5#'
                AND @ChildUssdCode = '*0*5*1#'
        BEGIN
            --SELECT @UssdCode = '*1*2#', @ChildUssdCode = '*1*2*1#';
            GOTO L$ShowAllAddress;
        END;
        -- UpMenu  ::= آدرس ارسال
        -- SubMenu ::= انتخاب آدرس ها
        -- UssdCod ::= *0*5*2#
        ELSE IF @UssdCode = '*0*5#'
                AND @ChildUssdCode = '*0*5*2#'
        BEGIN
            SELECT --@UssdCode = '*1*2#', @ChildUssdCode = '*1*2*2#',
                @MenuText = N'slctloc4ordr',
                @PostExec = N'',
                @Trigger = N'';
            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       'show_shipping' AS '@input',
                       0 AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      
            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT'),
                   @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

            IF @RsltCode = '002'
               AND ISNULL(@OrdrCode, 0) > 0
            BEGIN
                SET @ParamText = @OrdrCode;
                GOTO L$SelectAddress;
            END;
        END;
        -- UpMenu  ::= ویترین
        -- SubMenu ::= کارت هدیه
        -- UssdCod ::= *0*6*5#
        ELSE IF @UssdCode = '*0*6#'
                AND @ChildUssdCode = '*0*6*5#'
        BEGIN
            L$ShowGiftCardMenu:
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SET @XTemp =
            (
                SELECT mu.DATA_TEXT_DNRM AS '@data',
                       ROW_NUMBER() OVER (ORDER BY mu.ORDR) AS '@order',
                       mu.MENU_TEXT AS "text()"
                FROM dbo.Menu_Ussd mu
                WHERE mu.ROBO_RBID = @Rbid
                      AND mu.MENU_TYPE = '002' -- InlineQuery
                      AND mu.MNUS_MUID IN
                          (
                              SELECT mut.MUID
                              FROM dbo.Menu_Ussd mut
                              WHERE mut.ROBO_RBID = mu.ROBO_RBID
                                    AND mut.USSD_CODE = @ChildUssdCode
                          )
                ORDER BY mu.ORDR
                FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
            );
            SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            GOTO L$EndSP;
        END;
        -- پیش نمایش کارت هدیه هایی که مشتری برای خود ارسال یا از لیست انتخاب کرده است
        ELSE IF @UssdCode = '*0*6*5#'
                AND @ChildUssdCode = '*0*6*5*3#'
        BEGIN
            L$ShowOrdrGift:
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       'show' AS '@input',
                       0 AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      
            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT');

            IF @RsltCode = '002'
            BEGIN
                -- اگر سبد خریدی ذخیره شده باشد         
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.Order_Detail od
                    WHERE od.ORDR_CODE = @OrdrCode
                          AND od.ELMN_TYPE IN ( '002' /* photo */, '003' /* video */ )
                          AND od.IMAG_PATH IS NOT NULL
                )
                BEGIN
                    SET @XTemp =
                    (
                        SELECT dbo.STR_FRMT_U(
                                                 './{0};infoprod-{1},{2}$lessinfogift#',
                                                 '*0#' + ',' + CAST(od.ORDR_CODE AS VARCHAR(30)) + ','
                                                 + CAST(od.RWNO AS VARCHAR(10))
                                             ) AS '@data',
                               ROW_NUMBER() OVER (ORDER BY od.RWNO) AS '@order',
                               SUBSTRING(od.ORDR_DESC, 1, 20) + N' ... 💳 '
                               + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, od.EXPN_PRIC), 1), '.00', '') AS "text()"
                        FROM dbo.Order_Detail od
                        WHERE od.ORDR_CODE = @OrdrCode
                              AND od.ELMN_TYPE IN ( '002', '003' )
                              AND od.IMAG_PATH IS NOT NULL
                        ORDER BY od.RWNO
                        FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                    );
                    SET @Message = N'کارت های هدیه ای که شما انتخاب کرده اید';
                    SET @XTemp.modify('insert attribute caption {sql:variable("@message")} into (//InlineKeyboardMarkup)[1]');
                    SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
                    SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                    GOTO L$EndSP;
                END;
                ELSE
                BEGIN
                    SET @Message
                        = N'دوست عزیز شما برای این قسمت عکس کارت هدیه را انتخاب نکرده اید' + CHAR(10)
                          + N'شما می توانید عکس کارت هدیه خود را از لیست فعلی استفاده کنید' + CHAR(10)
                          + N'یا اینکه می توانید عکس مورد علاقه خود را ارسال تا با آن کارت هدیه خود را طراحی کنید';
                END;
            END;
        END;
        -- ثبت و ذخیره سازی عکس کارت هدیه
        ELSE IF @UssdCode = '*0*6*5*3#'
        BEGIN
            L$SaveGiftCard:
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;


            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       'show' AS '@input',
                       0 AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      
            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT');

            IF @RsltCode = '002'
               AND @ElmnType IN ( '001', '002', '003' )
               AND @MenuText LIKE N'%#%'
            BEGIN
                SELECT @Message = CASE id
                                      WHEN 1 THEN
                                          Item
                                      ELSE
                                          @Message
                                  END,
                       @Amnt = CASE id
                                   WHEN 2 THEN
                                       Item
                                   ELSE
                                       @Amnt
                               END
                FROM dbo.SplitString(@MenuText, '#');

                SELECT @ParamText = rp.TARF_CODE
                FROM dbo.Robot_Product rp
                WHERE rp.ROBO_RBID = @Rbid
                      AND rp.GROP_CODE_DNRM = 13992171200883; -- پیدا کردن کد تعرفه برای کارت هدیه

                SELECT @XTemp =
                (
                    SELECT 5 AS '@subsys',
                           '004' AS '@ordrtype',
                           '000' AS '@typecode',
                           @ChatID AS '@chatid',
                           @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @ParamText AS '@input',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('Action'), ROOT('Cart')
                );
                EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml 
                SELECT @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT');

                IF @ElmnType IN ( '002', '003' )
                   AND @Message IS NOT NULL
                   AND @Amnt IS NOT NULL
                    UPDATE dbo.Order_Detail
                    SET ORDR_DESC = @Message,
                        EXPN_PRIC = @Amnt,
                        IMAG_PATH = @PhotoFileId,
                        FILE_NAME = @FileName,
                        FILE_EXT = @FileExt,
                        MIME_TYPE = @MimeType,
                        ELMN_TYPE = @ElmnType
                    WHERE ORDR_CODE = @OrdrCode
                          AND TARF_CODE = @ParamText;
                ELSE IF @ElmnType IN ( '002', '003' )
                        AND @Message IS NULL
                        AND @Amnt IS NULL
                    UPDATE dbo.Order_Detail
                    SET IMAG_PATH = @PhotoFileId,
                        FILE_NAME = @FileName,
                        FILE_EXT = @FileExt,
                        MIME_TYPE = @MimeType,
                        ELMN_TYPE = @ElmnType
                    WHERE ORDR_CODE = @OrdrCode
                          AND TARF_CODE = @ParamText;
                ELSE IF @ElmnType = '001'
                        AND @Message IS NOT NULL
                        AND @Amnt IS NOT NULL
                    UPDATE dbo.Order_Detail
                    SET ORDR_DESC = @Message,
                        EXPN_PRIC = @Amnt
                    WHERE ORDR_CODE = @OrdrCode
                          AND TARF_CODE = @ParamText;

                UPDATE o
                SET o.EXPN_AMNT =
                    (
                        SELECT SUM(od.EXPN_PRIC * od.NUMB)
                        FROM dbo.Order_Detail od
                        WHERE od.ORDR_CODE = o.CODE
                    ),
                    o.EXTR_PRCT =
                    (
                        SELECT SUM(od.EXTR_PRCT * od.NUMB)
                        FROM dbo.Order_Detail od
                        WHERE od.ORDR_CODE = o.CODE
                    ),
                    o.DSCN_AMNT_DNRM =
                    (
                        SELECT SUM(((od.EXPN_PRIC + od.EXTR_PRCT) * od.NUMB) * ISNULL(od.OFF_PRCT, 0) / 100)
                        FROM dbo.Order_Detail od
                        WHERE od.ORDR_CODE = o.CODE
                    )
                FROM dbo.[Order] o
                WHERE o.CODE = @OrdrCode;
                GOTO L$ShowOrdrGift;
            END;
            ELSE
            BEGIN
                SET @Message
                    = N'👈 لطفا اطلاعات ارسال را طبق دستور العمل انجام دهید' + CHAR(10)
                      + N'عکس یا فیلم مورد نظر خود را انتخاب کنید و برای متن عکس به شیوه زیر عمل کنید' + CHAR(10)
                      + N'✏️ *متن کارت هدیه* # *مبلغ کارت هدیه*';
            END;
            GOTO L$EndSP;
        END;
        -- نمایش رسید های ثبت شده برای درخواست جاری
        ELSE IF @UssdCode = '*0*3#'
                AND @ChildUssdCode = '*0*3*4#'
        BEGIN
            L$ShowRcptPay:
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       'show' AS '@input',
                       0 AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      
            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT');

            IF @RsltCode = '002' AND ISNULL(@OrdrCode, 0) > 0
            BEGIN
                SELECT @MenuText = N'paycart',
                       @ParamText = @OrdrCode,
                       @PostExec = N'lessrcptcart';
                -- انتقال به توابع مربوط به سبد خرید
                GOTO L$CartOperations;
            END;
            ELSE
            BEGIN
                SET @Message
                    = N'👈 لطفا اطلاعات ارسال را طبق دستور العمل انجام دهید' + CHAR(10)
                      + N'*راه حل اول*' + CHAR(10) + N'*عکس رسید پرداخت* مورد نظر خود را انتخاب کنید و برای ارسال متن به شیوه زیر عمل کنید'
                      + CHAR(10) + N'✏️ *توضیحات قبض رسید* # *مبلغ رسید*' + CHAR(10) + CHAR(10) + 
                      + N'*راه حل دوم*' + CHAR(10) + N'*فایل رسید پرداخت* مورد نظر خود را انتخاب و ارسال کنید' + CHAR(10) + CHAR(10) + 
                      + N'*راه حل سوم*' + CHAR(10) + N'*شماره کد پیگیری* مورد نظر خود را وارد کنید';
            END;
        END;
        -- ارسال عکس های رسید پرداخت توسط مشتری
        ELSE IF @UssdCode = '*0*3*4#'
        BEGIN
            L$SaveReciptPay:
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       'show' AS '@input',
                       0 AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      
            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT');

            IF @RsltCode = '002' AND @ElmnType IN ('001' /* شماره پیگیری */ , '002' /* عکس */, '004' /* فایل pdf, ... */ ) AND ISNULL(@OrdrCode, 0) > 0
            BEGIN
                IF @MenuText LIKE '%#%'
                    SELECT @Message = CASE id WHEN 1 THEN Item ELSE @Message END,
                           @Amnt = CASE id WHEN 2 THEN Item ELSE @Amnt END
                    FROM dbo.SplitString(@MenuText, '#');
                ELSE IF @MenuText = 'No Text'
                    SET @Message = dbo.STR_FRMT_U(N'رسید پرداخت شماره فاکتور {0}', @OrdrCode);
                ELSE
                    SET @Message = N'کد رهگیری : *' + @MenuText + N'*';
                
                -- 1399/09/08 * اگر مبلغ خالی باشد
                IF ISNULL(@Amnt , 0) = 0
                  SELECT @Amnt = o.DEBT_DNRM
                    FROM dbo.[Order] o
                   WHERE o.CODE = @OrdrCode;
                
                IF @ElmnType IN ('001') 
                  -- شماره پیگیری نباید درون سیستم تکراری ثبت شود
                  IF NOT EXISTS (SELECT * FROM dbo.Order_State os WHERE os.TXID = @MenuText AND os.CONF_STAT IN ('003', '002'))
                     INSERT INTO dbo.Order_State (ORDR_CODE,CODE,STAT_DATE,STAT_DESC,AMNT,AMNT_TYPE,RCPT_MTOD,TXID,FILE_TYPE,CONF_STAT)
                     VALUES (@OrdrCode, 0, GETDATE(), @Message, @Amnt, '005', '002', @MenuText, @ElmnType, '003');
                  ELSE
                     SET @Message
                        = N'👈 لطفا اطلاعات شماره پیگیری سفارش خود را درست وارد کنید، *این شماره پیگیری تکراری میباشد*';
                ELSE IF @ElmnType IN ('002')                
                  INSERT INTO dbo.Order_State (ORDR_CODE,CODE,STAT_DATE,STAT_DESC,AMNT,AMNT_TYPE,RCPT_MTOD,FILE_ID,FILE_TYPE,CONF_STAT)
                  VALUES (@OrdrCode, 0, GETDATE(), @Message, @Amnt, '005', '002', @PhotoFileId, @ElmnType, '003');
                ELSE IF @ElmnType IN ('004')
                  INSERT INTO dbo.Order_State (ORDR_CODE,CODE,STAT_DATE,STAT_DESC,AMNT,AMNT_TYPE,RCPT_MTOD,FILE_ID,FILE_TYPE,CONF_STAT)
                  VALUES (@OrdrCode, 0, GETDATE(), @Message, @Amnt, '005', '002', @DocumentFileId, @ElmnType, '003');
                
                -- نمایش مجدد اطلاعات رسید های ارسال شده
                GOTO L$ShowRcptPay;
            END;
            ELSE
            BEGIN
                SET @Message
                    = N'👈 لطفا اطلاعات ارسال را طبق دستور العمل انجام دهید' + CHAR(10)
                      + N'*راه حل اول*' + CHAR(10) + N'*عکس رسید پرداخت* مورد نظر خود را انتخاب کنید و برای ارسال متن به شیوه زیر عمل کنید'
                      + CHAR(10) + N'✏️ *توضیحات قبض رسید* # *مبلغ رسید*' + CHAR(10) + CHAR(10) + 
                      + N'*راه حل دوم*' + CHAR(10) + N'*فایل رسید پرداخت* مورد نظر خود را انتخاب و ارسال کنید' + CHAR(10) + CHAR(10) + 
                      + N'*راه حل سوم*' + CHAR(10) + N'*شماره کد پیگیری* مورد نظر خود را وارد کنید';
            END;
        END;
        -- SubMenu ::= سرویس خدمات من
        -- UssdCod ::= *0*7#
        ELSE IF @UssdCode = '*0#'
                AND @ChildUssdCode = '*0*7#'
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SET @Message
                = N'😊✋ با سلام و احترام به شما دوست عزیز' + CHAR(10)
                  + N'💠 سرویس خدمات شما بر اساس مواردی هست که شما از این سرویس ها در برنامه فروشگاه استفاده کرده باشید'
                  + CHAR(10)
                  + N'👈 مثلا : خریدهایی که شما انجام داده اید، یا اینکه چه محصولاتی را درون لیست علاقه مندی های خود قرار داده ایدو غیره...'
                  + CHAR(10)
                  + N'این موارد به شما کمک میکند که بتوانید سوابق خرید ها و حتی مقایسه هایی را درون فروشگاه انجام دهید و تا بتوانید بهترین انتخاب را داشته باشید'
                  + CHAR(10) + N'با آرزوی هر چه بهتر شدن کیفیت خدمات ما به شما مردم عزیز ایران ✋';

            SET @XTemp =
            (
                SELECT @Rbid AS '@rbid',
                       @ChatID AS '@chatid',
                       @UssdCode AS '@ussdcode',
                       'lessisrvshop' AS '@cmndtext',
                       0 AS '@ordrcode'
                FOR XML PATH('RequestInLineQuery')
            );
            EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            SET @XTemp =
            (
                SELECT '1' AS '@order',
                       @Message AS '@caption',
                       @XTemp
                FOR XML PATH('InlineKeyboardMarkup')
            );
            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
        END;
        -- Menu ::= 📡 سرویس ثبت سفارش
        -- Ussd ::= *0*8#
        ELSE IF @UssdCode = '*0#' AND @ChildUssdCode = '*0*8#'
        BEGIN
           L$ReceptionOrder:
           -- بررسی اینکه مشتری خود را ثبت کرده یا خیر
           IF NOT EXISTS
           (
               SELECT *
               FROM iScsc.dbo.Fighter
               WHERE CHAT_ID_DNRM = @ChatID
           )
           BEGIN
               SET @Message
                   = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
               SET @XTemp =
               (
                   SELECT @Rbid AS '@rbid',
                          @ChatID AS '@chatid',
                          @UssdCode AS '@ussdcode',
                          'lessreguser' AS '@cmndtext'
                   FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml
                SET @XTemp =
               (
                   SELECT '1' AS '@order',
                          @Message AS '@caption',
                          @XTemp
                   FOR XML PATH('InlineKeyboardMarkup')
               );
               SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
               GOTO L$EndSP;
           END;
           
           SET @Message = N'متقاضی محترم با سلام' + CHAR(10) + 
                          N'شما می توانید با استفاده از قسمت *سرویس ثبت سفارش* قادر هستید که سفارشات خود را به صورت *متن ساده* یا *عکس دست نوشته* ، یا *پیام صوتی* ارسال کنید.' + CHAR(10) + 
                          N'در این قسمت همکاران ما به شما کمک میکنند تا سفارش خود را تکمیل کنید';
           
           SET @XTemp =
           (
               SELECT @Rbid AS '@rbid',
                      @ChatID AS '@chatid',
                      @UssdCode AS '@ussdcode',
                      'lesshistrecpordr' AS '@cmndtext'
               FOR XML PATH('RequestInLineQuery')
           );
           EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                @XRet = @XTemp OUTPUT; -- xml           
           
           SET @XTemp =
           (
               SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
           );
           
           SET @XMessage =
           (
               SELECT TOP 1
                      om.FILE_ID AS '@fileid',
                      om.IMAG_TYPE AS '@filetype',
                      @Message AS '@caption',
                      1 AS '@order',
                      @XTemp
               FROM dbo.Organ_Media om
               WHERE om.ROBO_RBID = @Rbid
                     AND om.RBCN_TYPE = '024'
                     AND om.IMAG_TYPE = '002'
                     AND om.STAT = '002'
               FOR XML PATH('Complex_InLineKeyboardMarkup')
           );
           SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
           GOTO L$EndSP;
        END 
        ELSE IF @UssdCode = '*0*8#'
        BEGIN
           -- بررسی اینکه مشتری خود را ثبت کرده یا خیر
           IF NOT EXISTS
           (
               SELECT *
               FROM iScsc.dbo.Fighter
               WHERE CHAT_ID_DNRM = @ChatID
           )
           BEGIN
               SET @Message
                   = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
               SET @XTemp =
               (
                   SELECT @Rbid AS '@rbid',
                          @ChatID AS '@chatid',
                          @UssdCode AS '@ussdcode',
                          'lessreguser' AS '@cmndtext'
                   FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml
                SET @XTemp =
               (
                   SELECT '1' AS '@order',
                          @Message AS '@caption',
                          @XTemp
                   FOR XML PATH('InlineKeyboardMarkup')
               );
               SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
               GOTO L$EndSP;
           END;
            
           -- ثبت درخواست کمپین تبلیغاتی
           SET @XTemp = (
               SELECT 12 AS '@subsys',
                      '025' AS '@ordrtype',
                      '000' AS '@typecode', 
                      @ChatId AS '@chatid',
                      @Rbid AS '@rbid',
                      0 AS '@ordrcode'
                  FOR XML PATH('Action')
           );
           EXEC dbo.SAVE_EXTO_P @X = @XTemp, -- xml
                                @xRet = @XTemp OUTPUT; -- xml
            
           SELECT @RsltCode = @XTemp.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)');
           IF @RsltCode = '002'
           BEGIN
               SELECT @OrdrCode = @XTemp.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');
               
               -- 1399/07/25 * اگر داده ارسالی از سمت مشتری عکس باشد باید مشخص کرده باشد که چه مقدار از این کالا را نیاز دارد
               IF @ElmnType IN ( '002' )
               BEGIN
                  IF ISNULL(@MenuText, 'No Text') = 'No Text'
                  BEGIN
                     SET @Message = 
                         N'⚠️ *خطا*' + CHAR(10) + CHAR(10) + 
                         N'لطفا در زمان ارسال عکس برای متن عکس مقدار درخواستی خود را وارد کنید' + CHAR(10) + 
                         N'👈 _مثال_ *2 عدد یا 2 کیلو یا 2 بسته*';
                     GOTO L$EndSP;
                  END 
               END 
               
               INSERT INTO dbo.Order_Detail ( ORDR_CODE ,ELMN_TYPE , ORDR_CMNT /* عنوان */, ORDR_DESC /* شرح */, IMAG_PATH )
               SELECT @OrdrCode, 
                      @ElmnType,
                      e.DOMN_DESC, 
                      CASE @ElmnType
                           WHEN '001' THEN @MenuText
                           WHEN '002' THEN @MenuText
                           ELSE NULL
                      END,
                      CASE @ElmnType
                           WHEN '001' THEN NULL
                           WHEN '002' THEN @PhotoFileId
                           WHEN '003' THEN @VideoFileId
                           WHEN '004' THEN @DocumentFileId
                           WHEN '005' THEN @AudioFileId
                      END
                 FROM dbo.[D$ELMT] e
                WHERE e.VALU = @ElmnType;
               
               -- ایجاد خروجی برای نمایش درخواست ثبت شده برای محصول ارسالی
               -- منوهای اولیه ای که برای مدیریت باید ارسال شود را آماده میکنیم
               SET @XTemp =
               (
                  SELECT @Rbid AS '@rbid',
                         @ChatID AS '@chatid',
                         @UssdCode AS '@ussdcode',
                         'lessnewrecpordr' AS '@cmndtext',
                         @OrdrCode AS '@ordrcode'
                  FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml

               SET @XTemp =
               (
                  SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
               );
               
               SET @Message = (
                   SELECT N'🟤 شماره درخواست [ *' + CAST(o.CODE AS VARCHAR(30)) + N'* ] ' + o.ORDR_TYPE + ' - ' + CAST(o.ORDR_TYPE_NUMB AS VARCHAR(30)) + CHAR(10) + CHAR(10) +
                          N'*اقلام  پذیرش انلاین*' + CHAR(10) + CHAR(10) +
                          (
                             SELECT N'👈 [ *' + e.DOMN_DESC + N'* ] ( _' + CAST(od.RWNO AS VARCHAR(30)) + N'_ ) ' + ISNULL(od.ORDR_DESC, N' ') + CHAR(10)
                               FROM dbo.Order_Detail od, dbo.[D$ELMT] e
                              WHERE od.ORDR_CODE = o.CODE
                                AND od.ELMN_TYPE = e.VALU
                                FOR XML PATH('')
                          )
                     FROM dbo.[Order] o
                    WHERE o.CODE = @OrdrCode
               );
               
               SET @XMessage =
               (
                  SELECT TOP 1
                         om.FILE_ID AS '@fileid',
                         om.IMAG_TYPE AS '@filetype',
                         @Message AS '@caption',
                         1 AS '@order'
                  FROM dbo.Organ_Media om
                  WHERE om.ROBO_RBID = @Rbid
                        AND om.RBCN_TYPE = '007'
                        AND om.IMAG_TYPE = '002'
                        AND om.STAT = '002'
                  FOR XML PATH('Complex_InLineKeyboardMarkup')
               );
               SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               GOTO L$EndSP;
           END 
            
        END 
        -- ]
        -- Menu ::= 🛍 فروشگاه من
        -- Ussd ::= 01#
        -- ///////////////////////////////////////////////////////////////////////    
        ---------------------------------------------------
        -- Menu ::= 👤 ورود به حساب کاربری
        -- Ussd ::= *1#
        -- [
        -- SubMenu ::= 📝 ورود اطلاعات
        -- UssdCod ::= *1*0*0#
        ELSE IF @UssdCode = '*1*0*0#'
        BEGIN
            L$RegUser:
            IF EXISTS (SELECT * FROM iScsc.dbo.Fighter WHERE CHAT_ID_DNRM = @ChatID)
            BEGIN
                SET @Message =
                  N'⚠️ شما درون سیستم ثبت شده اید. لطفا مراحل تکمیلی ثبت نام خود را بر اساس بقیه موارد انجام دهید انجام دهید.' + 
                  N'متقاضی محترم' + CHAR(10) +
                  N'لطفا جهت ثبت نام اولیه در سیستم، اطلاعات خود را مطابق نمونه داده شده ارسال کنید.' + CHAR(10) + 
                  N'با تشکر' + 
                  N'👈 نحوه ارسال اطلاعات (از راست به چپ) :' + CHAR(10) + 
                  N'✏️ * نام * # * فامیل * # * شماره موبایل * # * کدملی * # * کد معرف *' + CHAR(10) + 
                  N'👌 نمونه صحیح وارد شده : ' + CHAR(10) + 
                  N'* حیدر * # * خوش مرام * # * 09171234567 * # * 2372677654 * # * 1847807509 *' + CHAR(10) + CHAR(10) + 
                  N'👈 نکته : *کد معرف اجباری نمی باشد*';
                -- Repaire String
                SET @Message = REPLACE(@Message, '&#x0D;', '');
                GOTO L$EndSP;
            END;

            DECLARE @FrstName NVARCHAR(250),
                    @LastNamr NVARCHAR(250),
                    @NatlCode VARCHAR(10);

            -- اگر تعداد ورودی های ارسال شده طبق استاندارد ارسال نشده باشد
            IF(SELECT COUNT(id) FROM dbo.SplitString(@MenuText, '#')) NOT IN ( 4, 5 ) AND @MenuText != 'No Text'
            BEGIN
                SET @Message = N'⚠️ اطلاعات وارد شده صحیح نمیباشد، لطفا در ورود اطلاعات دقت نمایید';
                GOTO L$EndSP;
            END;
            ELSE IF @MenuText = 'No Text'
            BEGIN
                SET @Message =
                (
                    SELECT REPLACE(od.ITEM_VALU, '&amp;#x0D;', '') + CHAR(10)
                    FROM dbo.Organ_Description od
                    WHERE ROBO_RBID = @Rbid
                          AND USSD_CODE = @UssdCode
                    FOR XML PATH('')
                );
                -- Repaire String
                SET @Message = REPLACE(@Message, '&#x0D;', '');
                IF @GropTextDnrm = 'reguserothrcnty'
                  SET @Message = REPLACE(@Message, N'کدملی', N'کد فراگیر');
                
                GOTO L$EndSP;
            END;

            DECLARE C$Items CURSOR FOR
            SELECT Item
              FROM dbo.SplitString(@MenuText, '#')
             WHERE id <= 5;
             
            SET @Index = 0;
            OPEN [C$Items];
            L$FetchC$Item1:
            FETCH NEXT FROM [C$Items] INTO @Item;

            IF @@FETCH_STATUS <> 0
                GOTO L$EndC$Item1;

            IF @Index = 0
                SET @FrstName = RTRIM(LTRIM(@Item));
            ELSE IF @Index = 1
                SET @LastNamr = RTRIM(LTRIM(@Item));
            ELSE IF @Index = 2
                SET @CellPhon = RTRIM(LTRIM(@Item));
            ELSE IF @Index = 3
                SET @NatlCode = RTRIM(LTRIM(@Item));
            ELSE IF @Index = 4
                SET @RefChatId = RTRIM(LTRIM(@Item))

            SET @Index += 1;
            GOTO L$FetchC$Item1;
            L$EndC$Item1:
            CLOSE [C$Items];
            DEALLOCATE [C$Items];
            
            SET @XTemp =
            (
                SELECT @FrstName AS '@frstname',
                       @LastNamr AS '@lastname',
                       @CellPhon AS '@cellphon',
                       @NatlCode AS '@natlcode',
                       '05' AS '@subsys',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       '001' AS '@actntype',
                       'Save data' AS '@actndesc',
                       @GropTextDnrm AS '@cmndtext'
                FOR XML PATH('Service')
            );

            EXEC dbo.SAVE_SRBT_P @X = @XTemp, @XRet = @XTemp OUTPUT;

            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)');
            SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
            SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                               + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));

            -- عملیات موفقیت آمیز بوده
            IF @RsltCode = '002'
            BEGIN
                -- ثبت اطلاعات مشتری درون سیستم نرم افزار مدیریتی آرتا
                SELECT @XTemp =
                (
                    SELECT '05' AS '@subsys',
                           '100' AS '@cmndcode',        -- عملیات جامع ذخیره سازی
                           12 AS '@refsubsys',          -- محل ارجاعی
                           'appuser' AS '@execaslogin', -- توسط کدام کاربری اجرا شود               
                           '' AS '@refcode',
                           '' AS '@refnumb',            -- تعداد شماره درخواست ثبت شده
                           '' AS '@strtdate',
                           '' AS '@enddate',
                           @ChatID AS '@chatid',
                           sr.REAL_FRST_NAME AS '@frstname',
                           sr.REAL_LAST_NAME AS '@lastname',
                           sr.NATL_CODE AS '@natlcode',
                           sr.OTHR_CELL_PHON AS '@cellphon',
                            (
                                SELECT '' AS '@tarfcode',
                                       '' AS '@tarfdate',
                                       '' AS '@expnpric',
                                       '' AS '@extrprct',
                                       '025' AS '@rqtpcode',
                                       '' AS '@numb'
                                FOR XML PATH('Expense'), TYPE
                            )
                    FROM dbo.Service_Robot sr
                    WHERE sr.ROBO_RBID = @Rbid
                          AND sr.CHAT_ID = @ChatID
                    FOR XML PATH('Router_Command')
                );
                EXEC dbo.RouterdbCommand @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      
                IF @XTemp.query('//Router_Command').value('(Router_Command/@rsltcode)[1]', 'VARCHAR(3)') != '002'
                BEGIN
                    -- اگر درخواست ثبت مشتری با مشکل مواجه شد
                    SET @Message = NULL;
                END;
                
                -- 1399/09/26 * اگر کد معرف هم وارد شده باید اطلاعات آن را وارد کنید
                IF ISNULL(@RefChatId , 0) != 0
                  GOTO L$UpdateRefInit;
            END;

            GOTO L$EndSP;
        END;
        -- SubMenu ::= تاریخ تولد
        -- UssdCode ::= *1*0*1#
        ELSE IF @UssdCode = '*1*0*1#'
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            -- اگر طول رشته ورودی درست نباشد      
            IF LEN(@MenuText) != 10
            BEGIN
                SET @Message = N'⛔️ تاریخ وارد شده *معتبر نیست* ، لطفا بر اساس دستورالعمل تاریخ تولد خود را وارد کنید';
                GOTO L$EndSP;
            END;

            SET @FromDate = dbo.GET_STOM_U(@MenuText);
            IF @FromDate IS NULL
                SET @Message = N'⛔️ تاریخ وارد شده *معتبر نیست* ، لطفا بر اساس دستورالعمل تاریخ تولد خود را وارد کنید';
            ELSE
            BEGIN
                -- ثبت اطلاعات مشتری درون سیستم نرم افزار مدیریتی آرتا
                SELECT @XTemp =
                (
                    SELECT '05' AS '@subsys',
                           '100' AS '@cmndcode',        -- عملیات جامع ذخیره سازی
                           12 AS '@refsubsys',          -- محل ارجاعی
                           'appuser' AS '@execaslogin', -- توسط کدام کاربری اجرا شود               
                           '' AS '@refcode',
                           '' AS '@refnumb',            -- تعداد شماره درخواست ثبت شده
                           '' AS '@strtdate',
                           '' AS '@enddate',
                           @ChatID AS '@chatid',
                           'brthdate' AS '@colname',
                           @FromDate AS '@colvalu',
                (
                    SELECT '002' AS '@rqtpcode' FOR XML PATH('Expense'), TYPE
                )
                    FROM dbo.Service_Robot sr
                    WHERE sr.ROBO_RBID = @Rbid
                          AND sr.CHAT_ID = @ChatID
                    FOR XML PATH('Router_Command')
                );
                EXEC dbo.RouterdbCommand @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      
                SELECT @XTemp,
                       @XTemp.query('//Router_Command').value('(Router_Command/@rsltcode)[1]', 'VARCHAR(3)');
                IF @XTemp.query('//Router_Command').value('(Router_Command/@rsltcode)[1]', 'VARCHAR(3)') != '002'
                BEGIN
                    -- اگر درخواست ثبت مشتری با مشکل مواجه شد
                    SET @Message = N'⛔️ در ذخیره کردن *تاریخ تولد* مشکلی به وجود آمده است';
                END;
                ELSE
                BEGIN
                    -- درخواست ثبت تاریخ تولد مشتری با موفقیت ذخیره شد
                    SET @Message
                        = N'✅ اطلاعات *تاریخ تولد* شما درون سیستم ثبت شد' + CHAR(10) + CHAR(10)
                          + N'💡 در صورت نیاز به ویرایش، تاریخ تولد صحیح را مجددا وارد کنید';
                END;
            END;
        END;
        -- SubMenu :: دعوت از دوستان
        -- UssdCode ::= *1*10*3#
        ELSE IF @UssdCode = '*1*10*3#'
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SET @ContCellPhon = CASE LEN(@ContCellPhon)
                                    WHEN 11 THEN
                                        @ContCellPhon
                                    WHEN 12 THEN
                                        '0' + SUBSTRING(@ContCellPhon, 3, LEN(@ContCellPhon))
                                    WHEN 13 THEN
                                        '0' + SUBSTRING(@ContCellPhon, 4, LEN(@ContCellPhon))
                                END;

            IF @ContCellPhon IS NULL
               OR LEN(@ContCellPhon) < 11
            BEGIN
                SET @Message = N'شماره تلفن ارسال شده نامعتبر می باشد';
                GOTO L$EndSP;
            END;

            -- شرط هایی که وجود دارد
            -- 1 . اگر شماره ای که وارد سیستم میکنیم قبلا جز کسانی بودند که بله رو نصب کردن ولی در زیر مجموعه کسی قرار ندارند
            -- راحل : در این قسمت باید با آن مشتری پیامی ارسال کنیم که ازش تاییدیه بگیریم که آیا مایل هستین در گروه مخاطب درخواست کننده قرار بگیرید یا خیر
            -- 2 . اگر شماره که وارد سیستم میکنیم بله رو نصب کرده و زیر مجموعه شخص دیگری بوده
            -- ارسال پیام به درخواست کننده که بگیم این مشتری در گروه فروش شخص دیگری قرار دارد
            -- 3. اگر شماره ای که وارد میکنیم نرم افزار بله را نصب نکرده و میخواهیم با پیامک به آن اطلاع رسانی کنیم
            -- نکات ریز : ممکن است که قبلا شخص دیگری این فرد را دعوت کرده باشد پس دیگر نمی توان به درخواست کننده اجازه این کار را بدهیم
            -- اگر این شماره توسط شخص دیگری ثبت نشده باشد آن را ثبت میکنیم البته با فرض اینکه همین شماره قبلا برای همین درخواست کننده ثبت نشده باشد

            -- ذخیره سازی اطلاعات درون جدول موقت
            SELECT *
            INTO TT#Service_Robot
            FROM dbo.Service_Robot sr
            WHERE sr.ROBO_RBID = @Rbid
                  AND sr.CELL_PHON IS NOT NULL
                  AND (CASE LEN(sr.CELL_PHON)
                           WHEN 11 THEN
                               sr.CELL_PHON
                           WHEN 12 THEN
                               '0' + SUBSTRING(sr.CELL_PHON, 3, LEN(sr.CELL_PHON))
                           WHEN 13 THEN
                               '0' + SUBSTRING(sr.CELL_PHON, 4, LEN(sr.CELL_PHON))
                       END = @ContCellPhon
                      );

            -- بررسی گزینه 1
            IF EXISTS (SELECT * FROM TT#Service_Robot WHERE REF_CHAT_ID IS NULL)
            BEGIN
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessjoingpsl' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                );

                INSERT INTO dbo.[Order]
                (
                    SRBT_SERV_FILE_NO,
                    SRBT_ROBO_RBID,
                    SUB_SYS,
                    CODE,
                    ORDR_TYPE,
                    ORDR_STAT
                )
                SELECT sr.SERV_FILE_NO,
                       sr.ROBO_RBID,
                       12,
                       dbo.GNRT_NVID_U(),
                       '012',
                       '004'
                FROM TT#Service_Robot sr;

                -- بدست آوردن شماره درخواست
                SELECT @OrdrCode = o.CODE
                FROM dbo.[Order] o,
                     TT#Service_Robot sr,
                     dbo.Service_Robot srt
                WHERE o.ORDR_TYPE = '012'
                      AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                      AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                      AND o.ORDR_STAT = '004'
                      AND srt.CHAT_ID = @ChatID
                      AND srt.ROBO_RBID = @Rbid
                      AND NOT EXISTS
                (
                    SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE
                );

                INSERT INTO dbo.Order_Detail
                (
                    ORDR_CODE,
                    ELMN_TYPE,
                    ORDR_CMNT,
                    ORDR_DESC,
                    IMAG_PATH,
                    INLN_KEYB_DNRM
                )
                SELECT o.CODE,
                       '002',
                       N'سامانه اطلاع رسانی بابت عضویت در گروه',
                       N'*' + o.OWNR_NAME + N'* عزیز' + CHAR(10) + N'با سلام و احترام' + CHAR(10)
                       + N'درخواست عضویت در تیم فروش' + CHAR(10) + CHAR(10) + N'*' + srt.NAME
                       + N'* درخواست این را دارد که شما را در تیم فروش خود عضو کند آیا مایل هستید که در گروه ایشان قرار بگیرید؟',
                       (
                           SELECT TOP 1
                                  om.FILE_ID
                           FROM dbo.Organ_Media om
                           WHERE om.ROBO_RBID = @Rbid
                                 AND om.RBCN_TYPE = '012'
                                 AND om.STAT = '002'
                                 AND om.IMAG_TYPE = '002'
                       ),
                       @XTemp
                FROM dbo.[Order] o,
                     TT#Service_Robot sr,
                     dbo.Service_Robot srt
                WHERE o.ORDR_TYPE = '012'
                      AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                      AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                      AND o.ORDR_STAT = '004'
                      AND srt.CHAT_ID = @ChatID
                      AND srt.ROBO_RBID = @Rbid
                      AND NOT EXISTS
                (
                    SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE
                );

                SELECT @TDirPrjbCode = a.CODE
                FROM dbo.Personal_Robot_Job a,
                     dbo.Job b,
                     dbo.[Order] o
                WHERE a.PRBT_ROBO_RBID = @Rbid
                      AND a.JOB_CODE = b.CODE
                      AND b.ORDR_TYPE = '012'
                      AND o.CODE = @OrdrCode
                      AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO;

                SELECT @XMessage =
                (
                    SELECT @OrdrCode AS '@code',
                           @Rbid AS '@roborbid',
                           '012' '@type',
                           @TDirPrjbCode '@dirprjbcode'
                    FOR XML PATH('Order'), ROOT('Process')
                );
                EXEC Send_Order_To_Personal_Robot_Job @XMessage;

                SET @Message
                    = N'📨 درخواست شما برای مخاطبتان ارسال شده، زمانی که مخاطب شما پاسخ داد به شما اطلاع رسانی میکنیم، با تشکر از شما';
            END;
            -- بررسی گزینه 2
            ELSE IF EXISTS (SELECT * FROM TT#Service_Robot WHERE REF_CHAT_ID IS NOT NULL)
            BEGIN
                SET @Message = N'⚠️ این مشتری قبلا در گروه شخص دیگری قرار گرفته است';
            END;
            -- بررسی گزینه 3
            ELSE IF NOT EXISTS (SELECT * FROM TT#Service_Robot)
            BEGIN
                -- اگر مشتری توسط شخص دیگری پیامک دعوت برایش ارسال کرده باشد
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.Service_Robot_Inviting_Contact
                    WHERE SRBT_ROBO_RBID = @Rbid
                          AND CHAT_ID != @ChatID
                          AND CONT_CELL_PHON = @ContCellPhon
                )
                BEGIN
                    SET @Message = N'⚠️ مخاطب توسط شخص دیگری دعوت شده است';
                END;
                -- اگر قبلا این مخاطب درون لیست دعوت درخواست کننده نباشد
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.Service_Robot_Inviting_Contact
                    WHERE SRBT_ROBO_RBID = @Rbid
                          AND CHAT_ID = @ChatID
                          AND CONT_CELL_PHON = @ContCellPhon
                )
                BEGIN
                    SET @Message = N'⚠️ مخاطب قبلا درون لیست دعوت شما قرار گرفته است';
                END;
                -- مخاطب میتواند درون لیست شما قرار بگیرد و پیام برای آن ارسال شود
                ELSE
                BEGIN
                    -- در این قسمت زمانی که اطلاعات درون جدول لیست دعوت ها قرار گرفت به صورت اتومات 
                    INSERT INTO dbo.Service_Robot_Inviting_Contact
                    (
                        SRBT_SERV_FILE_NO,
                        SRBT_ROBO_RBID,
                        CODE,
                        CONT_NAME,
                        CONT_CELL_PHON
                    )
                    SELECT sr.SERV_FILE_NO,
                           sr.ROBO_RBID,
                           0,
                           @ContName,
                           @ContCellPhon
                    FROM dbo.Service_Robot sr
                    WHERE sr.ROBO_RBID = @Rbid
                          AND sr.CHAT_ID = @ChatID;
                    SET @Message =
                        --= N'✅ مخاطب با موفقیت درون لیست دعوت کننده گان شما قرار گرفت و پیام دعوت برایش ارسال شد';
                        N'🤚😊 *سلام، خوبی عزیزم؟*' + CHAR(10) + CHAR(10) + 
                        N'من با یه نرم افزار 💥 جدیدی آشنا شدم که 👌 دقیقا قابلیت های *تلگرام* رو داره و از همه مهمتر 🛍️ *فروشگاه های آنلاینی* که داره و میشه داخلش محصول مورد نظر تو _بخری_ و حتی 🤑 *درآمد* هم کسب کنی' + CHAR(10) + CHAR(10) + 
                        N'👈 *مراحل نصبش*' + CHAR(10) + 
                        N'داخل *google play* برنامه *بله* رو جستجو کن و اونو نصبش کن، بعد از نصب *شماره تلفن : ' + @ContCellPhon + N' * وارد کن پیام *تایید* برات میاد، با وارد کردن *پیام تایید* اسم و فامیل خودتو وارد کن، وارد نرم افزار که شدی به من پیام بده تا ' + 
                        N'بهت یاد بدم که چطوری ازش استفاده کنی، *من داخلش هستم و خرید میکنم* ، قیمتهایی که داره نسبت به بازار خیلی *پایین و مناسبه* و *حتی میتونی درآمد هم کسب کنی* و جالبه که میتونی مشخص کنی محصول رو کجا دریافت کنی *محدودیت ارسال نداره* و به همه جا ارسال میکنن' + CHAR(10) + CHAR(10) +
                        N'*اسم فروشگاه* ' + (select CHAR(10) + N'👉 ' + LOWER(NAME) + CHAR(10) + N' 🌐  *www.ble.ir/' + LOWER(SUBSTRING(NAME, 2, LEN(NAME))) + N'*'  FROM dbo.Robot WHERE RBID = @Rbid) + CHAR(10) + CHAR(10) +
                        N'#فروشگاه_انلاین #خرید #قیمت_ارزان #درآمدزایی'
                END;
            END;

            -- حذف جدول موقت از حافظه
            DROP TABLE TT#Service_Robot;
        END;
        -- SubMenu ::= 🗣 کد معرف
        -- UssdCod ::= *1*1#
        ELSE IF @UssdCode = '*1*1#'
        BEGIN            
            SET @RefChatId = CONVERT(BIGINT, @MenuText);
            L$UpdateRefInit:
            IF NOT EXISTS
            (
                SELECT *
                FROM dbo.Service_Robot sr
                WHERE sr.ROBO_RBID = @Rbid
                      AND sr.CHAT_ID = @RefChatId
            )
            BEGIN
                SELECT @Message
                    = N'کد معرف وارد شده درست نمیباشد. لطفا در وارد کردن کد معرف خود نهایت دقت را داشته باشید که به هیچ عنوان قابل ویرایش کردن نیست'
                      + CHAR(10) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                      + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
                GOTO L$EndSP;
            END;
            ELSE IF EXISTS
            (
                SELECT *
                FROM dbo.Service_Robot sr
                WHERE sr.ROBO_RBID = @Rbid
                      AND sr.CHAT_ID = @ChatID
                      AND sr.REF_CHAT_ID IS NOT NULL
            )
            BEGIN
                SELECT @Message
                    = N'قبلا برای شما کد معرف ثبت شده است' + CHAR(10) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE())
                      + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
                GOTO L$EndSP;
            END;
            ELSE IF EXISTS
            (
                SELECT *
                FROM dbo.Service_Robot sr1,
                     dbo.Service_Robot sr2
                WHERE sr1.ROBO_RBID = sr2.ROBO_RBID
                      AND sr1.CHAT_ID = @ChatID
                      AND sr2.CHAT_ID = @RefChatId
                      AND sr1.REF_CHAT_ID = sr2.CHAT_ID
            )
            BEGIN
                SELECT @Message
                    = N'این کار شما باعث ایجاد حلقه گروه ها میشود که در قالب تیم سازی کار درستی نیست' + CHAR(10)
                      + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                      + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
                GOTO L$EndSP;
            END;

            SET @XTemp =
            (
                SELECT @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @RefChatId AS '@refchatid',
                       '002' AS '@actntype',
                       'Update Ref Chat id' AS '@actndesc'
                FOR XML PATH('Service')
            );

            EXEC dbo.SAVE_SRBT_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)');
            -- Successfull
            IF @RsltCode = '002'
            BEGIN
                SELECT @Message = ISNULL(@Message, N'') + CHAR(10) +  @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
                SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
            END;
        END;
        -- UpMenu  ::= 📍 آدرسها
        -- SubMenu ::= 💾 ثبت جدید
        -- UssdCod ::= *1*2*0#
        ELSE IF @UssdCode = '*1*2*0#'
        BEGIN
            L$AddNewAddress:
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            IF @ElmnType = '001'
                SET @XTemp =
            (
                SELECT @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @MenuText AS '@postadrs',
                       '003' AS '@actntype',
                       'Update Service Post Address' AS '@actndesc'
                FOR XML PATH('Service')
            )   ;
            ELSE IF @ElmnType = '005'
                SET @XTemp =
            (
                SELECT @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @CordX AS '@cordx',
                       @CordY AS '@cordy',
                       '003' AS '@actntype',
                       'Update Service Location' AS '@actndesc'
                FOR XML PATH('Service')
            )   ;

            EXEC dbo.SAVE_SRBT_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)');
            -- Successfull
            IF @RsltCode = '002'
            BEGIN
                SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
                SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
            END;
        END;
        -- UpMenu  ::= 📍 آدرسها
        -- SubMenu ::= 🚩 نمایش
        -- UssdCod ::= *1*2#
        -- UssdCod ::= *1*2*1#
        ELSE IF @UssdCode = '*1*2#'
                AND @ChildUssdCode = '*1*2*1#'
        BEGIN
            L$ShowAllAddress:
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SET @XTemp =
            (
                SELECT @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       '004' AS '@actntype',
                       'Show All Post Address & Location' AS '@actndesc'
                FOR XML PATH('Service')
            );

            EXEC dbo.SAVE_SRBT_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)');
            -- Successfull
            IF @RsltCode = '002'
            BEGIN
                SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
                SELECT @Message += N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
            END;
        END;
        -- UpMenu  ::= 📍 آدرسها
        -- SubMenu ::= 🚩 انتخاب آدرس
        -- UssdCod ::= *1*2#
        -- UssdCod ::= *1*2*1#
        ELSE IF @UssdCode = '*1*2#'
                AND @ChildUssdCode = '*1*2*2#'
        BEGIN
            L$SelectAddress:
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SET @XTemp =
            (
                SELECT @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       '008' AS '@actntype',
                       @UssdCode AS '@ussdcode',
                       CASE
                           WHEN @MenuText IN ( 'slctloc4ordr', 'location::select', 'location::del' ) THEN
                               @MenuText
                           ELSE
                               'location::select'
                       END AS '@cmndtext',
                       @ParamText AS '@parmtext',
                       @PostExec AS '@postexec',
                       @Trigger AS '@trgrtext',
                       'Show All Post Address & Location For Select' AS '@actndesc'
                FOR XML PATH('Service')
            );
            EXEC dbo.SAVE_SRBT_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)');
            -- Successfull
            IF @RsltCode = '002'
            BEGIN
                SELECT @Message
                    = ISNULL(@Message, '') + @XTemp.query('//Message').value('(Message/text())[1]', 'NVARCHAR(MAX)');
                --SELECT @Message += CHAR(10) + N'⏰ '+ dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));          

                SELECT @XMessage =
                (
                    SELECT TOP 1
                           om.FILE_ID AS '@fileid',
                           '002' AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                          AND om.RBCN_TYPE = '006'
                          AND om.IMAG_TYPE = '002'
                          AND om.STAT = '002'
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                );
                SET @XTemp = @XTemp.query('//InlineKeyboardMarkup');
                SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
                GOTO L$EndSP;
            END;
        END;
        -- گزارشات
        -- سفارشات
        ELSE IF @UssdCode = '*1*3*0#'
                AND @ChildUssdCode IN ( '*1*3*0*0#', '*1*3*0*1#', '*1*3*0*2#', '*1*3*0*3#' )
        BEGIN
            L$ReportOrder:
            SELECT @MenuText = N'buyshop',
                   @PostExec = N'allbuyshop';
            GOTO L$ReportBuyShop;
        END;
        -- فروش زیر مجموعه
        ELSE IF @UssdCode = '*1*3*1#'
                AND @ChildUssdCode IN ( '*1*3*1*0#', '*1*3*1*1#', '*1*3*1*2#', '*1*3*1*3#' )
        BEGIN
            L$ReportSubsidiarySales:
            SET @Message
                = N'گزارش فروش زیر مجموعه' + CHAR(10) + N'🗓️ بازه گزارش از تاریخ *' + dbo.GET_MTOS_U(@FromDate)
                  + N'* تا تاریخ *' + dbo.GET_MTOS_U(@ToDate) + N'* می باشد' + CHAR(10)
                  + ISNULL(
                    (
                        SELECT N'👈 *' + sr.NAME + N'* [ کد ] *' + CAST(sr.CHAT_ID AS VARCHAR(30)) + N'* ' + CHAR(10)
                               + N'🔢 [ تعداد سفارشات ] *'
                               + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(o.CODE)), 1), '.00', '') + N'* عدد'
                               + CHAR(10) + N'💰 [ جمع مبلغ سفارشات ] *'
                               + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, SUM(o.SUM_EXPN_AMNT_DNRM)), 1), '.00', '')
                               + N'* ' + @AmntTypeDesc + CHAR(10) + N'✅ [ جمع مبلغ سود تایید شده ] *'
                               + REPLACE(CONVERT(NVARCHAR,
                                                 CONVERT(MONEY,
                                                         SUM(   CASE wd.CONF_STAT
                                                                    WHEN '002' THEN
                                                                        wd.AMNT
                                                                    ELSE
                                                                        0
                                                                END
                                                            )
                                                        ),
                                                 1
                                                ),
                                         '.00',
                                         ''
                                        ) + N'* ' + @AmntTypeDesc + CHAR(10) + N'🔰 [ جمع مبلغ سود تایید نشده ] *'
                               + REPLACE(CONVERT(NVARCHAR,
                                                 CONVERT(MONEY,
                                                         SUM(   CASE wd.CONF_STAT
                                                                    WHEN '002' THEN
                                                                        0
                                                                    ELSE
                                                                        wd.AMNT
                                                                END
                                                            )
                                                        ),
                                                 1
                                                ),
                                         '.00',
                                         ''
                                        ) + N'* ' + @AmntTypeDesc + CHAR(10)
                        FROM dbo.[Order] o
                            LEFT OUTER JOIN dbo.Wallet_Detail wd
                                ON wd.ORDR_CODE = o.CODE
                                   AND wd.CHAT_ID = @ChatID
                                   AND wd.TXFE_TFID IS NOT NULL,
                             dbo.Service_Robot sr
                        WHERE o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                              AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                              AND sr.REF_CHAT_ID = @ChatID
                              AND sr.ROBO_RBID = @Rbid
                              AND o.ORDR_TYPE = '004'
                              AND CAST(o.END_DATE AS DATE)
                              BETWEEN @FromDate AND @ToDate
                              AND EXISTS
                        (
                            SELECT osh.ORDR_CODE
                            FROM dbo.Order_Step_History osh
                            WHERE o.CODE = osh.ORDR_CODE
                                  AND osh.ORDR_STAT IN ( '004', '009' )
                            GROUP BY osh.ORDR_CODE
                            HAVING COUNT(DISTINCT osh.ORDR_STAT) IN ( 1, 2 )
                        )
                        GROUP BY sr.CHAT_ID,
                                 sr.NAME
                        ORDER BY SUM(o.SUM_EXPN_AMNT_DNRM) DESC
                        FOR XML PATH('')
                    ),
                    N'😐 گزارشی وجود ندارد'
                          ) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                  + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
        END;
        -- گردش مالی
        ELSE IF @UssdCode = '*1*3*2#'
                AND @ChildUssdCode IN ( '*1*3*2*0#', '*1*3*2*1#', '*1*3*2*2#', '*1*3*2*3#' )
        BEGIN
            L$ReportWallet:

            SET @Message
                = N'گزارش گردش مالی' + CHAR(10) + N'🗓️ بازه گزارش از تاریخ *' + dbo.GET_MTOS_U(@FromDate)
                  + N'* تا تاریخ *' + dbo.GET_MTOS_U(@ToDate) + N'* می باشد' + CHAR(10) + CHAR(10)
                  + ISNULL(
                    (
                        SELECT N'📅  *' + dbo.GET_MTOS_U(wd.CONF_DATE) + N' -  '
                               + CAST(CAST(wd.CONF_DATE AS TIME(0)) AS VARCHAR(5)) + N'* ' + CHAR(10)
                               + CASE wd.AMNT_STAT
                                     WHEN '001' THEN
                                         N'🔵 '
                                     WHEN '002' THEN
                                         N'🔴 '
                                 END + CASE wd.CONF_STAT
                                           WHEN '001' THEN
                                               N'❌ '
                                           WHEN '002' THEN
                                               N'✅ '
                                           WHEN '003' THEN
                                               N'⏳ '
                                       END + N' *' + REPLACE(CONVERT(NVARCHAR,
                                                                     CONVERT(   MONEY,
                                                                                CASE wd.AMNT_STAT
                                                                                    WHEN '001' THEN
                                                                                        wd.AMNT
                                                                                    WHEN '002' THEN
                                                                                        -wd.AMNT
                                                                                END
                                                                            ),
                                                                     1
                                                                    ),
                                                             '.00',
                                                             ''
                                                            ) + N'* ' + @AmntTypeDesc + CHAR(10) + N'◀️ _'
                               + wd.CONF_DESC + N'_' + CHAR(10) + CASE w.WLET_TYPE
                                                                      WHEN '001' THEN
                                                                          N'💎'
                                                                      WHEN '002' THEN
                                                                          N'💵'
                                                                  END + N' [ موجودی حساب ] *'
                               + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, wd.CRNT_WLET_AMNT_DNRM), 1), '.00', '')
                               + N'* ' + @AmntTypeDesc + CHAR(10) + CHAR(10)
                        FROM dbo.Wallet w,
                             dbo.Wallet_Detail wd,
                             dbo.Service_Robot sr
                        WHERE sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
                              AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
                              AND sr.CHAT_ID = w.CHAT_ID
                              AND w.CODE = wd.WLET_CODE
                              AND sr.ROBO_RBID = @Rbid
                              AND sr.CHAT_ID = @ChatID
                              AND CAST(wd.AMNT_DATE AS DATE)
                              BETWEEN @FromDate AND @ToDate
                              AND wd.CONF_STAT = '002'
                        ORDER BY wd.RWNO DESC
                        FOR XML PATH('')
                    ),
                    N''
                          )
                  + ISNULL(
                    (
                        SELECT N'📅 *' + dbo.GET_MTOS_U(wd.AMNT_DATE) + N'* ' + CASE wd.AMNT_STAT
                                                                                    WHEN '001' THEN
                                                                                        N'🔵 '
                                                                                    WHEN '002' THEN
                                                                                        N'🔴 '
                                                                                END + CASE wd.CONF_STAT
                                                                                          WHEN '001' THEN
                                                                                              N'❌ '
                                                                                          WHEN '002' THEN
                                                                                              N'✅ '
                                                                                          WHEN '003' THEN
                                                                                              N'⏳ '
                                                                                      END + N'💵 *'
                               + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, wd.AMNT), 1), '.00', '') + N'* '
                               + @AmntTypeDesc + CHAR(10) + N'◀️ _' + wd.CONF_DESC + N'_' + CHAR(10) + CHAR(10)
                        FROM dbo.Wallet w,
                             dbo.Wallet_Detail wd,
                             dbo.Service_Robot sr
                        WHERE sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
                              AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
                              AND sr.CHAT_ID = w.CHAT_ID
                              AND w.CODE = wd.WLET_CODE
                              AND sr.ROBO_RBID = @Rbid
                              AND sr.CHAT_ID = @ChatID
                              AND CAST(wd.AMNT_DATE AS DATE)
                              BETWEEN @FromDate AND @ToDate
                              AND wd.CONF_STAT = '003'
                        ORDER BY wd.AMNT_DATE DESC
                        FOR XML PATH('')
                    ),
                    N''
                          ) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                  + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
        END;
        ELSE IF @UssdCode = '*1*3*3#'
                AND @ChildUssdCode IN ( '*1*3*3*0#', '*1*3*3*1#', '*1*3*3*2#', '*1*3*3*3#' )
        BEGIN
            L$ReportWithdrawWallet:

            SET @Message
                = N'گزارش دریافت وجه' + CHAR(10) + N'🗓️ بازه گزارش از تاریخ *' + dbo.GET_MTOS_U(@FromDate)
                  + N'* تا تاریخ *' + dbo.GET_MTOS_U(@ToDate) + N'* می باشد' + CHAR(10) + CHAR(10)
                  + ISNULL(
                    (
                        SELECT N'[ ردیف ] : *' + CAST(ROW_NUMBER() OVER (ORDER BY o.END_DATE DESC) AS VARCHAR(10))
                               + N'*' + CHAR(10) + N'[ تاریخ درخواست ] : *' + dbo.GET_MTOS_U(o.STRT_DATE) + N'*'
                               + CHAR(10) + N'[ مبلغ درخواست وجه ] : *'
                               + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.EXPN_AMNT), 1), '.00', '') + N'* '
                               + @AmntTypeDesc + CHAR(10) + N'[ مبلغ واریزی ] : *'
                               + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_EXPN_AMNT_DNRM), 1), '.00', '') + N'* '
                               + @AmntTypeDesc + CHAR(10) + N'[ مبلغ کارمزد ] : *'
                               + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.SUM_FEE_AMNT_DNRM), 1), '.00', '') + N'* '
                               + @AmntTypeDesc + CHAR(10) + N'[ اطلاعات واریز ]' + CHAR(10)
                               +
                               (
                                   SELECT DISTINCT
                                          N'[ شماره کارت ] :' + CHAR(10) + N'*' + a.CARD_NUMB_DNRM + N'*' + CHAR(10)
                                          + N'[ شماره شبا ] : *' + ISNULL(a.SHBA_NUMB, N'---') + N'*' + CHAR(10)
                                          + N'[ بانک ] *' + a.BANK_NAME + N'* - *' + a.ACNT_OWNR + N'*' + CHAR(10)
                                   FROM dbo.Robot_Card_Bank_Account a
                                   WHERE a.ROBO_RBID = @Rbid
                                         AND a.CARD_NUMB = o.SORC_CARD_NUMB_DNRM
                               ) + N'[ کد پیگیری ] : *' + o.TXID_DNRM + N'*' + CHAR(10) + N'[ تاریخ واریز ] : *'
                               + dbo.GET_MTOS_U(o.END_DATE) + N'*' + CHAR(10)
                        FROM dbo.[Order] o
                        WHERE o.SRBT_ROBO_RBID = @Rbid
                              AND o.CHAT_ID = @ChatID
                              AND o.ORDR_STAT = '004'
                              AND o.ORDR_TYPE = '024'
                        ORDER BY o.END_DATE DESC
                        FOR XML PATH('')
                    ),
                    N''
                          ) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                  + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));

            GOTO L$EndSP;
        END;
        -- امور مالی
        -- موجودی کیف پول
        ELSE IF (
                    @UssdCode = '*1*4#'
                    AND @ChildUssdCode = '*1*4*0#'
                )
                OR
                (
                    @UssdCode = '*3*0#'
                    AND @ChildUssdCode = '*3*0*1#'
                )
                OR
                (
                    @UssdCode = '*6*0#'
                    AND @ChildUssdCode = '*6*0*2#'
                )
        BEGIN
            SET @Message
                = N'*موجودی کیف پول شما*' + CHAR(10) + CHAR(10)
                  + ISNULL(
                    (
                        SELECT N'👈 *' + wt.DOMN_DESC + N'*' + CHAR(10) + CASE w.WLET_TYPE
                                                                              WHEN '001' THEN
                                                                                  N'💳'
                                                                              WHEN '002' THEN
                                                                                  N'💵'
                                                                          END + N' [ موجودی حساب ] *'
                               + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, ISNULL(w.AMNT_DNRM, 0)), 1), '.00', '')
                               + N'* ' + @AmntTypeDesc + CHAR(10) + N'🔵 [ آخرین واریزی ] '
                               + CASE ISNULL(w.LAST_IN_AMNT_DNRM, 0)
                                     WHEN 0 THEN
                                         N' _نداشته اید_ '
                                     ELSE
                                         N'💵 *'
                                         + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, w.LAST_IN_AMNT_DNRM), 1), '.00', '')
                                         + N'* ' + @AmntTypeDesc + N' 📅 ' + dbo.GET_MTOS_U(w.LAST_IN_DATE_DNRM) + N''
                                 END + CHAR(10) + N'🔴 [ آخرین برداشتی ] '
                               + CASE ISNULL(w.LAST_OUT_AMNT_DNRM, 0)
                                     WHEN 0 THEN
                                         N' _نداشته اید_ '
                                     ELSE
                                         N'💵 *'
                                         + REPLACE(
                                                      CONVERT(NVARCHAR, CONVERT(MONEY, w.LAST_OUT_AMNT_DNRM), 1),
                                                      '.00',
                                                      ''
                                                  ) + N'* ' + @AmntTypeDesc + N' 📅 '
                                         + dbo.GET_MTOS_U(w.LAST_OUT_DATE_DNRM) + N''
                                 END + CHAR(10) + CHAR(10)
                        --CASE ISNULL(r.MIN_WITH_DRAW, 0) 
                        --     WHEN 0 THEN /* فروشگاه مبلغ پرداخت نقدی ندارد ولی اعضا میتواند پول اعتبارات خود را باهم خرید و فروش کنند */ N'🙂 مشتری عزیز 💎 _مبلغ اعتبار شما_ *قابلیت نقد شوندگی* برای 🏢 *فروشگاه ندارد* ، ولی شما می توانید 💎 *مبلغ اعتبار* خود را یا دیگر 👥 *اعضا* در میان بگذارید که اگر 🙋 *متقاضی* _خواهان اعتبار شما_ بود پول به صورت 💳 *کارت به کارت* پرداخت کرده و اعتبار خود را به دیگری واگذار کنید و شما به پول نقد دست یابید.'
                        --     ELSE /* فروشگاه قابلیت نقدشوندگی را دارد و همچنین می توانید اعتبار خود را به دیگر اعضا بفروشید، برای فروشگاه حداقل مبلغ برداشت اهمیت زیادی دارد */ N'😊 مشتری عزیز برای 💰 *برداشت مبلغ* خود می توانید از طریق 🏢 *فروشگاه* یا 👥 *مشتریان فروشگاه* استفاده کنید، فقط برای _فروشگاه مبلغ حداقل برداشت_ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, r.MIN_WITH_DRAW), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' میباشد که ممکن است 💸 *درخواست انتقال 48 ساعت* طول بینجامد ولی، 💳 *پرداخت بین اعضا 👥 * درصورتی که 🙋🏻 متقاضی باشد که به 💎 *اعتبار کیف پول شما* نیاز داشته باشد به صورت *انی* به 💳 _حساب شما_ *واریز* میگردد.'
                        --END
                        FROM dbo.Wallet w,
                             dbo.Service_Robot sr,
                             dbo.Robot r,
                             dbo.[D$WLTP] wt
                        WHERE r.RBID = sr.ROBO_RBID
                              AND sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
                              AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
                              AND r.RBID = @Rbid
                              AND sr.CHAT_ID = @ChatID
                              AND w.WLET_TYPE = wt.VALU
                        ORDER BY w.WLET_TYPE
                        FOR XML PATH('')
                    ),
                    N''
                          )
                  +
                  (
                      SELECT /*CASE ISNULL(r.MIN_WITH_DRAW, 0) 
                           WHEN 0 THEN /* فروشگاه مبلغ پرداخت نقدی ندارد ولی اعضا میتواند پول اعتبارات خود را باهم خرید و فروش کنند */ 
                                /*N'🙂 مشتری عزیز 💎 _مبلغ اعتبار شما_ *قابلیت نقد شوندگی* برای 🏢 *فروشگاه ندارد* ، ولی شما می توانید 💎 *مبلغ اعتبار* خود را یا دیگر 👥 *اعضا* در میان بگذارید که اگر 🙋 *متقاضی* _خواهان اعتبار شما_ بود پول به صورت 💳 *کارت به کارت* پرداخت کرده و اعتبار خود را به دیگری واگذار کنید و شما به پول نقد دست یابید.'*/
                                N'مبلغ کیف پول *اعتباری* تنها جهت 🛒 *خرید* از فروشگاه بوده و *قابل برداشت* به صورت *پول نقد* نمیباشد؛ در صورت تمایل میتوانید آن را در میان اعضای فروشگاه به فروش بگذارید.' + CHAR(10) +
                                N'مبلغ کیف پول نقدینگی قابل برداشت میباشد که فرایند انتقال وجه حدود 48 ساعت به طول می انجامد؛ در صورت تمایل به برداشت وجه در زمان کمتر، میتوانید آن را در میان اعضای فروشگاه به فروش بگذارید.'                                
                           ELSE /* فروشگاه قابلیت نقدشوندگی را دارد و همچنین می توانید اعتبار خود را به دیگر اعضا بفروشید، برای فروشگاه حداقل مبلغ برداشت اهمیت زیادی دارد */ 
                                /*N'😊 مشتری عزیز برای 💰 *برداشت مبلغ* خود می توانید از طریق 🏢 *فروشگاه* یا 👥 *مشتریان فروشگاه* استفاده کنید، فقط برای _فروشگاه مبلغ حداقل برداشت_ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, r.MIN_WITH_DRAW), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' میباشد که ممکن است 💸 *درخواست انتقال 48 ساعت* طول بینجامد ولی، 💳 *پرداخت بین اعضا 👥 * درصورتی که 🙋🏻 متقاضی باشد که به 💎 *اعتبار کیف پول شما* نیاز داشته باشد به صورت *انی* به 💳 _حساب شما_ *واریز* میگردد.'*/
                                
                      END*/
                          N'💳 مبلغ کیف پول *اعتباری* تنها جهت 🛒 *خرید* از فروشگاه بوده و *قابل برداشت* به صورت *مستقیم نمیباشد* ؛ در صورت تمایل میتوانید آن را در میان اعضای فروشگاه به *فروش* بگذارید.'
                          + CHAR(10) + CHAR(10)
                          + N'💵 مبلغ کیف پول *نقدینگی قابل برداشت میباشد* که فرایند انتقال وجه حدود *48 ساعت* به طول می انجامد؛ در صورت تمایل به برداشت وجه در زمان کمتر، میتوانید آن را در میان اعضای فروشگاه به *فروش* بگذارید.'
                          + CHAR(10) + N'⚠️ *حداقل* مبلغ قابل برداشت از فروشگاه *'
                          + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, r.MIN_WITH_DRAW), 1), '.00', '') + N' '
                          + @AmntTypeDesc + N'* میباشد'
                      FROM dbo.Robot r
                      WHERE r.RBID = @Rbid
                      FOR XML PATH('')
                  ) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                  + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
        END;
        -- درخواست وجه
        ELSE IF (
                    @UssdCode = '*1*4#'
                    AND @ChildUssdCode = '*1*4*1#'
                )
                OR
                (
                    @UssdCode = '*3*0#'
                    AND @ChildUssdCode = '*3*0*3#'
                )
        BEGIN
            L$CashOutProfit:
            SET @Message
                = N'*مدیریت برداشت وجه*' + CHAR(10) + CHAR(10)
                  + N'🤑 *سود بدست آمده* از عملکرد خود را می توانید *برداشت* کنید.' + CHAR(10) + CHAR(10)
                  + ISNULL(
                    (
                        SELECT N'👈 *' + wt.DOMN_DESC + N'*' + CHAR(10) + CASE w.WLET_TYPE
                                                                              WHEN '001' THEN
                                                                                  N'💳'
                                                                              WHEN '002' THEN
                                                                                  N'💵'
                                                                          END + N' [ موجودی حساب ] *'
                               + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, ISNULL(w.AMNT_DNRM, 0)), 1), '.00', '')
                               + N'* ' + @AmntTypeDesc + CHAR(10)
                        --N'🔵 [ آخرین واریزی ] ' + CASE ISNULL(w.LAST_IN_AMNT_DNRM, 0) WHEN 0 THEN N' _نداشته اید_ ' ELSE N'💵 *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, w.LAST_IN_AMNT_DNRM), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' 📅 ' + dbo.GET_MTOS_U(w.LAST_IN_DATE_DNRM) + N'' END + CHAR(10) +  
                        --N'🔴 [ آخرین برداشتی ] ' + CASE ISNULL(w.LAST_OUT_AMNT_DNRM, 0) WHEN 0 THEN N' _نداشته اید_ ' ELSE N'💵 *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, w.LAST_OUT_AMNT_DNRM), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' 📅 ' + dbo.GET_MTOS_U(w.LAST_OUT_DATE_DNRM) + N'' END + CHAR(10) + CHAR(10) 
                        --CASE ISNULL(r.MIN_WITH_DRAW, 0) 
                        --     WHEN 0 THEN /* فروشگاه مبلغ پرداخت نقدی ندارد ولی اعضا میتواند پول اعتبارات خود را باهم خرید و فروش کنند */ N'🙂 مشتری عزیز 💎 _مبلغ اعتبار شما_ *قابلیت نقد شوندگی* برای 🏢 *فروشگاه ندارد* ، ولی شما می توانید 💎 *مبلغ اعتبار* خود را یا دیگر 👥 *اعضا* در میان بگذارید که اگر 🙋 *متقاضی* _خواهان اعتبار شما_ بود پول به صورت 💳 *کارت به کارت* پرداخت کرده و اعتبار خود را به دیگری واگذار کنید و شما به پول نقد دست یابید.'
                        --     ELSE /* فروشگاه قابلیت نقدشوندگی را دارد و همچنین می توانید اعتبار خود را به دیگر اعضا بفروشید، برای فروشگاه حداقل مبلغ برداشت اهمیت زیادی دارد */ N'😊 مشتری عزیز برای 💰 *برداشت مبلغ* خود می توانید از طریق 🏢 *فروشگاه* یا 👥 *مشتریان فروشگاه* استفاده کنید، فقط برای _فروشگاه مبلغ حداقل برداشت_ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, r.MIN_WITH_DRAW), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' میباشد که ممکن است 💸 *درخواست انتقال 48 ساعت* طول بینجامد ولی، 💳 *پرداخت بین اعضا 👥 * درصورتی که 🙋🏻 متقاضی باشد که به 💎 *اعتبار کیف پول شما* نیاز داشته باشد به صورت *انی* به 💳 _حساب شما_ *واریز* میگردد.'
                        --END
                        FROM dbo.Wallet w,
                             dbo.Service_Robot sr,
                             dbo.Robot r,
                             dbo.[D$WLTP] wt
                        WHERE r.RBID = sr.ROBO_RBID
                              AND sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
                              AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
                              AND r.RBID = @Rbid
                              AND sr.CHAT_ID = @ChatID
                              AND w.WLET_TYPE = wt.VALU
                        ORDER BY w.WLET_TYPE
                        FOR XML PATH('')
                    ),
                    N''
                          ) + CHAR(10)
                  +
                  (
                      SELECT /*CASE ISNULL(r.MIN_WITH_DRAW, 0)
                                    WHEN 0 then N'😊 مشتری عزیز _پورسانت شما_ به صورت *اعتباری* میباشد و تنها می توانید از 🏢 فروشگاه خرید 🛒 کنید یا اینکه با دیگر 👥 *اعضا فروشگاه* اعتبار خود را *تعویض* کنید و به *پول نقد* تبدیل کنید.'
                                    ELSE N'😊 مشتری عزیز *پول اعتباری* شما قابلیت _نقد شوندگی_ از 🏢 *فروشگاه* و دیگر 👥 *اعضا فروشگاه ها* را دارید، ولی اگر میخواهید *فروشگاه* به _شما پرداخت_ داشته باشد باید 💵 *مبلغ* _حداقل_ *' + 
                                         REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, r.MIN_WITH_DRAW), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' داشته باشید که مبلغ قابل پرداخت باشد' + 
                                         N' 👈 البته شما می توانید *دریافت وجه* خود را با 👥 *کسانی* که به _اعتبار کیف پول_ شما *نیاز دارند تعویض کنید*' 
                               END*/
                          N'💳 مبلغ کیف پول *اعتباری* تنها جهت 🛒 *خرید* از فروشگاه بوده و *قابل برداشت* به صورت *مستقیم نمیباشد* ؛ در صورت تمایل میتوانید آن را در میان اعضای فروشگاه به *فروش* بگذارید.'
                          + CHAR(10) + CHAR(10)
                          + N'💵 مبلغ کیف پول *نقدینگی قابل برداشت میباشد* که فرایند انتقال وجه حدود *48 ساعت* به طول می انجامد؛ در صورت تمایل به برداشت وجه در زمان کمتر، میتوانید آن را در میان اعضای فروشگاه به *فروش* بگذارید.'
                          + CHAR(10) + N'⚠️ *حداقل* مبلغ قابل برداشت از فروشگاه *'
                          + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, r.MIN_WITH_DRAW), 1), '.00', '') + N' '
                          + @AmntTypeDesc + N'* میباشد'
                      FROM dbo.Robot r
                      WHERE r.RBID = @Rbid
                      FOR XML PATH('')
                  );
            SET @XTemp =
            (
                SELECT @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       @ChatID AS '@chatid',
                       'lesscashoutp' AS '@cmndtext'
                FOR XML PATH('RequestInLineQuery')
            );
            EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            SET @XTemp =
            (
                SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
            );

            SET @XMessage =
            (
                SELECT TOP 1
                       om.FILE_ID AS '@fileid',
                       om.IMAG_TYPE AS '@filetype',
                       @Message AS '@caption',
                       1 AS '@order'
                FROM dbo.Organ_Media om
                WHERE om.ROBO_RBID = @Rbid
                      AND om.RBCN_TYPE = '015'
                      AND om.IMAG_TYPE = '002'
                      AND om.STAT = '002'
                FOR XML PATH('Complex_InLineKeyboardMarkup')
            );
            SET @XMessage.modify('insert sql:variable("@XTemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
            SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            GOTO L$EndSP;
        END;
        -- مدیریت حساب ها
        ELSE IF (
                    @UssdCode = '*1*4#'
                    AND @ChildUssdCode = '*1*4*2#'
                )
                OR
                (
                    @UssdCode = '*3*0#'
                    AND @ChildUssdCode = '*3*0*0#'
                )
                OR
                (
                    @UssdCode = '*6*0#'
                    AND @ChildUssdCode = '*6*0*0#'
                )
        BEGIN
            L$BankCardShow:
            SET @Message
                = N'*مدیریت حساب ها*' + CHAR(10) + CHAR(10)
                  + N'💳 *حساب های* _مورد نیاز_ *خود* را ➕ *تعریف کنید* تا بتوانید در زمان *برداشت وجه* از آن _به راحتی_ استفاده کنید'
                  + CHAR(10)
                  + N'👈 *صحت و درستی* 📝 _ورود اطلاعات_ 💳 *حساب شما* به *عهده* _خود شماست_ ، *هر گونه مغایرت* _اطلاعات ورودی_ به عهده شخص میباشد';
            SET @XTemp =
            (
                SELECT @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       @ChatID AS '@chatid',
                       'lessbankacnt' AS '@cmndtext'
                FOR XML PATH('RequestInLineQuery')
            );
            EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            SET @XTemp =
            (
                SELECT '1' AS '@order',
                       --@Message AS '@caption',
                       @XTemp
                FOR XML PATH('InlineKeyboardMarkup')
            );

            SET @XMessage =
            (
                SELECT TOP 1
                       om.FILE_ID AS '@fileid',
                       om.IMAG_TYPE AS '@filetype',
                       @Message AS '@caption',
                       1 AS '@order'
                FROM dbo.Organ_Media om
                WHERE om.ROBO_RBID = @Rbid
                      AND om.RBCN_TYPE = '014'
                      AND om.IMAG_TYPE = '002'
                      AND om.STAT = '002'
                FOR XML PATH('Complex_InLineKeyboardMarkup')
            );
            SET @XMessage.modify('insert sql:variable("@XTemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
            SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            GOTO L$EndSP;
        END;
        -- ثبت رسید پرداخت شبا از واحد حسابداری برای پرداخت وجه مشتری
        ELSE IF @UssdCode = '*1*4*1#'
        BEGIN
            L$SaveReciptWithdraw:
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            -- بدست آوردن شماره درخواست حسابداری برای پرداخت وجه مشتری      
            SELECT @OrdrCode = CASE id
                                   WHEN 1 THEN
                                       Item
                                   ELSE
                                       @OrdrCode
                               END
            FROM dbo.SplitString(@ParamText, ',')
            WHERE LEN(Item) != 0;

            IF @ElmnType IN ( '002' )
               AND ISNULL(@OrdrCode, 0) > 0
            BEGIN
                IF @MenuText LIKE '%#%'
                    SELECT @Message = CASE id
                                          WHEN 1 THEN
                                              Item
                                          ELSE
                                              @Message
                                      END,
                           @Amnt = CASE id
                                       WHEN 2 THEN
                                           Item
                                       ELSE
                                           @Amnt
                                   END
                    FROM dbo.SplitString(@MenuText, '#');
                ELSE IF @MenuText = 'No Text'
                    SET @Message = dbo.STR_FRMT_U(N'رسید پرداخت شماره فاکتور {0}', @OrdrCode);
                ELSE
                    SET @Message = @MenuText;

                INSERT INTO dbo.Order_State
                (
                    ORDR_CODE,
                    CODE,
                    STAT_DATE,
                    STAT_DESC,
                    AMNT,
                    AMNT_TYPE,
                    RCPT_MTOD,
                    FILE_ID,
                    FILE_TYPE,
                    CONF_STAT
                )
                VALUES
                (@OrdrCode, 0, GETDATE(), @Message, @Amnt, '005', '013', @PhotoFileId, @ElmnType, '003');

                SELECT @ParamText = @OrdrCode,
                       @PostExec = N'lesswletwshprcpt';
                -- نمایش مجدد اطلاعات رسید های ارسال شده
                GOTO L$WalletWithDrawShop;
            END;
            ELSE
            BEGIN
                SET @Message
                    = N'👈 لطفا اطلاعات ارسال را طبق دستور العمل انجام دهید' + CHAR(10)
                      + N'*عکس رسید پرداخت* مورد نظر خود را انتخاب کنید و برای ارسال متن به شیوه زیر عمل کنید'
                      + CHAR(10) + N'✏️ *توضیحات قبض رسید* # *مبلغ رسید*';
            END;
        END;
        -- مدیریت کارت هدیه مشتری
        ELSE IF @UssdCode = '*1*4*3#'
                AND @ChildUssdCode IN ( '*1*4*3*0#', '*1*4*3*1#' )
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            -- اگر کارت هدیه ای وجود نداشته باشید 
            IF NOT EXISTS
            (
                SELECT *
                FROM dbo.Service_Robot_Gift_Card srg
                WHERE srg.SRBT_ROBO_RBID = @Rbid
                      AND srg.CHAT_ID = @ChatID
                      AND srg.VALD_TYPE = '002'
                      AND ISNULL(srg.BLNC_AMNT_DNRM, 0) - ISNULL(srg.TEMP_AMNT_USE, 0) > 0
            )
            BEGIN
                SET @Message = N'⚠️ کارت هدیه ای برای شما وجود ندارد';
            END;

            -- موجودی کلی کارت های هدیه
            IF @ChildUssdCode = '*1*4*3*0#'
            BEGIN
                SET @Message
                    = N'*موجودی اعتبار کارت های هدیه شما*' + CHAR(10) + CHAR(10)
                      +
                      (
                          SELECT N'💳 میزان اعتبار *'
                                 + REPLACE(
                                              CONVERT(
                                                         NVARCHAR,
                                                         CONVERT(
                                                                    MONEY,
                                                                    SUM(ISNULL(srg.BLNC_AMNT_DNRM, 0)
                                                                        - ISNULL(srg.TEMP_AMNT_USE, 0)
                                                                       )
                                                                ),
                                                         1
                                                     ),
                                              '.00',
                                              ''
                                          ) + N'* ' + @AmntTypeDesc + CHAR(10)
                          FROM dbo.Service_Robot_Gift_Card srg
                          WHERE srg.SRBT_ROBO_RBID = @Rbid
                                AND srg.CHAT_ID = @ChatID
                                AND srg.VALD_TYPE = '002'
                                AND ISNULL(srg.BLNC_AMNT_DNRM, 0) - ISNULL(srg.TEMP_AMNT_USE, 0) > 0
                          FOR XML PATH('')
                      ) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                      + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
            END;
            -- لیست تمام کارتهای هدیه معتبر
            ELSE IF @ChildUssdCode = '*1*4*3*1#'
            BEGIN
                SET @Message
                    = N'*کارت های هدیه شما*' + CHAR(10) + CHAR(10)
                      +
                      (
                          SELECT N'💳 میزان اعتبار *'
                                 + REPLACE(
                                              CONVERT(
                                                         NVARCHAR,
                                                         CONVERT(
                                                                    MONEY,
                                                                    ISNULL(srg.BLNC_AMNT_DNRM, 0)
                                                                    - ISNULL(srg.TEMP_AMNT_USE, 0)
                                                                ),
                                                         1
                                                     ),
                                              '.00',
                                              ''
                                          ) + N'* ' + @AmntTypeDesc + CHAR(10)
                          FROM dbo.Service_Robot_Gift_Card srg
                          WHERE srg.SRBT_ROBO_RBID = @Rbid
                                AND srg.CHAT_ID = @ChatID
                                AND srg.VALD_TYPE = '002'
                                AND ISNULL(srg.BLNC_AMNT_DNRM, 0) - ISNULL(srg.TEMP_AMNT_USE, 0) > 0
                          ORDER BY srg.CRET_DATE
                          FOR XML PATH('')
                      ) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                      + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
            END;
        END;
        -- مدیریت کارت تخفیف مشتری
        ELSE IF @UssdCode = '*1*4*4#'
                AND @ChildUssdCode IN ( '*1*4*4*0#', '*1*4*4*1#' )
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            -- اگر کارت تخفیفی وجود نداشته باشید 
            IF NOT EXISTS
            (
                SELECT *
                FROM dbo.Service_Robot_Discount_Card srd
                WHERE srd.SRBT_ROBO_RBID = @Rbid
                      AND srd.CHAT_ID = @ChatID
                      AND srd.VALD_TYPE = '002'
                      AND srd.EXPR_DATE >= GETDATE()
            )
            BEGIN
                SET @Message = N'⚠️ کارت تخفیفی برای شما وجود ندارد';
            END;

            -- موجودی کلی کارت های هدیه
            IF @ChildUssdCode = '*1*4*3*0#'
            BEGIN
                SET @Message
                    = N'*کارت های تخفیف شما*' + CHAR(10) + CHAR(10)
                      +
                      (
                          SELECT REPLACE(N'⏳ {0} روز باقیمانده ••• ', N'{0}', DATEDIFF(DAY, GETDATE(), od.EXPR_DATE))
                                 + od.DISC_CODE
                                 + CASE
                                       WHEN od.OFF_KIND = '002' /* تخفیف گردونه */ THEN
                                           N'💫 تخفیف گردونه شانس سقف مبلغ خرید *'
                                           + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, od.FROM_AMNT), 1), '.00', '')
                                           + N'* ' + @AmntTypeDesc + N' مبلغ تخفیف *'
                                           + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, od.MAX_AMNT_OFF), 1), '.00', '')
                                           + N'* ' + @AmntTypeDesc
                                       WHEN od.OFF_KIND = '001' /* تخفیف عادی */ THEN
                                           N'🔥 تخفیف عادی *' + CAST(od.OFF_PRCT AS VARCHAR(4)) + N'* %'
                                   END AS "text()"
                          FROM dbo.Service_Robot_Discount_Card od
                          WHERE od.CHAT_ID = @ChatID
                                AND od.SRBT_ROBO_RBID = @Rbid
                                AND od.EXPR_DATE >= GETDATE() -- تاریخ همچنان باقی داشته باشد
                                AND od.VALD_TYPE = '002' -- معتبر باشد                  
                          ORDER BY od.EXPR_DATE
                          FOR XML PATH('')
                      ) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                      + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
            END;
            -- لیست تمام کارتهای هدیه معتبر
            ELSE IF @ChildUssdCode = '*1*4*3*1#'
            BEGIN
                SET @Message
                    = N'*کارت های هدیه شما*' + CHAR(10) + CHAR(10)
                      +
                      (
                          SELECT N'💳 میزان اعتبار *'
                                 + REPLACE(
                                              CONVERT(
                                                         NVARCHAR,
                                                         CONVERT(
                                                                    MONEY,
                                                                    ISNULL(srg.BLNC_AMNT_DNRM, 0)
                                                                    - ISNULL(srg.TEMP_AMNT_USE, 0)
                                                                ),
                                                         1
                                                     ),
                                              '.00',
                                              ''
                                          ) + N'* ' + @AmntTypeDesc + CHAR(10)
                          FROM dbo.Service_Robot_Gift_Card srg
                          WHERE srg.SRBT_ROBO_RBID = @Rbid
                                AND srg.CHAT_ID = @ChatID
                                AND srg.VALD_TYPE = '002'
                                AND ISNULL(srg.BLNC_AMNT_DNRM, 0) - ISNULL(srg.TEMP_AMNT_USE, 0) > 0
                          ORDER BY srg.CRET_DATE
                          FOR XML PATH('')
                      ) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                      + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
            END;
        END;
        -- افزایش مبلغ کیف پول نقدینگی
        ELSE IF (
                    @UssdCode = '*1*4*5#'
                    AND @ChildUssdCode = '*1*4*5*1#'
                )
                OR
                (
                    @UssdCode = '*3*0*2#'
                    AND @ChildUssdCode = '*3*0*2*1#'
                )
                OR
                (
                    @UssdCode = '*6*0*3#'
                    AND @ChildUssdCode = '*6*0*3*1#'
                )
        BEGIN
            SELECT @MenuText = N'addamntwlet',
                   @ParamText = N'howinccashwlet',
                   @PostExec = N'lessaddwlet';
            GOTO L$AddAmountWallet;
        END;
        -- افزایش مبلغ کیف پول اعتباری 
        ELSE IF (
                    @UssdCode = '*1*4*5#'
                    AND @ChildUssdCode = '*1*4*5*0#'
                )
                OR
                (
                    @UssdCode = '*3*0*2#'
                    AND @ChildUssdCode = '*3*0*2*0#'
                )
                OR
                (
                    @UssdCode = '*6*0*3#'
                    AND @ChildUssdCode = '*6*0*3*0#'
                )
        BEGIN
            SELECT @MenuText = N'addamntwlet',
                   @ParamText = N'howinccreditwlet',
                   @PostExec = N'lessaddwlet';
            GOTO L$AddAmountWallet;
        END;
        -- UpMenu  ::= 👤 ورود به حساب کاربری
        -- SubMenu ::= 🙂 پروفایل شما
        -- UssdCod ::= *1#
        -- UssdCod ::= *1*0#
        ELSE IF @UssdCode = '*1#'
                AND @ChildUssdCode = '*1*0#'
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SET @XTemp =
            (
                SELECT @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       '005' AS '@actntype',
                       'Show Profile' AS '@actndesc'
                FOR XML PATH('Service')
            );

            EXEC dbo.SAVE_SRBT_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)');
            -- Successfull
            IF @RsltCode = '002'
            BEGIN
                SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
                SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
            END;
        END;
        -- UpMenu  ::= 👥 مجموعه فروش
        -- SubMenu ::= 🔢 تعداد نفرات
        -- UssdCod ::= *1*10#
        -- UssdCod ::= *1*10*0# 
        ELSE IF @UssdCode = '*1*10#'
                AND @ChildUssdCode = '*1*10*0#'
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SET @XTemp =
            (
                SELECT @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       '006' AS '@actntype',
                       'Show Sub Chatids' AS '@actndesc'
                FOR XML PATH('Service')
            );

            EXEC dbo.SAVE_SRBT_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)');
            -- Successfull
            IF @RsltCode = '002'
            BEGIN
                SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
                SELECT @Message += CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
            END;
        END;
        -- UpMenu  ::= 👥 مجموعه فروش
        -- SubMenu ::= 📊 پروفایل مجموعه
        -- UssdCod ::= *1*10#
        -- UssdCod ::= *1*10*1# 
        ELSE IF @UssdCode = '*1*10#'
                AND @ChildUssdCode = '*1*10*1#'
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            SET @XTemp =
            (
                SELECT @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       '007' AS '@actntype',
                       'Show Sub Chatids' AS '@actndesc'
                FOR XML PATH('Service')
            );

            EXEC dbo.SAVE_SRBT_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)');
            -- Successfull
            IF @RsltCode = '002'
            BEGIN
                SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
                SELECT @Message += CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
            END;
        END;
        -- ده فروشنده برتر
        ELSE IF @UssdCode = '*1*10#'
                AND @ChildUssdCode = '*1*10*2#'
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;

            IF NOT EXISTS
            (
                SELECT *
                FROM dbo.Service_Robot sr
                WHERE sr.ROBO_RBID = @Rbid
                      AND sr.REF_CHAT_ID = @ChatID
            )
            BEGIN
                SET @Message = N'شما مجموعه فروشی ندارید';
                GOTO L$EndSP;
            END;
            ELSE IF NOT EXISTS
                 (
                     SELECT *
                     FROM dbo.Service_Robot sr,
                          dbo.[Order] o
                     WHERE sr.ROBO_RBID = @Rbid
                           AND sr.REF_CHAT_ID = @ChatID
                           AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                           AND sr.CHAT_ID = o.CHAT_ID
                           AND o.ORDR_TYPE = '004'
                           AND o.ORDR_STAT IN ( '004', '009' )
                 )
            BEGIN
                SET @Message = N'مجموعه فروش شما تا به حال خریدی نداشته اند';
                GOTO L$EndSP;
            END;

            SET @Message
                = N'*فروش مجموعه شما*' + CHAR(10) + CHAR(10)
                  +
                  (
                      SELECT TOP 10
                             N'*' + o.OWNR_NAME + N'* با جمع فروش *'
                             + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, SUM(o.SUM_EXPN_AMNT_DNRM)), 1), '.00', '') + N'* '
                             + @AmntTypeDesc + CHAR(10)
                      FROM dbo.Service_Robot sr,
                           dbo.[Order] o
                      WHERE sr.ROBO_RBID = @Rbid
                            AND sr.REF_CHAT_ID = @ChatID
                            AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                            AND sr.CHAT_ID = o.CHAT_ID
                            AND o.ORDR_TYPE = '004'
                            AND o.ORDR_STAT IN ( '004', '009' )
                      GROUP BY o.OWNR_NAME,
                               sr.CHAT_ID
                      ORDER BY SUM(o.SUM_EXPN_AMNT_DNRM)
                      FOR XML PATH('')
                  ) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                  + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
        END;
        -- منوی ارسال پیام
        -- پیامهای دریافتی
        ELSE IF @UssdCode = '*1*11#' AND @ChildUssdCode = '*1*11*0#'
        BEGIN
           L$ReceiveMessage:
           -- آیا مشتری درون سیستم ثبت شده است یا خیر
           IF NOT EXISTS
           (
               SELECT *
               FROM iScsc.dbo.Fighter
               WHERE CHAT_ID_DNRM = @ChatID
           )
           BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
           END;
           
           -- در این قسمت گزینه ای باید به مشتری نمایش داده شود منوط به اینکه چه پیام هایی دارد که بخواد ببینید
           -- پیام های جدید
           -- پیام های خوانده شده
           -- پیام های مدیر فروشگاه
           -- پیام های پشتیبان نرم افزار
           -- پیام های مدیر مجموعه
           -- پیام های تبلیغاتی
           SET @XTemp =
           (
              SELECT @Rbid AS '@rbid',
                     @ChatID AS '@chatid',
                     @UssdCode AS '@ussdcode',
                     'lessrecvmesg' AS '@cmndtext'
              FOR XML PATH('RequestInLineQuery')
           );
           EXEC dbo.CRET_ILQM_P @X = @XTemp, @XRet = @XTemp OUTPUT;
           
           SET @Message = N'📥 پیام های دریافتی صندوق پستی شما';
           SET @XTemp =
           (
              SELECT '1' AS '@order',
                     @Message AS '@caption',
                     @XTemp
              FOR XML PATH('InlineKeyboardMarkup')
           );
           SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
           GOTO L$EndSP;
        END 
        -- ارسال پیام
        -- ارسال به واحد مدیریت فروشگاه
        -- ارسال پیام به واحد پشتیبانی نرم افزاری فروشگاه
        -- نمایش منوی اولیه
        ELSE IF (@UssdCode = '*1*11*1#' AND @ChildUssdCode IN ( '*1*11*1*0#' /* Manager Shop */,  '*1*11*1*1#' /* Software Team */, '*1*11*1*3#' /* Advertising */, '*1*11*1*4#' /* Advertising Campaign */ ))
        BEGIN
           L$SendMessage:
           -- آیا مشتری درون سیستم ثبت شده است یا خیر
           IF NOT EXISTS
           (
               SELECT *
               FROM iScsc.dbo.Fighter
               WHERE CHAT_ID_DNRM = @ChatID
           )
           BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
           END;
           
           SELECT @QueryStatement = 
                  CASE @ChildUssdCode
                       WHEN '*1*11*1*0#' THEN 'lesssendmailmngrshop'
                       WHEN '*1*11*1*1#' THEN 'lesssendmailsoftteam'
                       WHEN '*1*11*1*3#' THEN 'lesssendmailadvteam'
                       WHEN '*1*11*1*4#' THEN 'lesssendmailadvcamp'
                  END;
           -- منوهای اولیه ای که برای مدیریت باید ارسال شود را آماده میکنیم
           SET @XTemp =
           (
               SELECT @Rbid AS '@rbid',
                      @ChatID AS '@chatid',
                      @ChildUssdCode AS '@ussdcode',
                      @QueryStatement AS '@cmndtext'
               FOR XML PATH('RequestInLineQuery')
           );
           EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                @XRet = @XTemp OUTPUT; -- xml

           SET @XTemp =
           (
               SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
           );
           
           SET @Message = 
              CASE @ChildUssdCode 
                   WHEN '*1*11*1*0#' THEN N'👨‍💼 ارسال پیام به مدیریت فروشگاه' 
                   WHEN '*1*11*1*1#' THEN N'👨‍💼 ارسال پیام به مدیریت واحد پشتیبانی فروشگاه' 
                   WHEN '*1*11*1*3#' THEN N'👨‍💼 ارسال پیام به مدیریت واحد تبلیغات فروشگاه' 
                   WHEN '*1*11*1*4#' THEN N'👨‍💼 ارسال پیام به واحد کمپین تبلیغات فروشگاه' 
              END + CHAR(10) + CHAR(10) + 
              CASE @ChildUssdCode 
                   WHEN '*1*11*1*0#' THEN                    
                      N'نظرات، پيشنهادات و انتقادات ارزشمند شما کاربران گرامی در هر بخش از فعاليت های فروشگاه، ما را در شناسایی نقاط قوت و ضعف خدمات و محصولات یاری خواهد رساند.' + CHAR(10) + 
                      N'همچنين هرگونه پیشنهاد یا انتقاد در رابطه با عملكرد كارمندان، توسط مديران ارشد و مديریت عامل بررسي مي شود تا در تصمیم گیری های خرد و کلان فروشگاه لحاظ گردند.' + CHAR(10)
                   WHEN '*1*11*1*1#' THEN 
                      N'نظرات، پيشنهادات و انتقادات ارزشمند شما کاربران گرامی در هر بخش از فعاليت های فروشگاه، ما را در شناسایی نقاط قوت و ضعف خدمات و محصولات یاری خواهد رساند.' + CHAR(10) + 
                      N'همچنين هرگونه پیشنهاد یا انتقاد در رابطه با عملكرد نرم افزار، توسط تیم پشتیبانی نرم افزار بررسي مي شود تا در بهتر کردن قابلیت های نرم افزار فروشگاه لحاظ گردند.' + CHAR(10)
                   WHEN '*1*11*1*3#' THEN 
                      N'تبلیغات در اصطلاح یعنی پیامی که به مخاطب می‌رسانید تا توجهش را به ایده، محصول، خدمت یا شرکتتان جلب کنید. این پیام در واقع یک فراخوان یا call to action عمومی است که قرار است در چند دقیقه (یا حتی چند ثانیه) ما را مجاب کند که با این محصول تجربه بهتری خواهیم داشت.' + CHAR(10) + 
                      N'فقط با این تفاوت که همه در درآمدهای تبلیغاتی شریک هستن حتی مشتری' + CHAR(10)
                   WHEN '*1*11*1*4#' THEN 
                      N'کمپین تبلیغاتی مجموعه‌ای از فعالیت‌های تبلیغاتی چندجانبه است که قبل از هر چیز پیام هدف کمپین مشخص شده، مخاطب تعیین شده و با برنامه‌ریزی دقیق، بکوشد پیام مناسب در دوره زمانی مناسب با بودجه مناسب برای مخاطب مناسب ارسال شده و تعداد بیشتری از مخاطبان را برای نزدیک تر کردن ارتباط با مالک کمپین، ترغیب نماید. کمپین تبلیغاتی بدون تعریف معیار عددی مشخص برای سنجش کارایی، بی معنی است.' + CHAR(10)
              END + CHAR(10) +
              CASE @ChildUssdCode 
                   WHEN '*1*11*1*0#' THEN N'با تشکر مدیریت فروشگاه'
                   WHEN '*1*11*1*1#' THEN N'با تشکر مدیریت واحد پشتیبانی فروشگاه'
                   WHEN '*1*11*1*3#' THEN N'با تشکر مدیریت واحد تبلیغات فروشگاه'
                   WHEN '*1*11*1*4#' THEN N'با تشکر واحد کمپین تبلیغات فروشگاه'
              END;

           SET @XMessage =
           (
               SELECT TOP 1
                      om.FILE_ID AS '@fileid',
                      om.IMAG_TYPE AS '@filetype',
                      @Message AS '@caption',
                      1 AS '@order'
               FROM dbo.Organ_Media om
               WHERE om.ROBO_RBID = @Rbid
                     AND om.RBCN_TYPE = '024'
                     AND om.IMAG_TYPE = '002'
                     AND om.STAT = '002'
               FOR XML PATH('Complex_InLineKeyboardMarkup')
           );
           SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

           SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
           GOTO L$EndSP;
        END 
        -- ارسال پیام به واحد مدیریت فروشگاه
        -- ارسال پیام به واحد پشتیبانی نرم افزاری فروشگاه
        -- ثبت پیام جدید
        ELSE IF @UssdCode IN ( '*1*11*1*0#' /* واحد مدیریت فروشگاه */, '*1*11*1*1#' /* واحد پشتیبانی نرم افزار فروشگاه */, '*1*11*1*3#' /* واحد تبلیغات فروشگاه */)
        BEGIN
           -- آیا مشتری درون سیستم ثبت شده است یا خیر
           IF NOT EXISTS
           (
               SELECT *
               FROM iScsc.dbo.Fighter
               WHERE CHAT_ID_DNRM = @ChatID
           )
           BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
           END;
           
           -- در این قسمت مشخص میکنیم که چه عنوان پیام ارسال شده
           -- ابتدا بررسی میکنیم که چه کسانی مدیریت هستند
           SET @Said = dbo.GNRT_NVID_U();
           INSERT INTO dbo.Service_Robot_Replay_Message ( SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,RWNO ,MESG_TEXT ,FILE_ID ,MESG_TYPE ,WHO_SEND, SNDR_CHAT_ID, HEDR_CODE, HEDR_TYPE )
           SELECT sr.SERV_FILE_NO, sr.ROBO_RBID, dbo.GNRT_NVID_U(), @MenuText,  
                  CASE @ElmnType 
                       WHEN '002' THEN @PhotoFileId
                       WHEN '003' THEN @VideoFileId
                       WHEN '004' THEN @DocumentFileId
                       WHEN '006' THEN @AudioFileId
                       ELSE NULL
                  END,
                  @ElmnType, '005' , @ChatID, @Said, 
                  CASE @UssdCode 
                       WHEN '*1*11*1*0#' THEN '001' 
                       WHEN '*1*11*1*1#' THEN '003' 
                       WHEN '*1*11*1*3#' THEN '006' 
                  END 
             FROM dbo.Service_Robot sr, dbo.Service_Robot_Group sg
            WHERE sr.SERV_FILE_NO = sg.SRBT_SERV_FILE_NO
              AND sr.ROBO_RBID = sg.SRBT_ROBO_RBID
              AND sr.ROBO_RBID = @Rbid
              AND sg.GROP_GPID = CASE @UssdCode 
                                      WHEN '*1*11*1*0#' THEN 131 -- گروه مدیران فروشگاه 
                                      WHEN '*1*11*1*1#' THEN 135 -- گروه مدیران پشتیبانی نرم افزار فروشگاه 
                                      WHEN '*1*11*1*3#' THEN 131 -- گروه مدیران تبلیغات فروشگاه 
                                 END 
              AND sg.STAT = '002';
            
            -- بدست آوردن کد مدیر فروشگاه
	         SELECT TOP 1 
	                @Said = sr.CHAT_ID
	           FROM dbo.Service_Robot sr, dbo.Service_Robot_Group sg
	          WHERE sr.SERV_FILE_NO = sg.SRBT_SERV_FILE_NO
	            AND sr.ROBO_RBID = sg.SRBT_ROBO_RBID
	            AND sr.ROBO_RBID = @Rbid
	            AND sg.GROP_GPID = CASE @UssdCode 
                                      WHEN '*1*11*1*0#' THEN 131 -- گروه مدیران فروشگاه 
                                      WHEN '*1*11*1*1#' THEN 135 -- گروه مدیران پشتیبانی نرم افزار فروشگاه 
                                      WHEN '*1*11*1*3#' THEN 131 -- گروه مدیران تبلیغات فروشگاه 
                                  END 
	            AND sg.STAT = '002';
            
            -- اگر تعداد پیام های ارسالی فقط یکی باشد منوهایی برای مشتری نمایش داده میشود که متعلق به همان پیام ارسالی میباشد به مشتری نشان میدهیم
            IF (SELECT COUNT(DISTINCT a.HEDR_CODE) 
                  FROM dbo.Service_Robot_Replay_Message a 
                 WHERE a.SRBT_ROBO_RBID = @Rbid 
                   AND a.SNDR_CHAT_ID = @ChatID 
                   AND a.CHAT_ID = @Said 
                   AND a.SEND_STAT = '002' 
                   AND a.WHO_SEND = '005' 
                   AND a.HEDR_TYPE = CASE @UssdCode WHEN '*1*11*1*0#' THEN '001' WHEN '*1*11*1*1#' THEN '003' WHEN '*1*11*1*3#' THEN '006' END ) = 1
            BEGIN
               SET @QueryStatement = 
                  CASE @UssdCode 
                       WHEN '*1*11*1*0#' THEN 'lesssend1msgmngrshop'
                       WHEN '*1*11*1*1#' THEN 'lesssend1msgsoftteam'
                       WHEN '*1*11*1*3#' THEN 'lesssend1msgadvteam'
                  END;
               -- GOTO Show New Message For Ready To Send
               -- منوهای اولیه ای که برای مدیریت باید ارسال شود را آماده میکنیم
               SET @XTemp =
               (
                   SELECT @Rbid AS '@rbid',
                          @ChatID AS '@chatid',
                          @UssdCode AS '@ussdcode',
                          @QueryStatement AS '@cmndtext'                          
                   FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml
  
               SET @XTemp =
               (
                   SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
               );
               
               -- نمایش متن ارسال شده
               SELECT @Message = a.MESG_TEXT
                 FROM dbo.Service_Robot_Replay_Message a 
                WHERE a.SRBT_ROBO_RBID = @Rbid 
                  AND a.SNDR_CHAT_ID = @ChatID 
                  AND a.CHAT_ID = @Said 
                  AND a.SEND_STAT = '002'
                  AND a.WHO_SEND = '005'
                  AND a.HEDR_TYPE = CASE @UssdCode WHEN '*1*11*1*0#' THEN '001' WHEN '*1*11*1*1#' THEN '003' WHEN '*1*11*1*3#' THEN '006' END ;
  
               SET @XMessage =
               (
                   SELECT TOP 1
                          om.FILE_ID AS '@fileid',
                          om.IMAG_TYPE AS '@filetype',
                          @Message AS '@caption',
                          1 AS '@order'
                     FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                      AND om.RBCN_TYPE = '024'
                      AND om.IMAG_TYPE = '002'
                      AND om.STAT = '002'
                      FOR XML PATH('Complex_InLineKeyboardMarkup')
               );
               SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
            END 
            ELSE
            BEGIN
               -- Goto Show All Message For Ready To Send
               PRINT 'Hi There Else'
            END 
            
            SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            GOTO L$EndSP;
        END
        ELSE IF @UssdCode IN ( '*1*11*1*4#' /* واحد کمپین تبلیغاتی */)
        BEGIN
            -- آیا مشتری درون سیستم ثبت شده است یا خیر
           IF NOT EXISTS
           (
               SELECT *
               FROM iScsc.dbo.Fighter
               WHERE CHAT_ID_DNRM = @ChatID
           )
           BEGIN
                SET @Message
                    = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessreguser' AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
           END;
           
           -- ثبت درخواست کمپین تبلیغاتی
           SET @XTemp = (
               SELECT 12 AS '@subsys',
                      '027' AS '@ordrtype',
                      '000' AS '@typecode', 
                      @ChatId AS '@chatid',
                      @Rbid AS '@rbid',
                      0 AS '@ordrcode'
                  FOR XML PATH('Action')
           );
           EXEC dbo.SAVE_EXTO_P @X = @XTemp, -- xml
                                @xRet = @XTemp OUTPUT; -- xml
            
           SELECT @RsltCode = @XTemp.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)');
           IF @RsltCode = '002'
           BEGIN
               SELECT @OrdrCode = @XTemp.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');
               
               INSERT INTO dbo.Order_Detail ( ORDR_CODE ,ELMN_TYPE ,ORDR_DESC ,TARF_CODE )
               SELECT @OrdrCode, '001', rp.TARF_TEXT_DNRM, rp.TARF_CODE
                 FROM dbo.Robot_Product rp, dbo.SplitString(@MenuText, ',') a
                WHERE rp.ROBO_RBID = @Rbid
                  AND rp.TARF_CODE = a.Item
                  AND NOT EXISTS (
                          SELECT *
                            FROM dbo.Order_Detail od
                           WHERE od.ORDR_CODE = @OrdrCode
                             AND od.TARF_CODE = rp.TARF_CODE
                      );
               
               -- ایجاد خروجی برای نمایش درخواست ثبت شده برای محصول ارسالی
               -- منوهای اولیه ای که برای مدیریت باید ارسال شود را آماده میکنیم
               SET @XTemp =
               (
                  SELECT @Rbid AS '@rbid',
                         @ChatID AS '@chatid',
                         @UssdCode AS '@ussdcode',
                         'lessordradvcamp' AS '@cmndtext',
                         @OrdrCode AS '@ordrcode'
                  FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml

               SET @XTemp =
               (
                  SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
               );
               
               SET @Message = (
                   SELECT N'🟤 شماره درخواست [ *' + CAST(o.CODE AS VARCHAR(30)) + N'* ] ' + o.ORDR_TYPE + CHAR(10) + CHAR(10) +
                          N'*اقلام کمپین تبیلغاتی*' + CHAR(10) + CHAR(10) +
                          (
                             SELECT N'👈 [ *' + rp.TARF_CODE + N'* ] '+ rp.TARF_TEXT_DNRM + CHAR(10)
                               FROM dbo.Order_Detail od, dbo.Robot_Product rp
                              WHERE od.ORDR_CODE = o.CODE
                                AND od.TARF_CODE = rp.TARF_CODE
                                FOR XML PATH('')
                          )
                     FROM dbo.[Order] o
                    WHERE o.CODE = @OrdrCode
               );
               
               SET @XMessage =
               (
                  SELECT TOP 1
                         om.FILE_ID AS '@fileid',
                         om.IMAG_TYPE AS '@filetype',
                         @Message AS '@caption',
                         1 AS '@order'
                  FROM dbo.Organ_Media om
                  WHERE om.ROBO_RBID = @Rbid
                        AND om.RBCN_TYPE = '024'
                        AND om.IMAG_TYPE = '002'
                        AND om.STAT = '002'
                  FOR XML PATH('Complex_InLineKeyboardMarkup')
               );
               SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               GOTO L$EndSP;
           END 
        END 
        -- درخواست همکاری
        -- تامین کننده / همکار فروش
        ELSE IF @UssdCode = '*1*12#' AND @ChildUssdCode = '*1*12*0#'
        BEGIN
            -- در این قسمت مشتری درخواست همکاری تامین کننده خود را وارد میکند و یه پیام به واحد بازرگانی فروشگاه ارسال میشود            
            IF NOT EXISTS (SELECT * FROM dbo.Service_Robot_Seller s WHERE s.SRBT_ROBO_RBID = @Rbid AND s.CHAT_ID = @ChatID)
            BEGIN 
               SET @XTemp =
               (
                   SELECT @Rbid AS '@rbid',
                          @ChatID AS 'Order/@chatid',
                          '012' AS 'Order/@type',
                          'acptsupl' AS 'Order/@oprt'
                   FOR XML PATH('Robot')
               );

               EXEC dbo.SEND_MEOJ_P @X = @XTemp, @XRet = @XTemp OUTPUT;
               SET @Message = (
                   SELECT N'*' + sr.NAME + N'* عزیز' + CHAR(10) + 
                          N'درخواست شما برای واحد مربوطه ارسال شد، لطفا تا پاسخگویی همکاران ما منتظر بمانید' + CHAR(10) + 
                          N'با تشکر از شما'
                     FROM dbo.Service_Robot sr
                    WHERE sr.ROBO_RBID = @Rbid
                      AND sr.CHAT_ID = @ChatID
               );
            END 
            ELSE
               SET @Message = N'✅ درخواست شما قبلا ثبت شده';
        END 
        -- ]
        -- Menu ::= 👤 ورود به حساب کاربری
        -- Ussd ::= *1#

        -- Menu ::= امور فروشندگان
        -- Ussd ::= *6*0*1#
        -- SubMenu ::= 💶 پورسانت بازاریابان
        ELSE IF @UssdCode = '*6*0*1*0#'
        BEGIN
            IF ISNUMERIC(@MenuText) = 0
            BEGIN
                SET @Message = N'داده ورودی باید به صورت عددی باشد، لطفا در ورود اطلاعات خود دقت فرمایید';
                GOTO L$EndSP;
            END;

            IF CONVERT(REAL, @MenuText) NOT
               BETWEEN 0 AND 100
            BEGIN
                SET @Message = N'داده ورودی باید در بازه 0% تا 100% باشد، لطفا در ورود اطلاعات خود دقت فرمایید';
                GOTO L$EndSP;
            END;

            UPDATE dbo.Transaction_Fee
            SET TXFE_PRCT = CONVERT(REAL, @MenuText)
            WHERE TXFE_TYPE IN ( '003', '004' )
                  AND STAT = '002';

            SET @Message =
            (
                SELECT CASE tf.TXFE_PRCT
                           WHEN 0 THEN
                               N'فروشنده گرامی، فروشگاه شما *بدون پورسانت بازاریابی* به کار فروش اجناس خود انجام میدهد.'
                               + CHAR(10)
                               + N'⚠️ فروشنده عزیز امروزه سیستم فروش حرفه ای به اینصورت می باشد که شما بتوانید افراد و بازاریابانی برای خود ایجاد کنید که بتوانند کار فروش و معرفی فروشگاه شما را انجام دهند'
                           ELSE
                               N'فروشنده گرامی، فروشگاه شما با محاسبه پورسانت *' + CAST(tf.TXFE_PRCT AS NVARCHAR(10))
                               + N'* % برای بازاریابان شما در نظر گرفته شده که این پورسانت به صورت *'
                               + CASE tf.TXFE_TYPE
                                     WHEN '003' THEN
                                         N'اعتباری'
                                     WHEN '004' THEN
                                         N'نقدینگی'
                                 END + N'* برای آنها در نظر گرفته میشود.'
                       END
                FROM dbo.Transaction_Fee tf
                WHERE tf.TXFE_TYPE IN ( '003', '004' )
                      AND tf.STAT = '002'
            );
        END;
        -- SubMenu ::= نوع پورسانت
        -- پورسانت اعتباری / نقدینگی
        ELSE IF @UssdCode IN ( '*6*0*1*1#', '*6*0*1*1#' )
                AND @ChildUssdCode IN ( '*6*0*1*1*0#', '*6*0*1*1*1#' )
        BEGIN
            UPDATE dbo.Transaction_Fee
            SET STAT = '001'
            WHERE TXFE_TYPE IN ( '003', '004' )
                  AND STAT = '002';

            UPDATE dbo.Transaction_Fee
            SET STAT = '002'
            WHERE TXFE_TYPE IN ( '003', '004' )
                  AND STAT = '001'
                  AND TXFE_TYPE = CASE @ChildUssdCode
                                      WHEN '*6*0*1*1*0#' THEN
                                          '003'
                                      WHEN '*6*0*1*1*1#' THEN
                                          '004'
                                  END;
            SET @Message =
            (
                SELECT CASE tf.TXFE_PRCT
                           WHEN 0 THEN
                               N'فروشنده گرامی، فروشگاه شما *بدون پورسانت بازاریابی* به کار فروش اجناس خود انجام میدهد.'
                               + CHAR(10)
                               + N'⚠️ فروشنده عزیز امروزه سیستم فروش حرفه ای به اینصورت می باشد که شما بتوانید افراد و بازاریابانی برای خود ایجاد کنید که بتوانند کار فروش و معرفی فروشگاه شما را انجام دهند'
                           ELSE
                               N'فروشنده گرامی، فروشگاه شما با محاسبه پورسانت *' + CAST(tf.TXFE_PRCT AS NVARCHAR(10))
                               + N'* % برای بازاریابان شما در نظر گرفته شده که این پورسانت به صورت *'
                               + CASE tf.TXFE_TYPE
                                     WHEN '003' THEN
                                         N'اعتباری'
                                     WHEN '004' THEN
                                         N'نقدینگی'
                                 END + N'* برای آنها در نظر گرفته میشود.'
                       END
                FROM dbo.Transaction_Fee tf
                WHERE tf.TXFE_TYPE IN ( '003', '004' )
                      AND tf.STAT = '002'
            );
        END;
        -- 🕰️ مدت زمان واریز پورسانت
        ELSE IF @UssdCode = '*6*0*1*2#'
        BEGIN
            IF ISNUMERIC(@MenuText) = 0
            BEGIN
                SET @Message = N'داده ورودی باید به صورت عددی باشد، لطفا در ورود اطلاعات خود دقت فرمایید';
                GOTO L$EndSP;
            END;

            --IF CONVERT(BIGINT, @MenuText) < CASE @AmntType WHEN '001' THEN 100000 WHEN '002' THEN 10000 END
            --BEGIN
            --   SET @Message = N'مبلغ برداشت باید از 10 هزار تومان شروع شود';
            --   GOTO L$EndSP;
            --END 

            UPDATE dbo.Robot
            SET CONF_DURT_DAY = CONVERT(INT, @MenuText)
            WHERE RBID = @Rbid;

            SET @Message =
            (
                SELECT N'مدت زمان واریز پورسانت *' + dbo.GET_NTOS_U(r.CONF_DURT_DAY) + N'* روز تنظیم شد'
                FROM dbo.Robot r
                WHERE r.RBID = @Rbid
            );
        END;
        -- حداقل مبلغ برداشت
        ELSE IF @UssdCode = '*6*0*1*3#'
        BEGIN
            IF ISNUMERIC(@MenuText) = 0
            BEGIN
                SET @Message = N'داده ورودی باید به صورت عددی باشد، لطفا در ورود اطلاعات خود دقت فرمایید';
                GOTO L$EndSP;
            END;

            --IF CONVERT(BIGINT, @MenuText) < CASE @AmntType WHEN '001' THEN 100000 WHEN '002' THEN 10000 END
            --BEGIN
            --   SET @Message = N'مبلغ برداشت باید از 10 هزار تومان شروع شود';
            --   GOTO L$EndSP;
            --END 

            UPDATE dbo.Robot
            SET MIN_WITH_DRAW = CONVERT(BIGINT, @MenuText)
            WHERE RBID = @Rbid;

            SET @Message =
            (
                SELECT N'حداقل مبلغ برداشت *'
                       + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, r.MIN_WITH_DRAW), 1), '.00', '') + N'* تنظیم شد'
                FROM dbo.Robot r
                WHERE r.RBID = @Rbid
            );
        END;
        -- Menu ::= مدیریت محصولات توسط مدیر فروشگاه
        -- تعریف کالا
        ELSE IF @UssdCode = '*6*1*0#'
        BEGIN
            IF @MenuText = '*'
            BEGIN
                SET @Message =
                (
                    SELECT N'( *' + dbo.GET_LPAD_U(rp.TARF_CODE, 5, ' ') + N'* ) ' + rp.TARF_TEXT_DNRM + CHAR(10)
                    FROM dbo.Robot_Product rp
                    WHERE rp.ROBO_RBID = @Rbid
                    ORDER BY CONVERT(BIGINT, rp.TARF_CODE)
                    FOR XML PATH('')
                );
                GOTO L$EndSP;
            END;
            IF @MenuText LIKE N'%#%'
            BEGIN
                SELECT @TarfTextDnrm = CASE id
                                           WHEN 1 THEN
                                               Item
                                           ELSE
                                               @TarfTextDnrm
                                       END,
                       @TarfCode = CASE id
                                       WHEN 2 THEN
                                           Item
                                       ELSE
                                           @TarfCode
                                   END
                FROM dbo.SplitString(@MenuText, '#');
            END;
            ELSE
            BEGIN
                SELECT @TarfTextDnrm = @MenuText,
                       @TarfCode = 0;
            END;

            IF EXISTS
            (
                SELECT *
                FROM dbo.Robot_Product rp
                WHERE rp.TARF_TEXT_DNRM = @TarfTextDnrm
                      OR rp.TARF_CODE = @TarfCode
            )
            BEGIN
                SET @Message = N'کالا ورودی قبلا درون سیستم ثبت شده است';
                GOTO L$EndSP;
            END;

            SET @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '103' AS '@cmndcode',        -- عملیات جامع ذخیره سازی
                       12 AS '@refsubsys',          -- محل ارجاعی
                       'appuser' AS '@execaslogin', -- توسط کدام کاربری اجرا شود               
                       @TarfTextDnrm AS '@tarfname',
                       @TarfCode AS '@tarfcode'
                FOR XML PATH('Router_Command')
            );
            EXEC dbo.RouterdbCommand @X = @XTemp,           -- xml
                                     @xRet = @XTemp OUTPUT; -- xml

            IF @XTemp.query('//Router_Command').value('(Router_Command/@rsltcode)[1]', 'VARCHAR(3)') = '002'
            BEGIN
                SET @Message = N'اطلاعات محصول شما با موفقیت درون سیستم ثبت شد';
                EXEC dbo.EXEC_JOBS_P @X = NULL; -- xml

                -- اگر فروشنده ای وجود نداشته باشد
                IF NOT EXISTS
                (
                    SELECT *
                    FROM dbo.Service_Robot sr,
                         dbo.Service_Robot_Seller s
                    WHERE sr.ROBO_RBID = s.SRBT_ROBO_RBID
                          AND sr.SERV_FILE_NO = s.SRBT_SERV_FILE_NO
                          AND sr.ROBO_RBID = @Rbid
                )
                BEGIN
                    IF EXISTS
                    (
                        SELECT *
                        FROM dbo.[Group] g,
                             dbo.Service_Robot_Group srg
                        WHERE g.ROBO_RBID = @Rbid
                              AND g.GPID = 131
                              AND g.GPID = srg.GROP_GPID
                              AND g.ROBO_RBID = srg.SRBT_ROBO_RBID
                    )
                    BEGIN
                        -- دسترسی مدیر فروشگاه مشخص شده
                        SELECT TOP 1
                               @ServFileNo = srg.SRBT_SERV_FILE_NO
                        FROM dbo.[Group] g,
                             dbo.Service_Robot_Group srg
                        WHERE g.ROBO_RBID = @Rbid
                              AND g.GPID = 131
                              AND g.GPID = srg.GROP_GPID
                              AND g.ROBO_RBID = srg.SRBT_ROBO_RBID;
                        -- حال در مرحله بعدی مشخص میکنیم که آیا رکورد مدیر فروشگاه ثبت شده یا خیر
                        INSERT INTO dbo.Service_Robot_Seller
                        (
                            SRBT_SERV_FILE_NO,
                            SRBT_ROBO_RBID,
                            CODE,
                            CONF_STAT,
                            CONF_DATE
                        )
                        SELECT sr.SERV_FILE_NO,
                               sr.ROBO_RBID,
                               dbo.GNRT_NVID_U(),
                               '002',
                               GETDATE()
                        FROM dbo.Service_Robot sr
                        WHERE sr.SERV_FILE_NO = @ServFileNo
                              AND sr.ROBO_RBID = @Rbid;
                    END;
                    ELSE
                    BEGIN
                        RAISERROR(N'مدیر فروشگاه مشخص نشده', 16, 1);
                    END;
                END;

                -- بدست آوردن اطلاعات مربوط به مدیر فروشگاه
                SELECT @Said = CODE
                FROM dbo.Service_Robot_Seller
                WHERE SRBT_ROBO_RBID = @Rbid;

                SELECT @TarfCode = TARF_CODE
                  FROM dbo.Robot_Product
                 where ROBO_RBID = @Rbid 
                   AND TARF_TEXT_DNRM = @TarfTextDnrm;

                INSERT INTO dbo.Service_Robot_Seller_Product
                (
                    SRBS_CODE,
                    CODE,
                    TARF_CODE
                )
                VALUES
                (@Said, dbo.GNRT_NVID_U(), @TarfCode);

                GOTO L$EndSP;
            END;
        END;
        -- اعلام وضعیت کالا ها
        ELSE IF @UssdCode = '*6*1*1#'
        BEGIN
            SELECT @QueryStatement = CASE id
                                         WHEN 1 THEN
                                             Item
                                         ELSE
                                             @QueryStatement
                                     END,
                   @ParamText = CASE id
                                    WHEN 2 THEN
                                        Item
                                    ELSE
                                        @ParamText
                                END
            FROM dbo.SplitString(@MenuText, ':');

            IF LOWER(@QueryStatement) IN ( 'on', 'off' )
            BEGIN
                UPDATE rp
                SET rp.STAT = CASE LOWER(@QueryStatement)
                                  WHEN 'on' THEN
                                      '002'
                                  WHEN 'off' THEN
                                      '001'
                              END
                FROM dbo.Robot_Product rp,
                     dbo.SplitString(@ParamText, ',') p
                WHERE rp.ROBO_RBID = @Rbid
                      AND rp.TARF_CODE = p.Item;

                SET @Message
                    = N'بروزرسانی جدول محصولات با موفقیت انجام شده' + CHAR(10) + N'تعداد رکوردهای تغییر یافته : '
                      + CAST(@@ROWCOUNT AS VARCHAR(10)) + N' رکورد';
            END;
            ELSE
            BEGIN
                SET @Message = N'دستور وارد شده درست نمیباشد، لطفا طبق متن راهنما اطلاعات را وارد کنید';
            END;
        END;
        -- توضیحات و ویژگی های محصول
        ELSE IF @UssdCode = '*6*1*2#'
        BEGIN
            SELECT @TarfCode = CASE id
                                   WHEN 1 THEN
                                       Item
                                   ELSE
                                       @TarfCode
                               END,
                   @QueryStatement = CASE id
                                         WHEN 2 THEN
                                             Item
                                         ELSE
                                             @QueryStatement
                                     END
            FROM dbo.SplitString(@MenuText, ':');

            UPDATE dbo.Robot_Product
            SET PROD_FETR = @QueryStatement
            WHERE ROBO_RBID = @Rbid
                  AND TARF_CODE = @TarfCode;

            IF @@ROWCOUNT >= 1
                SET @Message = N'اطلاعات با موفقیت ثبت و ذخیره شد';
            ELSE
                SET @Message = N'در ثبت اطلاعات مشکلی به وجود آمده لطفا بررسی کنید';
        END;
        -- قرار دادن عکس برای محصولات 
        ELSE IF @UssdCode = '*6*1*3*0#'
        BEGIN
            IF @PhotoFileId IS NOT NULL and LEN(@PhotoFileId) > 0
            BEGIN 
               -- Save Product Image Preview
               INSERT INTO dbo.Robot_Product_Preview
               (
                   RBPR_CODE,
                   CODE,
                   ORDR,
                   FILE_ID,
                   FILE_TYPE,
                   FILE_DESC,
                   STAT
               )
               SELECT rp.CODE,
                      dbo.GNRT_NVID_U(),
                      0,
                      @PhotoFileId,
                      '002',
                      rp.TARF_TEXT_DNRM,
                      '002'
               FROM dbo.Robot_Product rp
               WHERE rp.ROBO_RBID = @Rbid
                     AND rp.TARF_CODE = @MenuText
                     AND NOT EXISTS
               (
                   SELECT *
                   FROM dbo.Robot_Product_Preview rpp
                   WHERE rp.CODE = rpp.RBPR_CODE
                         AND (
                             --rpp.FILE_ID = @FileId OR 
                             (
                                 SELECT Item FROM dbo.SplitString(rpp.FILE_ID, ':') WHERE id = 4
                             ) =
                             (
                                 SELECT Item FROM dbo.SplitString(@PhotoFileId, ':') WHERE id = 4
                             )
                             )
               );

               SET @Message = CASE @@ROWCOUNT
                                  WHEN 0 THEN
                                      N'این عکس قبلا ثبت شده است'
                                  ELSE
                                      N'عکس مورد نظر شما برای محصول *' + @MenuText + N'* قرار گرفت'
                              END;
            END 
            ELSE IF @VideoFileId IS NOT NULL AND LEN(@VideoFileId) > 0
            BEGIN
               -- Save Product Image Preview
               INSERT INTO dbo.Robot_Product_Preview
               (
                   RBPR_CODE,
                   CODE,
                   ORDR,
                   FILE_ID,
                   FILE_TYPE,
                   FILE_DESC,
                   STAT
               )
               SELECT rp.CODE,
                      dbo.GNRT_NVID_U(),
                      0,
                      @VideoFileId,
                      '003',
                      rp.TARF_TEXT_DNRM,
                      '002'
               FROM dbo.Robot_Product rp
               WHERE rp.ROBO_RBID = @Rbid
                     AND rp.TARF_CODE = @MenuText
                     AND NOT EXISTS
               (
                   SELECT *
                   FROM dbo.Robot_Product_Preview rpp
                   WHERE rp.CODE = rpp.RBPR_CODE
                         AND (
                             --rpp.FILE_ID = @FileId OR 
                             (
                                 SELECT Item FROM dbo.SplitString(rpp.FILE_ID, ':') WHERE id = 4
                             ) =
                             (
                                 SELECT Item FROM dbo.SplitString(@VideoFileId, ':') WHERE id = 4
                             )
                             )
               );

               SET @Message = CASE @@ROWCOUNT
                                  WHEN 0 THEN
                                      N'این فایل تصویری قبلا ثبت شده است'
                                  ELSE
                                      N'فایل تصویری مورد نظر شما برای محصول *' + @MenuText + N'* قرار گرفت'
                              END;
            END 
        END;
        -- حذف کردن عکس محصولات
        ELSE IF @UssdCode = '*6*1*3*1#'
        BEGIN
            -- Delete Product Image Preview
            SELECT @TarfCode = CASE id
                                   WHEN 1 THEN
                                       Item
                                   ELSE
                                       @TarfCode
                               END,
                   @ParamText = CASE id
                                    WHEN 2 THEN
                                        Item
                                    ELSE
                                        @ParamText
                                END
            FROM dbo.SplitString(@MenuText, ':');

            IF ISNULL(@ParamText, '') = ''
                DELETE dbo.Robot_Product_Preview
                WHERE TARF_CODE_DNRM = @TarfCode;
            ELSE
                DELETE dbo.Robot_Product_Preview
                WHERE TARF_CODE_DNRM = @TarfCode
                      AND ORDR IN
                          (
                              SELECT Item FROM dbo.SplitString(@ParamText, ',')
                          );
            SET @Message = N'تعداد عکس حذف شده : ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + N' رکورد';
        END;
        -- قیمت گذاری برای محصولات
        ELSE IF @UssdCode = '*6*1*4#'
        BEGIN
            -- Update Product Price
            SELECT @TarfCode = CASE id
                                   WHEN 1 THEN
                                       Item
                                   ELSE
                                       @TarfCode
                               END,
                   @Pric = CASE id
                               WHEN 2 THEN
                                   Item
                               ELSE
                                   @Pric
                           END
            FROM dbo.SplitString(@MenuText, ':');

            IF ISNULL(@Pric, 0) != 0
            BEGIN
                SET @XMessage =
                (
                    SELECT '05' AS '@subsys',
                           '104' AS '@cmndcode',
                           @ChatID AS '@chatid',
                           @Rbid AS '@rbid',
                           @TarfCode AS '@tarfcode',
                           @Pric AS '@tarfpric'
                    FOR XML PATH('Router_Command')
                );
                EXEC dbo.RouterdbCommand @X = @XMessage,           -- xml
                                         @xRet = @XMessage OUTPUT; -- xml

                SET @Message = N'قیمت محصول با موفقیت بروزرسانی شد';
            END;
            ELSE
            BEGIN
                SET @ParamText = @TarfCode;
                GOTO L$InfoProd;
            END;
        END;
        -- ثبت تخفیف ویژه برای محصولات
        ELSE IF @UssdCode = '*6*1*5*0#'
        BEGIN
            IF LOWER(@MenuText) IN ( 'show', '*', 'show active', '*#', 'show new', '*+', 'show deactive', '*$',
                                     'show end', '*-'
                                   )
            BEGIN
                L$ShowOff:
                GOTO L$EndSP;
            END;

            SELECT @OffPrct = CASE id
                                  WHEN 1 THEN
                                      Item
                                  ELSE
                                      @OffPrct
                              END,
                   @ParamText = CASE id
                                    WHEN 2 THEN
                                        Item
                                    ELSE
                                        @ParamText
                                END
            FROM dbo.SplitString(@MenuText, ':');

            IF EXISTS
            (
                SELECT *
                FROM dbo.Robot_Product_Discount rpd,
                     dbo.SplitString(@ParamText, ',') T
                WHERE rpd.ROBO_RBID = @Rbid
                      AND rpd.TARF_CODE = T.Item
                      AND rpd.OFF_TYPE != '002'
                      AND rpd.ACTV_TYPE = '002'
            )
            BEGIN
                SET @Message
                    = N'محصولات انتخابی شما تخفیفات فعال دیگری دارند که شما نمی توانید تخفیف جدیدی برای آنها ثبت کنید، لطفا تخفیفات قبلی را غیرفعال کنید تا بتوانید تخفیف جدید را اعمال کنید'
                      + CHAR(10) + N'برای نمایش تخفیفات می توانید از دستورات زیر استفاده کنید' + CHAR(10)
                      + N'show | ** : ' + N'این گزینه تمامی تخفیفات را نمایش میدهد' + CHAR(10)
                      + N'show active | **# : ' + N'این گزینه تخفیفات فعال را نمایش میدهد' + CHAR(10)
                      + N'show new | **+ : ' + N'این گزینه تخفیفات جدید ثبت شده امروز را نمایش میدهد' + CHAR(10)
                      + N'show deactive | **$ : ' + N'این گزینه تخفیفات غیرفعال را نمایش میدهد' + CHAR(10)
                      + N'show end | **- : ' + N'این گزینه تخفیفاتی که امروز به پایان رسیده اند را نمایش میدهد';
                GOTO L$EndSP;
            END;

            -- اگر کالایی قبلا در جدول قرار گرفته باشد
            UPDATE dbo.Robot_Product_Discount
            SET OFF_PRCT = @OffPrct,
                ACTV_TYPE = CASE @OffPrct
                                WHEN 0 THEN
                                    '001'
                                ELSE
                                    '002'
                            END
            FROM dbo.Robot_Product_Discount rpd,
                 dbo.SplitString(@ParamText, ',') T
            WHERE rpd.ROBO_RBID = @Rbid
                  AND rpd.TARF_CODE = T.Item
                  AND rpd.OFF_TYPE = '002';

            INSERT INTO dbo.Robot_Product_Discount
            (
                ROBO_RBID,
                CODE,
                TARF_CODE,
                OFF_TYPE,
                OFF_PRCT,
                ACTV_TYPE,
                OFF_DESC
            )
            SELECT rp.ROBO_RBID,
                   dbo.GNRT_NVID_U(),
                   rp.TARF_CODE,
                   '002',
                   @OffPrct,
                   CASE @OffPrct
                       WHEN 0 THEN
                           '001'
                       ELSE
                           '002'
                   END,
                   N'تخفیف ویژه'
            FROM dbo.Robot_Product rp,
                 dbo.SplitString(@ParamText, ',') T
            WHERE rp.ROBO_RBID = @Rbid
                  AND rp.TARF_CODE = T.Item
                  AND NOT EXISTS
            (
                SELECT *
                FROM dbo.Robot_Product_Discount rpd
                WHERE rpd.ROBO_RBID = rp.ROBO_RBID
                      AND rpd.TARF_CODE = rp.TARF_CODE
            );

            SET @Message = N'اطلاعات تخفیف برای کالاهای درخواستی ثبت شد';

            IF @OffPrct > 0
            BEGIN
                -- اطلاع رسانی به مشتریانی که برای تخفیف ثبت کرده اند
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS 'Order/@chatid',
                           '012' AS 'Order/@type',
                           @ParamText AS 'Order/@valu',
                           'discount' AS 'Order/@oprt'
                    FOR XML PATH('Robot')
                );

                EXEC dbo.SEND_MEOJ_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml
            END;
        END;
        -- ثبت تخفیف شگفت انگیز برای محصولات
        ELSE IF @UssdCode = '*6*1*5*1#'
        BEGIN
            IF LOWER(@MenuText) IN ( 'show', '*', 'show active', '*#', 'show new', '*+', 'show deactive', '*$',
                                     'show end', '*-'
                                   )
            BEGIN
                GOTO L$ShowOff;
            END;

            SELECT @OffPrct = CASE id
                                  WHEN 1 THEN
                                      Item
                                  ELSE
                                      @OffPrct
                              END,
                   @Said = CASE id
                               WHEN 2 THEN
                                   Item
                               ELSE
                                   @Said
                           END,
                   @ParamText = CASE id
                                    WHEN 3 THEN
                                        Item
                                    ELSE
                                        @ParamText
                                END
            FROM dbo.SplitString(@MenuText, ':');

            IF EXISTS
            (
                SELECT *
                FROM dbo.Robot_Product_Discount rpd,
                     dbo.SplitString(@ParamText, ',') T
                WHERE rpd.ROBO_RBID = @Rbid
                      AND rpd.TARF_CODE = T.Item
                      AND rpd.OFF_TYPE != '001'
                      AND rpd.ACTV_TYPE = '002'
            )
            BEGIN
                SET @Message
                    = N'محصولات انتخابی شما تخفیفات فعال دیگری دارند که شما نمی توانید تخفیف جدیدی برای آنها ثبت کنید، لطفا تخفیفات قبلی را غیرفعال کنید تا بتوانید تخفیف جدید را اعمال کنید';
                GOTO L$EndSP;
            END;

            -- اگر کالایی قبلا در جدول قرار گرفته باشد
            UPDATE dbo.Robot_Product_Discount
            SET OFF_PRCT = @OffPrct,
                REMN_TIME = DATEADD(HOUR, @Said, GETDATE()),
                ACTV_TYPE = CASE @OffPrct
                                WHEN 0 THEN
                                    '001'
                                ELSE
                                    '002'
                            END
            FROM dbo.Robot_Product_Discount rpd,
                 dbo.SplitString(@ParamText, ',') T
            WHERE rpd.ROBO_RBID = @Rbid
                  AND rpd.TARF_CODE = T.Item
                  AND rpd.OFF_TYPE = '001';

            INSERT INTO dbo.Robot_Product_Discount
            (
                ROBO_RBID,
                CODE,
                TARF_CODE,
                OFF_TYPE,
                OFF_PRCT,
                ACTV_TYPE,
                OFF_DESC,
                REMN_TIME
            )
            SELECT rp.ROBO_RBID,
                   dbo.GNRT_NVID_U(),
                   rp.TARF_CODE,
                   '001',
                   @OffPrct,
                   CASE @OffPrct
                       WHEN 0 THEN
                           '001'
                       ELSE
                           '002'
                   END,
                   N'تخفیف فروش ویژه زمان دار',
                   DATEADD(HOUR, @Said, GETDATE())
            FROM dbo.Robot_Product rp,
                 dbo.SplitString(@ParamText, ',') T
            WHERE rp.ROBO_RBID = @Rbid
                  AND rp.TARF_CODE = T.Item
                  AND NOT EXISTS
            (
                SELECT *
                FROM dbo.Robot_Product_Discount rpd
                WHERE rpd.ROBO_RBID = rp.ROBO_RBID
                      AND rpd.TARF_CODE = rp.TARF_CODE
                      AND rpd.OFF_TYPE = '001'
            );

            SET @Message = N'اطلاعات تخفیف برای کالاهای درخواستی ثبت شد';

            IF @OffPrct > 0
            BEGIN
                -- اطلاع رسانی به مشتریانی که برای تخفیف ثبت کرده اند
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS 'Order/@chatid',
                           '012' AS 'Order/@type',
                           @ParamText AS 'Order/@valu',
                           'discount' AS 'Order/@oprt'
                    FOR XML PATH('Robot')
                );

                EXEC dbo.SEND_MEOJ_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml
            END;
        END;
        -- اضافه کردن موجودی جدید برای کالاها
        ELSE IF @UssdCode = '*6*1*6*0#'
        BEGIN
            -- +:1:100

            -- اضافه کردن موجودی جدید به قفسه کالاها
            SELECT @ParamText = CASE id
                                    WHEN 1 THEN
                                        Item
                                    ELSE
                                        @ParamText
                                END,
                   @TarfCode = CASE id
                                   WHEN 2 THEN
                                       Item
                                   ELSE
                                       @TarfCode
                               END,
                   @QueryStatement = CASE id
                                         WHEN 3 THEN
                                             Item
                                         ELSE
                                             @QueryStatement
                                     END
            FROM dbo.SplitString(@MenuText, ':');

            IF @ParamText = '+'
            BEGIN
                INSERT INTO dbo.Service_Robot_Seller_Product_Store
                (
                    SRSP_CODE,
                    CODE,
                    STOR_DATE,
                    NUMB,
                    MAKE_DATE,
                    EXPR_DATE
                )
                SELECT p.CODE,
                       dbo.GNRT_NVID_U(),
                       GETDATE(),
                       @QueryStatement,
                       GETDATE(),
                       DATEADD(YEAR, 1, GETDATE())
                FROM dbo.Service_Robot_Seller s,
                     dbo.Service_Robot_Seller_Product p
                WHERE s.SRBT_ROBO_RBID = @Rbid
                      AND s.CODE = p.SRBS_CODE
                      AND p.TARF_CODE = @TarfCode;
            END;

            IF @@ROWCOUNT >= 1
                SET @Message = N'اطلاعات با موفقیت ثبت و ذخیره شد';
            ELSE
                SET @Message = N'در ثبت اطلاعات مشکلی به وجود آمده لطفا بررسی کنید';
        END;
        -- مشخص کردن مدت زمان تولید کالا
        ELSE IF @UssdCode = '*6*1*7#'
        BEGIN
            SELECT @TarfCode = CASE id
                                   WHEN 1 THEN
                                       Item
                                   ELSE
                                       @TarfCode
                               END,
                   @ParamText = CASE id
                                    WHEN 2 THEN
                                        Item
                                    ELSE
                                        @ParamText
                                END
            FROM dbo.SplitString(@MenuText, ':');

            UPDATE srsp
            SET srsp.MAKE_DAY =
                (
                    SELECT Item FROM dbo.SplitString(@ParamText, ',') m WHERE m.id = 1
                ),
                srsp.MAKE_HOUR =
                (
                    SELECT Item FROM dbo.SplitString(@ParamText, ',') m WHERE m.id = 2
                ),
                srsp.MAKE_MINT =
                (
                    SELECT Item FROM dbo.SplitString(@ParamText, ',') m WHERE m.id = 3
                )
            FROM dbo.Robot_Product rp,
                 dbo.Service_Robot_Seller_Product srsp
            WHERE rp.ROBO_RBID = @Rbid
                  AND rp.TARF_CODE = @TarfCode
                  AND rp.TARF_CODE = srsp.TARF_CODE;

            IF @@ROWCOUNT >= 1
                SET @Message = N'اطلاعات با موفقیت ثبت و ذخیره شد';
            ELSE
                SET @Message = N'در ثبت اطلاعات مشکلی به وجود آمده لطفا بررسی کنید';
        END;
        -- مشخص کردن مدت زمان تحویل کالا
        ELSE IF @UssdCode = '*6*1*8#'
        BEGIN
            SELECT @TarfCode = CASE id
                                   WHEN 1 THEN
                                       Item
                                   ELSE
                                       @TarfCode
                               END,
                   @ParamText = CASE id
                                    WHEN 2 THEN
                                        Item
                                    ELSE
                                        @ParamText
                                END
            FROM dbo.SplitString(@MenuText, ':');

            UPDATE srsp
            SET srsp.DELV_DAY =
                (
                    SELECT Item FROM dbo.SplitString(@ParamText, ',') m WHERE m.id = 1
                ),
                srsp.DELV_HOUR =
                (
                    SELECT Item FROM dbo.SplitString(@ParamText, ',') m WHERE m.id = 2
                ),
                srsp.DELV_MINT =
                (
                    SELECT Item FROM dbo.SplitString(@ParamText, ',') m WHERE m.id = 3
                )
            FROM dbo.Robot_Product rp,
                 dbo.Service_Robot_Seller_Product srsp
            WHERE rp.ROBO_RBID = @Rbid
                  AND rp.TARF_CODE = @TarfCode
                  AND rp.TARF_CODE = srsp.TARF_CODE;

            IF @@ROWCOUNT >= 1
                SET @Message = N'اطلاعات با موفقیت ثبت و ذخیره شد';
            ELSE
                SET @Message = N'در ثبت اطلاعات مشکلی به وجود آمده لطفا بررسی کنید';
        END;
        -- مشخص کردن کالای جایگزین
        ELSE IF @UssdCode IN ( '*6*1*9#' )
        BEGIN
            -- +:1:2,3,4
            -- -:1:3,4 | -:1:*

            -- Add Gift Product for Master product
            SELECT @ParamText = CASE id
                                    WHEN 1 THEN
                                        Item
                                    ELSE
                                        @ParamText
                                END,
                   @TarfCode = CASE id
                                   WHEN 2 THEN
                                       Item
                                   ELSE
                                       @TarfCode
                               END,
                   @QueryStatement = CASE id
                                         WHEN 3 THEN
                                             Item
                                         ELSE
                                             @QueryStatement
                                     END
            FROM dbo.SplitString(@MenuText, ':');

            IF @ParamText = '+'
            BEGIN
                IF @QueryStatement = '*'
                BEGIN
                    UPDATE dbo.Robot_Product_Alternative
                    SET STAT = '002'
                    WHERE TARF_CODE_DNRM = @TarfCode;
                END;
                ELSE
                BEGIN
                    MERGE dbo.Robot_Product_Alternative T
                    USING
                    (
                        SELECT s.CODE AS ALTR_RBPR_CODE,
                               t1.CODE AS RBPR_CODE,
                               t1.TARF_CODE
                        FROM dbo.Robot_Product s,
                             dbo.SplitString(@QueryStatement, ',') p ,
                             dbo.Robot_Product t1
                        WHERE s.ROBO_RBID = @Rbid
                              AND s.TARF_CODE = p.Item
                              AND t1.TARF_CODE = @TarfCode
                              AND t1.ROBO_RBID = @Rbid
                    ) S
                    ON (
                           T.TARF_CODE_DNRM = S.TARF_CODE
                           AND T.RBPR_CODE = S.RBPR_CODE
                           AND T.ALTR_RBPR_CODE = S.ALTR_RBPR_CODE
                       )
                    WHEN MATCHED THEN
                        UPDATE SET T.STAT = '002'
                    WHEN NOT MATCHED THEN
                        INSERT
                        (
                            RBPR_CODE,
                            ALTR_RBPR_CODE,
                            CODE,
                            STAT
                        )
                        VALUES
                        (S.RBPR_CODE, S.ALTR_RBPR_CODE, dbo.GNRT_NVID_U(), '002');
                END;
                -- To Be Continue...
                PRINT 'Add Product';
            END;
            ELSE IF @ParamText = '-'
            BEGIN
                IF @QueryStatement = '*'
                BEGIN
                    UPDATE dbo.Robot_Product_Alternative
                    SET STAT = '001'
                    WHERE TARF_CODE_DNRM = @TarfCode;
                END;
                ELSE
                BEGIN
                    MERGE dbo.Robot_Product_Alternative T
                    USING
                    (
                        SELECT s.CODE AS ALTR_RBPR_CODE,
                               t1.CODE AS RBPR_CODE,
                               t1.TARF_CODE
                        FROM dbo.Robot_Product s,
                             dbo.SplitString(@QueryStatement, ',') p ,
                             dbo.Robot_Product t1
                        WHERE s.ROBO_RBID = @Rbid
                              AND s.TARF_CODE = p.Item
                              AND t1.TARF_CODE = @TarfCode
                              AND t1.ROBO_RBID = @Rbid
                    ) S
                    ON (
                           T.TARF_CODE_DNRM = S.TARF_CODE
                           AND T.RBPR_CODE = S.RBPR_CODE
                           AND T.ALTR_RBPR_CODE = S.ALTR_RBPR_CODE
                       )
                    WHEN MATCHED THEN
                        UPDATE SET T.STAT = '001';
                END;
                PRINT 'Delete Product';
            END;

            IF @@ROWCOUNT >= 1
                SET @Message = N'اطلاعات با موفقیت ثبت و ذخیره شد';
            ELSE
                SET @Message = N'در ثبت اطلاعات مشکلی به وجود آمده لطفا بررسی کنید';
        END;
        -- مشخص کردن کالای هدیه برای محصولات
        ELSE IF @UssdCode = '*6*1*10#'
        BEGIN
            -- +:1:2,3,4
            -- -:1:3,4 | -:1:*

            -- Add Gift Product for Master product
            SELECT @ParamText = CASE id
                                    WHEN 1 THEN
                                        Item
                                    ELSE
                                        @ParamText
                                END,
                   @TarfCode = CASE id
                                   WHEN 2 THEN
                                       Item
                                   ELSE
                                       @TarfCode
                               END,
                   @QueryStatement = CASE id
                                         WHEN 3 THEN
                                             Item
                                         ELSE
                                             @QueryStatement
                                     END
            FROM dbo.SplitString(@MenuText, ':');

            IF @ParamText = '+'
            BEGIN
                IF @QueryStatement = '*'
                BEGIN
                    UPDATE dbo.Service_Robot_Seller_Product_Gift
                    SET STAT = '002'
                    WHERE TARF_CODE_DNRM = @TarfCode;
                END;
                ELSE
                BEGIN
                    MERGE dbo.Service_Robot_Seller_Product_Gift T
                    USING
                    (
                        SELECT s.CODE AS SSPG_CODE,
                               t1.CODE AS SRSP_CODE,
                               t1.TARF_CODE
                        FROM dbo.Service_Robot_Seller_Product s,
                             dbo.SplitString(@QueryStatement, ',') p ,
                             dbo.Service_Robot_Seller_Product t1
                        WHERE s.TARF_CODE = p.Item
                              AND t1.TARF_CODE = @TarfCode
                    ) S
                    ON (
                           T.TARF_CODE_DNRM = S.TARF_CODE
                           AND T.SRSP_CODE = S.SRSP_CODE
                           AND T.SSPG_CODE = S.SSPG_CODE
                       )
                    WHEN MATCHED THEN
                        UPDATE SET T.STAT = '002'
                    WHEN NOT MATCHED THEN
                        INSERT
                        (
                            SRSP_CODE,
                            SSPG_CODE,
                            CODE,
                            STAT
                        )
                        VALUES
                        (S.SRSP_CODE, S.SSPG_CODE, dbo.GNRT_NVID_U(), '002');
                END;
                -- To Be Continue...
                PRINT 'Add Product';
            END;
            ELSE IF @ParamText = '-'
            BEGIN
                IF @QueryStatement = '*'
                BEGIN
                    UPDATE dbo.Service_Robot_Seller_Product_Gift
                    SET STAT = '001'
                    WHERE TARF_CODE_DNRM = @TarfCode;
                END;
                ELSE
                BEGIN
                    MERGE dbo.Service_Robot_Seller_Product_Gift T
                    USING
                    (
                        SELECT s.CODE AS SSPG_CODE,
                               t1.CODE AS SRSP_CODE,
                               t1.TARF_CODE
                        FROM dbo.Service_Robot_Seller_Product s,
                             dbo.SplitString(@QueryStatement, ',') p ,
                             dbo.Service_Robot_Seller_Product t1
                        WHERE s.TARF_CODE = p.Item
                              AND t1.TARF_CODE = @TarfCode
                    ) S
                    ON (
                           T.TARF_CODE_DNRM = S.TARF_CODE
                           AND T.SRSP_CODE = S.SRSP_CODE
                           AND T.SSPG_CODE = S.SSPG_CODE
                       )
                    WHEN MATCHED THEN
                        UPDATE SET T.STAT = '001';
                END;
                PRINT 'Delete Product';
            END;

            IF @@ROWCOUNT >= 1
                SET @Message = N'اطلاعات با موفقیت ثبت و ذخیره شد';
            ELSE
                SET @Message = N'در ثبت اطلاعات مشکلی به وجود آمده لطفا بررسی کنید';
        END;
        -- مشخص کردن وزن کالا محصولات
        ELSE IF @UssdCode = '*6*1*11#'
        BEGIN
            -- 1:2000 => 2 Kg
            -- 1:1500 => 1.5 Kg

            -- مشخص کردن وزن کالا
            SELECT @TarfCode = CASE id
                                   WHEN 1 THEN
                                       Item
                                   ELSE
                                       @TarfCode
                               END,
                   @ParamText = CASE id
                                    WHEN 2 THEN
                                        Item
                                    ELSE
                                        @ParamText
                                END
            FROM dbo.SplitString(@MenuText, ':');

            UPDATE sp
            SET sp.WEGH_AMNT = @ParamText
            FROM dbo.Service_Robot_Seller_Product sp
            WHERE sp.TARF_CODE = @TarfCode;

            IF @@ROWCOUNT >= 1
                SET @Message = N'اطلاعات با موفقیت ثبت و ذخیره شد';
            ELSE
                SET @Message = N'در ثبت اطلاعات مشکلی به وجود آمده لطفا بررسی کنید';
        END;
        -- ///////////////////////////////////////////////////////////////////////

        -- #############################CALL BACK QUERY###########################
        L$CallBackQuery:
        IF @MenuText IN ( 'noaction' )
        BEGIN
            SET @Message = N'...';
            GOTO L$EndSP;
        END;
        ELSE IF @MenuText IN ( 'reguser', 'reguserothrcnty' )
        BEGIN
            SELECT @UssdCode = '*1*0*0#',
                   @GropTextDnrm = @MenuText,
                   @MenuText = N'No Text';                   
            GOTO L$RegUser;
        END;
        ELSE IF @MenuText = 'regsstrtchck'
        BEGIN
           IF NOT EXISTS
            (
                SELECT *
                FROM iScsc.dbo.Fighter
                WHERE CHAT_ID_DNRM = @ChatID
            )
            BEGIN
                --SELECT @UssdCode = '*1*0*0#',
                --       @MenuText = N'No Text';
                --GOTO L$RegUser;
                SELECT @UssdCode = '*0#', 
                       @ChildUssdCode = '*0*0#';
                GOTO L$ShowProds;
            END;
            
            SET @Message = (
                SELECT N'*' + sr.NAME + N'* عزیز ورود شما را به فروشگاه خودتان خیر مقدم عرض مینماییم'                
                  FROM dbo.Service_Robot sr
                 WHERE sr.ROBO_RBID = @Rbid
                   AND sr.CHAT_ID = @ChatID
            );
        END 
        -- گروه بندی محصولات
        ELSE IF @MenuText IN ( 'showgp' )
        BEGIN
            DECLARE @gropexpn BIGINT;
            -- آیا به نرم افزار حسابداری متصل میباشد
            IF @CnctAcntApp = '002'
            BEGIN
                -- نرم افزار مدیریتی آرتا
                IF @AcntAppType = '001'
                BEGIN
                    -- نمایش گروه سطح یک
                    IF @ParamText = 'frstlevl'
                    BEGIN
                        SET @XTemp =
                        (
                            SELECT N'./' + @UssdCode + N';showgp-' + CAST(ge.CODE AS NVARCHAR(30)) + N'$#' AS '@data',
                                   ROW_NUMBER() OVER (ORDER BY ge.ORDR) AS '@order',
                                   N'📚 ' + ge.GROP_DESC AS "text()"
                            FROM iScsc.dbo.Group_Expense ge
                            WHERE ge.GEXP_CODE IS NULL
                                  AND ge.GROP_TYPE = '001' -- گروه ها
                                  AND ISNULL(ge.SUB_EXPN_NUMB_DNRM, 0) > 0
                                  --AND EXISTS (SELECT * FROM dbo.Robot_Product rp WHERE rp.ROOT_GROP_CODE_DNRM = ge.CODE)
                            ORDER BY ge.ORDR
                            FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                        );
                        SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;
                        
                        -- Next Step #. More Menu
                        -- Static
                        SET @X = (
                           SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                                  @index AS '@order',
                                  N'⛔ بستن' AS "text()"
                              FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                    END;
                    -- اگر گروه دارای زیر مجموعه های پایین تر را دارا باشد
                    ELSE IF EXISTS
                    (
                        SELECT ge.CODE
                        FROM iScsc.dbo.Group_Expense ge
                        WHERE ge.GEXP_CODE = CAST(@ParamText AS BIGINT)
                    )
                    BEGIN
                        SET @XTemp =
                        (
                            SELECT N'./' + @UssdCode + N';showgp-' + CAST(ge.CODE AS NVARCHAR(30)) + N'$#' AS '@data',
                                   ROW_NUMBER() OVER (ORDER BY ge.ORDR) AS '@order',
                                   N'📚 ' + ge.GROP_DESC AS "text()"
                            FROM iScsc.dbo.Group_Expense ge
                            WHERE ge.GEXP_CODE = CAST(@ParamText AS BIGINT)
                                  AND ge.GROP_TYPE = '001' -- گروه ها
                                  AND ISNULL(ge.SUB_EXPN_NUMB_DNRM, 0) > 0
                            ORDER BY ge.ORDR
                            FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                        );
                        SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;

                        -- نمایش تمامی محصولات این قسمت
                        -- Next Step #. Show Products
                        -- Static
                        SET @X =
                        (
                            SELECT dbo.STR_FRMT_U('./{0};showgropprods-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
                                   @Index AS '@order',
                                   N'📦 نمایش محصولات' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                        
                        -- نمایش تمامی محصولات این قسمت
                        -- Next Step #. Show Products
                        -- Static
                        SET @X =
                        (
                            SELECT dbo.STR_FRMT_U('./{0};product::showimageall-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
                                   @Index AS '@order',
                                   N'📦 عکس محصولات' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                        
                        -- Next Step #. More Menu
                        -- Static
                        SET @X = (
                           SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                                  @index AS '@order',
                                  N'⛔ بستن' AS "text()"
                              FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                    END;
                    -- اگر به انتهای گروه پایینی رسیده باشیم و در این قسمت باید محصولات نمایش داده شود
                    ELSE
                    BEGIN
                        SET @XTemp =
                        (
                            SELECT N'./' + @UssdCode + N';infoprod-' + CAST(rp.TARF_CODE AS NVARCHAR(100))
                                   + N'$lessinfoprod#' AS '@data',
                                   ROW_NUMBER() OVER (ORDER BY rp.TARF_TEXT_DNRM) AS '@order',
                                   N'📦  ' + SUBSTRING(rp.TARF_TEXT_DNRM, 1, 25) + CASE WHEN LEN(rp.Tarf_Text_Dnrm) > 25 THEN N' ...' ELSE N'' END + N' ( '
                                   + REPLACE(CONVERT(NVARCHAR,CONVERT(MONEY,rp.EXPN_PRIC_DNRM + ISNULL(rp.EXTR_PRCT_DNRM, 0)),1),'.00','') + N' ) ' + @AmntTypeDesc
                            FROM dbo.Robot_Product rp
                            WHERE rp.ROBO_RBID = @Rbid
                                  AND rp.GROP_CODE_DNRM = CAST(@ParamText AS BIGINT)
                                  -- اگر کالا قابل دیدن برای مشتری خاص باشد
                                   AND NOT EXISTS (
                                       SELECT *
                                         FROM dbo.Robot_Product_Limited rpl, dbo.Robot_Limited_Commodity_Group rlcg
                                        WHERE rpl.RLCG_CODE = rlcg.CODE
                                          AND rlcg.ROBO_RBID = rp.ROBO_RBID
                                          AND rpl.RBPR_CODE = rp.CODE
                                          AND rpl.STAT = '002'
                                          AND rlcg.STAT = '002'
                                          AND NOT EXISTS (
                                              SELECT *
                                                FROM dbo.Service_Robot_Access_Limited_Group_Product sral
                                               WHERE sral.RLCG_CODE = rlcg.CODE
                                                 AND sral.CHAT_ID = @ChatID
                                                 AND sral.STAT = '002'                                        
                                          )
                                   )
                            ORDER BY rp.TARF_TEXT_DNRM
                            FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                        );
                        SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;

                        -- نمایش تمامی محصولات این قسمت
                        -- Next Step #. Show Products
                        -- Static
                        SET @X =
                        (
                            SELECT dbo.STR_FRMT_U('./{0};showgropprods-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
                                   @Index AS '@order',
                                   N'📦 نمایش محصولات' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                        
                        -- نمایش تمامی محصولات این قسمت
                        -- Next Step #. Show Products
                        -- Static
                        SET @X =
                        (
                            SELECT dbo.STR_FRMT_U('./{0};product::showimageall-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
                                   @Index AS '@order',
                                   N'📦 عکس محصولات' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                        
                        -- Next Step #. More Menu
                        -- Static
                        SET @X = (
                           SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                                  @index AS '@order',
                                  N'⛔ بستن' AS "text()"
                              FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                    END;

                    SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
                    SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                END;
            END;
        END;
        -- منوی تخفیفات
        ELSE IF @MenuText IN ( 'showoffs' )
        BEGIN
            SET @XTemp =
            (
                SELECT mu.DATA_TEXT_DNRM AS '@data',
                       ROW_NUMBER() OVER (ORDER BY mu.ORDR) AS '@order',
                       mu.MENU_TEXT AS "text()"
                FROM dbo.Menu_Ussd mu
                WHERE mu.ROBO_RBID = @Rbid
                      AND mu.MENU_TYPE = '002' -- Static InlineQuery
                      AND mu.MNUS_MUID IN
                          (
                              SELECT mut.MUID
                              FROM dbo.Menu_Ussd mut
                              WHERE mut.ROBO_RBID = mu.ROBO_RBID
                                    AND mut.USSD_CODE = @ParamText
                          )
                ORDER BY mu.ORDR
                FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
            );
            SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');

            -- Start Dynamic InLine Query
            -- بررسی اینکه ایا باید منوهای پویا را درست کنیم
            IF EXISTS
            (
                SELECT mu.MUID
                FROM dbo.Menu_Ussd mu
                WHERE mu.ROBO_RBID = @Rbid
                      AND mu.MENU_TYPE = '003' -- Dynamic InlineQuery
                      AND mu.MNUS_MUID IN
                          (
                              SELECT mut.MUID
                              FROM dbo.Menu_Ussd mut
                              WHERE mut.ROBO_RBID = mu.ROBO_RBID
                                    AND mut.USSD_CODE = @ParamText
                          )
            )
            BEGIN
                SET @XMessage =
                (
                    SELECT DISTINCT
                           mu.MNUS_MUID AS '@muid'
                    FROM dbo.Menu_Ussd mu
                    WHERE mu.ROBO_RBID = @Rbid
                          AND mu.MENU_TYPE = '003' -- Dynamic InlineQuery
                          AND mu.MNUS_MUID IN
                              (
                                  SELECT mut.MUID
                                  FROM dbo.Menu_Ussd mut
                                  WHERE mut.ROBO_RBID = mu.ROBO_RBID
                                        AND mut.USSD_CODE = @ParamText
                              )
                    FOR XML PATH('Menu_Ussd'), ROOT('Robot')
                );
                SET @XMessage.modify('insert (attribute rbid {sql:variable("@rbid")}) into (//Robot)[1]');
                EXEC dbo.DYN_ILQM_P @X = @XMessage, @XRet = @XMessage OUTPUT;
                SET @XTemp.modify('insert sql:variable("@xmessage") as last into (//InlineKeyboardMarkup)[1]');
            END;
            -- Exec Dyn_ILQM_P
            -- End Dynamic InLine Query      
            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
        END;
        -- محصولات تخفیف خورده
        ELSE IF @MenuText IN ( 'showgpoff', 'showprodofftimer', 'showprodoffspecsale' )
        BEGIN
            SET @XTemp =
            (
                SELECT N'./' + @UssdCode + N';infoprod-' + CAST(rp.TARF_CODE AS NVARCHAR(100)) + N'$lessinfoprod#' AS '@data',
                       ROW_NUMBER() OVER (ORDER BY rp.TARF_TEXT_DNRM) AS '@order',
                       N'📦  ' + rp.TARF_TEXT_DNRM + N' ( '
                       + REPLACE(
                                    CONVERT(
                                               NVARCHAR,
                                               CONVERT(MONEY, rp.EXPN_PRIC_DNRM + ISNULL(rp.EXTR_PRCT_DNRM, 0)),
                                               1
                                           ),
                                    '.00',
                                    ''
                                ) + N' ) ' + @AmntTypeDesc
                FROM dbo.Robot_Product rp,
                     dbo.Robot_Product_Discount rpd
                WHERE rp.ROBO_RBID = @Rbid
                      AND rpd.ROBO_RBID = rp.ROBO_RBID
                      AND rp.TARF_CODE = rpd.TARF_CODE
                      AND rpd.ACTV_TYPE = '002'
                      AND rp.ROOT_GROP_CODE_DNRM = CASE CAST(@ParamText AS BIGINT)
                                                       WHEN 0 THEN
                                                           rp.ROOT_GROP_CODE_DNRM
                                                       ELSE
                                                           CAST(@ParamText AS BIGINT)
                                                   END
                      AND rpd.OFF_TYPE = CASE @MenuText
                                             WHEN 'showgpoff' THEN
                                                 rpd.OFF_TYPE
                                             WHEN 'showprodofftimer' THEN
                                                 '001'
                                             WHEN 'showprodoffspecsale' THEN
                                                 '002'
                                         END
                       -- اگر کالا قابل دیدن برای مشتری خاص باشد
                       AND NOT EXISTS (
                           SELECT *
                             FROM dbo.Robot_Product_Limited rpl, dbo.Robot_Limited_Commodity_Group rlcg
                            WHERE rpl.RLCG_CODE = rlcg.CODE
                              AND rlcg.ROBO_RBID = rp.ROBO_RBID
                              AND rpl.RBPR_CODE = rp.CODE
                              AND rpl.STAT = '002'
                              AND rlcg.STAT = '002'
                              AND NOT EXISTS (
                                  SELECT *
                                    FROM dbo.Service_Robot_Access_Limited_Group_Product sral
                                   WHERE sral.RLCG_CODE = rlcg.CODE
                                     AND sral.CHAT_ID = @ChatID
                                     AND sral.STAT = '002'                                        
                              )
                       )
                ORDER BY rp.TARF_TEXT_DNRM
                FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
            );
            IF @XTemp IS NOT NULL
            BEGIN
               SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
               SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END
            ELSE
               SET @Message = N'⚠️ در حال حاضر هیچ تخفیفی برای محصولات و کالاهای فروشگاه وجود ندارد، لطفا منتظر اطلاع رسانی از طریق فروشگاه باشید، با تشکر از شما'
            
        END;
        -- نمایش طبقه بندی محصولات
        ELSE IF @MenuText IN ( 'showprods' )
        BEGIN
            SELECT @UssdCode = '*0#',
                   @ChildUssdCode = '*0*0#';
            GOTO L$ShowProds;
        END;
        -- نمایش محصولات داخل یک گروه محصولی
        ELSE IF @MenuText IN ( 'showgropprods' )
        BEGIN
            IF @CnctAcntApp = '002' -- اتصال به نرم افزار حسابداری
                IF @AcntAppType = '001' -- نرم افزار مدیریتی آرتا
                BEGIN;
                    WITH GROPS (GEXP_CODE, CODE, GROP_DESC, LEVEL)
                    AS (SELECT gp.GEXP_CODE,
                               gp.CODE,
                               gp.GROP_DESC,
                               0 AS Level
                        FROM iScsc.dbo.Group_Expense gp
                        WHERE gp.CODE = CAST(ISNULL(@ParamText, gp.CODE) AS BIGINT)
                              AND gp.GROP_TYPE = '001' -- Groups
                              AND gp.STAT = '002' -- Active
                        UNION ALL
                        SELECT gc.GEXP_CODE,
                               gc.CODE,
                               gc.GROP_DESC,
                               LEVEL + 1
                        FROM iScsc.dbo.Group_Expense gc,
                             GROPS g
                        WHERE gc.GEXP_CODE = g.CODE
                              AND gc.STAT = '002' -- Active
                              AND gc.GROP_TYPE = '001' -- Groups
                    )
                    SELECT @XTemp
                        =
                        (
                            SELECT N'./' + @UssdCode + N';infoprod-' + CAST(rp.TARF_CODE AS NVARCHAR(100))
                                   + N'$lessinfoprod#' AS '@data',
                                   ROW_NUMBER() OVER (ORDER BY rp.TARF_TEXT_DNRM) AS '@order',
                                   N'📦  ' + rp.TARF_TEXT_DNRM + N' ( '
                                   + REPLACE(CONVERT(NVARCHAR,CONVERT(MONEY, rp.EXPN_PRIC_DNRM + rp.EXTR_PRCT_DNRM),1),'.00','') + N' ) ' + @AmntTypeDesc
                            FROM (
                             SELECT DISTINCT 
                                    rp.TARF_CODE, rp.TARF_TEXT_DNRM, rp.EXPN_PRIC_DNRM, rp.EXTR_PRCT_DNRM                                    
                               FROM dbo.Robot_Product rp,
                                    GROPS g
                               WHERE rp.ROBO_RBID = @Rbid
                                     AND iScsc.dbo.LINK_GROP_U(g.CODE, rp.GROP_CODE_DNRM) = 1
                                     -- اگر کالا قابل دیدن برای مشتری خاص باشد
                                     AND NOT EXISTS (
                                          SELECT *
                                            FROM dbo.Robot_Product_Limited rpl, dbo.Robot_Limited_Commodity_Group rlcg
                                           WHERE rpl.RLCG_CODE = rlcg.CODE
                                             AND rlcg.ROBO_RBID = rp.ROBO_RBID
                                             AND rpl.RBPR_CODE = rp.CODE
                                             AND rpl.STAT = '002'
                                             AND rlcg.STAT = '002'
                                             AND NOT EXISTS (
                                                 SELECT *
                                                   FROM dbo.Service_Robot_Access_Limited_Group_Product sral
                                                  WHERE sral.RLCG_CODE = rlcg.CODE
                                                    AND sral.CHAT_ID = @ChatID
                                                    AND sral.STAT = '002'                                        
                                             )
                                      )
                            ) rp
                            ORDER BY rp.TARF_TEXT_DNRM
                            FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                        );
                    SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;
                    -- نمایش زیر گروه
                    -- Next Step #. Show Products
                    -- Static
                    SET @X =
                    (
                        SELECT dbo.STR_FRMT_U('./{0};showgp-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
                               @Index AS '@order',
                               N'📚 نمایش زیر گروه' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                    );
                    SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                    SET @Index += 1;
                    
                    -- نمایش تمامی محصولات این قسمت
                    -- Next Step #. Show Products
                    -- Static
                    SET @X =
                    (
                        SELECT dbo.STR_FRMT_U('./{0};product::showimageall-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
                               @Index AS '@order',
                               N'📦 عکس محصولات' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                    );
                    SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                    SET @Index += 1;
                    
                    -- Next Step #. More Menu
                    -- Static
                    SET @X = (
                       SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                              @index AS '@order',
                              N'⛔ بستن' AS "text()"
                          FOR XML PATH('InlineKeyboardButton')
                    );
                    SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                    SET @Index += 1;

                    SELECT @Message = GROP_DESC
                    FROM iScsc.dbo.Group_Expense
                    WHERE CODE = CAST(@ParamText AS BIGINT);
                    SET @XTemp.modify('insert attribute caption {sql:variable("@message")} into (//InlineKeyboardMarkup)[1]');
                    SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
                    SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                END;
        END;
        -- نمایش معاملات روز
        ELSE IF @MenuText IN ( 'daydeals::show', 'daydeals::sort', 'daydeals::advance', 'daydeals::advance::category',
                               'daydeals::advance::type', 'daydeals::advance::price', 'daydeals::advance::discount',
                               'daydeals::advance::customerreview'
                             )
        BEGIN
            IF @MenuText = 'daydeals::show'
            BEGIN
                L$DayDeals:
                -- در این قسمت ما یک سری ورودی داریم که کاربر این موارد را وارد میکند
                -- 1 ) Page Number
                -- 2 ) Sort
                -- 2.1 ) Price 
                -- 2.1.1 ) {Low to High} (splh)
                -- 2.1.2 ) {High to Low} (sphl)
                -- 2.2 ) Discount
                -- 2.2.1 ) {Low to High} (sdlh)
                -- 2.2.2 ) {High to Low} (sdhl)
                -- 2.3 ) Release
                -- 2.3.1 ) {New to Old} {srno}
                -- 2.3.2 ) {Old to New} (sron)
                -- 2.4 ) Visited
                -- 2.4.1 ) {More to Less} (svml)
                -- 2.4.2 ) {Less to More} (svlm)
                -- 2.5 ) Favorite
                -- 2.5.1 ) {More to Less} (sfml)
                -- 2.5.2 ) {Less to More} (sflm)
                -- 2.6 ) Best Selling
                -- 2.6.1 ) {More to Less} (sbml)
                -- 2.6.2 ) {Less to More} (sblm)
                -- 2.7 ) Time Deliver 
                -- 2.7.1 ) {Fast to Slow} (stfs)
                -- 2.7.2 ) {Slow to Fast} (stsf)
                -- 2.8 ) Make Deliver 
                -- 2.8.1 ) {Fast to Slow} (smfs)
                -- 2.8.2 ) {Slow to Fast} (smsf)
                -- 2.9 ) Available Products
                -- 2.9.1 ) {true} (spat)
                -- 2.9.2 ) {false} (spaf)
                -- **********************************
                -- 3 ) Filter
                -- 3.1 ) Group Product (g123)
                -- 3.2 ) Deal Type (t001)
                -- 3.3 ) Price (p002)
                -- 3.4 ) Discount (d002)
                -- 3.5 ) Customer Review (c005)
                -- **********************************
                -- 4 ) Result 
                -- 4.1 ) Text Menu
                -- 4.2 ) Image (with Text) Menu

                -- ابتدا باید این موارد را از ورودی ارساب شده جدا کنیم
                SELECT @Page = CASE id
                                   WHEN 1 THEN
                                       Item
                                   ELSE
                                       @Page
                               END,
                       @SortType = CASE id
                                       WHEN 2 THEN
                                           Item
                                       ELSE
                                           @SortType
                                   END,
                       @FilterType = CASE id
                                         WHEN 3 THEN
                                             Item
                                         ELSE
                                             @FilterType
                                     END,
                       @ResultType = CASE id
                                         WHEN 4 THEN
                                             Item
                                         ELSE
                                             @ResultType
                                     END
                FROM dbo.SplitString(@ParamText, ',');

                -- اگر برای داده ها فیلتری انتخاب شده باشد
                IF @FilterType != 'n'
                BEGIN
                    SELECT @FGCode = CASE SUBSTRING(Item, 1, 1)
                                         WHEN 'g' THEN
                                             SUBSTRING(Item, 2, LEN(Item))
                                         ELSE
                                             @FGCode
                                     END,
                           @FTCode = CASE SUBSTRING(Item, 1, 1)
                                         WHEN 't' THEN
                                             SUBSTRING(Item, 2, LEN(Item))
                                         ELSE
                                             @FTCode
                                     END,
                           @FPCode = CASE SUBSTRING(Item, 1, 1)
                                         WHEN 'p' THEN
                                             SUBSTRING(Item, 2, LEN(Item))
                                         ELSE
                                             @FPCode
                                     END,
                           @FDCode = CASE SUBSTRING(Item, 1, 1)
                                         WHEN 'd' THEN
                                             SUBSTRING(Item, 2, LEN(Item))
                                         ELSE
                                             @FDCode
                                     END,
                           @FCCode = CASE SUBSTRING(Item, 1, 1)
                                         WHEN 'c' THEN
                                             SUBSTRING(Item, 2, LEN(Item))
                                         ELSE
                                             @FCCode
                                     END
                    FROM dbo.SplitString(@FilterType, '*');
                END;

                DECLARE @T#DayDeals TABLE
                (
                    Tarf_Code VARCHAR(100),
                    Qnty REAL,
                    Data VARCHAR(100),
                    Ordr INT,
                    [Text] NVARCHAR(MAX)
                );

                SET @FromDate = GETDATE();
                -- بدست آوردن فروش محصولات در 30 روز گذشته بر اساس تعداد فروش      
                INSERT INTO @T#DayDeals
                (
                    Tarf_Code,
                    Qnty,
                    Data,
                    Ordr,
                    [Text]
                )
                -- Step 2 . Minig Data from First Result
                SELECT T.TARF_CODE,
                       T.QNTY,
                       N'./' + @UssdCode + N';infoprod-' + CAST(rp.TARF_CODE AS NVARCHAR(100)) + N'$lessinfoprod#' AS DATA,
                       ROW_NUMBER() OVER (ORDER BY rp.TARF_CODE) AS ORDR,
                       N'📦  ' + rp.TARF_TEXT_DNRM
                       + dbo.STR_FRMT_U(
                                           N' [ {0} نفر ]',
                                           --dbo.STR_COPY_U(N'⭐️ ', rp.RTNG_NUMB_DNRM) + N','
                                           + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, rp.RTNG_CONT_DNRM), 1), '.00', '')
                                       ) AS [TEXT]
                FROM
                (
                    SELECT od.TARF_CODE,
                           SUM(od.NUMB) AS QNTY
                    FROM [Order] o,
                         [Order_Detail] od
                    WHERE o.CODE = od.ORDR_CODE
                          AND o.SRBT_ROBO_RBID = @Rbid
                          AND o.ORDR_TYPE = '004'
                          AND o.END_DATE
                          BETWEEN DATEADD(DAY, -30, GETDATE()) AND GETDATE() /* اطلاعات 30 روزه گذشته */
                          AND EXISTS
                    (
                        SELECT *
                        FROM [Order_Step_History] osh
                        WHERE osh.ORDR_CODE = o.CODE
                              AND osh.ORDR_STAT = '004' /* مشتری هزینه سفارش را پرداخت کرده باشد */
                    )
                    GROUP BY od.TARF_CODE
                ) T ,
                dbo.Robot_Product rp
                    LEFT OUTER JOIN dbo.Robot_Product_Discount rpd
                        ON rp.ROBO_RBID = rpd.ROBO_RBID
                           AND rp.TARF_CODE = rpd.TARF_CODE
                WHERE rp.ROBO_RBID = @Rbid
                      AND rp.TARF_CODE = T.TARF_CODE
                      -- اگر کالا قابل دیدن برای مشتری خاص باشد
                      AND NOT EXISTS (
                           SELECT *
                             FROM dbo.Robot_Product_Limited rpl, dbo.Robot_Limited_Commodity_Group rlcg
                            WHERE rpl.RLCG_CODE = rlcg.CODE
                              AND rlcg.ROBO_RBID = rp.ROBO_RBID
                              AND rpl.RBPR_CODE = rp.CODE
                              AND rpl.STAT = '002'
                              AND rlcg.STAT = '002'
                              AND NOT EXISTS (
                                  SELECT *
                                    FROM dbo.Service_Robot_Access_Limited_Group_Product sral
                                   WHERE sral.RLCG_CODE = rlcg.CODE
                                     AND sral.CHAT_ID = @ChatID
                                     AND sral.STAT = '002'                                        
                              )
                      )
                      AND
                      (
                          @FGCode IS NULL
                          OR iScsc.dbo.LINK_GROP_U(rp.GROP_CODE_DNRM, @FGCode) = 1
                      )
                      AND
                      (
                          ISNULL(@FTCode, '000') = '000'
                          OR
                          (
                              @FTCode IN ( '001' /* فروش شگفت انگیز */, '002' /* تخفیف ویژه */ )
                              AND EXISTS
                                  (
                                      SELECT rpd.TARF_CODE
                                      FROM dbo.Robot_Product_Discount rpd
                                      WHERE rpd.ROBO_RBID = rp.ROBO_RBID
                                            AND rpd.TARF_CODE = rp.TARF_CODE
                                            AND rpd.OFF_TYPE = @FTCode
                                            AND
                                            (
                                                ISNULL(@FDCode, '000') = '000'
                                                OR
                                                (
                                                    @FDCode = '001' /* 1-10% Off or more */
                                                    AND rpd.OFF_PRCT BETWEEN 1 AND 24
                                                )
                                                OR
                                                (
                                                    @FDCode = '002' /* 25% off or more */
                                                    AND rpd.OFF_PRCT BETWEEN 25 AND 49
                                                )
                                                OR
                                                (
                                                    @FDCode = '003' /* 50% off or more */
                                                    AND rpd.OFF_PRCT BETWEEN 50 AND 69
                                                )
                                                OR
                                                (
                                                    @FDCode = '004' /* 70% off or more */
                                                    AND rpd.OFF_PRCT >= 70
                                                )
                                            )
                                            AND
                                            (
                                                (
                                                    rpd.OFF_TYPE = '001' /* showprodofftimer */
                                                    AND rpd.REMN_TIME >= GETDATE()
                                                )
                                                OR rpd.OFF_TYPE != '001'
                                            )
                                            AND rpd.ACTV_TYPE = '002'
                                  )
                          )
                          OR
                          (
                              @FTCode = '003' /* فروش کالا همراه با هدیه */
                              AND EXISTS
                                  (
                                      SELECT *
                                      FROM dbo.Service_Robot_Seller_Product sp,
                                           dbo.Service_Robot_Seller_Product_Gift pg
                                      WHERE sp.TARF_CODE = rp.TARF_CODE
                                            AND sp.CODE = pg.SRSP_CODE
                                            AND pg.STAT = '002'
                                  )
                          )
                      )
                      AND
                      (
                          ISNULL(@FPCode, '000') = '000'
                          OR
                          (
                              @FPCode = '001' /* 0 - 250,000 Rial */
                              AND rp.EXPN_PRIC_DNRM BETWEEN 0 AND 250000
                          )
                          OR
                          (
                              @FPCode = '002' /* 250,000 - 500,000 Rial */
                              AND rp.EXPN_PRIC_DNRM BETWEEN 250001 AND 500000
                          )
                          OR
                          (
                              @FPCode = '003' /* 500,000 - 1,000,000 Rial */
                              AND rp.EXPN_PRIC_DNRM BETWEEN 500001 AND 1000000
                          )
                          OR
                          (
                              @FPCode = '004' /* 1,000,000 - 2,000,000 Rial */
                              AND rp.EXPN_PRIC_DNRM BETWEEN 1000001 AND 2000000
                          )
                          OR
                          (
                              @FPCode = '005' /* 2,000,000 - Infinity Rial */
                              AND rp.EXPN_PRIC_DNRM > 2000000
                          )
                      )
                      AND
                      (
                          ISNULL(@FCCode, 0) = 0
                          OR rp.RTNG_NUMB_DNRM >= @FCCode
                      )
                ORDER BY CASE @SortType
                             WHEN 'splh' THEN
                                 rp.EXPN_PRIC_DNRM
                             ELSE ( SELECT NULL )
                         END ASC,
                         CASE @SortType
                             WHEN 'sphl' THEN
                                 rp.EXPN_PRIC_DNRM
                             ELSE ( SELECT NULL )
                         END DESC,
                         CASE @SortType
                             WHEN 'sdlh' THEN
                                 rpd.OFF_PRCT
                             ELSE ( SELECT NULL )
                         END ASC,
                         CASE @SortType
                             WHEN 'sdhl' THEN
                                 rpd.OFF_PRCT
                             ELSE ( SELECT NULL )
                         END DESC,
                         CASE @SortType
                             WHEN 'srno' THEN
                                 rp.RELS_TIME
                             ELSE ( SELECT NULL )
                         END ASC,
                         CASE @SortType
                             WHEN 'sron' THEN
                                 rp.RELS_TIME
                             ELSE ( SELECT NULL )
                         END DESC,
                         CASE @SortType
                             WHEN 'svml' THEN
                                 rp.VIST_CONT_DNRM
                             ELSE ( SELECT NULL )
                         END ASC,
                         CASE @SortType
                             WHEN 'svlm' THEN
                                 rp.VIST_CONT_DNRM
                             ELSE ( SELECT NULL )
                         END DESC,
                         CASE @SortType
                             WHEN 'sfml' THEN
                                 rp.LIKE_CONT_DNRM
                             ELSE ( SELECT NULL )
                         END ASC,
                         CASE @SortType
                             WHEN 'sflm' THEN
                                 rp.LIKE_CONT_DNRM
                             ELSE ( SELECT NULL )
                         END DESC,
                         CASE @SortType
                             WHEN 'sbml' THEN
                                 rp.BEST_SLNG_CONT_DNRM
                             ELSE ( SELECT NULL )
                         END ASC,
                         CASE @SortType
                             WHEN 'sblm' THEN
                                 rp.BEST_SLNG_CONT_DNRM
                             ELSE ( SELECT NULL )
                         END DESC,
                         CASE @SortType
                              WHEN 'spat' then 
                                 rp.CRNT_NUMB_DNRM
                              ELSE ( SELECT NULL )
                         END ASC,
                         CASE @SortType
                              WHEN 'spaf' THEN 
                                 rp.CRNT_NUMB_DNRM
                              ELSE ( SELECT NULL )
                         END DESC /*,
                     --**##CASE @SortType WHEN 'stfs' THEN (rp.ِDELV_DAY_DNRM + rp.DELV_HOUR_DNRM + rp.DELV_MINT_DNRM) ELSE (SELECT NULL) END ASC,
                     CASE @SortType WHEN 'stsf' THEN (rp.ِDELV_DAY_DNRM + rp.DELV_HOUR_DNRM + rp.DELV_MINT_DNRM) ELSE (SELECT NULL) END DESC,
                     CASE @SortType WHEN 'smfs' THEN (rp.MAKE_DAY_DNRM + rp.MAKE_HOUR_DNRM + rp.MAKE_MINT_DNRM) ELSE (SELECT NULL) END ASC,
                     CASE @SortType WHEN 'smsf' THEN (rp.ِMAKE_DAY_DNRM + rp.MAKE_HOUR_DNRM + rp.MAKE_MINT_DNRM) ELSE (SELECT NULL) END DESC*/
                ;
                SET @ToDate = GETDATE();

                SET @Message =
                (
                    SELECT N'🔍 معاملات روزانه' + CHAR(10)
                           + dbo.STR_FRMT_U(
                                               N'🗂 حدود {0} نتیجه، ({1} ثانیه)',
                                               REPLACE(
                                                          CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(T.Tarf_Code)), 1),
                                                          '.00',
                                                          ''
                                                      ) + N','
                                               + CAST(DATEDIFF(SECOND, @FromDate, @ToDate) AS NVARCHAR(50))
                                           )
                    FROM @T#DayDeals T
                    FOR XML PATH('')
                );
                SET @Message += CHAR(10)
                                +
                                (
                                    SELECT CASE Item
                                               WHEN 'n' THEN
                                                   ''
                                               WHEN 'splh' THEN
                                                   N'👈 لیست بر اساس قیمت از 🔺 ارزان به گران نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sphl' THEN
                                                   N'👈 لیست بر اساس قیمت از 🔻 گران به ارزان نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sdlh' THEN
                                                   N'👈 لیست بر اساس تخفیف از 🔺 کم به زیاد نمایش داده شده' + CHAR(10)
                                               WHEN 'sdhl' THEN
                                                   N'👈 لیست بر اساس تخفیف از 🔻 زیاد به کم نمایش داده شده' + CHAR(10)
                                               WHEN 'srno' THEN
                                                   N'👈 لیست بر اساس زمان انتشار از 🔺 جدید به قدیم نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sron' THEN
                                                   N'👈 لیست بر اساس زمان انتشار از 🔻 قدیم به جدید نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'svml' THEN
                                                   N'👈 لیست بر اساس بازدید از 🔺 زیاد به کم نمایش داده شده' + CHAR(10)
                                               WHEN 'svlm' THEN
                                                   N'👈 لیست بر اساس بازدید از 🔻 کم به زیاد نمایش داده شده' + CHAR(10)
                                               WHEN 'sfml' THEN
                                                   N'👈 لیست بر اساس محبوبیت از 🔺 زیاد به کم نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sflm' THEN
                                                   N'👈 لیست بر اساس زمان محبوبیت از 🔻 کم به زیاد نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sbml' THEN
                                                   N'👈 لیست بر اساس پر فروش ترین از 🔺 زیاد به کم نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sblm' THEN
                                                   N'👈 لیست بر اساس پر فروش ترین از 🔻 کم به زیاد نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'stfs' THEN
                                                   N'👈 لیست بر اساس زمان ارسال / تحویل از 🔺 سریع به کند نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'stsf' THEN
                                                   N'👈 لیست بر اساس زمان ارسال / تحویل از 🔻 کند به سریع نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'smfs' THEN
                                                   N'👈 لیست بر اساس زمان تولید از 🔺 سریع به کند نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'smsf' THEN
                                                   N'👈 لیست بر اساس زمان تولید از 🔻 کند به سریع نمایش داده شده'
                                                   + CHAR(10)                                               
                                               WHEN 'spat' THEN
                                                   N'👈 لیست بر اساس موجودی کالا از 🔺 موجود به ناموجود نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'spaf' THEN
                                                   N'👈 لیست بر اساس موجودی کالا از 🔻 ناموجود به موجود نمایش داده شده'
                                                   + CHAR(10)
                                           END
                                    FROM dbo.SplitString(@ParamText, ',')
                                    WHERE id = 2
                                ) +
                                (
                                    SELECT
                                        (
                                            SELECT CASE
                                                       WHEN t.Item LIKE '%n%' THEN
                                                           N''
                                                       WHEN t.Item LIKE '%g%' THEN
                                                           N'👈 لیست بر اساس *گروه کالا* فیلتر شده' + CHAR(10)
                                                       WHEN t.Item LIKE '%t%'
                                                            AND t.Item NOT LIKE '%t000%' THEN
                                                           N'👈 لیست بر اساس *نوع معاملات* فیلتر شده' + CHAR(10)
                                                       WHEN t.Item LIKE '%p%'
                                                            AND t.Item NOT LIKE '%p000%' THEN
                                                           N'👈 لیست بر اساس *مبلغ کالا* فیلتر شده' + CHAR(10)
                                                       WHEN t.Item LIKE '%d%'
                                                            AND t.Item NOT LIKE '%d000%' THEN
                                                           N'👈 لیست بر اساس *تخفیف ها* فیلتر شده' + CHAR(10)
                                                       WHEN t.Item LIKE '%c%'
                                                            AND t.Item NOT LIKE '%c000%' THEN
                                                           N'👈 لیست بر اساس *بازخورد مشتریان* فیلتر شده' + CHAR(10)
                                                   END
                                            FROM dbo.SplitString(Item, '*') t
                                            WHERE LEN(t.Item) != 0
                                            FOR XML PATH('')
                                        )
                                    FROM dbo.SplitString(@ParamText, ',')
                                    WHERE id = 3
                                );

                -- اگر جستجو هیچ گونه خروجی در بر نداشته باشد
                IF NOT EXISTS (SELECT * FROM @T#DayDeals)
                BEGIN
                    SET @XTemp =
                    (
                        SELECT 1 AS '@order',
                               N'داده ای یافت نشد' AS '@caption'
                        FOR XML PATH('InlineKeyboardMarkup')
                    );
                    GOTO L$CountineDayDeals;
                END;

                SET @XTemp =
                (
                    SELECT T.Data AS '@data',
                           T.Ordr AS '@order',
                           T.[Text] AS "text()"
                    FROM @T#DayDeals T
                    WHERE T.Ordr
                    BETWEEN ((@Page - 1) * @PageFechRows) + 1 AND ((((@Page - 1) * @PageFechRows)) + @PageFechRows)
                    FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                );
                SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
                SET @XTemp.modify('insert attribute caption {sql:variable("@Message")} into (//InlineKeyboardMarkup)[1]');

                -- [      
                ---- Advance Search
                ---- اضافه کردن صفحه بندی * Next * Perv
                ---- Sort 
                -- ]

                -- اگر تعداد رکورد های درون جدول خروجی بیشتر از صفحه بندی باشد 
                IF @Page * @PageFechRows <=
                (
                    SELECT COUNT(*) FROM @T#DayDeals
                )
                BEGIN
                    -- Update parameter for change page number
                    SET @ParamText =
                    (
                        SELECT CASE
                                   WHEN id IN ( 1 ) THEN
                                       CAST(@Page + 1 AS VARCHAR(10)) + ','
                                   WHEN id IN ( 2, 3 ) THEN
                                       Item + ','
                                   ELSE
                                       Item
                               END
                        FROM dbo.SplitString(@ParamText, ',')
                        FOR XML PATH('')
                    );
                    SET @Index = @PageFechRows + 1;
                    -- Next Step #. Next Page
                    -- Dynamic
                    SET @X =
                    (
                        SELECT dbo.STR_FRMT_U('./*0#;findprod-{0}$del#', @ParamText) AS '@data',
                               @Index AS '@order',
                               N'▶️ صفحه بعدی' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                    );
                    SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                    SET @Index += 1;
                END;
                -- اضافه کردن دکمه صفحه قبل 
                IF @Page > 1
                BEGIN
                    -- Update parameter for change page number
                    SET @ParamText =
                    (
                        SELECT CASE
                                   WHEN id IN ( 1 ) THEN
                                       CAST(@Page - 1 AS VARCHAR(10)) + ','
                                   WHEN id IN ( 2, 3 ) THEN
                                       Item + ','
                                   ELSE
                                       Item
                               END
                        FROM dbo.SplitString(@ParamText, ',')
                        FOR XML PATH('')
                    );
                    -- Next Step #. Perv Page
                    -- Dynamic
                    SET @X =
                    (
                        SELECT dbo.STR_FRMT_U('./*0#;findprod-{0}$del#', @ParamText) AS '@data',
                               @Index AS '@order',
                               N'◀️ صفحه قبلی' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                    );
                    SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                    SET @Index += 1;
                END;

                L$CountineDayDeals:
                -- Update parameter for change page number
                SET @ParamText =
                (
                    SELECT CASE
                               WHEN id IN ( 1 ) THEN
                                   CAST(@Page AS VARCHAR(10)) + ','
                               WHEN id IN ( 2, 3 ) THEN
                                   Item + ','
                               ELSE
                                   Item
                           END
                    FROM dbo.SplitString(@ParamText, ',')
                    FOR XML PATH('')
                );
                -- اضافه کردن مرتب سازی      
                -- Static
                SET @X =
                (
                    SELECT REPLACE('./*0#;daydeals::sort-{0}$del,lesssortdeal#', '{0}', @ParamText) AS '@data',
                           @Index AS '@order',
                           N'📚 مرتب سازی' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );
                SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;

                -- Advance Search
                -- Static
                SET @X =
                (
                    SELECT REPLACE('./*0#;daydeals::advance-{0}$del,lessadvndeal#', '{0}', @ParamText) AS '@data',
                           @Index AS '@order',
                           N'🔍 جستجوی پیشرفته' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );
                SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;

                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
            ELSE IF @MenuText IN ( 'daydeals::sort', 'daydeals::advance' )
            BEGIN
                IF @MenuText = 'daydeals::sort'
                BEGIN
                    SET @Message = N'💹 شما می توانید اطلاعات خروجی را به دلخواه خود مرتب کنید';
                    SET @Message += CHAR(10)
                                    +
                                    (
                                        SELECT CASE Item
                                                   WHEN 'n' THEN
                                                       N'👈 لیست بدون ترتیب نمایش داده شده'
                                                   WHEN 'splh' THEN
                                                       N'👈 لیست بر اساس قیمت از 🔺 ارزان به گران نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sphl' THEN
                                                       N'👈 لیست بر اساس قیمت از 🔻 گران به ارزان نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sdlh' THEN
                                                       N'👈 لیست بر اساس تخفیف از 🔺 کم به زیاد نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sdhl' THEN
                                                       N'👈 لیست بر اساس تخفیف از 🔻 زیاد به کم نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'srno' THEN
                                                       N'👈 لیست بر اساس زمان انتشار از 🔺 جدید به قدیم نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sron' THEN
                                                       N'👈 لیست بر اساس زمان انتشار از 🔻 قدیم به جدید نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'svml' THEN
                                                       N'👈 لیست بر اساس بازدید از 🔺 زیاد به کم نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'svlm' THEN
                                                       N'👈 لیست بر اساس بازدید از 🔻 کم به زیاد نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sfml' THEN
                                                       N'👈 لیست بر اساس محبوبیت از 🔺 زیاد به کم نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sflm' THEN
                                                       N'👈 لیست بر اساس زمان محبوبیت از 🔻 کم به زیاد نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sbml' THEN
                                                       N'👈 لیست بر اساس پر فروش ترین از 🔺 زیاد به کم نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sblm' THEN
                                                       N'👈 لیست بر اساس پر فروش ترین از 🔻 کم به زیاد نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'stfs' THEN
                                                       N'👈 لیست بر اساس زمان ارسال / تحویل از 🔺 سریع به کند نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'stsf' THEN
                                                       N'👈 لیست بر اساس زمان ارسال / تحویل از 🔻 کند به سریع نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'smfs' THEN
                                                       N'👈 لیست بر اساس زمان تولید از 🔺 سریع به کند نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'smsf' THEN
                                                       N'👈 لیست بر اساس زمان تولید از 🔻 کند به سریع نمایش داده شده'
                                                       + CHAR(10)
                                               END
                                        FROM dbo.SplitString(@ParamText, ',')
                                        WHERE id = 2
                                    );
                END;
                ELSE IF @MenuText = 'daydeals::advance'
                BEGIN
                    SET @Message = N'💹 شما می توانید اطلاعات خروجی را به دلخواه خود فیلتر کنید';
                    SET @Message += CHAR(10)
                                    +
                                    (
                                        SELECT CASE SUBSTRING(Item, 2, LEN(Item))
                                                   WHEN 'n' THEN
                                                       N'👈 لیست بدون فیلتر نمایش داده شده'
                                                   ELSE
                                               (
                                                   SELECT CASE SUBSTRING(Item, 1, 1)
                                                              WHEN 'g' THEN
                                                                  N'👈 لیست بر اساس *گروه کالا* فیلتر شده' + CHAR(10)
                                                              WHEN 't' THEN
                                                                  N'👈 لیست بر اساس *نوع معاملات* فیلتر شده' + CHAR(10)
                                                              WHEN 'p' THEN
                                                                  N'👈 لیست بر اساس *مبلغ کالا* فیلتر شده' + CHAR(10)
                                                              WHEN 'd' THEN
                                                                  N'👈 لیست بر اساس *تخفیف ها* فیلتر شده' + CHAR(10)
                                                              WHEN 'c' THEN
                                                                  N'👈 لیست بر اساس *بازخورد مشتریان* فیلتر شده'
                                                                  + CHAR(10)
                                                              ELSE
                                                                  N''
                                                          END
                                                   FROM dbo.SplitString(SUBSTRING(Item, 2, LEN(Item)), '*')
                                                   FOR XML PATH('')
                                               )
                                               END
                                        FROM dbo.SplitString(@ParamText, ',')
                                        WHERE id = 3
                                    );
                END;

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           CASE @MenuText
                               WHEN 'daydeals::sort' THEN
                                   'lesssortdeal'
                               WHEN 'daydeals::advance' THEN
                                   'lessadvndeal'
                           END AS '@cmndtext',
                           @ParamText AS '@param'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
            ELSE IF @MenuText = 'daydeals::advance::category'
            BEGIN
                -- بدست آوردن اینکه در گروه کالا ها باید چه مرحله ای را پیمایش کنیم
                SELECT @gropexpn = CASE
                                       WHEN Item = 'n'
                                            OR Item NOT LIKE '%g%' THEN
                                           NULL
                                       ELSE
                (
                    SELECT SUBSTRING(Item, 2, LEN(Item))
                    FROM dbo.SplitString(Item, '*')
                    WHERE Item LIKE 'g%'
                )
                                   END
                FROM dbo.SplitString(@ParamText, ',')
                WHERE id = 3;

                SET @QueryStatement =
                (
                    SELECT CASE
                               WHEN id IN ( 1, 2 ) THEN
                                   Item + ','
                               WHEN id = 3
                                    AND ISNULL(@gropexpn, 0) != 0 THEN
                        (
                            SELECT CASE SUBSTRING(Item, 1, 1)
                                       WHEN 'g' THEN
                                           'g{0}*'
                                       ELSE
                                           Item + '*'
                                   END
                            FROM dbo.SplitString(Item, '*')
                            WHERE LEN(Item) != 0
                            FOR XML PATH('')
                        ) + ','
                               WHEN id = 3
                                    AND ISNULL(@gropexpn, 0) = 0
                                    AND Item != 'n' THEN
                                   Item + '*g{0},'
                               WHEN id = 3
                                    AND ISNULL(@gropexpn, 0) = 0
                                    AND Item = 'n' THEN
                                   'g{0},'
                               WHEN id = 4 THEN
                                   Item
                           END
                    FROM dbo.SplitString(@ParamText, ',')
                    FOR XML PATH('')
                );

                -- آیا به نرم افزار حسابداری متصل میباشد
                IF @CnctAcntApp = '002'
                BEGIN
                    -- نرم افزار مدیریتی آرتا
                    IF @AcntAppType = '001'
                    BEGIN
                        -- نمایش گروه سطح یک
                        IF @gropexpn IS NULL -- @ParamText = 'frstlevl' 
                        BEGIN
                            SET @XTemp =
                            (
                                SELECT N'./*0#;daydeals::advance::category-' + REPLACE(@QueryStatement, '{0}', ge.CODE)
                                       + N'$del#' AS '@data',
                                       ROW_NUMBER() OVER (ORDER BY ge.ORDR) AS '@order',
                                       N'📚 ' + ge.GROP_DESC AS "text()"
                                FROM iScsc.dbo.Group_Expense ge
                                WHERE ge.GEXP_CODE IS NULL
                                      AND ge.GROP_TYPE = '001' -- گروه ها
                                      AND ISNULL(ge.SUB_EXPN_NUMB_DNRM, 0) > 0
                                ORDER BY ge.ORDR
                                FOR XML PATH('InlineKeyboardButton') --, ROOT('InlineKeyboardMarkup')
                            );
                            SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE('./*0#;daydeals::show-{0}$del#', '{0}', @ParamText) AS '@data',
                                       @Index AS '@order',
                                       N'📊 نمایش خروجی' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE(   './*0#;daydeals::advance-{0}$del#',
                                                  '{0}',
                                       (
                                           SELECT CASE
                                                      WHEN id IN ( 1, 2 ) THEN
                                                          Item + ','
                                                      WHEN id = 3
                                                           AND Item NOT LIKE '%g%' THEN
                                                          Item + ','
                                                      WHEN id = 3
                                                           AND Item LIKE '%g%' THEN
                                                          CASE
                                                          (
                                                              SELECT t.Item + '*'
                                                              FROM dbo.SplitString(Item, '*') t
                                                              WHERE t.Item NOT LIKE 'g%'
                                                              FOR XML PATH('')
                                                          )
                                                              WHEN '*' THEN
                                                                  'n'
                                                              ELSE
                                                          (
                                                              SELECT t.Item + '*'
                                                              FROM dbo.SplitString(Item, '*') t
                                                              WHERE LEN(t.Item) != 0
                                                                    AND t.Item NOT LIKE 'g%'
                                                              FOR XML PATH('')
                                                          )
                                                          END + ','
                                                      ELSE
                                                          Item
                                                  END
                                           FROM dbo.SplitString(@ParamText, ',')
                                           FOR XML PATH('')
                                       )
                                              ) AS '@data',
                                       @Index AS '@order',
                                       N'🎲 بدون فیلتر' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE('./*0#;daydeals::advance-{0}$del#', '{0}', @ParamText) AS '@data',
                                       @Index AS '@order',
                                       N'⬆️ بازگشت' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;
                        END;
                        -- اگر گروه دارای زیر مجموعه های پایین تر را دارا باشد
                        ELSE IF EXISTS
                        (
                            SELECT ge.CODE
                            FROM iScsc.dbo.Group_Expense ge
                            WHERE ge.GEXP_CODE = @gropexpn
                        )
                        BEGIN
                            SET @XTemp =
                            (
                                SELECT N'./*0#;daydeals::advance::category-' + REPLACE(@QueryStatement, '{0}', ge.CODE)
                                       + N'$del#' AS '@data',
                                       ROW_NUMBER() OVER (ORDER BY ge.ORDR) AS '@order',
                                       N'📚 ' + ge.GROP_DESC AS "text()"
                                FROM iScsc.dbo.Group_Expense ge
                                WHERE ge.GEXP_CODE = @gropexpn
                                      AND ge.GROP_TYPE = '001' -- گروه ها
                                      AND ISNULL(ge.SUB_EXPN_NUMB_DNRM, 0) > 0
                                ORDER BY ge.ORDR
                                FOR XML PATH('InlineKeyboardButton') --, ROOT('InlineKeyboardMarkup')
                            );
                            SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE('./*0#;daydeals::show-{0}$del#', '{0}', @ParamText) AS '@data',
                                       @Index AS '@order',
                                       N'📊 نمایش خروجی' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE(   './*0#;daydeals::advance-{0}$del#',
                                                  '{0}',
                                       (
                                           SELECT CASE
                                                      WHEN id IN ( 1, 2 ) THEN
                                                          Item + ','
                                                      WHEN id = 3
                                                           AND Item NOT LIKE '%g%' THEN
                                                          Item + ','
                                                      WHEN id = 3
                                                           AND Item LIKE '%g%' THEN
                                                          CASE
                                                          (
                                                              SELECT t.Item + '*'
                                                              FROM dbo.SplitString(Item, '*') t
                                                              WHERE t.Item NOT LIKE 'g%'
                                                              FOR XML PATH('')
                                                          )
                                                              WHEN '*' THEN
                                                                  'n'
                                                              ELSE
                                                          (
                                                              SELECT t.Item + '*'
                                                              FROM dbo.SplitString(Item, '*') t
                                                              WHERE LEN(t.Item) != 0
                                                                    AND t.Item NOT LIKE 'g%'
                                                              FOR XML PATH('')
                                                          )
                                                          END + ','
                                                      ELSE
                                                          Item
                                                  END
                                           FROM dbo.SplitString(@QueryStatement, ',')
                                           FOR XML PATH('')
                                       )
                                              ) AS '@data',
                                       @Index AS '@order',
                                       N'🎲 بدون فیلتر' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;


                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE(
                                                  './*0#;daydeals::advance-{0}$del#',
                                                  '{0}',
                                                  REPLACE(@QueryStatement, '{0}', @gropexpn)
                                              ) AS '@data',
                                       @Index AS '@order',
                                       N'⬆️ بازگشت' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;
                        END;
                        -- اگر به انتهای گروه پایینی رسیده باشیم و در این قسمت باید محصولات نمایش داده شود
                        ELSE
                        BEGIN
                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE('./*0#;daydeals::show-{0}$del#', '{0}', @ParamText) AS '@data',
                                       @Index AS '@order',
                                       N'📊 نمایش خروجی' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE(   './*0#;daydeals::advance-{0}$del#',
                                                  '{0}',
                                       (
                                           SELECT CASE
                                                      WHEN id IN ( 1, 2 ) THEN
                                                          Item + ','
                                                      WHEN id = 3
                                                           AND Item NOT LIKE '%g%' THEN
                                                          Item + ','
                                                      WHEN id = 3
                                                           AND Item LIKE '%g%' THEN
                                                          CASE
                                                          (
                                                              SELECT t.Item + '*'
                                                              FROM dbo.SplitString(Item, '*') t
                                                              WHERE t.Item NOT LIKE 'g%'
                                                              FOR XML PATH('')
                                                          )
                                                              WHEN '*' THEN
                                                                  'n'
                                                              ELSE
                                                          (
                                                              SELECT t.Item + '*'
                                                              FROM dbo.SplitString(Item, '*') t
                                                              WHERE LEN(t.Item) != 0
                                                                    AND t.Item NOT LIKE 'g%'
                                                              FOR XML PATH('')
                                                          )
                                                          END + ','
                                                      ELSE
                                                          Item
                                                  END
                                           FROM dbo.SplitString(@QueryStatement, ',')
                                           FOR XML PATH('')
                                       )
                                              ) AS '@data',
                                       @Index AS '@order',
                                       N'🎲 بدون فیلتر' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE(
                                                  './*0#;daydeals::advance-{0}$del#',
                                                  '{0}',
                                                  REPLACE(@QueryStatement, '{0}', @gropexpn)
                                              ) AS '@data',
                                       @Index AS '@order',
                                       N'⬆️ بازگشت' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;
                        END;

                        SET @XTemp =
                        (
                            SELECT '1' AS '@order',
                                   N'شما می توانید دسته بنده کالاهای خود را اینجا انتخاب کنید' AS '@caption',
                                   @XTemp
                            FOR XML PATH('InlineKeyboardMarkup')
                        );
                        SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                    END;
                END;
            END;
            ELSE IF @MenuText IN ( 'daydeals::advance::type', 'daydeals::advance::price',
                                   'daydeals::advance::discount', 'daydeals::advance::customerreview'
                                 )
            BEGIN
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           CASE @MenuText
                               WHEN 'daydeals::advance::type' THEN
                                   'lessadvtdeal'
                               WHEN 'daydeals::advance::price' THEN
                                   'lessadvpdeal'
                               WHEN 'daydeals::advance::discount' THEN
                                   'lessadvddeal'
                               WHEN 'daydeals::advance::customerreview' THEN
                                   'lessadvcdeal'
                           END AS '@cmndtext',
                           @ParamText AS '@param'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
        END;
        -- جنگ برندها
        ELSE IF @MenuText IN ( 'brandswar::show', 'brandswar::sort', 'brandswar::showinfobrand::show',
                               'brandswar::showinfobrand::sort', 'brandswar::showinfobrand::advance',
                               'brandswar::showinfobrand::advance::category',
                               'brandswar::showinfobrand::advance::type', 'brandswar::showinfobrand::advance::price',
                               'brandswar::showinfobrand::advance::discount',
                               'brandswar::showinfobrand::advance::customerreview'
                             )
        BEGIN
            IF @MenuText IN ( 'brandswar::show' )
            BEGIN
                L$BrandsWar:
                -- در این قسمت ما یک سری ورودی داریم که کاربر این موارد را وارد میکند
                -- 1 ) Page Number
                -- 2 ) Sort
                -- 2.1 ) Price 
                -- 2.1.1 ) {Low to High} (splh)
                -- 2.1.2 ) {High to Low} (sphl)
                -- 2.2 ) Discount
                -- 2.2.1 ) {Low to High} (sdlh)
                -- 2.2.2 ) {High to Low} (sdhl)
                -- 2.3 ) Release
                -- 2.3.1 ) {New to Old} {srno}
                -- 2.3.2 ) {Old to New} (sron)
                -- 2.4 ) Visited
                -- 2.4.1 ) {More to Less} (svml)
                -- 2.4.2 ) {Less to More} (svlm)
                -- 2.5 ) Favorite
                -- 2.5.1 ) {More to Less} (sfml)
                -- 2.5.2 ) {Less to More} (sflm)
                -- 2.6 ) Best Selling
                -- 2.6.1 ) {More to Less} (sbml)
                -- 2.6.2 ) {Less to More} (sblm)
                -- 2.7 ) Time Deliver 
                -- 2.7.1 ) {Fast to Slow} (stfs)
                -- 2.7.2 ) {Slow to Fast} (stsf)
                -- 2.8 ) Time Make
                -- 2.8.1 ) {Fast to Slow} (smfs)
                -- 2.8.2 ) {Slow to Fast} (smsf)

                -- ابتدا باید این موارد را از ورودی ارساب شده جدا کنیم
                SELECT @Page = CASE id
                                   WHEN 1 THEN
                                       Item
                                   ELSE
                                       @Page
                               END,
                       @SortType = CASE id
                                       WHEN 2 THEN
                                           Item
                                       ELSE
                                           @SortType
                                   END
                FROM dbo.SplitString(@ParamText, ',');

                SET @QueryStatement =
                (
                    SELECT CASE
                               WHEN id IN ( 1, 2 ) THEN
                                   Item + ','
                               WHEN id = 3 THEN
                                   'b{0},'
                               WHEN id = 4 THEN
                                   Item
                           END
                    FROM dbo.SplitString(@ParamText, ',')
                    FOR XML PATH('')
                );

                DECLARE @T#BrandsWar TABLE
                (
                    Brnd_Code BIGINT,
                    Avg_Expn_Pric_Dnrm BIGINT,
                    Avg_Off_Prct_Dnrm REAL,
                    Max_Rels_Time DATETIME,
                    Avg_Vist_Cont_Dnrm BIGINT,
                    Avg_Best_Slng_Cont_Dnrm BIGINT,
                    Avg_Like_Cont_Dnrm BIGINT,
                    Avg_Delv_Time_Dnrm SMALLINT,
                    Avg_Make_Time_Dnrm SMALLINT,
                    Data VARCHAR(100),
                    Ordr INT,
                    [Text] NVARCHAR(MAX)
                );

                SET @FromDate = GETDATE();
                INSERT INTO @T#BrandsWar
                (
                    Brnd_Code,
                    Avg_Expn_Pric_Dnrm,
                    Avg_Off_Prct_Dnrm,
                    Max_Rels_Time,
                    Avg_Vist_Cont_Dnrm,
                    Avg_Best_Slng_Cont_Dnrm,
                    Avg_Like_Cont_Dnrm,
                    Avg_Delv_Time_Dnrm,
                    Avg_Make_Time_Dnrm,
                    Data,
                    Ordr,
                    [Text]
                )
                SELECT T.BRND_CODE_DNRM,
                       T.AVG_EXPN_PRIC_DNRM,
                       T.AVG_OFF_PRCT_DNRM,
                       T.MAX_RELS_TIME,
                       T.AVG_VIST_CONT_DNRM,
                       T.AVG_BEST_SLNG_CONT_DNRM,
                       T.AVG_LIKE_CONT_DNRM,
                       T.AVG_DELV_TIME_DNRM,
                       T.AVG_MAKE_TIME_DNRM,
                       REPLACE(
                                  './*0#;brandswar::showinfobrand::show-{0}$del#',
                                  '{0}',
                                  REPLACE(@QueryStatement, '{0}', T.BRND_CODE_DNRM)
                              ) AS [Data],
                       ROW_NUMBER() OVER (ORDER BY T.BRND_CODE_DNRM) AS [Ordr],
                       T.BRND_TEXT_DNRM AS [Text]
                FROM
                (
                    SELECT rp.BRND_CODE_DNRM,
                           rp.BRND_TEXT_DNRM,
                           AVG(rp.EXPN_PRIC_DNRM) AS AVG_EXPN_PRIC_DNRM,
                           AVG(ISNULL(rpd.OFF_PRCT, 0)) AS AVG_OFF_PRCT_DNRM,
                           MAX(ISNULL(rp.RELS_TIME, GETDATE())) AS MAX_RELS_TIME,
                           AVG(ISNULL(rp.VIST_CONT_DNRM, 0)) AS AVG_VIST_CONT_DNRM,
                           AVG(ISNULL(rp.BEST_SLNG_CONT_DNRM, 0)) AS AVG_BEST_SLNG_CONT_DNRM,
                           AVG(ISNULL(rp.LIKE_CONT_DNRM, 0)) AS AVG_LIKE_CONT_DNRM,
                           AVG(ISNULL(rp.DELV_DAY_DNRM, 0) + ISNULL(rp.DELV_HOUR_DNRM, 0)
                               + ISNULL(rp.DELV_MINT_DNRM, 0)
                              ) AS AVG_DELV_TIME_DNRM,
                           AVG(ISNULL(rp.MAKE_DAY_DNRM, 0) + ISNULL(rp.MAKE_HOUR_DNRM, 0)
                               + ISNULL(rp.MAKE_MINT_DNRM, 0)
                              ) AS AVG_MAKE_TIME_DNRM
                    FROM dbo.Robot_Product rp
                        LEFT OUTER JOIN dbo.Robot_Product_Discount rpd
                            ON rp.ROBO_RBID = rpd.ROBO_RBID
                               AND rp.TARF_CODE = rpd.TARF_CODE
                    WHERE rp.ROBO_RBID = @Rbid
                          -- اگر کالا قابل دیدن برای مشتری خاص باشد
                          AND NOT EXISTS (
                              SELECT *
                                FROM dbo.Robot_Product_Limited rpl, dbo.Robot_Limited_Commodity_Group rlcg
                               WHERE rpl.RLCG_CODE = rlcg.CODE
                                 AND rlcg.ROBO_RBID = rp.ROBO_RBID
                                 AND rpl.RBPR_CODE = rp.CODE
                                 AND rpl.STAT = '002'
                                 AND rlcg.STAT = '002'
                                 AND NOT EXISTS (
                                     SELECT *
                                       FROM dbo.Service_Robot_Access_Limited_Group_Product sral
                                      WHERE sral.RLCG_CODE = rlcg.CODE
                                        AND sral.CHAT_ID = @ChatID
                                        AND sral.STAT = '002'                                        
                                 )
                          )
                    GROUP BY rp.BRND_CODE_DNRM,
                             rp.BRND_TEXT_DNRM
                ) T
                ORDER BY CASE @SortType
                             WHEN 'splh' THEN
                                 T.AVG_EXPN_PRIC_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'sphl' THEN
                                 T.AVG_EXPN_PRIC_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC,
                         CASE @SortType
                             WHEN 'sdlh' THEN
                                 T.AVG_OFF_PRCT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'sdhl' THEN
                                 T.AVG_OFF_PRCT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC,
                         CASE @SortType
                             WHEN 'srno' THEN
                                 T.MAX_RELS_TIME
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'sron' THEN
                                 T.MAX_RELS_TIME
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC,
                         CASE @SortType
                             WHEN 'svml' THEN
                                 T.AVG_VIST_CONT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'svlm' THEN
                                 T.AVG_VIST_CONT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC,
                         CASE @SortType
                             WHEN 'sfml' THEN
                                 T.AVG_LIKE_CONT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'sflm' THEN
                                 T.AVG_LIKE_CONT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC,
                         CASE @SortType
                             WHEN 'sbml' THEN
                                 T.AVG_BEST_SLNG_CONT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'sblm' THEN
                                 T.AVG_BEST_SLNG_CONT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC,
                         CASE @SortType
                             WHEN 'stfs' THEN
                                 T.AVG_DELV_TIME_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'stsf' THEN
                                 T.AVG_DELV_TIME_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC,
                         CASE @SortType
                             WHEN 'smfs' THEN
                                 T.AVG_MAKE_TIME_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'smsf' THEN
                                 T.AVG_MAKE_TIME_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC;
                SET @ToDate = GETDATE();

                SET @Message =
                (
                    SELECT N'🔍 برندها' + CHAR(10)
                           + dbo.STR_FRMT_U(
                                               N'🗂 حدود {0} نتیجه، ({1} ثانیه)',
                                               REPLACE(
                                                          CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(T.Brnd_Code)), 1),
                                                          '.00',
                                                          ''
                                                      ) + N','
                                               + CAST(DATEDIFF(SECOND, @FromDate, @ToDate) AS NVARCHAR(50))
                                           )
                    FROM @T#BrandsWar T
                    FOR XML PATH('')
                );
                SET @Message += CHAR(10)
                                +
                                (
                                    SELECT CASE Item
                                               WHEN 'n' THEN
                                                   ''
                                               WHEN 'splh' THEN
                                                   N'👈 لیست بر اساس قیمت از 🔺 ارزان به گران نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sphl' THEN
                                                   N'👈 لیست بر اساس قیمت از 🔻 گران به ارزان نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sdlh' THEN
                                                   N'👈 لیست بر اساس تخفیف از 🔺 کم به زیاد نمایش داده شده' + CHAR(10)
                                               WHEN 'sdhl' THEN
                                                   N'👈 لیست بر اساس تخفیف از 🔻 زیاد به کم نمایش داده شده' + CHAR(10)
                                               WHEN 'srno' THEN
                                                   N'👈 لیست بر اساس زمان انتشار از 🔺 جدید به قدیم نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sron' THEN
                                                   N'👈 لیست بر اساس زمان انتشار از 🔻 قدیم به جدید نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'svml' THEN
                                                   N'👈 لیست بر اساس بازدید از 🔺 زیاد به کم نمایش داده شده' + CHAR(10)
                                               WHEN 'svlm' THEN
                                                   N'👈 لیست بر اساس بازدید از 🔻 کم به زیاد نمایش داده شده' + CHAR(10)
                                               WHEN 'sfml' THEN
                                                   N'👈 لیست بر اساس محبوبیت از 🔺 زیاد به کم نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sflm' THEN
                                                   N'👈 لیست بر اساس زمان محبوبیت از 🔻 کم به زیاد نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sbml' THEN
                                                   N'👈 لیست بر اساس پر فروش ترین از 🔺 زیاد به کم نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sblm' THEN
                                                   N'👈 لیست بر اساس پر فروش ترین از 🔻 کم به زیاد نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'stfs' THEN
                                                   N'👈 لیست بر اساس زمان ارسال / تحویل از 🔺 سریع به کند نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'stsf' THEN
                                                   N'👈 لیست بر اساس زمان ارسال / تحویل از 🔻 کند به سریع نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'smfs' THEN
                                                   N'👈 لیست بر اساس زمان تولید از 🔺 سریع به کند نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'smsf' THEN
                                                   N'👈 لیست بر اساس زمان تولید از 🔻 کند به سریع نمایش داده شده'
                                                   + CHAR(10)
                                           END
                                    FROM dbo.SplitString(@ParamText, ',')
                                    WHERE id = 2
                                );

                -- اگر جستجو هیچ گونه خروجی در بر نداشته باشد
                IF NOT EXISTS (SELECT * FROM @T#BrandsWar)
                BEGIN
                    SET @XTemp =
                    (
                        SELECT 1 AS '@order',
                               N'داده ای یافت نشد' AS '@caption'
                        FOR XML PATH('InlineKeyboardMarkup')
                    );
                    GOTO L$CountineBrandsWar;
                END;

                SET @XTemp =
                (
                    SELECT T.Data AS '@data',
                           T.Ordr AS '@order',
                           N'⚡️ ' + T.[Text] AS "text()"
                    FROM @T#BrandsWar T
                    WHERE T.Ordr
                    BETWEEN ((@Page - 1) * @PageFechRows) + 1 AND ((((@Page - 1) * @PageFechRows)) + @PageFechRows)
                    FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                );
                SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
                SET @XTemp.modify('insert attribute caption {sql:variable("@Message")} into (//InlineKeyboardMarkup)[1]');

                -- [      
                ---- اضافه کردن صفحه بندی * Next * Perv
                ---- Sort 
                -- ]

                -- اگر تعداد رکورد های درون جدول خروجی بیشتر از صفحه بندی باشد 
                IF @Page * @PageFechRows <=
                (
                    SELECT COUNT(*) FROM @T#BrandsWar
                )
                BEGIN
                    -- Update parameter for change page number
                    SET @ParamText =
                    (
                        SELECT CASE
                                   WHEN id IN ( 1 ) THEN
                                       CAST(@Page + 1 AS VARCHAR(10)) + ','
                                   WHEN id IN ( 2, 3 ) THEN
                                       Item + ','
                                   ELSE
                                       Item
                               END
                        FROM dbo.SplitString(@ParamText, ',')
                        FOR XML PATH('')
                    );
                    SET @Index = @PageFechRows + 1;
                    -- Next Step #. Next Page
                    -- Dynamic
                    SET @X =
                    (
                        SELECT dbo.STR_FRMT_U('./*0#;brandswar::show-{0}$del#', @ParamText) AS '@data',
                               @Index AS '@order',
                               N'▶️ صفحه بعدی' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                    );
                    SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                    SET @Index += 1;
                END;
                -- اضافه کردن دکمه صفحه قبل 
                IF @Page > 1
                BEGIN
                    -- Update parameter for change page number
                    SET @ParamText =
                    (
                        SELECT CASE
                                   WHEN id IN ( 1 ) THEN
                                       CAST(@Page - 1 AS VARCHAR(10)) + ','
                                   WHEN id IN ( 2, 3 ) THEN
                                       Item + ','
                                   ELSE
                                       Item
                               END
                        FROM dbo.SplitString(@ParamText, ',')
                        FOR XML PATH('')
                    );
                    -- Next Step #. Perv Page
                    -- Dynamic
                    SET @X =
                    (
                        SELECT dbo.STR_FRMT_U('./*0#;brandswar::show-{0}$del#', @ParamText) AS '@data',
                               @Index AS '@order',
                               N'◀️ صفحه قبلی' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                    );
                    SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                    SET @Index += 1;
                END;

                L$CountineBrandsWar:
                -- Update parameter for change page number
                SET @ParamText =
                (
                    SELECT CASE
                               WHEN id IN ( 1 ) THEN
                                   CAST(@Page AS VARCHAR(10)) + ','
                               WHEN id IN ( 2, 3 ) THEN
                                   Item + ','
                               ELSE
                                   Item
                           END
                    FROM dbo.SplitString(@ParamText, ',')
                    FOR XML PATH('')
                );
                -- اضافه کردن مرتب سازی      
                -- Static
                SET @X =
                (
                    SELECT REPLACE('./*0#;brandswar::sort-{0}$del,lesssortdeal#', '{0}', @ParamText) AS '@data',
                           @Index AS '@order',
                           N'📚 مرتب سازی' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );
                SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;

                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
            ELSE IF @MenuText IN ( 'brandswar::sort', 'brandswar::showinfobrand::sort',
                                   'brandswar::showinfobrand::advance'
                                 )
            BEGIN
                IF @MenuText IN ( 'brandswar::sort', 'brandswar::showinfobrand::sort' )
                BEGIN
                    SET @Message = N'💹 شما می توانید اطلاعات خروجی را به دلخواه خود مرتب کنید';
                    SET @Message += CHAR(10)
                                    +
                                    (
                                        SELECT CASE Item
                                                   WHEN 'n' THEN
                                                       N'👈 لیست بدون ترتیب نمایش داده شده'
                                                   WHEN 'splh' THEN
                                                       N'👈 لیست بر اساس قیمت از 🔺 ارزان به گران نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sphl' THEN
                                                       N'👈 لیست بر اساس قیمت از 🔻 گران به ارزان نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sdlh' THEN
                                                       N'👈 لیست بر اساس تخفیف از 🔺 کم به زیاد نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sdhl' THEN
                                                       N'👈 لیست بر اساس تخفیف از 🔻 زیاد به کم نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'srno' THEN
                                                       N'👈 لیست بر اساس زمان انتشار از 🔺 جدید به قدیم نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sron' THEN
                                                       N'👈 لیست بر اساس زمان انتشار از 🔻 قدیم به جدید نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'svml' THEN
                                                       N'👈 لیست بر اساس بازدید از 🔺 زیاد به کم نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'svlm' THEN
                                                       N'👈 لیست بر اساس بازدید از 🔻 کم به زیاد نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sfml' THEN
                                                       N'👈 لیست بر اساس محبوبیت از 🔺 زیاد به کم نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sflm' THEN
                                                       N'👈 لیست بر اساس زمان محبوبیت از 🔻 کم به زیاد نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sbml' THEN
                                                       N'👈 لیست بر اساس پر فروش ترین از 🔺 زیاد به کم نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'sblm' THEN
                                                       N'👈 لیست بر اساس پر فروش ترین از 🔻 کم به زیاد نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'stfs' THEN
                                                       N'👈 لیست بر اساس زمان ارسال / تحویل از 🔺 سریع به کند نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'stsf' THEN
                                                       N'👈 لیست بر اساس زمان ارسال / تحویل از 🔻 کند به سریع نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'smfs' THEN
                                                       N'👈 لیست بر اساس زمان تولید از 🔺 سریع به کند نمایش داده شده'
                                                       + CHAR(10)
                                                   WHEN 'smsf' THEN
                                                       N'👈 لیست بر اساس زمان تولید از 🔻 کند به سریع نمایش داده شده'
                                                       + CHAR(10)
                                               END
                                        FROM dbo.SplitString(@ParamText, ',')
                                        WHERE id = 2
                                    );
                END;
                ELSE IF @MenuText = 'brandswar::showinfobrand::advance'
                BEGIN
                    SET @Message = N'💹 شما می توانید اطلاعات خروجی را به دلخواه خود فیلتر کنید';
                    SET @Message += CHAR(10)
                                    +
                                    (
                                        SELECT CASE SUBSTRING(Item, 2, LEN(Item))
                                                   WHEN 'n' THEN
                                                       N'👈 لیست بدون فیلتر نمایش داده شده'
                                                   ELSE
                                               (
                                                   SELECT CASE SUBSTRING(Item, 1, 1)
                                                              WHEN 'b' THEN
                                                                  N'👈 لیست بر اساس *برند کالا* فیلتر شده' + CHAR(10)
                                                              WHEN 'g' THEN
                                                                  N'👈 لیست بر اساس *گروه کالا* فیلتر شده' + CHAR(10)
                                                              WHEN 't' THEN
                                                                  N'👈 لیست بر اساس *نوع معاملات* فیلتر شده' + CHAR(10)
                                                              WHEN 'p' THEN
                                                                  N'👈 لیست بر اساس *مبلغ کالا* فیلتر شده' + CHAR(10)
                                                              WHEN 'd' THEN
                                                                  N'👈 لیست بر اساس *تخفیف ها* فیلتر شده' + CHAR(10)
                                                              WHEN 'c' THEN
                                                                  N'👈 لیست بر اساس *بازخورد مشتریان* فیلتر شده'
                                                                  + CHAR(10)
                                                              ELSE
                                                                  N''
                                                          END
                                                   FROM dbo.SplitString(SUBSTRING(Item, 2, LEN(Item)), '*')
                                                   FOR XML PATH('')
                                               )
                                               END
                                        FROM dbo.SplitString(@ParamText, ',')
                                        WHERE id = 3
                                    );
                END;

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           CASE @MenuText
                               WHEN 'brandswar::sort' THEN
                                   'lesssortbrnd'
                               WHEN 'brandswar::showinfobrand::sort' THEN
                                   'lesssortprodbrnd'
                               WHEN 'brandswar::showinfobrand::advance' THEN
                                   'lessadvnbrnd'
                           END AS '@cmndtext',
                           @ParamText AS '@param'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
            ELSE IF @MenuText IN ( 'brandswar::showinfobrand::show' )
            BEGIN
                -- در این قسمت ما یک سری ورودی داریم که کاربر این موارد را وارد میکند
                -- 1 ) Page Number
                -- 2 ) Sort
                -- 2.1 ) Price 
                -- 2.1.1 ) {Low to High} (splh)
                -- 2.1.2 ) {High to Low} (sphl)
                -- 2.2 ) Discount
                -- 2.2.1 ) {Low to High} (sdlh)
                -- 2.2.2 ) {High to Low} (sdhl)
                -- 2.3 ) Release
                -- 2.3.1 ) {New to Old} {srno}
                -- 2.3.2 ) {Old to New} (sron)
                -- 2.4 ) Visited
                -- 2.4.1 ) {More to Less} (svml)
                -- 2.4.2 ) {Less to More} (svlm)
                -- 2.5 ) Favorite
                -- 2.5.1 ) {More to Less} (sfml)
                -- 2.5.2 ) {Less to More} (sflm)
                -- 2.6 ) Best Selling
                -- 2.6.1 ) {More to Less} (sbml)
                -- 2.6.2 ) {Less to More} (sblm)
                -- 2.7 ) Time Deliver 
                -- 2.7.1 ) {Fast to Slow} (stfs)
                -- 2.7.2 ) {Slow to Fast} (stsf)
                -- 2.8 ) Time Make
                -- 2.8.1 ) {Fast to Slow} (stfs)
                -- 2.8.2 ) {Slow to Fast} (stsf)
                -- **********************************
                -- 3 ) Filter
                -- 3.1 ) Group Product (g123)
                -- 3.2 ) Deal Type (t001)
                -- 3.3 ) Price (p002)
                -- 3.4 ) Discount (d002)
                -- 3.5 ) Customer Review (c005)
                -- 3.6 ) Brand Product (b154)
                -- **********************************
                -- 4 ) Result 
                -- 4.1 ) Text Menu
                -- 4.2 ) Image (with Text) Menu

                -- ابتدا باید این موارد را از ورودی ارساب شده جدا کنیم
                SELECT @Page = CASE id
                                   WHEN 1 THEN
                                       Item
                                   ELSE
                                       @Page
                               END,
                       @SortType = CASE id
                                       WHEN 2 THEN
                                           Item
                                       ELSE
                                           @SortType
                                   END,
                       @FilterType = CASE id
                                         WHEN 3 THEN
                                             Item
                                         ELSE
                                             @FilterType
                                     END,
                       @ResultType = CASE id
                                         WHEN 4 THEN
                                             Item
                                         ELSE
                                             @ResultType
                                     END
                FROM dbo.SplitString(@ParamText, ',');

                -- اگر برای داده ها فیلتری انتخاب شده باشد
                IF @FilterType != 'n'
                BEGIN
                    SELECT @FBCode = CASE SUBSTRING(Item, 1, 1)
                                         WHEN 'b' THEN
                                             SUBSTRING(Item, 2, LEN(Item))
                                         ELSE
                                             @FBCode
                                     END,
                           @FGCode = CASE SUBSTRING(Item, 1, 1)
                                         WHEN 'g' THEN
                                             SUBSTRING(Item, 2, LEN(Item))
                                         ELSE
                                             @FGCode
                                     END,
                           @FTCode = CASE SUBSTRING(Item, 1, 1)
                                         WHEN 't' THEN
                                             SUBSTRING(Item, 2, LEN(Item))
                                         ELSE
                                             @FTCode
                                     END,
                           @FPCode = CASE SUBSTRING(Item, 1, 1)
                                         WHEN 'p' THEN
                                             SUBSTRING(Item, 2, LEN(Item))
                                         ELSE
                                             @FPCode
                                     END,
                           @FDCode = CASE SUBSTRING(Item, 1, 1)
                                         WHEN 'd' THEN
                                             SUBSTRING(Item, 2, LEN(Item))
                                         ELSE
                                             @FDCode
                                     END,
                           @FCCode = CASE SUBSTRING(Item, 1, 1)
                                         WHEN 'c' THEN
                                             SUBSTRING(Item, 2, LEN(Item))
                                         ELSE
                                             @FCCode
                                     END
                    FROM dbo.SplitString(@FilterType, '*');
                END;

                DECLARE @T#ProductsOfBrand TABLE
                (
                    Tarf_Code VARCHAR(100),
                    Data VARCHAR(100),
                    Ordr INT,
                    [Text] NVARCHAR(MAX)
                );

                SET @FromDate = GETDATE();
                INSERT INTO @T#ProductsOfBrand
                (
                    Tarf_Code,
                    Data,
                    Ordr,
                    [Text]
                )
                SELECT rp.TARF_CODE,
                       N'./' + @UssdCode + N';infoprod-' + CAST(rp.TARF_CODE AS NVARCHAR(100)) + N'$lessinfoprod#' AS DATA,
                       ROW_NUMBER() OVER (ORDER BY rp.TARF_CODE) AS ORDR,
                       N'📦  ' + rp.TARF_TEXT_DNRM
                       + dbo.STR_FRMT_U(
                                           N' [ {0} نفر ]',
                                           --dbo.STR_COPY_U(N'⭐️ ', rp.RTNG_NUMB_DNRM) + N','
                                           + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, rp.RTNG_CONT_DNRM), 1), '.00', '')
                                       ) AS [TEXT]
                FROM dbo.Robot_Product rp
                    LEFT OUTER JOIN dbo.Robot_Product_Discount rpd
                        ON rp.ROBO_RBID = rpd.ROBO_RBID
                           AND rp.TARF_CODE = rpd.TARF_CODE
                WHERE rp.ROBO_RBID = @Rbid
                      AND rp.BRND_CODE_DNRM = @FBCode
                      -- اگر کالا قابل دیدن برای مشتری خاص باشد
                      AND NOT EXISTS (
                           SELECT *
                             FROM dbo.Robot_Product_Limited rpl, dbo.Robot_Limited_Commodity_Group rlcg
                            WHERE rpl.RLCG_CODE = rlcg.CODE
                              AND rlcg.ROBO_RBID = rp.ROBO_RBID
                              AND rpl.RBPR_CODE = rp.CODE
                              AND rpl.STAT = '002'
                              AND rlcg.STAT = '002'
                              AND NOT EXISTS (
                                  SELECT *
                                    FROM dbo.Service_Robot_Access_Limited_Group_Product sral
                                   WHERE sral.RLCG_CODE = rlcg.CODE
                                     AND sral.CHAT_ID = @ChatID
                                     AND sral.STAT = '002'                                        
                              )
                      )
                      AND
                      (
                          @FGCode IS NULL
                          OR iScsc.dbo.LINK_GROP_U(rp.GROP_CODE_DNRM, @FGCode) = 1
                      )
                      AND
                      (
                          ISNULL(@FTCode, '000') = '000'
                          OR
                          (
                              @FTCode IN ( '001' /* فروش شگفت انگیز */, '002' /* تخفیف ویژه */ )
                              AND EXISTS
                (
                    SELECT rpd.TARF_CODE
                    FROM dbo.Robot_Product_Discount rpd
                    WHERE rpd.ROBO_RBID = rp.ROBO_RBID
                          AND rpd.TARF_CODE = rp.TARF_CODE
                          AND rpd.OFF_TYPE = @FTCode
                          AND
                          (
                              ISNULL(@FDCode, '000') = '000'
                              OR
                              (
                                  @FDCode = '001' /* 1-10% Off or more */
                                  AND rpd.OFF_PRCT
                          BETWEEN 1 AND 24
                              )
                              OR
                              (
                                  @FDCode = '002' /* 25% off or more */
                                  AND rpd.OFF_PRCT
                          BETWEEN 25 AND 49
                              )
                              OR
                              (
                                  @FDCode = '003' /* 50% off or more */
                                  AND rpd.OFF_PRCT
                          BETWEEN 50 AND 69
                              )
                              OR
                              (
                                  @FDCode = '004' /* 70% off or more */
                                  AND rpd.OFF_PRCT >= 70
                              )
                          )
                          AND
                          (
                              (
                                  rpd.OFF_TYPE = '001' /* showprodofftimer */
                                  AND rpd.REMN_TIME >= GETDATE()
                              )
                              OR rpd.OFF_TYPE != '001'
                          )
                          AND rpd.ACTV_TYPE = '002'
                )
                          )
                          OR
                          (
                              @FTCode = '003' /* فروش کالا همراه با هدیه */
                              AND EXISTS
                (
                    SELECT *
                    FROM dbo.Service_Robot_Seller_Product sp,
                         dbo.Service_Robot_Seller_Product_Gift pg
                    WHERE sp.TARF_CODE = rp.TARF_CODE
                          AND sp.CODE = pg.SRSP_CODE
                          AND pg.STAT = '002'
                )
                          )
                      )
                      AND
                      (
                          ISNULL(@FPCode, '000') = '000'
                          OR
                          (
                              @FPCode = '001' /* 0 - 250,000 Rial */
                              AND rp.EXPN_PRIC_DNRM
                      BETWEEN 0 AND 250000
                          )
                          OR
                          (
                              @FPCode = '002' /* 250,000 - 500,000 Rial */
                              AND rp.EXPN_PRIC_DNRM
                      BETWEEN 250001 AND 500000
                          )
                          OR
                          (
                              @FPCode = '003' /* 500,000 - 1,000,000 Rial */
                              AND rp.EXPN_PRIC_DNRM
                      BETWEEN 500001 AND 1000000
                          )
                          OR
                          (
                              @FPCode = '004' /* 1,000,000 - 2,000,000 Rial */
                              AND rp.EXPN_PRIC_DNRM
                      BETWEEN 1000001 AND 2000000
                          )
                          OR
                          (
                              @FPCode = '005' /* 2,000,000 - Infinity Rial */
                              AND rp.EXPN_PRIC_DNRM > 2000000
                          )
                      )
                      AND
                      (
                          ISNULL(@FCCode, 0) = 0
                          OR rp.RTNG_NUMB_DNRM >= @FCCode
                      )
                ORDER BY CASE @SortType
                             WHEN 'splh' THEN
                                 rp.EXPN_PRIC_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'sphl' THEN
                                 rp.EXPN_PRIC_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC,
                         CASE @SortType
                             WHEN 'sdlh' THEN
                                 rpd.OFF_PRCT
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'sdhl' THEN
                                 rpd.OFF_PRCT
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC,
                         CASE @SortType
                             WHEN 'srno' THEN
                                 rp.RELS_TIME
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'sron' THEN
                                 rp.RELS_TIME
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC,
                         CASE @SortType
                             WHEN 'svml' THEN
                                 rp.VIST_CONT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'svlm' THEN
                                 rp.VIST_CONT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC,
                         CASE @SortType
                             WHEN 'sfml' THEN
                                 rp.LIKE_CONT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'sflm' THEN
                                 rp.LIKE_CONT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC,
                         CASE @SortType
                             WHEN 'sbml' THEN
                                 rp.BEST_SLNG_CONT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END ASC,
                         CASE @SortType
                             WHEN 'sblm' THEN
                                 rp.BEST_SLNG_CONT_DNRM
                             ELSE
                         (
                             SELECT NULL
                         )
                         END DESC /*,
                     --**##CASE @SortType WHEN 'stfs' THEN (rp.ِDELV_DAY_DNRM + rp.DELV_HOUR_DNRM + rp.DELV_MINT_DNRM) ELSE (SELECT NULL) END ASC,
                     CASE @SortType WHEN 'stsf' THEN (rp.ِDELV_DAY_DNRM + rp.DELV_HOUR_DNRM + rp.DELV_MINT_DNRM) ELSE (SELECT NULL) END DESC,
                     CASE @SortType WHEN 'smfs' THEN (rp.MAKE_DAY_DNRM + rp.MAKE_HOUR_DNRM + rp.MAKE_MINT_DNRM) ELSE (SELECT NULL) END ASC,
                     CASE @SortType WHEN 'smsf' THEN (rp.ِMAKE_DAY_DNRM + rp.MAKE_HOUR_DNRM + rp.MAKE_MINT_DNRM) ELSE (SELECT NULL) END DESC*/
                ;
                SET @ToDate = GETDATE();

                SET @Message =
                (
                    SELECT N'🔍 محصولات برند انتخابی' + CHAR(10)
                           + dbo.STR_FRMT_U(
                                               N'🗂 حدود {0} نتیجه، ({1} ثانیه)',
                                               REPLACE(
                                                          CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(T.Tarf_Code)), 1),
                                                          '.00',
                                                          ''
                                                      ) + N','
                                               + CAST(DATEDIFF(SECOND, @FromDate, @ToDate) AS NVARCHAR(50))
                                           )
                    FROM @T#ProductsOfBrand T
                    FOR XML PATH('')
                );
                SET @Message += CHAR(10)
                                +
                                (
                                    SELECT CASE Item
                                               WHEN 'n' THEN
                                                   ''
                                               WHEN 'splh' THEN
                                                   N'👈 لیست بر اساس قیمت از 🔺 ارزان به گران نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sphl' THEN
                                                   N'👈 لیست بر اساس قیمت از 🔻 گران به ارزان نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sdlh' THEN
                                                   N'👈 لیست بر اساس تخفیف از 🔺 کم به زیاد نمایش داده شده' + CHAR(10)
                                               WHEN 'sdhl' THEN
                                                   N'👈 لیست بر اساس تخفیف از 🔻 زیاد به کم نمایش داده شده' + CHAR(10)
                                               WHEN 'srno' THEN
                                                   N'👈 لیست بر اساس زمان انتشار از 🔺 جدید به قدیم نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sron' THEN
                                                   N'👈 لیست بر اساس زمان انتشار از 🔻 قدیم به جدید نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'svml' THEN
                                                   N'👈 لیست بر اساس بازدید از 🔺 زیاد به کم نمایش داده شده' + CHAR(10)
                                               WHEN 'svlm' THEN
                                                   N'👈 لیست بر اساس بازدید از 🔻 کم به زیاد نمایش داده شده' + CHAR(10)
                                               WHEN 'sfml' THEN
                                                   N'👈 لیست بر اساس محبوبیت از 🔺 زیاد به کم نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sflm' THEN
                                                   N'👈 لیست بر اساس زمان محبوبیت از 🔻 کم به زیاد نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sbml' THEN
                                                   N'👈 لیست بر اساس پر فروش ترین از 🔺 زیاد به کم نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'sblm' THEN
                                                   N'👈 لیست بر اساس پر فروش ترین از 🔻 کم به زیاد نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'stfs' THEN
                                                   N'👈 لیست بر اساس زمان ارسال / تحویل از 🔺 سریع به کند نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'stsf' THEN
                                                   N'👈 لیست بر اساس زمان ارسال / تحویل از 🔻 کند به سریع نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'smfs' THEN
                                                   N'👈 لیست بر اساس زمان تولید از 🔺 سریع به کند نمایش داده شده'
                                                   + CHAR(10)
                                               WHEN 'smsf' THEN
                                                   N'👈 لیست بر اساس زمان تولید از 🔻 کند به سریع نمایش داده شده'
                                                   + CHAR(10)
                                           END
                                    FROM dbo.SplitString(@ParamText, ',')
                                    WHERE id = 2
                                ) +
                                (
                                    SELECT
                                        (
                                            SELECT CASE
                                                       WHEN t.Item LIKE '%n%' THEN
                                                           N''
                                                       WHEN t.Item LIKE '%b%' THEN
                                                           N'👈 لیست بر اساس *برند کالا* فیلتر شده' + CHAR(10)
                                                       WHEN t.Item LIKE '%g%' THEN
                                                           N'👈 لیست بر اساس *گروه کالا* فیلتر شده' + CHAR(10)
                                                       WHEN t.Item LIKE '%t%'
                                                            AND t.Item NOT LIKE '%t000%' THEN
                                                           N'👈 لیست بر اساس *نوع معاملات* فیلتر شده' + CHAR(10)
                                                       WHEN t.Item LIKE '%p%'
                                                            AND t.Item NOT LIKE '%p000%' THEN
                                                           N'👈 لیست بر اساس *مبلغ کالا* فیلتر شده' + CHAR(10)
                                                       WHEN t.Item LIKE '%d%'
                                                            AND t.Item NOT LIKE '%d000%' THEN
                                                           N'👈 لیست بر اساس *تخفیف ها* فیلتر شده' + CHAR(10)
                                                       WHEN t.Item LIKE '%c%'
                                                            AND t.Item NOT LIKE '%c000%' THEN
                                                           N'👈 لیست بر اساس *بازخورد مشتریان* فیلتر شده' + CHAR(10)
                                                   END
                                            FROM dbo.SplitString(Item, '*') t
                                            WHERE LEN(t.Item) != 0
                                            FOR XML PATH('')
                                        )
                                    FROM dbo.SplitString(@ParamText, ',')
                                    WHERE id = 3
                                );

                -- اگر جستجو هیچ گونه خروجی در بر نداشته باشد
                IF NOT EXISTS (SELECT * FROM @T#ProductsOfBrand)
                BEGIN
                    SET @XTemp =
                    (
                        SELECT 1 AS '@order',
                               N'داده ای یافت نشد' AS '@caption'
                        FOR XML PATH('InlineKeyboardMarkup')
                    );
                    GOTO L$CountineProductsOfBrand;
                END;

                SET @XTemp =
                (
                    SELECT T.Data AS '@data',
                           T.Ordr AS '@order',
                           N'⚡️ ' + T.[Text] AS "text()"
                    FROM @T#ProductsOfBrand T
                    WHERE T.Ordr
                    BETWEEN ((@Page - 1) * @PageFechRows) + 1 AND ((((@Page - 1) * @PageFechRows)) + @PageFechRows)
                    FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                );
                SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
                SET @XTemp.modify('insert attribute caption {sql:variable("@Message")} into (//InlineKeyboardMarkup)[1]');

                -- [      
                ---- Advance Search
                ---- اضافه کردن صفحه بندی * Next * Perv
                ---- Sort 
                -- ]

                -- اگر تعداد رکورد های درون جدول خروجی بیشتر از صفحه بندی باشد 
                IF @Page * @PageFechRows <=
                (
                    SELECT COUNT(*) FROM @T#BrandsWar
                )
                BEGIN
                    -- Update parameter for change page number
                    SET @ParamText =
                    (
                        SELECT CASE
                                   WHEN id IN ( 1 ) THEN
                                       CAST(@Page + 1 AS VARCHAR(10)) + ','
                                   WHEN id IN ( 2, 3 ) THEN
                                       Item + ','
                                   ELSE
                                       Item
                               END
                        FROM dbo.SplitString(@ParamText, ',')
                        FOR XML PATH('')
                    );
                    SET @Index = @PageFechRows + 1;
                    -- Next Step #. Next Page
                    -- Dynamic
                    SET @X =
                    (
                        SELECT dbo.STR_FRMT_U('./*0#;brandswar::showinfobrand-{0}$del#', @ParamText) AS '@data',
                               @Index AS '@order',
                               N'▶️ صفحه بعدی' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                    );
                    SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                    SET @Index += 1;
                END;
                -- اضافه کردن دکمه صفحه قبل 
                IF @Page > 1
                BEGIN
                    -- Update parameter for change page number
                    SET @ParamText =
                    (
                        SELECT CASE
                                   WHEN id IN ( 1 ) THEN
                                       CAST(@Page - 1 AS VARCHAR(10)) + ','
                                   WHEN id IN ( 2, 3 ) THEN
                                       Item + ','
                                   ELSE
                                       Item
                               END
                        FROM dbo.SplitString(@ParamText, ',')
                        FOR XML PATH('')
                    );
                    -- Next Step #. Perv Page
                    -- Dynamic
                    SET @X =
                    (
                        SELECT dbo.STR_FRMT_U('./*0#;brandswar::showinfobrand-{0}$del#', @ParamText) AS '@data',
                               @Index AS '@order',
                               N'◀️ صفحه قبلی' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                    );
                    SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                    SET @Index += 1;
                END;

                L$CountineProductsOfBrand:
                -- Update parameter for change page number
                SET @ParamText =
                (
                    SELECT CASE
                               WHEN id IN ( 1 ) THEN
                                   CAST(@Page AS VARCHAR(10)) + ','
                               WHEN id IN ( 2, 3 ) THEN
                                   Item + ','
                               ELSE
                                   Item
                           END
                    FROM dbo.SplitString(@ParamText, ',')
                    FOR XML PATH('')
                );
                -- اضافه کردن مرتب سازی      
                -- Static
                SET @X =
                (
                    SELECT REPLACE('./*0#;brandswar::showinfobrand::sort-{0}$del,lesssortprodbrnd#', '{0}', @ParamText) AS '@data',
                           @Index AS '@order',
                           N'📚 مرتب سازی' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );
                SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;

                -- Advance Search
                -- Static
                SET @X =
                (
                    SELECT REPLACE('./*0#;brandswar::showinfobrand::advance-{0}$del,lessadvnbrnd#', '{0}', @ParamText) AS '@data',
                           @Index AS '@order',
                           N'🔍 جستجوی پیشرفته' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );
                SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;

                -- Back
                -- Static
                SET @X =
                (
                    SELECT REPLACE('./*0#;brandswar::show-{0}$del#', '{0}', @ParamText) AS '@data',
                           @Index AS '@order',
                           N'⤴️ بازگشت' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );
                SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;

                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
            ELSE IF @MenuText = 'brandswar::showinfobrand::advance::category'
            BEGIN
                -- بدست آوردن اینکه در گروه کالا ها باید چه مرحله ای را پیمایش کنیم
                SELECT @gropexpn = CASE
                                       WHEN Item = 'n'
                                            OR Item NOT LIKE '%g%' THEN
                                           NULL
                                       ELSE
                (
                    SELECT SUBSTRING(Item, 2, LEN(Item))
                    FROM dbo.SplitString(Item, '*')
                    WHERE Item LIKE 'g%'
                )
                                   END
                FROM dbo.SplitString(@ParamText, ',')
                WHERE id = 3;

                SET @QueryStatement =
                (
                    SELECT CASE
                               WHEN id IN ( 1, 2 ) THEN
                                   Item + ','
                               WHEN id = 3
                                    AND ISNULL(@gropexpn, 0) != 0 THEN
                        (
                            SELECT CASE SUBSTRING(Item, 1, 1)
                                       WHEN 'g' THEN
                                           'g{0}*'
                                       ELSE
                                           Item + '*'
                                   END
                            FROM dbo.SplitString(Item, '*')
                            WHERE LEN(Item) != 0
                            FOR XML PATH('')
                        ) + ','
                               WHEN id = 3
                                    AND ISNULL(@gropexpn, 0) = 0
                                    AND Item != 'n' THEN
                                   Item + '*g{0},'
                               WHEN id = 3
                                    AND ISNULL(@gropexpn, 0) = 0
                                    AND Item = 'n' THEN
                                   'g{0},'
                               WHEN id = 4 THEN
                                   Item
                           END
                    FROM dbo.SplitString(@ParamText, ',')
                    FOR XML PATH('')
                );

                -- آیا به نرم افزار حسابداری متصل میباشد
                IF @CnctAcntApp = '002'
                BEGIN
                    -- نرم افزار مدیریتی آرتا
                    IF @AcntAppType = '001'
                    BEGIN
                        -- نمایش گروه سطح یک
                        IF @gropexpn IS NULL -- @ParamText = 'frstlevl' 
                        BEGIN
                            SET @XTemp =
                            (
                                SELECT N'./*0#;brandswar::showinfobrand::advance::category-'
                                       + REPLACE(@QueryStatement, '{0}', ge.CODE) + N'$del#' AS '@data',
                                       ROW_NUMBER() OVER (ORDER BY ge.ORDR) AS '@order',
                                       N'📚 ' + ge.GROP_DESC AS "text()"
                                FROM iScsc.dbo.Group_Expense ge
                                WHERE ge.GEXP_CODE IS NULL
                                      AND ge.GROP_TYPE = '001' -- گروه ها
                                      AND ISNULL(ge.SUB_EXPN_NUMB_DNRM, 0) > 0
                                ORDER BY ge.ORDR
                                FOR XML PATH('InlineKeyboardButton') --, ROOT('InlineKeyboardMarkup')
                            );
                            SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE('./*0#;brandswar::showinfobrand::show-{0}$del#', '{0}', @ParamText) AS '@data',
                                       @Index AS '@order',
                                       N'📊 نمایش خروجی' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE(   './*0#;brandswar::showinfobrand::advance-{0}$del#',
                                                  '{0}',
                                       (
                                           SELECT CASE
                                                      WHEN id IN ( 1, 2 ) THEN
                                                          Item + ','
                                                      WHEN id = 3
                                                           AND Item NOT LIKE '%g%' THEN
                                                          Item + ','
                                                      WHEN id = 3
                                                           AND Item LIKE '%g%' THEN
                                                          CASE
                                                          (
                                                              SELECT t.Item + '*'
                                                              FROM dbo.SplitString(Item, '*') t
                                                              WHERE t.Item NOT LIKE 'g%'
                                                              FOR XML PATH('')
                                                          )
                                                              WHEN '*' THEN
                                                                  'n'
                                                              ELSE
                                                          (
                                                              SELECT t.Item + '*'
                                                              FROM dbo.SplitString(Item, '*') t
                                                              WHERE LEN(t.Item) != 0
                                                                    AND t.Item NOT LIKE 'g%'
                                                              FOR XML PATH('')
                                                          )
                                                          END + ','
                                                      ELSE
                                                          Item
                                                  END
                                           FROM dbo.SplitString(@ParamText, ',')
                                           FOR XML PATH('')
                                       )
                                              ) AS '@data',
                                       @Index AS '@order',
                                       N'🎲 بدون فیلتر' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE('./*0#;brandswar::showinfobrand::advance-{0}$del#', '{0}', @ParamText) AS '@data',
                                       @Index AS '@order',
                                       N'⬆️ بازگشت' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;
                        END;
                        -- اگر گروه دارای زیر مجموعه های پایین تر را دارا باشد
                        ELSE IF EXISTS
                        (
                            SELECT ge.CODE
                            FROM iScsc.dbo.Group_Expense ge
                            WHERE ge.GEXP_CODE = @gropexpn
                        )
                        BEGIN
                            SET @XTemp =
                            (
                                SELECT N'./*0#;brandswar::showinfobrand::advance::category-'
                                       + REPLACE(@QueryStatement, '{0}', ge.CODE) + N'$del#' AS '@data',
                                       ROW_NUMBER() OVER (ORDER BY ge.ORDR) AS '@order',
                                       N'📚 ' + ge.GROP_DESC AS "text()"
                                FROM iScsc.dbo.Group_Expense ge
                                WHERE ge.GEXP_CODE = @gropexpn
                                      AND ge.GROP_TYPE = '001' -- گروه ها
                                      AND ISNULL(ge.SUB_EXPN_NUMB_DNRM, 0) > 0
                                ORDER BY ge.ORDR
                                FOR XML PATH('InlineKeyboardButton') --, ROOT('InlineKeyboardMarkup')
                            );
                            SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE('./*0#;brandswar::showinfobrand::show-{0}$del#', '{0}', @ParamText) AS '@data',
                                       @Index AS '@order',
                                       N'📊 نمایش خروجی' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE(   './*0#;brandswar::showinfobrand::advance-{0}$del#',
                                                  '{0}',
                                       (
                                           SELECT CASE
                                                      WHEN id IN ( 1, 2 ) THEN
                                                          Item + ','
                                                      WHEN id = 3
                                                           AND Item NOT LIKE '%g%' THEN
                                                          Item + ','
                                                      WHEN id = 3
                                                           AND Item LIKE '%g%' THEN
                                                          CASE
                                                          (
                                                              SELECT t.Item + '*'
                                                              FROM dbo.SplitString(Item, '*') t
                                                              WHERE t.Item NOT LIKE 'g%'
                                                              FOR XML PATH('')
                                                          )
                                                              WHEN '*' THEN
                                                                  'n'
                                                              ELSE
                                                          (
                                                              SELECT t.Item + '*'
                                                              FROM dbo.SplitString(Item, '*') t
                                                              WHERE LEN(t.Item) != 0
                                                                    AND t.Item NOT LIKE 'g%'
                                                              FOR XML PATH('')
                                                          )
                                                          END + ','
                                                      ELSE
                                                          Item
                                                  END
                                           FROM dbo.SplitString(@QueryStatement, ',')
                                           FOR XML PATH('')
                                       )
                                              ) AS '@data',
                                       @Index AS '@order',
                                       N'🎲 بدون فیلتر' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;


                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE(
                                                  './*0#;brandswar::showinfobrand::advance-{0}$del#',
                                                  '{0}',
                                                  REPLACE(@QueryStatement, '{0}', @gropexpn)
                                              ) AS '@data',
                                       @Index AS '@order',
                                       N'⬆️ بازگشت' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;
                        END;
                        -- اگر به انتهای گروه پایینی رسیده باشیم و در این قسمت باید محصولات نمایش داده شود
                        ELSE
                        BEGIN
                            SET @XTemp = '';
                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE('./*0#;brandswar::showinfobrand::show-{0}$del#', '{0}', @ParamText) AS '@data',
                                       @Index AS '@order',
                                       N'📊 نمایش خروجی' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE(   './*0#;brandswar::showinfobrand::advance-{0}$del#',
                                                  '{0}',
                                       (
                                           SELECT CASE
                                                      WHEN id IN ( 1, 2 ) THEN
                                                          Item + ','
                                                      WHEN id = 3
                                                           AND Item NOT LIKE '%g%' THEN
                                                          Item + ','
                                                      WHEN id = 3
                                                           AND Item LIKE '%g%' THEN
                                                          CASE
                                                          (
                                                              SELECT t.Item + '*'
                                                              FROM dbo.SplitString(Item, '*') t
                                                              WHERE t.Item NOT LIKE 'g%'
                                                              FOR XML PATH('')
                                                          )
                                                              WHEN '*' THEN
                                                                  'n'
                                                              ELSE
                                                          (
                                                              SELECT t.Item + '*'
                                                              FROM dbo.SplitString(Item, '*') t
                                                              WHERE LEN(t.Item) != 0
                                                                    AND t.Item NOT LIKE 'g%'
                                                              FOR XML PATH('')
                                                          )
                                                          END + ','
                                                      ELSE
                                                          Item
                                                  END
                                           FROM dbo.SplitString(@QueryStatement, ',')
                                           FOR XML PATH('')
                                       )
                                              ) AS '@data',
                                       @Index AS '@order',
                                       N'🎲 بدون فیلتر' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;

                            -- Static
                            SET @X =
                            (
                                SELECT REPLACE(
                                                  './*0#;brandswar::showinfobrand::advance-{0}$del#',
                                                  '{0}',
                                                  REPLACE(@QueryStatement, '{0}', @gropexpn)
                                              ) AS '@data',
                                       @Index AS '@order',
                                       N'⬆️ بازگشت' AS "text()"
                                FOR XML PATH('InlineKeyboardButton')
                            );
                            SET @XTemp.modify('insert sql:variable("@X") as last into (.)[1]');
                            SET @Index += 1;
                        END;

                        SET @XTemp =
                        (
                            SELECT '1' AS '@order',
                                   N'شما می توانید دسته بنده کالاهای خود را اینجا انتخاب کنید' AS '@caption',
                                   @XTemp
                            FOR XML PATH('InlineKeyboardMarkup')
                        );
                        SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                    END;
                END;
            END;
            ELSE IF @MenuText IN ( 'brandswar::showinfobrand::advance::type',
                                   'brandswar::showinfobrand::advance::price',
                                   'brandswar::showinfobrand::advance::discount',
                                   'brandswar::showinfobrand::advance::customerreview'
                                 )
            BEGIN
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           CASE @MenuText
                               WHEN 'brandswar::showinfobrand::advance::type' THEN
                                   'lessadvtbrnd'
                               WHEN 'brandswar::showinfobrand::advance::price' THEN
                                   'lessadvpbrnd'
                               WHEN 'brandswar::showinfobrand::advance::discount' THEN
                                   'lessadvdbrnd'
                               WHEN 'brandswar::showinfobrand::advance::customerreview' THEN
                                   'lessadvcbrnd'
                           END AS '@cmndtext',
                           @ParamText AS '@param'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
        END;
        -- نمایش محصولات موجود
        ELSE IF @MenuText IN ( 'product::inshelf' )
        BEGIN
            --DECLARE @gropexpn BIGINT;
            -- آیا به نرم افزار حسابداری متصل میباشد
            IF @CnctAcntApp = '002'
            BEGIN
                -- نرم افزار مدیریتی آرتا
                IF @AcntAppType = '001'
                BEGIN
                    -- نمایش گروه سطح یک
                    IF @ParamText = 'frstlevl'
                    BEGIN
                        SET @XTemp =
                        (
                            SELECT N'./' + @UssdCode + N';product::inshelf-' + CAST(ge.CODE AS NVARCHAR(30)) + N'$#' AS '@data',
                                   ROW_NUMBER() OVER (ORDER BY ge.ORDR) AS '@order',
                                   N'📚 ' + ge.GROP_DESC AS "text()"
                            FROM iScsc.dbo.Group_Expense ge
                            WHERE ge.GEXP_CODE IS NULL
                                  AND ge.GROP_TYPE = '001' -- گروه ها
                                  AND ISNULL(ge.SUB_EXPN_NUMB_DNRM, 0) > 0
                                  AND Exists (
                                      Select *
                                        from robot_product rp
                                       where ge.CODE = rp.ROOT_GROP_CODE_DNRM
                                         AND rp.STAT = '002'
                                         AND rp.CRNT_NUMB_DNRM > 0
                                  )
                            ORDER BY ge.ORDR
                            FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                        );
                        SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;
                        
                        -- Next Step #. More Menu
                        -- Static
                        SET @X = (
                           SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                                  @index AS '@order',
                                  N'⛔ بستن' AS "text()"
                              FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                    END;
                    -- اگر گروه دارای زیر مجموعه های پایین تر را دارا باشد
                    ELSE IF EXISTS
                    (
                        SELECT ge.CODE
                        FROM iScsc.dbo.Group_Expense ge
                        WHERE ge.GEXP_CODE = CAST(@ParamText AS BIGINT)
                    )
                    BEGIN
                        SET @XTemp =
                        (
                            SELECT N'./' + @UssdCode + N';product::inshelf-' + CAST(ge.CODE AS NVARCHAR(30)) + N'$#' AS '@data',
                                   ROW_NUMBER() OVER (ORDER BY ge.ORDR) AS '@order',
                                   N'📚 ' + ge.GROP_DESC AS "text()"
                            FROM iScsc.dbo.Group_Expense ge
                            WHERE ge.GEXP_CODE = CAST(@ParamText AS BIGINT)
                                  AND ge.GROP_TYPE = '001' -- گروه ها
                                  AND ISNULL(ge.SUB_EXPN_NUMB_DNRM, 0) > 0
                                  AND Exists(
                                      Select * 
                                        from Robot_Product rp
                                       WHERE iScsc.dbo.LINK_GROP_U(rp.GROP_CODE_DNRM, ge.Code) = 1
                                         AND ROBO_RBID = @Rbid
                                         AND STAT = '002'
                                         AND CRNT_NUMB_DNRM > 0
                                  )
                            ORDER BY ge.ORDR
                            FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                        );
                        SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;

                        -- نمایش تمامی محصولات این قسمت
                        -- Next Step #. Show Products
                        -- Static
                        SET @X =
                        (
                            SELECT dbo.STR_FRMT_U('./{0};product::showlistall-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
                                   @Index AS '@order',
                                   N'📦 لیست محصولات' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                        
                        -- نمایش تمامی محصولات این قسمت
                        -- Next Step #. Show Products
                        -- Static
                        SET @X =
                        (
                            SELECT dbo.STR_FRMT_U('./{0};product::showimageall-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
                                   @Index AS '@order',
                                   N'📦 عکس محصولات' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                        
                        -- Next Step #. More Menu
                        -- Static
                        SET @X = (
                           SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                                  @index AS '@order',
                                  N'⛔ بستن' AS "text()"
                              FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                    END;
                    -- اگر به انتهای گروه پایینی رسیده باشیم و در این قسمت باید محصولات نمایش داده شود
                    ELSE
                    BEGIN
                        SET @XTemp =
                        (
                            SELECT N'./' + @UssdCode + N';infoprod-' + CAST(rp.TARF_CODE AS NVARCHAR(100))
                                   + N'$lessinfoprod#' AS '@data',
                                   ROW_NUMBER() OVER (ORDER BY rp.TARF_TEXT_DNRM) AS '@order',
                                   N'📦  ' + SUBSTRING(rp.TARF_TEXT_DNRM, 1, 25) + CASE WHEN LEN(rp.Tarf_Text_Dnrm) > 25 THEN N' ...' ELSE N'' END + N' ( '
                                   + REPLACE(CONVERT(NVARCHAR,CONVERT(MONEY,rp.EXPN_PRIC_DNRM + ISNULL(rp.EXTR_PRCT_DNRM, 0)),1),'.00','') + N' ) ' + @AmntTypeDesc
                            FROM dbo.Robot_Product rp
                            WHERE rp.ROBO_RBID = @Rbid
                                  AND rp.GROP_CODE_DNRM = CAST(@ParamText AS BIGINT)
                                  -- اگر کالا قابل دیدن برای مشتری خاص باشد
                                   AND NOT EXISTS (
                                       SELECT *
                                         FROM dbo.Robot_Product_Limited rpl, dbo.Robot_Limited_Commodity_Group rlcg
                                        WHERE rpl.RLCG_CODE = rlcg.CODE
                                          AND rlcg.ROBO_RBID = rp.ROBO_RBID
                                          AND rpl.RBPR_CODE = rp.CODE
                                          AND rpl.STAT = '002'
                                          AND rlcg.STAT = '002'
                                          AND NOT EXISTS (
                                              SELECT *
                                                FROM dbo.Service_Robot_Access_Limited_Group_Product sral
                                               WHERE sral.RLCG_CODE = rlcg.CODE
                                                 AND sral.CHAT_ID = @ChatID
                                                 AND sral.STAT = '002'                                        
                                          )
                                   )
                            ORDER BY rp.TARF_TEXT_DNRM
                            FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                        );
                        SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;
                        
                        -- نمایش تمامی محصولات این قسمت
                        -- Next Step #. Show Products
                        -- Static
                        --SET @XTemp = (
							   --   SELECT N'' AS '@caption'
							   --      FOR XML PATH('InlineKeyboardMarkup')
                        --);
                        SET @X =
                        (
                            SELECT dbo.STR_FRMT_U('./{0};product::showlistall-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
                                   @Index AS '@order',
                                   N'📦 لیست محصولات' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                        
                        -- نمایش تمامی محصولات این قسمت
                        -- Next Step #. Show Products
                        -- Static
                        SET @X =
                        (
                            SELECT dbo.STR_FRMT_U('./{0};product::showimageall-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
                                   @Index AS '@order',
                                   N'📦 عکس محصولات' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                        
                        -- Next Step #. More Menu
                        -- Static
                        SET @X = (
                           SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                                  @index AS '@order',
                                  N'⛔ بستن' AS "text()"
                              FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                    END;
                    
                    IF(@XTemp IS NOT NULL)
                    BEGIN
						SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
						SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
					END 
					ELSE
						SET @Message = N'در حال حاضر کالای موجودی وجود ندارد';
                END;
            END;
        END;
        -- نمایش محصولات موجود
        ELSE IF @MenuText IN ( 'product::listprice' )
        BEGIN
            --DECLARE @gropexpn BIGINT;
            -- آیا به نرم افزار حسابداری متصل میباشد
            IF @CnctAcntApp = '002'
            BEGIN
                -- نرم افزار مدیریتی آرتا
                IF @AcntAppType = '001'
                BEGIN
                    -- نمایش گروه سطح یک
                    IF @ParamText = 'frstlevl'
                    BEGIN
                        SET @XTemp =
                        (
                            SELECT N'./' + @UssdCode + N';product::listprice-' + CAST(ge.CODE AS NVARCHAR(30)) + N'$#' AS '@data',
                                   ROW_NUMBER() OVER (ORDER BY ge.ORDR) AS '@order',
                                   N'📚 ' + ge.GROP_DESC AS "text()"
                            FROM iScsc.dbo.Group_Expense ge
                            WHERE ge.GEXP_CODE IS NULL
                                  AND ge.GROP_TYPE = '001' -- گروه ها
                                  AND ISNULL(ge.SUB_EXPN_NUMB_DNRM, 0) > 0
                                  AND Exists (
                                      Select *
                                        from robot_product rp
                                       where ge.CODE = rp.ROOT_GROP_CODE_DNRM
                                         AND rp.STAT = '002'
                                         AND rp.CRNT_NUMB_DNRM > 0
                                  )
                            ORDER BY ge.ORDR
                            FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                        );
                    END;
                    -- اگر گروه دارای زیر مجموعه های پایین تر را دارا باشد
                    ELSE IF EXISTS
                    (
                        SELECT ge.CODE
                        FROM iScsc.dbo.Group_Expense ge
                        WHERE ge.GEXP_CODE = CAST(@ParamText AS BIGINT)
                    )
                    BEGIN
                        SET @XTemp =
                        (
                            SELECT N'./' + @UssdCode + N';product::listprice-' + CAST(ge.CODE AS NVARCHAR(30)) + N'$#' AS '@data',
                                   ROW_NUMBER() OVER (ORDER BY ge.ORDR) AS '@order',
                                   N'📚 ' + ge.GROP_DESC AS "text()"
                            FROM iScsc.dbo.Group_Expense ge
                            WHERE ge.GEXP_CODE = CAST(@ParamText AS BIGINT)
                                  AND ge.GROP_TYPE = '001' -- گروه ها
                                  AND ISNULL(ge.SUB_EXPN_NUMB_DNRM, 0) > 0
                                  AND Exists(
                                      Select * 
                                        from Robot_Product rp
                                       WHERE iScsc.dbo.LINK_GROP_U(rp.GROP_CODE_DNRM, ge.Code) = 1
                                         AND ROBO_RBID = @Rbid
                                         AND STAT = '002'
                                         AND CRNT_NUMB_DNRM > 0
                                  )
                            ORDER BY ge.ORDR
                            FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                        );
                        SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;

                        -- نمایش تمامی محصولات این قسمت
                        -- Next Step #. Show Products
                        -- Static
                        SET @X =
                        (
                            SELECT dbo.STR_FRMT_U('@/{0};product::getreport::listprice::sendpdffile-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
                                   @Index AS '@order',
                                   N'📦 دریافت فایل لیست قیمت محصولات' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                    END;
                    -- اگر به انتهای گروه پایینی رسیده باشیم و در این قسمت باید محصولات نمایش داده شود
                    ELSE
                    BEGIN
                        --SET @XTemp =
                        --(
                        --    SELECT N'@/' + @UssdCode + N';product::getreport::listprice::sendpdffile-' + CAST(rp.TARF_CODE AS NVARCHAR(100))
                        --           + N'$lessinfoprod#' AS '@data',
                        --           ROW_NUMBER() OVER (ORDER BY rp.TARF_TEXT_DNRM) AS '@order',
                        --           N'📦  ' + rp.TARF_TEXT_DNRM + N' ( '
                        --           + REPLACE(
                        --                        CONVERT(
                        --                                   NVARCHAR,
                        --                                   CONVERT(
                        --                                              MONEY,
                        --                                              rp.EXPN_PRIC_DNRM + ISNULL(rp.EXTR_PRCT_DNRM, 0)
                        --                                          ),
                        --                                   1
                        --                               ),
                        --                        '.00',
                        --                        ''
                        --                    ) + N' ) ' + @AmntTypeDesc
                        --    FROM dbo.Robot_Product rp
                        --    WHERE rp.ROBO_RBID = @Rbid
                        --      AND rp.GROP_CODE_DNRM = CAST(@ParamText AS BIGINT)
                        --      AND rp.STAT = '002'
                        --      AND rp.CRNT_NUMB_DNRM > 0
                        --    ORDER BY rp.TARF_TEXT_DNRM
                        --    FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                        --);
                        -- نمایش تمامی محصولات این قسمت
                        -- Next Step #. Show Products
                        -- Static
                        SET @X =
                        (
                            SELECT dbo.STR_FRMT_U('@/{0};product::getreport::listprice::sendpdffile-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
                                   @Index AS '@order',
                                   N'📦 دریافت فایل لیست قیمت محصولات' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );
                        SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                        SET @Index += 1;
                    END;
                    
                    IF(@XTemp IS NOT NULL)
                    BEGIN
						SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
						SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
					END 
					ELSE
						SET @Message = N'در حال حاضر کالای موجودی وجود ندارد';
                END;
            END;
        END;
        -- جستجوی محصولات
        ELSE IF @MenuText IN ( 'findprod' )
        BEGIN
            DECLARE C$Items CURSOR FOR
            SELECT Item
            FROM dbo.SplitString(@ParamText, ',');
            SET @Index = 0;
            OPEN [C$Items];
            L$FetchC$Item2:
            FETCH NEXT FROM [C$Items]
            INTO @Item;

            IF @@FETCH_STATUS <> 0
                GOTO L$EndC$Item2;

            IF @Index = 0
                SET @MenuText = @Item;
            ELSE IF @Index = 1
                SET @Page = CAST(@Item AS INT);
            ELSE IF @Index = 2
                SET @SortType = CAST(@Item AS INT);

            SET @Index += 1;
            GOTO L$FetchC$Item2;
            L$EndC$Item2:
            CLOSE [C$Items];
            DEALLOCATE [C$Items];

            GOTO L$SearchProds;
        END;
        -- جستجوی محصول بر اساس نمایش عکس محصول
        ELSE IF @MenuText IN ('findprodbyimag')
        BEGIN
			L$SearchProdsByImag:
			
			DECLARE C$Items CURSOR FOR
         SELECT Item
         FROM dbo.SplitString(@ParamText, ',');
         SET @Index = 0;
         OPEN [C$Items];
         L$FetchC$Item3:
         FETCH NEXT FROM [C$Items]
         INTO @Item;

         IF @@FETCH_STATUS <> 0
             GOTO L$EndC$Item3;

         IF @Index = 0
             SET @MenuText = @Item;
         ELSE IF @Index = 1
             SET @Page = CAST(@Item AS INT);
         ELSE IF @Index = 2
             SET @SortType = CAST(@Item AS INT);

         SET @Index += 1;
         GOTO L$FetchC$Item3;
         L$EndC$Item3:
         CLOSE [C$Items];
         DEALLOCATE [C$Items];
         
			
         IF NOT EXISTS
         (
             SELECT *
             FROM iScsc.dbo.Fighter
             WHERE CHAT_ID_DNRM = @ChatID
         )
         BEGIN
             SET @Message
                 = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
             SET @XTemp =
             (
                 SELECT @Rbid AS '@rbid',
                        @ChatID AS '@chatid',
                        @UssdCode AS '@ussdcode',
                        'lessreguser' AS '@cmndtext'
                 FOR XML PATH('RequestInLineQuery')
             );
             EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                  @XRet = @XTemp OUTPUT; -- xml

             SET @XTemp =
             (
                 SELECT '1' AS '@order',
                        @Message AS '@caption',
                        @XTemp
                 FOR XML PATH('InlineKeyboardMarkup')
             );
             SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
             GOTO L$EndSP;
         END;

         -- Sort Type List      
            -- 1. پربازدیدترین
            -- 2. پرفروش ترین
            -- 3. محبوب ترین      
            -- 4. جدیدترین            
            -- 5. ارزان ترین
            -- 6. گرانترین
            -- 7. سریع ترین ارسال
            -- 8. محصولات موجود
         IF @SortType IS NULL
             SET @SortType = '8';

         SET @FromDate = GETDATE();
         DECLARE @T#SearchProductsByImage TABLE
         (
             DATA VARCHAR(100),
             ORDR INT,
             [TEXT] NVARCHAR(MAX),
             [File_Id] VARCHAR(MAX),
             [File_Type] VARCHAR(3)
         );
         IF @CnctAcntApp = '002'
             IF @AcntAppType = '001'
             BEGIN
                 INSERT INTO @T#SearchProductsByImage
                 (
                     DATA,
                     ORDR,
                     [TEXT],
                     [File_Id],
                     File_Type
                 )
                 SELECT N'./' + @UssdCode + N';infoprod-' + CAST(rp.TARF_CODE AS NVARCHAR(100)) + N'$lessinfoprod#' AS DATA,
                        ROW_NUMBER() OVER (ORDER BY rp.TARF_CODE) AS ORDR,
                        CASE 
                             WHEN rp.CRNT_NUMB_DNRM > 0 THEN N'✅ '
                             WHEN rp.CRNT_NUMB_DNRM = 0 THEN N'⛔ '
                        END + SUBSTRING(rp.TARF_TEXT_DNRM, 1, 25 ) + CASE WHEN LEN(rp.Tarf_Text_Dnrm) > 25 THEN N' ...' ELSE N'' END
                        + dbo.STR_FRMT_U(
                                            N' [ {0} نفر ]',
                                            --dbo.STR_COPY_U(N'⭐️ ', rp.RTNG_NUMB_DNRM) + N','
                                            + REPLACE( CONVERT(NVARCHAR, CONVERT(MONEY, rp.RTNG_CONT_DNRM), 1), '.00', '' )
                                        ) AS [TEXT],
                       rpp.FILE_ID,
                       rpp.FILE_TYPE
                 FROM dbo.Robot_Product rp, dbo.Robot_Product_Preview rpp
                 WHERE rp.ROBO_RBID = @Rbid
                       AND
                       (
                           rp.TARF_TEXT_DNRM LIKE N'%' + @MenuText + N'%'
                           OR rp.TARF_ENGL_TEXT LIKE N'%' + @MenuText + N'%'
                           OR rp.GROP_TEXT_DNRM LIKE N'%' + @MenuText + N'%'
                           OR rp.BRND_TEXT_DNRM LIKE N'%' + @MenuText + N'%'
                           OR rp.PROD_FETR LIKE N'%' + @MenuText + N'%'
                           OR rp.TARF_CODE LIKE N'%' + @MenuText + N'%'
                       )
                       -- اگر کالا قابل دیدن برای مشتری خاص باشد
                       AND NOT EXISTS (
                           SELECT *
                             FROM dbo.Robot_Product_Limited rpl, dbo.Robot_Limited_Commodity_Group rlcg
                            WHERE rpl.RLCG_CODE = rlcg.CODE
                              AND rlcg.ROBO_RBID = rp.ROBO_RBID
                              AND rpl.RBPR_CODE = rp.CODE
                              AND rpl.STAT = '002'
                              AND rlcg.STAT = '002'
                              AND NOT EXISTS (
                                  SELECT *
                                    FROM dbo.Service_Robot_Access_Limited_Group_Product sral
                                   WHERE sral.RLCG_CODE = rlcg.CODE
                                     AND sral.CHAT_ID = @ChatID
                                     AND sral.STAT = '002'                                        
                              )
                       )
                       AND rpp.RBPR_CODE = rp.CODE
                       AND rpp.FILE_TYPE = '002' -- Photo Image
                 ORDER BY CASE @SortType
                               WHEN '1' THEN rp.VIST_CONT_DNRM
                               ELSE ( SELECT NULL )
                          END ,
                          CASE @SortType
                               WHEN '2' THEN rp.SALE_NUMB_DNRM
                               ELSE ( SELECT NULL )
                          END,
                          CASE @SortType
                               WHEN '3' THEN rp.LIKE_CONT_DNRM
                               ELSE ( SELECT NULL )
                          END,
                          CASE @SortType
                               WHEN '4' THEN rp.CRET_DATE
                               ELSE ( SELECT NULL )
                          END DESC,
                          CASE @SortType 
                               WHEN '5' THEN rp.EXPN_PRIC_DNRM
                               ELSE ( SELECT NULL )
                          END ASC,
                          CASE @SortType
                               WHEN '6' THEN rp.EXPN_PRIC_DNRM
                               ELSE (SELECT NULL)
                          END DESC,
                          CASE @SortType
                               WHEN '7' THEN (rp.DELV_DAY_DNRM + rp.DELV_HOUR_DNRM + rp.DELV_MINT_DNRM)
                               ELSE ( SELECT NULL )
                          END,
                          CASE @SortType
                               WHEN '8' THEN rp.CRNT_NUMB_DNRM
                               ELSE ( SELECT NULL )
                          END DESC;
             END;
         SET @ToDate = GETDATE();

         SET @Message =
         (
             SELECT N'🔍 ' + @MenuText + CHAR(10)
                    + dbo.STR_FRMT_U(
                                        N'حدود {0} نتیجه، ({1} ثانیه)' + N' صفحه {2} ام -  رکورد {3} تا {4}',
                                        REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(T.ORDR)), 1), '.00', '')
                                        + N',' + CAST(DATEDIFF(SECOND, @FromDate, @ToDate) AS NVARCHAR(50)) 
                                        + N',' + CAST(@Page AS NVARCHAR(10)) 
                                        + N',' + CAST(((@Page - 1) * @PageFechRows) + 1 AS NVARCHAR(10))
                                        + N',' + CAST(((((@Page - 1) * @PageFechRows)) + @PageFechRows) AS NVARCHAR(10))
                                    )
             FROM @T#SearchProductsByImage T
             FOR XML PATH('')
         );

         -- اگر جستجو هیچ گونه خروجی در بر نداشته باشد
         IF NOT EXISTS (SELECT * FROM @T#SearchProductsByImage)
         BEGIN
             GOTO L$EndSP;
         END;

         SET @XTemp =
         (
             SELECT T.[FILE_ID] AS '@fileid',
                    T.[FILE_TYPE] AS '@filetype',
                    T.ORDR AS '@order',
                    T.[TEXT] AS '@caption',
                    (
                     SELECT T.DATA AS '@data',
                            1 AS '@order',
                            T.[TEXT] AS "text()"
                        FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup'), TYPE                           
                    )
             FROM @T#SearchProductsByImage T
             WHERE T.ORDR
             BETWEEN ((@Page - 1) * @PageFechRows) + 1 AND ((((@Page - 1) * @PageFechRows)) + @PageFechRows)
             FOR XML PATH('Complex_InLineKeyboardMarkup')--, ROOT('InlineKeyboardMarkup')
         );
         --SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
         --SET @XTemp.modify('insert attribute caption {sql:variable("@Message")} into (//InlineKeyboardMarkup)[1]');
         SET @XMessage = @XTemp;
         
         SET @Index = @XMessage.value('max(//Complex_InLineKeyboardMarkup/@order)', 'INT') + 1;
         SET @XTemp = (
            SELECT @Message AS '@caption',
                   @Index AS '@order'
               FOR XML PATH('InlineKeyboardMarkup')
         );


         -- [      
         ---- Advance Search
         ---- اضافه کردن صفحه بندی * Next * Perv
         ---- Sort 
         -- ]

         -- اگر تعداد رکورد های درون جدول خروجی بیشتر از صفحه بندی باشد 
         IF @Page * @PageFechRows <=
         (
             SELECT COUNT(*) FROM @T#SearchProductsByImage
         )
         BEGIN
             SET @Index = @PageFechRows + 1;
             -- Next Step #. Next Page
             -- Dynamic
             SET @X =
             (
                 SELECT dbo.STR_FRMT_U(
                                          './{0};findprodbyimag-{1},{2},{3}$del#',
                                          '*0*1#,' + @MenuText + N',' + CAST((@Page + 1) AS NVARCHAR(10)) + N','
                                          + CAST(@SortType AS NVARCHAR(2))
                                      ) AS '@data',
                        @Index AS '@order',
                        N'▶️ صفحه بعدی' AS "text()"
                 FOR XML PATH('InlineKeyboardButton')
             );
             SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
             SET @Index += 1;
         END;
         -- اضافه کردن دکمه صفحه قبل 
         IF @Page > 1
         BEGIN
             -- Next Step #. Perv Page
             -- Dynamic
             SET @X =
             (
                 SELECT dbo.STR_FRMT_U(
                                          './{0};findprodbyimag-{1},{2},{3}$del#',
                                          '*0*1#,' + @MenuText + N',' + CAST((@Page - 1) AS NVARCHAR(10)) + N','
                                          + CAST(@SortType AS NVARCHAR(2))
                                      ) AS '@data',
                        @Index AS '@order',
                        N'◀️ صفحه قبلی' AS "text()"
                 FOR XML PATH('InlineKeyboardButton')
             );
             SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
             SET @Index += 1;
         END;
         
         -- اضافه کردن جستجو بر اساس متنی
         -- Static
         SET @X =
         (
             SELECT dbo.STR_FRMT_U(
                                      './{0};findprod-{1},{2},{3}$del#',
                                      '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                      + CAST(@SortType AS NVARCHAR(2))
                                  ) AS '@data',
                    @Index AS '@order',
                    N'🧾 متنی' AS "text()"
             FOR XML PATH('InlineKeyboardButton')
         );
         SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
         SET @Index += 1;
         
         -- اضافه کردن جستجو بر اساس عکس
         -- Static
         SET @X =
         (
             SELECT dbo.STR_FRMT_U(
                                      './{0};findprodbyimag-{1},{2},{3}$del#',
                                      '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                      + CAST(@SortType AS NVARCHAR(2))
                                  ) AS '@data',
                    @Index AS '@order',
                    N'🖼️ عکس' AS "text()"
             FOR XML PATH('InlineKeyboardButton')
         );
         SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
         SET @Index += 1;
         
         -- اضافه کردن جستجو بر اساس تصویری
         -- Static
         SET @X =
         (
             SELECT dbo.STR_FRMT_U(
                                      './{0};findprodbyvideo-{1},{2},{3}$del#',
                                      '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                      + CAST(@SortType AS NVARCHAR(2))
                                  ) AS '@data',
                    @Index AS '@order',
                    N'📺 تصویری' AS "text()"
             FOR XML PATH('InlineKeyboardButton')
         );
         SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
         SET @Index += 1;

         -- اضافه کردن مرتب سازی      
         -- Static
         SET @X =
         (
             SELECT dbo.STR_FRMT_U(
                                      './{0};sortprod-{1},{2},{3}$del#',
                                      '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                      + CAST(@SortType AS NVARCHAR(2))
                                  ) AS '@data',
                    @Index AS '@order',
                    N'📚 مرتب سازی' AS "text()"
             FOR XML PATH('InlineKeyboardButton')
         );
         SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
         SET @Index += 1;

         -- Advance Search
         -- Static
         SET @X =
         (
             SELECT dbo.STR_FRMT_U(
                                      './{0};advnfindprod-{1},{2},{3}$del#',
                                      '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                      + CAST(@SortType AS NVARCHAR(2))
                                  ) AS '@data',
                    @Index AS '@order',
                    N'🔍 جستجوی پیشرفته' AS "text()"
             FOR XML PATH('InlineKeyboardButton')
         );
         SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
         SET @Index += 1;
         
         SET @XTemp = (
            SELECT @XMessage, @XTemp
               FOR XML PATH('Message')
         );

         SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
        END 
        -- جستجوی محصول بر اساس نمایش تصاویر محصول
        ELSE IF @MenuText IN ('findprodbyvideo')
        BEGIN
			L$SearchProdsByVideo:
			
			DECLARE C$Items CURSOR FOR
         SELECT Item
         FROM dbo.SplitString(@ParamText, ',');
         SET @Index = 0;
         OPEN [C$Items];
         L$FetchC$Item4:
         FETCH NEXT FROM [C$Items]
         INTO @Item;

         IF @@FETCH_STATUS <> 0
             GOTO L$EndC$Item4;

         IF @Index = 0
             SET @MenuText = @Item;
         ELSE IF @Index = 1
             SET @Page = CAST(@Item AS INT);
         ELSE IF @Index = 2
             SET @SortType = CAST(@Item AS INT);

         SET @Index += 1;
         GOTO L$FetchC$Item4;
         L$EndC$Item4:
         CLOSE [C$Items];
         DEALLOCATE [C$Items];
         
			
         IF NOT EXISTS
         (
             SELECT *
             FROM iScsc.dbo.Fighter
             WHERE CHAT_ID_DNRM = @ChatID
         )
         BEGIN
             SET @Message
                 = N'⚠️ شما هنوز درون سیستم ثبت نشده اید. لطفا مراحل تکمیل ثبت نام خود را بر اساس دستور العمل انجام دهید. با تشکر';
             SET @XTemp =
             (
                 SELECT @Rbid AS '@rbid',
                        @ChatID AS '@chatid',
                        @UssdCode AS '@ussdcode',
                        'lessreguser' AS '@cmndtext'
                 FOR XML PATH('RequestInLineQuery')
             );
             EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                  @XRet = @XTemp OUTPUT; -- xml

             SET @XTemp =
             (
                 SELECT '1' AS '@order',
                        @Message AS '@caption',
                        @XTemp
                 FOR XML PATH('InlineKeyboardMarkup')
             );
             SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
             GOTO L$EndSP;
         END;

            -- Sort Type List      
            -- 1. پربازدیدترین
            -- 2. پرفروش ترین
            -- 3. محبوب ترین      
            -- 4. جدیدترین            
            -- 5. ارزان ترین
            -- 6. گرانترین
            -- 7. سریع ترین ارسال
            -- 8. محصولات موجود
         IF @SortType IS NULL
             SET @SortType = '8';

         SET @FromDate = GETDATE();
         DECLARE @T#SearchProductsByVideo TABLE
         (
             DATA VARCHAR(100),
             ORDR INT,
             [TEXT] NVARCHAR(MAX),
             [File_Id] VARCHAR(MAX),
             [File_Type] VARCHAR(3)
         );
         IF @CnctAcntApp = '002'
             IF @AcntAppType = '001'
             BEGIN
                 INSERT INTO @T#SearchProductsByVideo
                 (
                     DATA,
                     ORDR,
                     [TEXT],
                     [File_Id],
                     File_Type
                 )
                 SELECT N'./' + @UssdCode + N';infoprod-' + CAST(rp.TARF_CODE AS NVARCHAR(100)) + N'$lessinfoprod#' AS DATA,
                        ROW_NUMBER() OVER (ORDER BY rp.TARF_CODE) AS ORDR,
                        CASE 
                             WHEN rp.CRNT_NUMB_DNRM > 0 THEN N'✅ '
                             WHEN rp.CRNT_NUMB_DNRM = 0 THEN N'⛔ '
                        END + SUBSTRING(rp.TARF_TEXT_DNRM, 1, 25) + CASE WHEN LEN(rp.Tarf_Text_Dnrm) > 25 THEN N' ...' ELSE N'' END
                        + dbo.STR_FRMT_U(
                                            N' [ {0} نفر ]',
                                            --dbo.STR_COPY_U(N'⭐️ ', rp.RTNG_NUMB_DNRM) + N','
                                            + REPLACE( CONVERT(NVARCHAR, CONVERT(MONEY, rp.RTNG_CONT_DNRM), 1), '.00', '' )
                                        ) AS [TEXT],
                       rpp.FILE_ID,
                       rpp.FILE_TYPE
                 FROM dbo.Robot_Product rp, dbo.Robot_Product_Preview rpp
                 WHERE rp.ROBO_RBID = @Rbid
                       AND
                       (
                           rp.TARF_TEXT_DNRM LIKE N'%' + @MenuText + N'%'
                           OR rp.TARF_ENGL_TEXT LIKE N'%' + @MenuText + N'%'
                           OR rp.GROP_TEXT_DNRM LIKE N'%' + @MenuText + N'%'
                           OR rp.BRND_TEXT_DNRM LIKE N'%' + @MenuText + N'%'
                           OR rp.PROD_FETR LIKE N'%' + @MenuText + N'%'
                           OR rp.TARF_CODE LIKE N'%' + @MenuText + N'%'
                       )
                       -- اگر کالا قابل دیدن برای مشتری خاص باشد
                       AND NOT EXISTS (
                           SELECT *
                             FROM dbo.Robot_Product_Limited rpl, dbo.Robot_Limited_Commodity_Group rlcg
                            WHERE rpl.RLCG_CODE = rlcg.CODE
                              AND rlcg.ROBO_RBID = rp.ROBO_RBID
                              AND rpl.RBPR_CODE = rp.CODE
                              AND rpl.STAT = '002'
                              AND rlcg.STAT = '002'
                              AND NOT EXISTS (
                                  SELECT *
                                    FROM dbo.Service_Robot_Access_Limited_Group_Product sral
                                   WHERE sral.RLCG_CODE = rlcg.CODE
                                     AND sral.CHAT_ID = @ChatID
                                     AND sral.STAT = '002'                                        
                              )
                       )
                       AND rpp.RBPR_CODE = rp.CODE
                       AND rpp.FILE_TYPE = '003' -- Video
                 ORDER BY CASE @SortType
                               WHEN '1' THEN rp.VIST_CONT_DNRM
                               ELSE ( SELECT NULL )
                          END ,
                          CASE @SortType
                               WHEN '2' THEN rp.SALE_NUMB_DNRM
                               ELSE ( SELECT NULL )
                          END,
                          CASE @SortType
                               WHEN '3' THEN rp.LIKE_CONT_DNRM
                               ELSE ( SELECT NULL )
                          END,
                          CASE @SortType
                               WHEN '4' THEN rp.CRET_DATE
                               ELSE ( SELECT NULL )
                          END DESC,
                          CASE @SortType 
                               WHEN '5' THEN rp.EXPN_PRIC_DNRM
                               ELSE ( SELECT NULL )
                          END ASC,
                          CASE @SortType
                               WHEN '6' THEN rp.EXPN_PRIC_DNRM
                               ELSE (SELECT NULL)
                          END DESC,
                          CASE @SortType
                               WHEN '7' THEN (rp.DELV_DAY_DNRM + rp.DELV_HOUR_DNRM + rp.DELV_MINT_DNRM)
                               ELSE ( SELECT NULL )
                          END,
                          CASE @SortType
                               WHEN '8' THEN rp.CRNT_NUMB_DNRM
                               ELSE ( SELECT NULL )
                          END DESC;
             END;
         SET @ToDate = GETDATE();

         SET @Message =
         (
             SELECT N'🔍 ' + @MenuText + CHAR(10)
                    + dbo.STR_FRMT_U(
                                        N'حدود {0} نتیجه، ({1} ثانیه)' + N' صفحه {2} ام -  رکورد {3} تا {4}',
                                        REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(T.ORDR)), 1), '.00', '')
                                        + N',' + CAST(DATEDIFF(SECOND, @FromDate, @ToDate) AS NVARCHAR(50)) 
                                        + N',' + CAST(@Page AS NVARCHAR(10)) 
                                        + N',' + CAST(((@Page - 1) * @PageFechRows) + 1 AS NVARCHAR(10))
                                        + N',' + CAST(((((@Page - 1) * @PageFechRows)) + @PageFechRows) AS NVARCHAR(10))
                                    )
             FROM @T#SearchProductsByVideo T
             FOR XML PATH('')
         );

         -- اگر جستجو هیچ گونه خروجی در بر نداشته باشد
         IF NOT EXISTS (SELECT * FROM @T#SearchProductsByVideo)
         BEGIN
             GOTO L$EndSP;
         END;

         SET @XTemp =
         (
             SELECT T.[FILE_ID] AS '@fileid',
                    T.[FILE_TYPE] AS '@filetype',
                    T.ORDR AS '@order',
                    T.[TEXT] AS '@caption',
                    (
                     SELECT T.DATA AS '@data',
                            1 AS '@order',
                            T.[TEXT] AS "text()"
                        FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup'), TYPE                           
                    )
             FROM @T#SearchProductsByVideo T
             WHERE T.ORDR
             BETWEEN ((@Page - 1) * @PageFechRows) + 1 AND ((((@Page - 1) * @PageFechRows)) + @PageFechRows)
             FOR XML PATH('Complex_InLineKeyboardMarkup')--, ROOT('InlineKeyboardMarkup')
         );
         --SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
         --SET @XTemp.modify('insert attribute caption {sql:variable("@Message")} into (//InlineKeyboardMarkup)[1]');
         SET @XMessage = @XTemp;
         
         SET @Index = @XMessage.value('max(//Complex_InLineKeyboardMarkup/@order)', 'INT') + 1;
         SET @XTemp = (
            SELECT @Message AS '@caption',
                   @Index AS '@order'
               FOR XML PATH('InlineKeyboardMarkup')
         );


         -- [      
         ---- Advance Search
         ---- اضافه کردن صفحه بندی * Next * Perv
         ---- Sort 
         -- ]

         -- اگر تعداد رکورد های درون جدول خروجی بیشتر از صفحه بندی باشد 
         IF @Page * @PageFechRows <=
         (
             SELECT COUNT(*) FROM @T#SearchProductsByVideo
         )
         BEGIN
             SET @Index = @PageFechRows + 1;
             -- Next Step #. Next Page
             -- Dynamic
             SET @X =
             (
                 SELECT dbo.STR_FRMT_U(
                                          './{0};findprodbyvideo-{1},{2},{3}$del#',
                                          '*0*1#,' + @MenuText + N',' + CAST((@Page + 1) AS NVARCHAR(10)) + N','
                                          + CAST(@SortType AS NVARCHAR(2))
                                      ) AS '@data',
                        @Index AS '@order',
                        N'▶️ صفحه بعدی' AS "text()"
                 FOR XML PATH('InlineKeyboardButton')
             );
             SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
             SET @Index += 1;
         END;
         -- اضافه کردن دکمه صفحه قبل 
         IF @Page > 1
         BEGIN
             -- Next Step #. Perv Page
             -- Dynamic
             SET @X =
             (
                 SELECT dbo.STR_FRMT_U(
                                          './{0};findprodbyvideo-{1},{2},{3}$del#',
                                          '*0*1#,' + @MenuText + N',' + CAST((@Page - 1) AS NVARCHAR(10)) + N','
                                          + CAST(@SortType AS NVARCHAR(2))
                                      ) AS '@data',
                        @Index AS '@order',
                        N'◀️ صفحه قبلی' AS "text()"
                 FOR XML PATH('InlineKeyboardButton')
             );
             SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
             SET @Index += 1;
         END;
         
         -- اضافه کردن جستجو بر اساس متنی
         -- Static
         SET @X =
         (
             SELECT dbo.STR_FRMT_U(
                                      './{0};findprod-{1},{2},{3}$del#',
                                      '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                      + CAST(@SortType AS NVARCHAR(2))
                                  ) AS '@data',
                    @Index AS '@order',
                    N'🧾 متنی' AS "text()"
             FOR XML PATH('InlineKeyboardButton')
         );
         SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
         SET @Index += 1;
         
         -- اضافه کردن جستجو بر اساس عکس
         -- Static
         SET @X =
         (
             SELECT dbo.STR_FRMT_U(
                                      './{0};findprodbyimag-{1},{2},{3}$del#',
                                      '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                      + CAST(@SortType AS NVARCHAR(2))
                                  ) AS '@data',
                    @Index AS '@order',
                    N'🖼️ عکس' AS "text()"
             FOR XML PATH('InlineKeyboardButton')
         );
         SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
         SET @Index += 1;
         
         -- اضافه کردن جستجو بر اساس تصویری
         -- Static
         SET @X =
         (
             SELECT dbo.STR_FRMT_U(
                                      './{0};findprodbyvideo-{1},{2},{3}$del#',
                                      '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                      + CAST(@SortType AS NVARCHAR(2))
                                  ) AS '@data',
                    @Index AS '@order',
                    N'📺 تصویری' AS "text()"
             FOR XML PATH('InlineKeyboardButton')
         );
         SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
         SET @Index += 1;

         -- اضافه کردن مرتب سازی      
         -- Static
         SET @X =
         (
             SELECT dbo.STR_FRMT_U(
                                      './{0};sortprod-{1},{2},{3}$del#',
                                      '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                      + CAST(@SortType AS NVARCHAR(2))
                                  ) AS '@data',
                    @Index AS '@order',
                    N'📚 مرتب سازی' AS "text()"
             FOR XML PATH('InlineKeyboardButton')
         );
         SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
         SET @Index += 1;

         -- Advance Search
         -- Static
         SET @X =
         (
             SELECT dbo.STR_FRMT_U(
                                      './{0};advnfindprod-{1},{2},{3}$del#',
                                      '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                      + CAST(@SortType AS NVARCHAR(2))
                                  ) AS '@data',
                    @Index AS '@order',
                    N'🔍 جستجوی پیشرفته' AS "text()"
             FOR XML PATH('InlineKeyboardButton')
         );
         SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
         SET @Index += 1;
         
         SET @XTemp = (
            SELECT @XMessage, @XTemp
               FOR XML PATH('Message')
         );

         SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
        END 
        -- مرتب سازی جستجو
        ELSE IF @MenuText IN ( 'sortprod' )
        BEGIN
            -- اضافه کردن منوهای اولیه مربوط به فاکتور فروش مشتری         
            SET @XTemp =
            (
                SELECT @Rbid AS '@rbid',
                       @ChatID AS '@chatid',
                       @UssdCode AS '@ussdcode',
                       'sortprod' AS '@cmndtext',
                       @ParamText AS '@param',
                       @OrdrCode AS '@ordrcode'
                FOR XML PATH('RequestInLineQuery')
            );
            EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            SET @XTemp =
            (
                SELECT '1' AS '@order',
                       N'📊 مرتب سازی بر اساس' AS '@caption',
                       @XTemp
                FOR XML PATH('InlineKeyboardMarkup')
            );

            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
        END;
        -- اضافه کردن جستجو پیشرفته
        ELSE IF @MenuText IN ( 'advnfindprod' )
        BEGIN
           DECLARE C$Items CURSOR FOR
           SELECT Item
           FROM dbo.SplitString(@ParamText, ',');
           SET @Index = 0;
           OPEN [C$Items];
           L$FetchC$Item5:
           FETCH NEXT FROM [C$Items] INTO @Item;
           
           IF @@FETCH_STATUS <> 0
              GOTO L$EndC$Item5;
           
           IF @Index = 0
               SET @MenuText = @Item;
           ELSE IF @Index = 1
               SET @Page = CAST(@Item AS INT);
           ELSE IF @Index = 2
               SET @SortType = CAST(@Item AS INT);
            SET @Index += 1;
           
           GOTO L$FetchC$Item5;
           L$EndC$Item5:
           CLOSE [C$Items];
           DEALLOCATE [C$Items];
             
           INSERT INTO @T#SearchProducts
           (
               DATA,
               ORDR,
               [TEXT]
           )
           SELECT N'./' + @UssdCode + N';selr-' + CAST(s.CODE AS NVARCHAR(30)) + N'$#' AS DATA,
                  ROW_NUMBER() OVER (ORDER BY s.CODE) AS ORDR,
                  ISNULL(s.SHOP_NAME, sr.NAME) AS [TEXT]
             FROM dbo.Service_Robot_Seller s, dbo.Service_Robot sr
            WHERE s.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
              AND s.SRBT_ROBO_RBID = sr.ROBO_RBID
              AND 
              (
                     s.SHOP_NAME LIKE N'%' + @MenuText + N'%'
                  OR s.SHOP_POST_ADRS LIKE N'%' + @MenuText + N'%'
                  OR s.SHOP_BOT LIKE N'%' + @MenuText + N'%'
                  OR s.SHOP_DESC LIKE N'%' + @MenuText + N'%'
                  OR EXISTS (
                     SELECT *
                       FROM dbo.Robot_Product rp, dbo.Service_Robot_Seller_Product sp
                      WHERE rp.ROBO_RBID = @Rbid
                        AND rp.CODE = sp.RBPR_CODE
                        AND sp.SRBS_CODE = s.CODE
                        AND
                        (
                            rp.TARF_TEXT_DNRM LIKE N'%' + @MenuText + N'%'
                            OR rp.TARF_ENGL_TEXT LIKE N'%' + @MenuText + N'%'
                            OR rp.GROP_TEXT_DNRM LIKE N'%' + @MenuText + N'%'
                            OR rp.BRND_TEXT_DNRM LIKE N'%' + @MenuText + N'%'
                            OR rp.PROD_FETR LIKE N'%' + @MenuText + N'%'
                            OR rp.TARF_CODE LIKE N'%' + @MenuText + N'%'
                        )
                  )
               );
           
           SET @ToDate = GETDATE();

            SET @Message =
            (
                SELECT N'🔍 ' + @MenuText + CHAR(10)
                       + dbo.STR_FRMT_U(
                                           N'حدود {0} نتیجه، ({1} ثانیه)' + N' صفحه {2} ام -  رکورد {3} تا {4}',
                                           REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(T.ORDR)), 1), '.00', '')
                                           + N',' + CAST(DATEDIFF(SECOND, @FromDate, @ToDate) AS NVARCHAR(50)) 
                                           + N',' + CAST(@Page AS NVARCHAR(10)) 
                                           + N',' + CAST(((@Page - 1) * @PageFechRows) + 1 AS NVARCHAR(10))
                                           + N',' + CAST(((((@Page - 1) * @PageFechRows)) + @PageFechRows) AS NVARCHAR(10))
                                       )
                FROM @T#SearchProducts T
                FOR XML PATH('')
            );

            -- اگر جستجو هیچ گونه خروجی در بر نداشته باشد
            IF NOT EXISTS (SELECT * FROM @T#SearchProducts)
            BEGIN
               -- Advance Search
               SET @XTemp = '<InlineKeyboardMarkup order="1"/>';
               -- Static
               SET @X =
               (
                   SELECT dbo.STR_FRMT_U(
                                            './{0};advnfindprod-{1},{2},{3}$del#',
                                            '*0*1#,' + @MenuText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                            + CAST(@SortType AS NVARCHAR(2))
                                        ) AS '@data',
                          @Index AS '@order',
                          N'🔍 جستجوی پیشرفته' AS "text()"
                   FOR XML PATH('InlineKeyboardButton')
               );
               SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');               
               SET @Index += 1;
               
               -- Next Step #. More Menu
               -- Static
               SET @X = (
                  SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                         @index AS '@order',
                         N'⛔ بستن' AS "text()"
                     FOR XML PATH('InlineKeyboardButton')
               );
               SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
               SET @Index += 1;
               
               SET @XTemp.modify('insert attribute caption {sql:variable("@Message")} into (//InlineKeyboardMarkup)[1]');               
               SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);           
               
               GOTO L$EndSP;                
            END;

            SET @XTemp =
            (
                SELECT T.DATA AS '@data',
                       T.ORDR AS '@order',
                       T.[TEXT] AS "text()"
                FROM @T#SearchProducts T
                WHERE T.ORDR
                BETWEEN ((@Page - 1) * @PageFechRows) + 1 AND ((((@Page - 1) * @PageFechRows)) + @PageFechRows)
                FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
            );
            SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
            SET @XTemp.modify('insert attribute caption {sql:variable("@Message")} into (//InlineKeyboardMarkup)[1]');


            -- [      
            ---- Advance Search
            ---- اضافه کردن صفحه بندی * Next * Perv
            ---- Sort 
            -- ]

            -- اگر تعداد رکورد های درون جدول خروجی بیشتر از صفحه بندی باشد 
            IF @Page * @PageFechRows <=
            (
                SELECT COUNT(*) FROM @T#SearchProducts
            )
            BEGIN
                SET @Index = @PageFechRows + 1;
                -- Next Step #. Next Page
                -- Dynamic
                SET @X =
                (
                    SELECT dbo.STR_FRMT_U(
                                             './{0};advnfindprod-{1},{2},{3}$del#',
                                             '*0*1#,' + @MenuText + N',' + CAST((@Page + 1) AS NVARCHAR(10)) + N','
                                             + CAST(@SortType AS NVARCHAR(2))
                                         ) AS '@data',
                           @Index AS '@order',
                           N'▶️ صفحه بعدی' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );
                SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;
            END;
            -- اضافه کردن دکمه صفحه قبل 
            IF @Page > 1
            BEGIN
                -- Next Step #. Perv Page
                -- Dynamic
                SET @X =
                (
                    SELECT dbo.STR_FRMT_U(
                                             './{0};advnfindprod-{1},{2},{3}$del#',
                                             '*0*1#,' + @MenuText + N',' + CAST((@Page - 1) AS NVARCHAR(10)) + N','
                                             + CAST(@SortType AS NVARCHAR(2))
                                         ) AS '@data',
                           @Index AS '@order',
                           N'◀️ صفحه قبلی' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );
                SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;
            END;
            
            -- Next Step #. More Menu
            -- Static
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                      @index AS '@order',
                      N'⛔ بستن' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
            SET @Index += 1;

            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);           
        END;
        -- تغییر تعداد محصولات درون سبد به صورت دستی
        ELSE IF @MenuText IN ( 'numbprodcart' )
        BEGIN
            -- اگر در قسمت داده ورودی بیش از یک داده باشد ابتدا عملیاتی جهت تغییر تعداد کالا را انجام میدهیم
            IF @ParamText LIKE '%,%'
            BEGIN
                SELECT @Item = CASE id
                                   WHEN 1 THEN
                                       Item
                                   ELSE
                                       @Item
                               END,
                       @Numb = CASE id
                                   WHEN 2 THEN
                                       Item
                                   ELSE
                                       @Numb
                               END
                FROM dbo.SplitString(@ParamText, ',');

                SET @XTemp =
                (
                    SELECT 5 AS '@subsys',
                           '004' AS '@ordrtype',
                           '000' AS '@typecode',
                           @ChatID AS '@chatid',
                           @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           dbo.STR_FRMT_U('{0}*n{1}', @Item /* tarfcode */ + ',' + @Numb) AS '@input',
                           0 AS '@ordrcode'
                    FOR XML PATH('Action'), ROOT('Cart')
                );
                EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT;
            END;

            -- ابتدا بررسی اینکه فاکتوری ثبت شده و آیا ما تعداد از این کالا را داریم یا خیر
            SET @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       dbo.STR_FRMT_U('{0}*count', @ParamText /* tarfcode */) AS '@input',
                       0 AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT;

            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT');

            IF @RsltCode = '002'
            BEGIN
                -- ایجاد منوهای مربوط به گزینه تعداد دستی
                -- +1 +5 +10
                -- -1 -5 -10
                -- باگشت
                SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
                SELECT @Message += CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
                -- اضافه کردن منوهای اولیه مربوط به فاکتور فروش مشتری         
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'numbprodcart' AS '@cmndtext',
                           @ParamText AS '@tarfcode',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           --@Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );

                -- مشخص شدن اینکه متن با عبارت متنی ساده باید ارسال شود یا با عکس
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.Robot_Product rp,
                         dbo.Robot_Product_Preview rpp
                    WHERE rp.ROBO_RBID = @Rbid
                          AND rp.CODE = rpp.RBPR_CODE
                          AND rp.TARF_CODE = @ParamText /* @tarfcode */
                          AND rpp.STAT = '002'
                )
                BEGIN
                    SET @XMessage =
                    (
                        SELECT TOP 1
                               rpp.FILE_ID AS '@fileid',
                               rpp.FILE_TYPE AS '@filetype',
                               @Message AS '@caption',
                               1 AS '@order'
                        FROM dbo.Robot_Product rp,
                             dbo.Robot_Product_Preview rpp
                        WHERE rp.ROBO_RBID = @Rbid
                              AND rp.CODE = rpp.RBPR_CODE
                              AND rp.TARF_CODE = @ParamText
                              AND rpp.STAT = '002'
                        ORDER BY rpp.ORDR
                        FOR XML PATH('Complex_InLineKeyboardMarkup')
                    );
                    SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
                END;
                ELSE
                BEGIN
                    SET @XTemp.modify('insert attribute caption {sql:variable("@message")} as first into (//InlineKeyboardMarkup)[1]');
                    SET @XMessage = @XTemp;
                END;

                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
        END;
        -- اطلاعات مربوط به محصولات
        ELSE IF @MenuText IN ( 'infoprod' )
        BEGIN
            L$InfoProd:
            -- اگر محصول کارت هدیه ثبت شده درون سیستم باشد و مشتری بخواهد از آن ها استفاده کند
            IF @ParamText LIKE 'gc%'
            BEGIN
                -- بدست آوردن شماره کد عکس کارت هدیه
                SET @ParamText = SUBSTRING(@ParamText, 3, LEN(@ParamText));
                SET @RbppCode = @ParamText;

                -- بدست آوردن متن کارت هدیه
                SELECT @MenuText = FILE_DESC,
                       @ParamText = rp.TARF_CODE
                FROM dbo.Robot_Product_Preview rpp,
                     dbo.Robot_Product rp
                WHERE rp.CODE = rpp.RBPR_CODE
                      AND rpp.CODE = @ParamText;
                SET @PostExec = N'lessinfogftp';
                GOTO L$GiftCards;
            END;
            -- اگر پارامتر ورودی از کاما استفاده شده باشد گزینه کارت اعتباری می باشد که شماره درخواست و شماره ردیف درخواست را به شما داده
            ELSE IF @ParamText LIKE N'%,%'
            BEGIN
                -- بدست آوردن اطلاعات مربوط به کالا کارت اعتباری
                SELECT @OrdrCode = CASE id
                                       WHEN 1 THEN
                                           Item
                                       ELSE
                                           @OrdrCode
                                   END,
                       @OrdrRwno = CASE id
                                       WHEN 2 THEN
                                           Item
                                       ELSE
                                           @OrdrRwno
                                   END
                FROM dbo.SplitString(@ParamText, ',');

                -- بدست آوردن مبلغ اعتباری درخواست شده
                SELECT @Amnt = EXPN_PRIC,
                       @ParamText = TARF_CODE,
                       @MenuText = ORDR_DESC
                FROM dbo.Order_Detail
                WHERE ORDR_CODE = @OrdrCode
                      AND RWNO = @OrdrRwno;
                SET @PostExec = N'lessinfogfto';

                L$GiftCards:
                SET @Message = N'👈 ';
                -- بدست آوردن اطلاعات مربوط به کالا
                SELECT @RtngNumbDnrm = RTNG_NUMB_DNRM,
                       @RtngContDnrm = RTNG_CONT_DNRM,
                       @ProdFetr = PROD_FETR,
                       @TarfTextDnrm = TARF_TEXT_DNRM,
                       @TarfEnglText = TARF_ENGL_TEXT,
                       @RevwContDnrm = REVW_CONT_DNRM,
                       @BrndTextDnrm = BRND_TEXT_DNRM,
                       @GropTextDnrm = GROP_TEXT_DNRM
                FROM dbo.Robot_Product rp
                WHERE ROBO_RBID = @Rbid
                      AND TARF_CODE = @ParamText;

                SET @Item = N'';
                -- آیا کالا درقسمت علاقه مندی های مشتری قرار گرفته است یا خیر
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.Service_Robot_Product_Like a,
                         dbo.Robot_Product b
                    WHERE CHAT_ID = @ChatID
                          AND a.SRBT_ROBO_RBID = @Rbid
                          AND a.RBPR_CODE = b.CODE
                          AND b.TARF_CODE = @ParamText /* @tarfcode */
                          AND a.STAT = '002'
                )
                BEGIN
                    SET @Item = N'❤️';
                END;

                -- ایا مشتری این محصول را در قسمت اطلاع رسانی تخفیفات قرار داده است
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.Service_Robot_Product_Amazing_Notification a,
                         dbo.Robot_Product b
                    WHERE a.CHAT_ID = @ChatID
                          AND a.SRBT_ROBO_RBID = @Rbid
                          AND a.RBPR_CODE = b.CODE
                          AND b.TARF_CODE = @ParamText /* @tarfcode */
                          AND a.STAT = '002'
                )
                BEGIN
                    IF LEN(@Item) >= 1
                        SET @Item += N' • ';
                    SET @Item += N'🔔';
                END;

                SET @Message += REPLACE(N'*{0}*', N'{0}', @TarfTextDnrm) + CHAR(10)
                                + CASE
                                      WHEN @TarfEnglText IS NULL
                                           OR @TarfEnglText
                    = N'' THEN
                                          N' '
                                      ELSE
                (@TarfEnglText + CHAR(10))
                                  END + CASE
                                            WHEN LEN(@Item) >= 1 THEN
                                                @Item + CHAR(10)
                                            ELSE
                                                N''
                                        END + REPLACE(N'⭐️ *{0}* ', N'{0}', @RtngNumbDnrm)
                                + REPLACE(N'({0})', N'{0}', @RtngContDnrm) + N' • '
                                + REPLACE(N'{0} دیدگاه کاربران', N'{0}', @RevwContDnrm) + CHAR(10)
                                + REPLACE(N'برند : {0}', N'{0}', @BrndTextDnrm) + N'  '
                                + REPLACE(N'گروه : {0}', N'{0}', @GropTextDnrm) + CHAR(10) + N'*ویژگی های محصول*'
                                + CHAR(10) + REPLACE(N'{0}', N'{0}', @ProdFetr) + CHAR(10) + CHAR(10)
                                + N'*پیام کارت هدیه* ' + CHAR(10) + @MenuText + CHAR(10) + CHAR(10) + N'مبلغ اعتبار : '
                                + CHAR(10) + N'*'
                                + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, ISNULL(@Amnt, 0)), 1), '.00', '') + N' '
                                + @AmntTypeDesc + N'*';

                -- بدست آوردن منوی محصول
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           @PostExec AS '@cmndtext', -- اجرای منو در حالی که میخواهیم
                           @ParamText AS '@tarfcode',
                           @OrdrCode AS '@ordrcode',
                           @OrdrRwno AS '@ordrrwno',
                           @RbppCode AS '@rbppcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                );

                IF @PostExec = 'lessinfogfto'
                    SET @XMessage =
                (
                    SELECT TOP 1
                           od.IMAG_PATH AS '@fileid',
                           od.ELMN_TYPE AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Order_Detail od
                    WHERE od.ORDR_CODE = @OrdrCode
                          AND od.RWNO = @OrdrRwno
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                )   ;
                ELSE IF @PostExec = 'lessinfogftp'
                    SET @XMessage =
                (
                    SELECT TOP 1
                           rpp.FILE_ID AS '@fileid',
                           rpp.FILE_TYPE AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Robot_Product_Preview rpp
                    WHERE rpp.CODE = @RbppCode
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                )   ;
                SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
            ELSE
            BEGIN
                -- 1399/04/21 
                -- ثبت تعداد ویزیت کالا
                UPDATE p
                   SET p.VIST_CONT_DNRM = ISNULL(p.VIST_CONT_DNRM, 0) + 1
                  FROM dbo.Robot_Product p
                 WHERE p.ROBO_RBID = @Rbid
                   AND p.TARF_CODE = @ParamText;                
                
                -- 1399/08/12 * بروزرسانی اطلاعات از سمت سرور منبع
                SET @XTemp = (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @MenuText + ':' + @ParamText AS '@input'                    
                       FOR XML PATH('Action'), ROOT('Link_Server')                       
                );
                EXEC dbo.LKS_EXTR_P @X = @XTemp -- xml                

                -- نمایش اطلاعات مربوط به محصول انتخاب شده
                -- Step 1 : بدست اوردن اطلاعات توضحیات مربوط به کالا
                -- Step 1.1 : آیا کالا دارای تخفیف شگفت انگیز میباشد      
                DECLARE @RbpdCode BIGINT,
                        @RemnTime DATETIME,
                        @offType VARCHAR(3),
                        @StrtDistCont DATETIME;
                SELECT TOP 1
                       @RbpdCode = rpd.CODE,
                       @OffPrct = rpd.OFF_PRCT,
                       @RemnTime = rpd.REMN_TIME,
                       @offType = rpd.OFF_TYPE,
                       @StrtDistCont = rpd.MDFY_DATE
                FROM dbo.Robot_Product_Discount rpd
                WHERE rpd.ROBO_RBID = @Rbid
                      AND rpd.TARF_CODE = @ParamText
                      AND rpd.ACTV_TYPE = '002' --  فعال باشد
                ORDER BY rpd.OFF_TYPE;

                -- بررسی تخفیف شگفت انگیر
                IF @RbpdCode IS NOT NULL
                   AND @offType = '001' /* تخفیف شگفت انگیر */
                   AND @RemnTime <= GETDATE()
                BEGIN
                    UPDATE Robot_Product_Discount
                    SET ACTV_TYPE = '001'
                    WHERE CODE = @RbpdCode;
                    SELECT @RbpdCode = NULL,
                           @offType = NULL,
                           @RemnTime = NULL;
                END;

                -- بدست آوردن مبلغ کالا
                SELECT @Pric = EXPN_PRIC_DNRM,
                       @ExtrPrct = ISNULL(EXTR_PRCT_DNRM, 0)
                FROM dbo.Robot_Product
                WHERE TARF_CODE = @ParamText;

                SET @Message = N'👈 ';
                -- اگر محصول در تخفیف قرار گرفته باشد
                IF @RbpdCode IS NOT NULL
                BEGIN
                    -- محاسبه مبلغ تخفیف
                    SET @Amnt = (@Pric - (@Pric * @OffPrct / 100)) + @ExtrPrct;

                -- ایجاد متن تخفیف
                --IF @offType = '001' AND @RemnTime >= GETDATE() -- تخفیف شگفت انگیز
                --BEGIN
                --   IF CAST(@RemnTime AS DATE) = CAST(GETDATE() AS DATE)
                --      SET @Message += N'*تخفیف شگفت انگیز* ⏳ *' + CAST(CAST(@RemnTime AS TIME(0)) AS NVARCHAR(5)) + N'*' + CHAR(10);
                --   ELSE
                --      SET @Message += N'*تخفیف شگفت انگیز* ⏳ *' + dbo.GET_MTOS_U(@RemnTime) + N' ' + CAST(CAST(@RemnTime AS TIME(0)) AS NVARCHAR(5)) + N'*' + CHAR(10);
                --END
                END;
                ELSE -- اگر تخفیفی وجود نداشته باشد
                    SET @Amnt = @Pric + @ExtrPrct;

                -- بدست آوردن اطلاعات مربوط به کالا
                SELECT @RtngNumbDnrm = RTNG_NUMB_DNRM,
                       @RtngContDnrm = RTNG_CONT_DNRM,
                       @ProdFetr = PROD_FETR,
                       @TarfTextDnrm = TARF_TEXT_DNRM,
                       @TarfEnglText = TARF_ENGL_TEXT,
                       @RevwContDnrm = REVW_CONT_DNRM,
                       @BrndTextDnrm = BRND_TEXT_DNRM,
                       @GropTextDnrm = GROP_TEXT_DNRM,
                       @TarfCode = TARF_CODE,
                       @LikeContDnrm = LIKE_CONT_DNRM,
                       @VistContDnrm = VIST_CONT_DNRM,
                       @SaleContDnrm = SALE_NUMB_DNRM,
                       @MinOrdr = MIN_ORDR_DNRM,
                       @GrntStat = GRNT_STAT_DNRM,
                       @GrntNumb = GRNT_NUMB_DNRM,
                       @GrntTime = GRNT_TIME_DNRM,
                       @GrntType = GRNT_TYPE_DNRM,
                       @WrntStat = WRNT_STAT_DNRM,
                       @WrntNumb = WRNT_NUMB_DNRM,
                       @WrntTime = WRNT_TIME_DNRM,
                       @WrntType = WRNT_TYPE_DNRM,
                       @UnitDescDnrm = UNIT_DESC_DNRM,
                       @CrntNumbDnrm = CRNT_NUMB_DNRM,
                       @AlrmMinNumbDnrm = ALRM_MIN_NUMB_DNRM,
                       @DelvDayDnrm = DELV_DAY_DNRM,
                       @DelvHourDnrm = DELV_HOUR_DNRM,
                       @DelvMintDnrm = DELV_MINT_DNRM,
                       @MakeDayDnrm = MAKE_DAY_DNRM,
                       @MakeHourDnrm = MAKE_HOUR_DNRM,
                       @MakeMintDnrm = MAKE_MINT_DNRM,
                       @ProdLifeStat = PROD_LIFE_STAT,
                       @ProdSuplLoctStat = PROD_SUPL_LOCT_STAT,
                       @ProdSuplLoctDesc = PROD_SUPL_LOCT_DESC,
                       @RespShipCostType = RESP_SHIP_COST_TYPE
                FROM dbo.Robot_Product
                WHERE ROBO_RBID = @Rbid
                      AND TARF_CODE = @ParamText;

                SET @Item = N'';
                -- آیا کالا درقسمت علاقه مندی های مشتری قرار گرفته است یا خیر
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.Service_Robot_Product_Like a,
                         dbo.Robot_Product b
                    WHERE CHAT_ID = @ChatID
                          AND a.SRBT_ROBO_RBID = @Rbid
                          AND a.RBPR_CODE = b.CODE
                          AND b.TARF_CODE = @ParamText /* @tarfcode */
                          AND a.STAT = '002'
                )
                BEGIN
                    SET @Item = N'❤️';
                END;

                -- ایا مشتری این محصول را در قسمت اطلاع رسانی تخفیفات قرار داده است
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.Service_Robot_Product_Amazing_Notification a,
                         dbo.Robot_Product b
                    WHERE a.CHAT_ID = @ChatID
                          AND a.SRBT_ROBO_RBID = @Rbid
                          AND a.RBPR_CODE = b.CODE
                          AND b.TARF_CODE = @ParamText /* @tarfcode */
                          AND a.STAT = '002'
                )
                BEGIN
                    IF LEN(@Item) >= 1
                        SET @Item += N' • ';
                    SET @Item += N'🔔';
                END;

                -- 1399/04/28
                -- بدست آوردن تعداد عکس هایی که یه محصول داره
                SELECT @Said = COUNT(pp.CODE)
                FROM dbo.Robot_Product_Preview pp
                WHERE pp.TARF_CODE_DNRM = @ParamText
                      AND pp.STAT = '002';

                SET @Message += REPLACE(N'*{0}*', N'{0}', @TarfTextDnrm) + CASE WHEN @Said > 1 THEN N'  📷 ' + CAST(@Said AS VARCHAR(3)) ELSE N'' END + N'    ( کد محصول : ' + @TarfCode + N' )' + CHAR(10) + 
                                CASE WHEN @TarfEnglText IS NULL OR @TarfEnglText = N'' THEN N' ' ELSE (@TarfEnglText + CHAR(10)) END + 
                                CASE WHEN LEN(@Item) >= 1 THEN N'     ' + @Item + CHAR(10) ELSE N'' END + REPLACE(N'⭐️ *{0}* ', N'{0}', @RtngNumbDnrm)
                                + REPLACE(N'( {0} )', N'{0}', @RtngContDnrm) + N' • ' + REPLACE(N'{0} دیدگاه کاربران', N'{0}', @RevwContDnrm)
                                + CASE -- نمایش تعداد لایک های زده شده از توسط مشتری
                                      WHEN ISNULL(@LikeContDnrm, 0) != 0 THEN
                                          N' • ' + REPLACE(N'💛 *{0}*', N'{0}', @LikeContDnrm)
                                      ELSE
                                          N' '
                                  END + 
                                  CASE -- نمایش تعداد بازدید های انجام شده توسط مشتریان
                                      WHEN ISNULL(@VistContDnrm, 0) != 0 THEN
                                          N' • ' + REPLACE(N'👓 *{0}*', N'{0}', @VistContDnrm)
                                      ELSE
                                          N' '
                                  END + CHAR(10) + REPLACE(N'برند : *{0}*', N'{0}', @BrndTextDnrm) + N'     '
                                + REPLACE(N'گروه : {0}', N'{0}', @GropTextDnrm) + CHAR(10) + CHAR(10)
                                + N'*ویژگی های محصول*' + CHAR(10) 
                                + (SELECT N'⏱️ *- ' + d.DOMN_DESC + N' -*' FROM dbo.[D$PROT] d WHERE d.VALU = ISNULL(@ProdLifeStat, '001')) + CHAR(10)
                                + REPLACE(N'{0}', N'{0}', ISNULL(@ProdFetr, N' ')) + CHAR(10)
                                + CHAR(10) + N'📦 موجودی کالا : *'
                                + CASE ISNULL(@ViewInvrStat, '002')
                                      WHEN '001' THEN -- نمایش تعداد موجودی کالا
                                          CAST(@CrntNumbDnrm AS NVARCHAR(32)) + N' ' + ISNULL(@UnitDescDnrm, N'واحد')
                                      WHEN '002' THEN -- نمایش عنوان موجودی  یا عدم موجودی
                                          CASE
                                              WHEN ISNULL(@CrntNumbDnrm, 0) > 0
                                                   AND ISNULL(@CrntNumbDnrm, 0) > ISNULL(@AlrmMinNumbDnrm, 0) THEN
                                                  N'✅ موجود'
                                              WHEN ISNULL(@CrntNumbDnrm, 0) > 0
                                                   AND ISNULL(@CrntNumbDnrm, 0) <= ISNULL(@AlrmMinNumbDnrm, 0) THEN
                                                  N'☑️ تعداد محدود'
                                              WHEN ISNULL(@CrntNumbDnrm, 0) = 0 THEN
                                                  N'❌ ناموجود'
                                          END
                                  END + N'*' + dbo.STR_COPY_U(N' ', 5) --+ CHAR(10) + CHAR(10) 
                                + CASE -- زمان تولید
                                      WHEN ISNULL(@CrntNumbDnrm, 0) != 0 THEN -- اگر کالا موجود باشد
                                           N'🚚 *آماده ارسال*'
                                      ELSE -- اگر کالا موجود نباشد
                                          CASE (@MakeDayDnrm + @MakeHourDnrm + @MakeMintDnrm)
                                               WHEN 0 THEN N''
                                               ELSE 
                                                N'🎛️ زمان تولید : ' 
                                                + CASE @MakeDayDnrm WHEN 0 THEN N'' ELSE CAST(@MakeDayDnrm AS VARCHAR(3)) + N' روز' END 
                                                + CASE @MakeHourDnrm WHEN 0 THEN N'' ELSE CAST(@MakeHourDnrm AS VARCHAR(3)) + N' ساعت' END 
                                                + CASE @MakeMintDnrm WHEN 0 THEN N'' ELSE CAST(@MakeMintDnrm AS VARCHAR(3)) + N' دقیقه' END 
                                          END 
                                  END + CHAR(10)
                                + CASE -- زمان تحویل
                                      WHEN @DelvDayDnrm != 0 OR @DelvHourDnrm != 0 or @DelvMintDnrm != 0 THEN 
                                           dbo.STR_COPY_U(N' ', 7) 
                                          + N'زمان تحویل : ' 
                                          + CASE @DelvDayDnrm WHEN 0 THEN N'' ELSE N'*' + CAST(@DelvDayDnrm AS VARCHAR(3)) + N'* روز ' END 
                                          + CASE @DelvHourDnrm WHEN 0 THEN N'' ELSE N'*' + CAST(@DelvHourDnrm AS VARCHAR(3)) + N'* ساعت ' END 
                                          + CASE @DelvMintDnrm WHEN 0 THEN N'' ELSE N'*' + CAST(@DelvMintDnrm AS VARCHAR(3)) + N'* دقیقه ' END + CHAR(10)
                                      ELSE N''
                                  END + 
                                  -- 1399/09/20 * اضافه شدن حوزه تامین کننده و هزینه ارسال باربری
                                + CASE ISNULL(@ProdSuplLoctStat, '001')
                                       WHEN '001' THEN N'' 
                                       WHEN '002' THEN N'📌 حوزه تامین : *' + ISNULL(@ProdSuplLoctDesc, N'مشخص نیست') + N'  •  ' + 
                                       (SELECT N'🚚 ' + d.DOMN_DESC FROM dbo.[D$RSCT] d WHERE d.VALU = ISNULL(@RespShipCostType, '001')) + N'*' + CHAR(10) 
                                  END 
                                + CASE -- حداقل سفارش کالا
                                      WHEN ISNULL(@MinOrdr, 1) > 1 THEN
                                          +N'*[ حداقل ثبت سفارش 👈 ' + CAST(@MinOrdr AS VARCHAR(3)) + N' ' + @UnitDescDnrm + N' 👉 می باشد. ]*'
                                          + CHAR(10) + CHAR(10)
                                      ELSE
                                          N' ' + CHAR(10) 
                                  END + 
                                + N'قیمت مصرف کننده : '
                                + CASE
                                      WHEN @RbpdCode IS NOT NULL THEN
                                          N' '
                                          + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @Pric + @ExtrPrct), 1), '.00', '')
                                          + N' ' + @AmntTypeDesc + CHAR(10) + REPLACE(N'🔥 *{0}%* ', N'{0}', @OffPrct)
                                      ELSE
                                          N' '
                                  END
                                + CASE
                                      WHEN @RbpdCode IS NOT NULL
                                           AND @offType = '001' THEN
                                          N'*تخفیف شگفت انگیز*' + CHAR(10) + N'             تا  '
                                          + CAST(CAST(@RemnTime AS TIME(0)) AS NVARCHAR(5)) + N'   '
                                          + dbo.GET_MTOS_U(@RemnTime) + CHAR(10) + CHAR(10)
                                          +

                                           --N'▫️▪️▫️▪️▫️▪️▫️▪️▫️▪️' + CHAR(10) + 
                                           --N'⬜️⬛️⬜️⬛️⬜️⬛️⬜️⬛️⬜️⬛️ ' + CHAR(10) + 
                                           --N'⬜️⬜️⬜️⬜️⬜️⬛️⬛️⬛️⬛️⬛️ ' + 
                                           dbo.STR_COPY_U(
                                                             N'⬜️',
                                                             (ROUND(
                                                                       DATEDIFF(MINUTE, @StrtDistCont, GETDATE()) * 100
                                                                       / DATEDIFF(MINUTE, @StrtDistCont, @RemnTime),
                                                                       -1,
                                                                       0
                                                                   ) / 10
                                                             )
                                                         )
                                          + dbo.STR_COPY_U(
                                                              N'⬛️',
                                                              ((100
                                                                - ROUND(
                                                                           DATEDIFF(MINUTE, @StrtDistCont, GETDATE())
                                                                           * 100
                                                                           / DATEDIFF(MINUTE, @StrtDistCont, @RemnTime),
                                                                           -1,
                                                                           0
                                                                       )
                                                               ) / 10
                                                              )
                                                          ) + N' '
                                          + CAST(DATEDIFF(MINUTE, @StrtDistCont, GETDATE()) * 100
                                                 / DATEDIFF(MINUTE, @StrtDistCont, @RemnTime) AS NVARCHAR(3)) + N' % '
                                          + CHAR(10) + N'*'
                                          + CAST(DATEDIFF(MINUTE, GETDATE(), @RemnTime) / 60 AS NVARCHAR(10))
                                          + N' ساعت و '
                                          + CAST(DATEDIFF(MINUTE, GETDATE(), @RemnTime) % 60 AS NVARCHAR(10))
                                          + N' دقیقه ' + N' تا پایان تخفیف *' + CHAR(10) + CHAR(10)
                                      -- ایجاد متن تخفیف
                                      --IF @offType = '001' AND @RemnTime >= GETDATE() -- تخفیف شگفت انگیز
                                      --BEGIN
                                      --   --IF CAST(@RemnTime AS DATE) = CAST(GETDATE() AS DATE)
                                      --   --   SET @Message += N'*تخفیف شگفت انگیز* ⏳ *' + CAST(CAST(@RemnTime AS TIME(0)) AS NVARCHAR(5)) + N'*' + CHAR(10);
                                      --   --ELSE
                                      --   --   SET @Message += N'*تخفیف شگفت انگیز* ⏳ *' + dbo.GET_MTOS_U(@RemnTime) + N' ' + CAST(CAST(@RemnTime AS TIME(0)) AS NVARCHAR(5)) + N'*' + CHAR(10);                       
                                      --END
                                      WHEN @RbpdCode IS NOT NULL
                                           AND @offType = '002' THEN
                                          N'*تخفیف ویژه*' + CHAR(10) + CHAR(10)
                                      ELSE
                                          CHAR(10)
                                  END + N'💰 *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @Amnt), 1), '.00', '')
                                + N' ' + @AmntTypeDesc + N'*' + CHAR(10) + CHAR(10)
                                + CASE -- نمایش تعداد فروخته شده از همین کالا
                                      WHEN ISNULL(@SaleContDnrm, 0) != 0 THEN
                                           N'🛍️ ' + REPLACE(N'*{0}*', N'{0}', @SaleContDnrm)
                                      ELSE
                                          N' '
                                      END + 
                                  CASE -- نمایش اینکه کالا هدیه دارد یا خیر
                                      WHEN EXISTS (
                                             SELECT *
                                             FROM dbo.Service_Robot_Seller_Product_Gift pg,
                                                  dbo.Service_Robot_Seller_Product sp,
                                                  dbo.Robot_Product rp
                                             WHERE pg.TARF_CODE_DNRM = @TarfCode
                                                   AND pg.STAT = '002'
                                                   AND pg.SSPG_CODE = sp.CODE
                                                   AND sp.CRNT_NUMB_DNRM > 0
                                                   AND sp.TARF_CODE = rp.TARF_CODE
                                                   AND rp.ROBO_RBID = @Rbid
                                                   AND rp.STAT = '002'
                                           ) THEN
                                             N' • 🎁'
                                       ELSE
                                             N' '
                                  END
                                + CASE -- اگر محصول شرایط گارانتی داشته باشد
                                      WHEN ISNULL(@GrntStat, '000') = '002' THEN
                                      (
                                          SELECT N' • 🏅' + CAST(@GrntNumb AS VARCHAR(3)) + d.DOMN_DESC + N' گارانتی'
                                          FROM dbo.[D$DAYT] d
                                          WHERE d.VALU = @GrntTime
                                      ) +                                      
                                      (
                                          CASE 
                                               WHEN @GrntType != '' AND ISNULL(@GrntType, '000') != '000' THEN 
                                               (
                                                  SELECT N' • 👌 *100%* ' + d.DOMN_DESC
                                                    FROM dbo.[D$GRNT] d
                                                   WHERE d.VALU = @GrntType
                                               )
                                               ELSE N' '
                                          END 
                                      )                                      
                                      ELSE
                                          N' '
                                  END; --+ CHAR(10)

                -- بدست آوردن منوی محصول
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           CASE @PostExec
                               WHEN 'lessinfoprod' THEN
                                   @PostExec
                               WHEN 'moreinfoprod' THEN
                                   @PostExec
                               ELSE
                                   'lessinfoprod'
                           END AS '@cmndtext', -- اجرای منو در حالی که میخواهیم
                           @ParamText AS '@tarfcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                );

                -- 1399/04/28
                -- اگر فرآیند از جایی دیگر اجرا شده باشد باید دوباره به همان مرحله قبل برگردیم
                IF @V$WhereAreYouFrom = 'showimagprod'
                    GOTO L$ShowImagProd;
                ELSE IF @V$WhereAreYouFrom = 'showgiftslerprod'
                    GOTO L$ShowGiftSlerProd;
                ELSE IF @V$WhereAreYouFrom = 'showothrlinkprod'
                    GOTO L$ShowOthrLinkProd;

                -- مشخص شدن اینکه متن با عبارت متنی ساده باید ارسال شود یا با عکس
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.Robot_Product rp,
                         dbo.Robot_Product_Preview rpp
                    WHERE rp.ROBO_RBID = @Rbid
                          AND rp.CODE = rpp.RBPR_CODE
                          AND rp.TARF_CODE = @ParamText /* @tarfcode */
                          AND rpp.STAT = '002'
                )
                BEGIN
                    SET @XMessage =
                    (
                        SELECT TOP 1
                               rpp.FILE_ID AS '@fileid',
                               rpp.FILE_TYPE AS '@filetype',
                               @Message AS '@caption',
                               1 AS '@order'
                        FROM dbo.Robot_Product rp,
                             dbo.Robot_Product_Preview rpp
                        WHERE rp.ROBO_RBID = @Rbid
                              AND rp.CODE = rpp.RBPR_CODE
                              AND rp.TARF_CODE = @ParamText
                              AND rpp.STAT = '002'
                        ORDER BY rpp.ORDR
                        FOR XML PATH('Complex_InLineKeyboardMarkup')
                    );
                    SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
                END;
                ELSE
                BEGIN
                    SET @XTemp.modify('insert attribute caption {sql:variable("@message")} as first into (//InlineKeyboardMarkup)[1]');
                    SET @XMessage = @XTemp;
                END;
                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
        END;
        -- مدیریت سبد خرید
        ELSE IF @MenuText IN ( 'addcart', 'delcart', 'deccart', 'showcart', 'remvcart', 'paycart', 'infocart',
                               'finalcart', 'historycart'
                             )
        BEGIN
            L$CartOperations:
            IF @ParamText LIKE '%,%'
                SELECT @ParamText = CASE id WHEN 1 THEN Item ELSE @ParamText END,
                       @RbppCode = CASE id WHEN 2 THEN Item ELSE @RbppCode END
                FROM dbo.SplitString(@ParamText, ',');

            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       CASE @MenuText
                           WHEN 'finalcart' THEN
                               '006'
                           ELSE
                               '000'
                       END AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       CASE @MenuText
                           WHEN 'addcart' THEN
                               @ParamText /* tarfcode */ -- افزودن به سبد خرید
                           WHEN 'delcart' THEN
                               @ParamText /* tarfcode */ -- حذف کردن کالا از سبد خرید
                           WHEN 'deccart' THEN
                               @ParamText /* tarfcode */ -- کم کردن تعداد کالا                     
                           WHEN 'showcart' THEN
                               'show'     -- نمایش فاکتور                     
                           WHEN 'remvcart' THEN
                               'empty'    -- خالی کردن تمام اقلام کالا درون سبد
                           WHEN 'paycart' THEN
                               'show'     -- نحوه پرداخت
                           WHEN 'infocart' THEN
                               'show'     -- نمایش اطلاعات فاکتور
                           WHEN 'finalcart' THEN
                               'final'    -- پرداخت فاکتور / نمایش پرداخت شده فاکتور
                           WHEN 'historycart' THEN
                               'history'  -- نمایش سابقه صورتحساب
                       END AS '@input',
                       CASE @MenuText
                           WHEN 'addcart' THEN
                               '0'        -- افزودن به سبد خرید
                           WHEN 'delcart' THEN
                               '0'        -- حذف کردن کالا از سبد خرید
                           WHEN 'deccart' THEN
                               '0'        -- کم کردن تعداد کالا
                           WHEN 'showcart' THEN
                               @ParamText /* ordrcode */ -- نمایش فاکتور                     
                           WHEN 'remvcart' THEN
                               @ParamText /* ordrcode */ -- خالی کردن تمام اقلام کالا درون سبد
                           WHEN 'paycart' THEN
                               @ParamText /* ordrcode */ -- نحوه پرداخت
                           WHEN 'infocart' THEN
                               @ParamText /* ordrcode */ -- نمایش اطلاعات فاکتور
                           WHEN 'finalcart' THEN
                               @ParamText /* ordrcode */ -- نمایش اطلاعات فاکتور پرداخت شده
                           WHEN 'historycart' THEN
                               @ParamText /* ordrcode */ -- نمایش اطلاعات سابقه فاکتور
                       END AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      
            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT');

            -- اگر کالایی که ثبت شده جز کارت های اعتباری باشد باید تغییری درون جدول ردیف درخواست اعمال کنیم
            UPDATE od
            SET od.ELMN_TYPE = '002',
                od.IMAG_PATH = rpp.FILE_ID,
                od.ORDR_DESC = rpp.FILE_DESC
            FROM dbo.Order_Detail od,
                 dbo.Robot_Product rp,
                 dbo.Robot_Product_Preview rpp
            WHERE od.ORDR_CODE = @OrdrCode
                  AND rp.TARF_CODE = @ParamText
                  AND rp.TARF_CODE = od.TARF_CODE
                  AND rp.GROP_CODE_DNRM = 13992171200883 /* گروه کارت هدیه */
                  AND rp.CODE = rpp.RBPR_CODE
                  AND rpp.CODE = @RbppCode;

            -- Successfull
            IF @RsltCode = '002'
            BEGIN
                SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
                SELECT @Message += CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
                -- اضافه کردن منوهای اولیه مربوط به فاکتور فروش مشتری         
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           CASE @MenuText
                               WHEN 'addcart' THEN
                                   'lessinfoinvc'
                               WHEN 'delcart' THEN
                                   'lessinfoinvc'
                               WHEN 'deccart' THEN
                                   'lessinfoinvc'
                               WHEN 'remvcart' THEN
                                   @PostExec
                               WHEN 'showcart' THEN
                                   @PostExec
                               WHEN 'paycart' THEN
                                   @PostExec
                               WHEN 'infocart' THEN
                                   @PostExec
                               WHEN 'finalcart' THEN
                                   @PostExec
                           END AS '@cmndtext',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                -- اگر مشتری بخواهد پراخت خود را از طریق کیف پول انجام دهد باید چک کنیم که میزان مبلغ کیف پول از مبلغ سفارش بیشتر باشد در غیر اینصورت پیام هشدار در پایان متن صورتحسات قرار گیرد
                IF @MenuText = 'paycart'
                   AND @PostExec = 'lesswletcart'
                BEGIN
                    IF EXISTS
                    (
                        SELECT *
                        FROM dbo.[Order] o,
                             dbo.Wallet w
                        WHERE o.CODE = @OrdrCode
                              AND o.SRBT_SERV_FILE_NO = w.SRBT_SERV_FILE_NO
                              AND o.SRBT_ROBO_RBID = w.SRBT_ROBO_RBID
                              AND o.CHAT_ID = w.CHAT_ID
                              AND w.WLET_TYPE = '002' -- Cash Wallet
                              AND o.DEBT_DNRM > (ISNULL(w.AMNT_DNRM, 0) - ISNULL(w.TEMP_AMNT_USE, 0))
                    )
                    BEGIN
                        SET @Message += CHAR(10)
                                        + N'⚠️ *مبلغ فاکتور شما بیشتر از موجودی کیف پول می باشد، لطفا جهت افزایش اعتبار کیف پول اقدام نمایید.*';
                    END;
                END;

                -- اگر مشتری درخواست این را داشته باشد که بخواهد از طریق ارسال رسید کار کند باید به آن شماره کارت را ارائه دهیم
                IF @MenuText = 'paycart'
                   AND @PostExec = 'lessrcptcart'
                BEGIN
                    SET @Message += CHAR(10) + CHAR(10)
                                    +
                                    (
                                        SELECT N'💵 *واریز هزینه' + CHAR(10) + N'💳 ' + b.CARD_NUMB_FRMT_DNRM
                                               + CHAR(10) + CASE
                                                                WHEN ISNULL(b.SHBA_NUMB_DNRM, N'') ! = N'' THEN
                                                                    N'🏦 ' + b.SHBA_NUMB_FRMT_DNRM + CHAR(10)
                                                                ELSE
                                                                    N''
                                                            END + b.ACNT_OWNR_DNRM + N' - ' + b.BANK_NAME_DNRM + N'*'
                                        FROM dbo.[Order] o,
                                             dbo.Service_Robot_Card_Bank b
                                        WHERE o.CODE = @OrdrCode
                                              AND o.DEST_CARD_NUMB_DNRM = b.CARD_NUMB_DNRM
                                              AND o.ORDR_TYPE = b.ORDR_TYPE_DNRM
                                              AND b.ACNT_STAT_DNRM = '002'
                                    );
                END;

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                
                IF(@MenuText = 'finalcart')
                BEGIN
                    -- اگر درخواست پذیرش انلاین داشته باشیم آن را هم تحویل به مشتری و پایانی میکنیم
                    -- ####################
                    UPDATE dbo.[Order]
                       SET ORDR_STAT = '009',
                           END_DATE = GETDATE()
                     WHERE ORDR_TYPE = '025'
                       AND CODE IN (
                           SELECT o.ORDR_CODE
                             FROM dbo.[Order] o
                            WHERE o.ORDR_TYPE = '004'
                              AND o.CODE = @OrdrCode                           
                     );
                    
                    UPDATE dbo.[Order]
                       SET ORDR_STAT = '004',
                           END_DATE = GETDATE()
                     WHERE ORDR_TYPE = '025'
                       AND CODE IN (
                           SELECT o.ORDR_CODE
                             FROM dbo.[Order] o
                            WHERE o.ORDR_TYPE = '004'
                              AND o.CODE = @OrdrCode                           
                     );
                    -- ####################
                END 

                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
            ELSE IF @RsltCode IN ( '003', '004' ) -- اگر کالا موجودی نداشته باشد یا تعداد موجودی کمتر از تعداد درخواستی باشد
            BEGIN
                SELECT @TarfCode = @XTemp.query('//Message').value('(Message/@tarfcode)[1]', 'VARCHAR(100)');
                -- باید ابتدا بررسی کنیم که آیا برای کالای فعلی کالای جایگزین یا سوپر گروه وجود دارد یا خیر
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.Robot_Product_Alternative pa
                    WHERE pa.TARF_CODE_DNRM = @TarfCode
                          AND pa.STAT = '002'
                )
                   OR EXISTS
                (
                    SELECT *
                    FROM dbo.Robot_Product ps,
                         dbo.Robot_Product pt
                    WHERE ps.ROBO_RBID = @Rbid
                          AND ps.ROBO_RBID = pt.ROBO_RBID
                          AND ps.TARF_CODE = @TarfCode
                          AND pt.TARF_CODE != @TarfCode
                          AND ps.GROP_JOIN_DNRM = pt.GROP_JOIN_DNRM
                          AND pt.STAT = '002'
                )
                BEGIN
                    SET @Message
                        = CASE @RsltCode
                              WHEN '003' THEN
                                  N'⚠️ متاسفانه *کالای درخواستی شما* _موجود_ 🚫 نمی باشد.'
                              WHEN '004' THEN
                                  N'⚠️ متاسفانه *تعداد کالای درخواستی شما* _موجود_ 🚫 نمی باشد، لطفا 🔢 *تعداد کالای* خود را ✏️ _اصلاح_ کنید'
                          END + CHAR(10) + CHAR(10)
                          + N'🔵 البته شما می توانید از 🔄  کالاهای *جایگزین* یا کالاهای ↔️ *مشابه* زیر هم استفاده کنید.';
                    -- اضافه کردن منوهای اولیه مربوط به فاکتور فروش مشتری         
                    SET @XTemp =
                    (
                        SELECT @Rbid AS '@rbid',
                               @ChatID AS '@chatid',
                               @UssdCode AS '@ussdcode',
                               'lesslockinvrwas' AS '@cmndtext',
                               @OrdrCode AS '@ordrcode',
                               @TarfCode AS '@tarfcode'
                        FOR XML PATH('RequestInLineQuery')
                    );
                    EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                         @XRet = @XTemp OUTPUT; -- xml

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                    );

                    SET @XMessage =
                    (
                        SELECT TOP 1
                               om.FILE_ID AS '@fileid',
                               om.IMAG_TYPE AS '@filetype',
                               @Message AS '@caption',
                               1 AS '@order'
                        FROM dbo.Organ_Media om
                        WHERE om.ROBO_RBID = @Rbid
                              AND om.RBCN_TYPE = '017'
                              AND om.IMAG_TYPE = '002'
                              AND om.STAT = '002'
                        FOR XML PATH('Complex_InLineKeyboardMarkup')
                    );
                    SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

                    SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
                END;
                ELSE
                BEGIN
                    SET @Message
                        = CASE @RsltCode
                              WHEN '003' THEN
                                  N'⚠️ متاسفانه *کالای درخواستی شما* _موجود_ 🚫 نمی باشد.'
                              WHEN '004' THEN
                                  N'⚠️ متاسفانه *تعداد کالای درخواستی شما* _موجود_ 🚫 نمی باشد، لطفا 🔢 *تعداد کالای* خود را ✏️ _اصلاح_ کنید'
                          END + CHAR(10) + CHAR(10)
                          + N'🔵 البته به محض اینکه موجودی کالا اضافه شد، به شما مشتری عزیز اطلاع رسانی میکنیم.';

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order'
                        --@XTemp
                        FOR XML PATH('InlineKeyboardMarkup')
                    );

                    SET @XMessage =
                    (
                        SELECT TOP 1
                               om.FILE_ID AS '@fileid',
                               om.IMAG_TYPE AS '@filetype',
                               @Message AS '@caption',
                               1 AS '@order'
                        FROM dbo.Organ_Media om
                        WHERE om.ROBO_RBID = @Rbid
                              AND om.RBCN_TYPE = '017'
                              AND om.IMAG_TYPE = '002'
                              AND om.STAT = '002'
                        FOR XML PATH('Complex_InLineKeyboardMarkup')
                    );
                    SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

                    SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
                END;
            END;
            ELSE IF @RsltCode = '001'
            BEGIN
                SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
                SELECT @Message += CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
                -- اضافه کردن منوهای اولیه مربوط به فاکتور فروش مشتری         
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'productnotfound' AS '@cmndtext',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @XMessage =
                (
                    SELECT TOP 1
                           om.FILE_ID AS '@fileid',
                           om.IMAG_TYPE AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                          AND om.RBCN_TYPE = '009'
                          AND om.IMAG_TYPE = '002'
                          AND om.STAT = '002'
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                );
                SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
        END;
        -- ذخیره کردن محصول جز علاقه مندی های مشتری
        ELSE IF @MenuText IN ( 'likeprod' )
        BEGIN
            SET @Said = NULL;
            SELECT @LikeStat = srpl.STAT,
                   @Said = srpl.CODE
            FROM dbo.Robot_Product rp,
                 dbo.Service_Robot_Product_Like srpl
            WHERE rp.ROBO_RBID = @Rbid
                  AND rp.ROBO_RBID = srpl.SRBT_ROBO_RBID
                  AND rp.CODE = srpl.RBPR_CODE
                  AND rp.TARF_CODE = @ParamText
                  AND srpl.CHAT_ID = @ChatID;

            IF @Said IS NOT NULL
            BEGIN
                UPDATE dbo.Service_Robot_Product_Like
                SET STAT = CASE @LikeStat
                               WHEN '001' THEN
                                   '002'
                               WHEN '002' THEN
                                   '001'
                           END,
                    LIKE_DATE = GETDATE()
                WHERE CODE = @Said;
            END;
            ELSE
            BEGIN
                INSERT INTO dbo.Service_Robot_Product_Like
                (
                    SRBT_SERV_FILE_NO,
                    SRBT_ROBO_RBID,
                    RBPR_CODE,
                    CODE,
                    CHAT_ID,
                    LIKE_DATE,
                    STAT
                )
                SELECT sr.SERV_FILE_NO,
                       sr.ROBO_RBID,
                       rp.CODE,
                       dbo.GNRT_NVID_U(),
                       @ChatID,
                       GETDATE(),
                       '002'
                FROM dbo.Service_Robot sr,
                     dbo.Robot_Product rp
                WHERE sr.ROBO_RBID = rp.ROBO_RBID
                      AND sr.ROBO_RBID = @Rbid
                      AND sr.CHAT_ID = @ChatID
                      AND rp.TARF_CODE = @ParamText;
                SET @LikeStat = '002';
            END;

            IF @LikeStat = '001'
                SET @Message = N'محصول از لیست علاقه مندی شما خارج شد';
            ELSE IF @LikeStat = '002'
                SET @Message = N'محصول در لیست علاقه مندی شما قرار گرفت';
        END;
        -- اطلاع رسانی بابت تخفیفات فروشگاه بر روی کالای مورد نظر ما
        ELSE IF @MenuText IN ( 'amzgnoti' )
        BEGIN
            SET @Said = NULL;
            SELECT @AmazNotiStat = srpan.STAT,
                   @Said = srpan.CODE
            FROM dbo.Robot_Product rp,
                 dbo.Service_Robot_Product_Amazing_Notification srpan
            WHERE rp.ROBO_RBID = @Rbid
                  AND rp.ROBO_RBID = srpan.SRBT_ROBO_RBID
                  AND rp.CODE = srpan.RBPR_CODE
                  AND rp.TARF_CODE = @ParamText
                  AND srpan.CHAT_ID = @ChatID;

            IF @Said IS NOT NULL
            BEGIN
                UPDATE dbo.Service_Robot_Product_Amazing_Notification
                SET STAT = CASE @AmazNotiStat
                               WHEN '001' THEN
                                   '002'
                               WHEN '002' THEN
                                   '001'
                           END
                WHERE CODE = @Said;
            END;
            ELSE
            BEGIN
                INSERT INTO dbo.Service_Robot_Product_Amazing_Notification
                (
                    SRBT_SERV_FILE_NO,
                    SRBT_ROBO_RBID,
                    RBPR_CODE,
                    CODE,
                    CHAT_ID,
                    SEND_WITH_SMS,
                    SEND_WITH_APP,
                    STAT
                )
                SELECT sr.SERV_FILE_NO,
                       sr.ROBO_RBID,
                       rp.CODE,
                       dbo.GNRT_NVID_U(),
                       @ChatID,
                       '001',
                       '002',
                       '002'
                FROM dbo.Service_Robot sr,
                     dbo.Robot_Product rp
                WHERE sr.ROBO_RBID = rp.ROBO_RBID
                      AND sr.ROBO_RBID = @Rbid
                      AND sr.CHAT_ID = @ChatID
                      AND rp.TARF_CODE = @ParamText;
                SET @AmazNotiStat = '002';
            END;

            IF @AmazNotiStat = '001'
                SET @Message = N'اطلاع رسانی تخفیفات محصول برای شما غیرفعال شد';
            ELSE IF @AmazNotiStat = '002'
                SET @Message = N'اطلاع رسانی تخفیفات محصول برای شما فعال شد';
        END;
        -- در صورت ناموجود بودن اطلاع رسانی به مشتری انجام شود
        ELSE IF @MenuText IN ( 'sgnlnoti' )
        BEGIN
            SET @TarfCode = @ParamText;
            
            INSERT INTO dbo.Service_Robot_Product_Signal
            (SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,RBPR_CODE ,CODE ,SEND_STAT, CHCK_RQST_NUMB)
            SELECT sr.SERV_FILE_NO, sr.ROBO_RBID, rp.CODE, dbo.GNRT_NVID_U(), '002', 1
              FROM dbo.Service_Robot sr, dbo.Robot_Product rp
             WHERE sr.ROBO_RBID = @Rbid
               AND sr.CHAT_ID = @ChatId
               AND rp.ROBO_RBID = sr.ROBO_RBID
               AND rp.TARF_CODE = @tarfcode
               AND NOT EXISTS (
                     SELECT *
                       FROM dbo.Service_Robot_Product_Signal ps
                      WHERE ps.SRBT_ROBO_RBID = @Rbid
                        AND ps.CHAT_ID = @ChatId
                        AND ps.TARF_CODE_DNRM = @tarfcode
                        AND ps.SEND_STAT IN ('002', '005')
                   );
                   
            -- 1399/05/05
            -- اگر ردیف کالا برای مشتری قبلا ثبت شده باشد فقط کافیست که تعداد دفعات را بروزرسانی کنیم
            IF @@ROWCOUNT = 0
            BEGIN 
               DELETE dbo.Service_Robot_Product_Signal 
                WHERE SRBT_ROBO_RBID = @Rbid
                  AND CHAT_ID = @ChatID
                  AND TARF_CODE_DNRM = @TarfCode
                  AND SEND_STAT IN ('002', '005');
               
               SET @SgnlNotiStat = '001';
            END 
            ELSE
            BEGIN
               SET @SgnlNotiStat = '002';
            END             
             
            IF @SgnlNotiStat = '001'
                SET @Message = N'اطلاع رسانی موجودی محصول برای شما غیرفعال شد';
            ELSE IF @SgnlNotiStat = '002'
                SET @Message = N'اطلاع رسانی موجودی محصول برای شما فعال شد';
        END 
        -- مشاهده قیمتهای پله کانی
        ELSE IF @MenuText IN ( 'steppric' )
        BEGIN
           SET @TarfCode = @ParamText;
           SET @Message = (
               (SELECT N'[ *' + rp.TARF_CODE + N'* ] ' + rp.TARF_TEXT_DNRM + CHAR(10)
                 FROM dbo.Robot_Product rp
                WHERE rp.ROBO_RBID = @Rbid
                  AND rp.TARF_CODE = @TarfCode
                  FOR XML PATH('')) + CHAR(10) + 
               (SELECT N'👈 *' + b.DOMN_DESC + N'*' + CHAR(10) + 
                 (
                   SELECT CASE b.VALU
                               WHEN '001' THEN N'🔢 تعداد *' + CAST(a.TARF_CODE_QNTY AS VARCHAR(10)) + N'* قیمت فروش *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, a.EXPN_PRIC), 1), '.00', '') + N'* ' + @AmntTypeDesc
                               WHEN '002' THEN N'🛍️ جمع فاکتور *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, a.CART_SUM_PRIC), 1), '.00', '') + N'* قیمت فروش *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, a.EXPN_PRIC), 1), '.00', '') + N'* ' + @AmntTypeDesc
                          END + CHAR(10)
                     FROM dbo.Robot_Product_StepPrice a
                    WHERE a.TARF_CODE_DNRM = @TarfCode
                      AND a.STEP_TYPE = b.Valu
                      AND a.STAT = '002'
                    ORDER BY a.TARF_CODE_QNTY, a.CART_SUM_PRIC
                      FOR XML PATH('')                         
                 ) + CHAR(10)
                 FROM dbo.[D$SPTP] b
                 FOR XML PATH(''))
           )
        END 
        -- نمایش عکس های محصول
        ELSE IF @MenuText IN ( 'showimagprod' )
        BEGIN
            SET @V$WhereAreYouFrom = 'showimagprod';
            GOTO L$InfoProd;

            L$ShowImagProd:
            SET @V$WhereAreYouFrom = NULL;

            SET @XMessage =
            (
                SELECT pp.FILE_ID AS '@fileid',
                       pp.FILE_TYPE AS '@filetype',
                       @Message AS '@caption',
                       pp.ORDR AS '@order',
                       (
                           SELECT @XTemp
                       )
                FROM dbo.Robot_Product_Preview pp
                WHERE pp.TARF_CODE_DNRM = @ParamText
                      AND pp.STAT = '002'
                ORDER BY pp.FILE_TYPE,
                         pp.ORDR
                FOR XML PATH('Complex_InLineKeyboardMarkup'), ROOT('Message')
            );

            SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
        END;
        -- در این قسمت محصول های هدیه را نمایش میدهیم
        ELSE IF @MenuText IN ( 'showgiftslerprod' )
        BEGIN
            SET @V$WhereAreYouFrom = 'showgiftslerprod';
            GOTO L$InfoProd;

            L$ShowGiftSlerProd:
            SET @V$WhereAreYouFrom = NULL;

            SET @XTemp =
            (
                SELECT @Rbid AS '@rbid',
                       @ChatID AS '@chatid',
                       @UssdCode AS '@ussdcode',
                       'lessgiftprod' AS '@cmndtext',
                       @TarfCode AS '@tarfcode'
                FOR XML PATH('RequestInLineQuery')
            );
            EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            SET @XTemp =
            (
                SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
            );

            SET @XMessage =
            (
                SELECT TOP 1
                       om.FILE_ID AS '@fileid',
                       om.IMAG_TYPE AS '@filetype',
                       @Message AS '@caption',
                       1 AS '@order'
                FROM dbo.Organ_Media om
                WHERE om.ROBO_RBID = @Rbid
                      AND om.RBCN_TYPE = '019'
                      AND om.IMAG_TYPE = '002'
                      AND om.STAT = '002'
                FOR XML PATH('Complex_InLineKeyboardMarkup')
            );
            SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

            SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
        END;
        -- کالاهای مرتبط با کالا
        ELSE IF @MenuText IN ( 'showothrlinkprod' )
        BEGIN
            SET @V$WhereAreYouFrom = 'showothrlinkprod';
            GOTO L$InfoProd;

            L$ShowOthrLinkProd:
            SET @V$WhereAreYouFrom = NULL;

            SET @XTemp =
            (
                SELECT @Rbid AS '@rbid',
                       @ChatID AS '@chatid',
                       @UssdCode AS '@ussdcode',
                       'lesslinkprod' AS '@cmndtext',
                       @TarfCode AS '@tarfcode'
                FOR XML PATH('RequestInLineQuery')
            );
            EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            SET @XTemp =
            (
                SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
            );

            SET @XMessage =
            (
                SELECT TOP 1
                       om.FILE_ID AS '@fileid',
                       om.IMAG_TYPE AS '@filetype',
                       @Message AS '@caption',
                       1 AS '@order'
                FROM dbo.Organ_Media om
                WHERE om.ROBO_RBID = @Rbid
                      AND om.RBCN_TYPE = '020'
                      AND om.IMAG_TYPE = '002'
                      AND om.STAT = '002'
                FOR XML PATH('Complex_InLineKeyboardMarkup')
            );
            SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

            SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
        END;
        ELSE IF @MenuText IN ( 'showothrslerbrndprod' )
        BEGIN
            -- To Do List On Task
            PRINT 'Show Other Seller Brands Product';
        END;
        -- ثبت اطلاعات بازخورد کالا برای مشتری
        ELSE IF @MenuText IN ( 'feedbackprod' )
        BEGIN
            SET @TarfCode = @ParamText;
            L$FeedbackProd:
            -- To Do List On Task
            PRINT 'Feedback Product';

            SET @XTemp =
            (
                SELECT @Rbid AS '@rbid',
                       @ChatID AS '@chatid',
                       @UssdCode AS '@ussdcode',
                       'lessfdbkprod' AS '@cmndtext',
                       @TarfCode AS '@tarfcode'
                FOR XML PATH('RequestInLineQuery')
            );
            EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            SET @XTemp =
            (
                SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
            );

            SET @Message = N'لطفا نظر خود را درمورد محصول برای ما وارد کنید';

            SET @XMessage =
            (
                SELECT TOP 1
                       om.FILE_ID AS '@fileid',
                       om.IMAG_TYPE AS '@filetype',
                       @Message AS '@caption',
                       1 AS '@order'
                FROM dbo.Organ_Media om
                WHERE om.ROBO_RBID = @Rbid
                      AND om.RBCN_TYPE = '021'
                      AND om.IMAG_TYPE = '002'
                      AND om.STAT = '002'
                FOR XML PATH('Complex_InLineKeyboardMarkup')
            );
            SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

            SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
        END;
        -- Gift Card
        -- Shop By Occasion
        ELSE IF @MenuText IN ( 'shopbyoccasion' )
        BEGIN
            SET @XTemp =
            (
                SELECT mu.DATA_TEXT_DNRM AS '@data',
                       ROW_NUMBER() OVER (ORDER BY mu.ORDR) AS '@order',
                       mu.MENU_TEXT AS "text()"
                FROM dbo.Menu_Ussd mu
                WHERE mu.ROBO_RBID = @Rbid
                      AND mu.MENU_TYPE = '002' -- InlineQuery
                      AND mu.MNUS_MUID IN
                          (
                              SELECT mut.MUID
                              FROM dbo.Menu_Ussd mut
                              WHERE mut.ROBO_RBID = mu.ROBO_RBID
                                    AND mut.USSD_CODE = @ParamText
                          )
                ORDER BY mu.ORDR
                FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
            );
            SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            GOTO L$EndSP;
        END;
        -- Show Preview Gift Card Category
        ELSE IF @MenuText IN ( 'showgftpcards' )
        BEGIN
            L$SearchGiftCards:
            -- Sort Type List      
            -- 1. پربازدیدترین
            -- 2. پرفروش ترین
            -- 3. محبوب ترین      
            -- 5. جدیدترین
            -- 6. سریع ترین ارسال
            -- 7. ارزان ترین
            -- 8. گرانترین

            SET @FromDate = GETDATE();
            --DECLARE @T#SearchProducts TABLE (DATA varchar(100), ORDR int, [TEXT] nvarchar(MAX));
            INSERT INTO @T#SearchProducts
            (
                DATA,
                ORDR,
                [TEXT]
            )
            SELECT N'./' + @UssdCode + N';infoprod-gc' + CAST(rpp.CODE AS NVARCHAR(30)) + N'$lessinfogftp#' AS DATA,
                   ROW_NUMBER() OVER (ORDER BY rpp.ORDR) AS ORDR,
                   N'📦  ' + rpp.FILE_DESC
                   + dbo.STR_FRMT_U(
                                       N' [ {0} {1} نفر ]',
                                       dbo.STR_COPY_U(N'⭐️ ', rp.RTNG_NUMB_DNRM) + N','
                                       + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, rp.RTNG_CONT_DNRM), 1), '.00', '')
                                   ) AS [TEXT]
            FROM dbo.Robot_Product rp,
                 dbo.Robot_Product_Preview rpp
            WHERE rp.ROBO_RBID = @Rbid
                  AND rp.CODE = rpp.RBPR_CODE
                  AND rpp.FILE_KIND = @ParamText
                  AND rpp.STAT = '002'
            ORDER BY rpp.ORDR;
            SET @ToDate = GETDATE();

            SET @Message =
            (
                SELECT N'🔍 کارت های هدیه مناسبتی انتخابی شما' + CHAR(10)
                       + dbo.STR_FRMT_U(
                                           N'حدود {0} نتیجه، ({1} ثانیه)' + N' صفحه {2} ام -  تعداد {3} رکورد',
                                           REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(T.ORDR)), 1), '.00', '')
                                           + N',' + CAST(DATEDIFF(SECOND, @FromDate, @ToDate) AS NVARCHAR(50)) 
                                           + N',' + CAST(@Page AS NVARCHAR(10)) 
                                           + N',' + CAST(@PageFechRows AS NVARCHAR(10))
                                       )
                FROM @T#SearchProducts T
                FOR XML PATH('')
            );

            SET @XTemp =
            (
                SELECT T.DATA AS '@data',
                       T.ORDR AS '@order',
                       T.[TEXT] AS "text()"
                FROM @T#SearchProducts T
                WHERE T.ORDR
                BETWEEN ((@Page - 1) * @PageFechRows) + 1 AND ((((@Page - 1) * @PageFechRows)) + @PageFechRows)
                FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
            );
            SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
            SET @XTemp.modify('insert attribute caption {sql:variable("@Message")} into (//InlineKeyboardMarkup)[1]');


            -- [      
            ---- Advance Search
            ---- اضافه کردن صفحه بندی * Next * Perv
            ---- Sort 
            -- ]

            -- اگر تعداد رکورد های درون جدول خروجی بیشتر از صفحه بندی باشد 
            IF @Page * @PageFechRows <=
            (
                SELECT COUNT(*) FROM @T#SearchProducts
            )
            BEGIN
                SET @Index = @PageFechRows + 1;
                -- Next Step #. Next Page
                -- Dynamic
                SET @X =
                (
                    SELECT dbo.STR_FRMT_U(
                                             './{0};showgiftcards-{1},{2},{3}$del#',
                                             @UssdCode + ',' + @ParamText + N',' + CAST((@Page + 1) AS NVARCHAR(10))
                                             + N',' + CAST(@SortType AS NVARCHAR(2))
                                         ) AS '@data',
                           @Index AS '@order',
                           N'▶️ صفحه بعدی' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );
                SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;
            END;
            -- اضافه کردن دکمه صفحه قبل 
            IF @Page > 1
            BEGIN
                -- Next Step #. Perv Page
                -- Dynamic
                SET @X =
                (
                    SELECT dbo.STR_FRMT_U(
                                             './{0};showgiftcards-{1},{2},{3}$del#',
                                             @UssdCode + ',' + @ParamText + N',' + CAST((@Page - 1) AS NVARCHAR(10))
                                             + N',' + CAST(@SortType AS NVARCHAR(2))
                                         ) AS '@data',
                           @Index AS '@order',
                           N'◀️ صفحه قبلی' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );
                SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;
            END;
            -- اضافه کردن مرتب سازی      
            -- Static
            SET @X =
            (
                SELECT dbo.STR_FRMT_U(
                                         './{0};sortgift-{1},{2},{3}$del#',
                                         @UssdCode + ',' + @ParamText + N',' + CAST(@Page AS NVARCHAR(10)) + N','
                                         + CAST(@SortType AS NVARCHAR(2))
                                     ) AS '@data',
                       @Index AS '@order',
                       N'📚 مرتب سازی' AS "text()"
                FOR XML PATH('InlineKeyboardButton')
            );
            SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
            SET @Index += 1;

            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
        END;
        ELSE IF @MenuText IN ( 'editgfto' )
        BEGIN
            SELECT @UssdCode = '*0*6*5*3#',
                   @MenuText = N'';
            GOTO L$SaveGiftCard;
        END;
        ELSE IF @MenuText IN ( 'rcptcart', 'delrcpt' )
        BEGIN
            IF @MenuText = 'delrcpt'
            BEGIN
                DELETE dbo.Order_State
                WHERE CODE = @ParamText
                      AND CONF_STAT = '003';
                SELECT @UssdCode = '*0*3#',
                       @ChildUssdCode = '*0*3*4#';
                GOTO L$ShowRcptPay;
            END;

            -- بدست آوردن شماره درخواست رسید پرداختی
            SET @Message =
            (
                SELECT N'📥 رسید ارسال شده توسط شما' + CHAR(10) + CHAR(10) + N'📋  صورتحساب شما' + CHAR(10)
                       + N'👈  شماره فاکتور *' + CAST(os.ORDR_CODE AS NVARCHAR(30)) + N'*' + CHAR(10) + CHAR(10)
                       + CASE os.CONF_STAT
                             WHEN '001' THEN
                                 N'⛔️ '
                             WHEN '002' THEN
                                 N'✅ '
                             WHEN '003' THEN
                                 N'⌛️ '
                         END + N'وضعیت رسید [ *' + c.DOMN_DESC + N'* ]' + CHAR(10)
                       + CASE os.CONF_STAT
                             WHEN '001' THEN
                                 N'👈 [ دلیل عدم تایید ] *' + ISNULL(os.CONF_DESC, N'دلیلی ثبت نشده') + N'*' + CHAR(10)
                                 + N'📆 [ تاریخ عدم تایید ] *' + dbo.GET_MTOS_U(os.CONF_DATE) + N'*' + CHAR(10)
                             WHEN '002' THEN
                                 N'💵 [ مبلغ ] *'
                                 + REPLACE(
                                              CONVERT(
                                                         NVARCHAR,
                                                         CONVERT(
                                                                    MONEY,
                                                                    ISNULL(os.AMNT, N'مبلغ متناسب با رسید ارسال شده')
                                                                ),
                                                         1
                                                     ),
                                              '.00',
                                              ''
                                          ) + N'* [ *' + @AmntTypeDesc + N'* ] ' + CHAR(10) + N'📆 [ تاریخ تایید ] *'
                                 + dbo.GET_MTOS_U(os.CONF_DATE) + N'*' + CHAR(10) + N'📃 [ شماره پیگیری ] *'
                                 + ISNULL(os.TXID, '0') + N'*' + CHAR(10)
                             WHEN '003' THEN
                                 N' '
                         END
                FROM dbo.Order_State os,
                     dbo.[D$CONF] c
                WHERE os.CODE = @ParamText
                      AND os.CONF_STAT = c.VALU
            );

            -- اضافه کردن منوهای مربوطه
            SET @XTemp =
            (
                SELECT @Rbid AS '@rbid',
                       @ChatID AS '@chatid',
                       @UssdCode AS '@ussdcode',
                       'lessinforcpt' AS '@cmndtext',
                       @ParamText AS '@odstcode'
                FOR XML PATH('RequestInLineQuery')
            );
            EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            SET @XTemp =
            (
                SELECT '1' AS '@order',
                       --@Message AS '@caption',
                       @XTemp
                FOR XML PATH('InlineKeyboardMarkup')
            );

            SET @XMessage =
            (
                SELECT TOP 1
                       os.FILE_ID AS '@fileid',
                       os.FILE_TYPE AS '@filetype',
                       @Message AS '@caption',
                       1 AS '@order'
                FROM dbo.Order_State os
                WHERE os.CODE = @ParamText
                FOR XML PATH('Complex_InLineKeyboardMarkup')
            );
            SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

            SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
        END;
        ELSE IF @MenuText IN ( 'howshipping' )
        BEGIN
            L$HowShipping:

            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       'show_shipping' AS '@input',
                       @ParamText AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      
            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT'),
                   @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

            IF @RsltCode = '002'
               AND ISNULL(@OrdrCode, 0) > 0
            BEGIN
                -- تنظیم کردن نحوه ارسال بسته برای سفارش
                UPDATE dbo.[Order]
                SET HOW_SHIP = CASE @PostExec
                                   WHEN 'lessstorcart' THEN
                                       '001'
                                   WHEN 'lessinctcart' THEN
                                       HOW_SHIP --'002'
                                   WHEN 'lessotctcart' THEN
                                       HOW_SHIP --'003'
                                   WHEN 'lesspostcart' THEN 
                                       '004' -- Post
                                   ELSE
                                       HOW_SHIP
                               END
                WHERE CODE = @ParamText;

                IF @PostExec IN ( 'lessstorcart' )
                BEGIN
                    --SET @Message += CHAR(10) + N'👈 بسته سفارش شما در *فروشگاه تحویل داده میشود*' + 
                    --                CHAR(10) + N'🏃 لطفا جهت تحویل بسته از فروشگاه اقدام فرمایید' + CHAR(10) + CHAR(10);
                    SELECT @MenuText = N'showcart',
                           @PostExec = N'lessinfoinvc',
                           @ParamText = @OrdrCode;
                    GOTO L$CartOperations;
                END;
                ELSE IF @PostExec IN ( 'lessinctcart', 'lessotctcart', 'lesspostcart' )
                    SET @Message +=
                    (
                       SELECT CASE
                                  WHEN o.HOW_SHIP = '000' THEN
                                      N'🔔 لطفا آدرس ارسال سفارش را مشخص کنید' + CHAR(10)
                                  WHEN o.HOW_SHIP IN ( '002', '003' ) THEN
                                      N'👈 بسته سفارش شما در لیست *ارسال به مقصد شما* قرار گرفت' + CHAR(10)
                                      + N'📍 آدرس مورد نظر شما برای ارسال سفارش' + CHAR(10) + N'وضعیت : *'
                                      + CASE
                                            WHEN o.SERV_ADRS IS NULL
                                                 OR ISNULL(o.CORD_X, 0) = 0
                                                 OR ISNULL(o.CORD_Y, 0) = 0 THEN
                                                N'⭕️ آدرس ناقص می باشد'
                                            ELSE
                                                N'✅ آدرس کامل می باشد'
                                        END + N'*' + CHAR(10) + N'آدرس پستی : *' + ISNULL(o.SERV_ADRS, N'---') + N'*'
                                      + CHAR(10) + N'موقعیت مکانی : * X : ' + CAST(ISNULL(o.CORD_X, 0) AS NVARCHAR(30))
                                      + N' Y : ' + CAST(ISNULL(o.CORD_Y, 0) AS NVARCHAR(30)) + N'*' + CHAR(10)
                                      + N'🔔 لطفا منتظر دریافت *نتیجه از فروشگاه* باشید' + CHAR(10) + CHAR(10)
                              END
                       FROM dbo.[Order] o
                       WHERE o.CODE = @OrdrCode
                    );

                SELECT @Message += N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                   + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           @PostExec AS '@cmndtext',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           --@Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );

                --
                IF @PostExec IN ( 'lessshipcart', 'lesstarfcart', 'lesshistcart', 'lessfinlcart' )
                    SELECT @PostExec = 
                              CASE o.HOW_SHIP
                                  WHEN '000' THEN 'lessshipcart'
                                  WHEN '001' THEN 'lessstorcart'
                                  WHEN '002' THEN 'lessinctcart'
                                  WHEN '003' THEN 'lessotctcart'
                                  WHEN '004' THEN 'lesspostcart'                                               
                              END
                    FROM dbo.[Order] o
                    WHERE o.CODE = @OrdrCode;

                SET @XMessage =
                (
                    SELECT TOP 1
                           CASE @PostExec
                               WHEN 'lessshipcart' THEN
                               (
                                   SELECT TOP 1
                                          om.FILE_ID
                                   FROM dbo.Organ_Media om
                                   WHERE om.ROBO_RBID = r.RBID
                                         AND om.RBCN_TYPE = '001'
                                         AND om.IMAG_TYPE = '002'
                                         AND om.STAT = '002'
                               )
                               WHEN 'lessstorcart' THEN
                               (
                                   SELECT TOP 1
                                          om.FILE_ID
                                   FROM dbo.Organ_Media om
                                   WHERE om.ROBO_RBID = r.RBID
                                         AND om.RBCN_TYPE = '002'
                                         AND om.IMAG_TYPE = '002'
                                         AND om.STAT = '002'
                               )
                               WHEN 'lessinctcart' THEN
                               (
                                   SELECT TOP 1
                                          om.FILE_ID
                                   FROM dbo.Organ_Media om
                                   WHERE om.ROBO_RBID = r.RBID
                                         AND om.RBCN_TYPE = '003'
                                         AND om.IMAG_TYPE = '002'
                                         AND om.STAT = '002'
                               )
                               WHEN 'lessotctcart' THEN
                               (
                                   SELECT TOP 1
                                          om.FILE_ID
                                   FROM dbo.Organ_Media om
                                   WHERE om.ROBO_RBID = r.RBID
                                         AND om.RBCN_TYPE = '004'
                                         AND om.IMAG_TYPE = '002'
                                         AND om.STAT = '002'
                               )
                               WHEN 'lesspostcart' THEN
                               (
                                   SELECT TOP 1
                                          om.FILE_ID
                                   FROM dbo.Organ_Media om
                                   WHERE om.ROBO_RBID = r.RBID
                                         AND om.RBCN_TYPE = '004'
                                         AND om.IMAG_TYPE = '002'
                                         AND om.STAT = '002'
                               )
                           END AS '@fileid',
                           '002' AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Robot r
                    WHERE r.RBID = @Rbid
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                );
                SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
            ELSE
            BEGIN
                SET @Message = N'مدت زمان ثبت سفارش شما به پایان رسید، لطفا سفارش خود را دوباره ثبت کنید';
            END;
            
            GOTO L$EndSP;
        END;
        ELSE IF @MenuText IN ( 'slctloc4ordr' )
        BEGIN
            SELECT @OrdrCode = CASE id WHEN 1 THEN Item ELSE @OrdrCode END,
                   @Index = CASE id WHEN 2 THEN Item ELSE @Index END
              FROM dbo.SplitString(@ParamText, ',');

            UPDATE o
            SET o.CORD_X = p.CORD_X,
                o.CORD_Y = p.CORD_Y,
                o.SERV_ADRS = p.SERV_ADRS,
                o.SRBT_SRPB_RWNO = p.RWNO,
                o.HOW_SHIP = CASE @PostExec
                                 --WHEN 'lessstorcart' THEN '001'
                                 WHEN 'lessinctcart' THEN '002'
                                 WHEN 'lessotctcart' THEN '003'
                                 WHEN 'lesspostcart' THEN '004'
                                 ELSE HOW_SHIP
                             END
            FROM dbo.[Order] o,
                 dbo.Service_Robot_Public p
            WHERE o.CODE = @OrdrCode
                  AND o.CHAT_ID = p.CHAT_ID
                  AND p.SRBT_ROBO_RBID = @Rbid
                  AND p.RWNO = @Index;

            SELECT @MenuText = N'showcart',
                   @PostExec = N'lessinfoinvc',
                   @ParamText = @OrdrCode;
            GOTO L$CartOperations;

        --SET @Message = ( 
        --   SELECT N'📍 آدرس مورد نظر شما برای ارسال سفارش انتخاب و ذخیره گردید' + CHAR(10) + 
        --          N'وضعیت : *' + CASE WHEN p.SERV_ADRS IS NULL OR ISNULL(p.CORD_X, 0) = 0 OR ISNULL(p.CORD_Y, 0) = 0 THEN N'⭕️ آدرس ناقص می باشد' ELSE N'✅ آدرس کامل می باشد' END + N'*'+ CHAR(10) +
        --          N'آدرس پستی : *' + ISNULL(p.SERV_ADRS, N'---') + N'*' + CHAR(10) + 
        --          N'موقعیت مکانی : * X : ' + CAST(ISNULL(p.CORD_X, 0) AS NVARCHAR(30)) + N' Y : ' + CAST(ISNULL(p.CORD_Y, 0) AS NVARCHAR(30)) + N'*'
        --     FROM dbo.Service_Robot_Public p
        --    WHERE p.CHAT_ID = @ChatID
        --      AND p.RWNO = @Index
        --      AND p.SRBT_ROBO_RBID = @Rbid
        --);

        --SET @XTemp = (
        --   SELECT @Rbid AS '@rbid'
        --         ,@ChatID AS '@chatid'
        --         ,@UssdCode AS '@ussdcode'
        --         ,CASE @PostExec
        --               WHEN 'lessinctcart' THEN 'moreinctcart'
        --               WHEN 'lessotctcart' THEN 'moreotctcart'
        --          END  AS '@cmndtext'
        --         ,@OrdrCode AS '@ordrcode'
        --      FOR XML PATH('RequestInLineQuery')
        --)
        --EXEC dbo.CRET_ILQM_P @X = @XTemp, -- xml
        --    @XRet = @XTemp OUTPUT; -- xml

        --SET @XTemp = (
        --   SELECT '1' AS '@order',
        --          --@Message AS '@caption',
        --          @XTemp
        --      FOR XML PATH('InlineKeyboardMarkup')
        --);         

        --SET @XMessage = (
        --   SELECT TOP 1 
        --          CASE @PostExec
        --               --WHEN 'lessshipcart' THEN r.HOW_SHIP_FILE_ID
        --               --WHEN 'lessstorcart' THEN r.DELV_STOR_FILE_ID
        --               WHEN 'lessinctcart' THEN r.DELV_INCT_FILE_ID
        --               WHEN 'lessotctcart' THEN r.DELV_OTCT_FILE_ID
        --          END  AS '@fileid', 
        --          '002' AS '@filetype',
        --          @Message AS '@caption',
        --          1 AS '@order'
        --     FROM dbo.Robot r
        --    WHERE r.RBID = @Rbid
        --      FOR XML PATH('Complex_InLineKeyboardMarkup')
        --);         
        --SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
        --SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);        
        END;
        -- اعمال بن تخفیف های مربوط به مشتری برای استفاده از خرید سفارشات 
        ELSE IF @MenuText IN ( 'adddsctcart', 'replacedsctcart', 'deldsctcart' )
        BEGIN
            IF @MenuText IN ( 'replacedsctcart' )
            BEGIN
                UPDATE od
                SET od.OFF_PRCT = 0,
                    od.OFF_TYPE = NULL,
                    od.OFF_KIND = NULL
                FROM dbo.Order_Detail od,
                     dbo.Order_State os
                WHERE od.ORDR_CODE = os.ORDR_CODE
                      AND os.DISC_DCID = @ParamText
                      AND NOT EXISTS
                      (
                          SELECT *
                          FROM dbo.Robot_Product_Discount d
                          WHERE od.TARF_CODE = d.TARF_CODE
                                AND d.ACTV_TYPE = '002'
                                AND
                                (
                                    (
                                        d.OFF_TYPE = '001' /* showprodofftimer */
                                        AND d.REMN_TIME >= GETDATE()
                                    )
                                    OR d.OFF_TYPE != '001'
                                )
                      );
                DELETE dbo.Order_State
                WHERE DISC_DCID = @ParamText;
                SET @MenuText = N'adddsctcart';
            END;
            ELSE IF @MenuText IN ( 'deldsctcart' )
            BEGIN
                UPDATE od
                   SET od.OFF_PRCT = 0,
                       od.OFF_TYPE = NULL,
                       od.OFF_KIND = NULL
                  FROM dbo.Order_Detail od,
                       dbo.Order_State os
                  WHERE od.ORDR_CODE = os.ORDR_CODE
                    AND os.DISC_DCID = @ParamText
                    AND NOT EXISTS (
                        SELECT *
                          FROM dbo.Robot_Product_Discount d
                         WHERE od.TARF_CODE = d.TARF_CODE
                           AND d.ACTV_TYPE = '002'
                           AND (
                                 (
                                     d.OFF_TYPE = '001' /* showprodofftimer */
                                     AND d.REMN_TIME >= GETDATE()
                                 )
                                 OR d.OFF_TYPE != '001'
                               )
                   );
                
                -- بدست آوردن شماره درخواست سفارش
                SELECT @Said = os.ORDR_CODE
                  FROM dbo.Order_State os
                 WHERE os.DISC_DCID = @ParamText;
                   
                DELETE dbo.Order_State
                 WHERE DISC_DCID = @ParamText;
                 
                SELECT @MenuText = N'paycart',
                       @UssdCode = '*0*3*1#',
                       @OrdrCode = @Said,
                       @ParamText = @Said;
                GOTO L$CartOperations;
            END;

            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       'show' AS '@input',
                       0 AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      
            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT'),
                   @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

            IF @RsltCode = '002' AND ISNULL(@OrdrCode, 0) != 0
            BEGIN
                -- برای محاسبه تخفیفات بن کارت برای مشتریان به روش زیر انجام میشود
                SET @XTemp =
                (
                    SELECT a.DCID AS '@dcid',
                           a.CHAT_ID AS '@chatid',
                           a.SRBT_ROBO_RBID AS '@rbid',
                           @OrdrCode AS '@ordrcode'
                    FROM dbo.Service_Robot_Discount_Card a
                    WHERE DCID = @ParamText
                    FOR XML PATH('Service_Robot_Discount_Card')
                );
                EXEC dbo.SAVE_DSCT_P @X = @XTemp, @XRet = @XTemp OUTPUT;
                  
                SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                       @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           CASE @RsltCode
                               WHEN '001' THEN
                                   'lessinfodsct'
                               WHEN '002' THEN
                                   'lesseditdsct'
                           END AS '@cmndtext',
                           @OrdrCode AS '@ordrcode',
                           @ParamText AS '@discdcid'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml
                
                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
        END;
        ELSE IF @MenuText IN ( 'addgiftcart', 'delgiftcart' )
        BEGIN

            SET @PostExec = N'lessinfogift';

            IF @MenuText = 'delgiftcart'
            BEGIN
                SET @PostExec = N'lessinfocart';
            END;

            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       'show' AS '@input',
                       0 AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      
            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT'),
                   @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

            IF @RsltCode = '002'
               AND ISNULL(@OrdrCode, 0) != 0
            BEGIN
                SET @XTemp =
                (
                    SELECT @ParamText AS '@gcid',
                           @ChatID AS '@chatid',
                           @Rbid AS '@rbid',
                           @OrdrCode AS '@ordrcode',
                           CASE @MenuText
                               WHEN 'addgiftcart' THEN
                                   'add'
                               WHEN 'delgiftcart' THEN
                                   'del'
                           END AS '@oprttype'
                    FOR XML PATH('Service_Robot_Gift_Card')
                );
                EXEC dbo.SAVE_GIFT_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                       @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           @PostExec AS '@cmndtext',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
        END;
        ELSE IF @MenuText IN ( 'addamntwlet' )
        BEGIN
            L$AddAmountWallet:
            IF @ParamText LIKE '%,%' -- howinccashwlet,200000 or howinccreditwlet,200000
            BEGIN
                SELECT @ParamText = CASE id WHEN 1 THEN Item ELSE @ParamText END,
                       @Amnt = CASE id WHEN 2 THEN Item ELSE @Amnt END
                FROM dbo.SplitString(@ParamText, ',');
                
                -- 1399/08/18 * اگر نرخ تومان باشه باید اطلاح کنیم
                IF @AmntType = '002' SET @Amnt /= 10;
                
                SELECT @XTemp =
                (
                    SELECT 5 AS '@subsys',
                           CASE @ParamText
                               WHEN 'howinccashwlet' THEN
                                   '015' -- Cash Wallet
                               WHEN 'howinccreditwlet' THEN
                                   '013' -- Credit Wallet
                           END AS '@ordrtype', /* افزایش مبلغ کیف پول نقدینگی / اعتباری */
                           '000' AS '@typecode',
                           @ChatID AS '@chatid',
                           @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @Amnt AS '@input',
                           0 AS '@ordrcode'
                    FOR XML PATH('Action'), ROOT('Cart')
                );
            END;
            ELSE -- howinccashwlet or howinccreditwlet
            BEGIN
                SELECT @XTemp =
                (
                    SELECT 5 AS '@subsys',
                           CASE @ParamText
                               WHEN 'howinccashwlet' THEN
                                   '015' -- Cash Wallet
                               WHEN 'howinccreditwlet' THEN
                                   '013' -- Credit Wallet
                           END AS '@ordrtype', /* افزایش مبلغ کیف پول نقدینگی / اعتباری */
                           '000' AS '@typecode',
                           @ChatID AS '@chatid',
                           @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @ParamText AS '@input',
                           0 AS '@ordrcode'
                    FOR XML PATH('Action'), ROOT('Cart')
                );
            END;
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
            
            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT'),
                   @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

            IF @RsltCode = '002'
               AND ISNULL(@OrdrCode, 0) != 0
            BEGIN
                SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                       @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           @PostExec AS '@cmndtext',
                           @ParamText AS '@param',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
        END;
        ELSE IF @MenuText IN ( 'emptyamntwlet' )
        BEGIN
            -- بدست آوردن شماره درخواست افزایش مبلغ کیف پول
            SELECT @OrdrCode = o.CODE,
                   @OrdrType = o.ORDR_TYPE
            FROM dbo.[Order] o
            WHERE o.CODE = @ParamText;

            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       @OrdrType AS '@ordrtype', /* افزایش مبلغ کیف پول نقدینگی / اعتباری */
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       'empty' AS '@input',
                       @OrdrCode AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      

            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT'),
                   @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

            IF @RsltCode = '002'
               AND ISNULL(@OrdrCode, 0) != 0
            BEGIN
                SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                       @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

                SET @ParamText = CASE @OrdrType
                                     WHEN '015' THEN
                                         'howinccashwlet'   -- Cash Wallet
                                     WHEN '013' THEN
                                         'howinccreditwlet' -- Credit Wallet
                                 END;

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           @PostExec AS '@cmndtext',
                           @ParamText AS '@param',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
        END;
        ELSE IF @MenuText IN ( 'addcashwletcart', 'addcreditwletcart', 'delcashwletcart', 'delcreditwletcart' )
        BEGIN
            SET @PostExec = N'lessinfowlet';

            IF @MenuText = 'delwletcart'
            BEGIN
                SET @PostExec = N'lessinfocart';
            END;

            SELECT @XTemp =
            (
                SELECT 5 AS '@subsys',
                       '004' AS '@ordrtype',
                       '000' AS '@typecode',
                       @ChatID AS '@chatid',
                       @Rbid AS '@rbid',
                       @UssdCode AS '@ussdcode',
                       'show' AS '@input',
                       0 AS '@ordrcode'
                FOR XML PATH('Action'), ROOT('Cart')
            );
            EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml      
            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
            SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                   @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT'),
                   @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

            IF @RsltCode = '002'
               AND ISNULL(@OrdrCode, 0) != 0
            BEGIN
                SET @XTemp =
                (
                    SELECT @ParamText AS '@wldtcode',
                           @ChatID AS '@chatid',
                           @Rbid AS '@rbid',
                           @OrdrCode AS '@ordrcode',
                           CASE @MenuText
                               WHEN 'addcashwletcart' THEN
                                   'add'
                               WHEN 'addcreditwletcart' THEN
                                   'add'
                               WHEN 'delcashwletcart' THEN
                                   'del'
                               WHEN 'delcreditwletcart' THEN
                                   'del'
                           END AS '@oprttype',
                           CASE @MenuText
                               WHEN 'addcashwletcart' THEN
                                   '002'
                               WHEN 'addcreditwletcart' THEN
                                   '001'
                               WHEN 'delcashwletcart' THEN
                                   '002'
                               WHEN 'delcreditwletcart' THEN
                                   '001'
                           END AS '@wlettype'
                    FOR XML PATH('Wallet_Detail')
                );
                EXEC dbo.SAVE_WLET_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                       @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           @PostExec AS '@cmndtext',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
        END;
        ELSE IF @MenuText IN ( 'buyshop' )
        BEGIN
            L$ReportBuyShop:
            IF @PostExec IN ( 'lessbuyshop' )
                SET @Message
                    = N'شما می توانید سوابق خرید هایی که قبلا داشته اید یا خرید هایی که انجام دادید و حتی خریدی که در مرحله اولیه می باشد را در این قسمت دنبال کنید';
            ELSE IF @PostExec IN ( 'lesshbuyshop' )
                SET @Message
                    = N'خرید هایی که شما انجام داده اید و بسته سفارش ها به دست شما رسیده اند را اینجا می توانید مشاهده کنید';
            ELSE IF @PostExec IN ( 'allbuyshop' )
                SET @Message
                    = N'🛒 کلیه خرید هایی که شما داشته اید 📋 به شرح زیر میباشد' + CHAR(10)
                      + N'🗓️ بازه تاریخی مورد نظر شما *' + dbo.GET_MTOS_U(@FromDate) + N'* - *'
                      + dbo.GET_MTOS_U(@ToDate) + N'*';

            SET @XTemp =
            (
                SELECT @Rbid AS '@rbid',
                       @ChatID AS '@chatid',
                       @UssdCode AS '@ussdcode',
                       @PostExec AS '@cmndtext',
                       dbo.STR_FRMT_U(
                                         '{0},{1}',
                                         CONVERT(VARCHAR(10), ISNULL(@FromDate, ''), 101) + ','
                                         + CONVERT(VARCHAR(10), ISNULL(@ToDate, ''), 101)
                                     ) AS '@param'
                FOR XML PATH('RequestInLineQuery')
            );
            EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            SET @XTemp =
            (
                SELECT '1' AS '@order',
                       @Message AS '@caption',
                       @XTemp
                FOR XML PATH('InlineKeyboardMarkup')
            );
            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
        END;
        ELSE IF @MenuText IN ( 'ordrstat' )
        BEGIN
            SET @Message =
            (
                SELECT N'🎛 وضعیت سفارش' + CHAR(10)
                       +
                       (
                           SELECT dbo.STR_FRMT_U(
                                                    N'👈 {0} ) ✅ {1} {2}',
                                                    CAST(osh.RWNO AS VARCHAR(30)) + ',' + d.DOMN_DESC + ','
                                                    + dbo.GET_MTOS_U(osh.STAT_DATE)
                                                ) + CHAR(10)
                           FROM dbo.Order_Step_History osh,
                                dbo.[D$ODST] d
                           WHERE osh.ORDR_CODE = o.CODE
                                 AND osh.ORDR_STAT = d.VALU
                           ORDER BY osh.RWNO
                           FOR XML PATH('')
                       )
                FROM dbo.[Order] o
                WHERE o.CODE = @ParamText
            );

            SET @XTemp =
            (
                SELECT @Rbid AS '@rbid',
                       @ChatID AS '@chatid',
                       @UssdCode AS '@ussdcode',
                       @PostExec AS '@cmndtext',
                       @ParamText AS '@ordrcode'
                FOR XML PATH('RequestInLineQuery')
            );
            EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            SET @XTemp =
            (
                SELECT '1' AS '@order',
                       @Message AS '@caption',
                       @XTemp
                FOR XML PATH('InlineKeyboardMarkup')
            );
            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
        END;
        ELSE IF @MenuText IN ( 'writerating' )
        BEGIN
            --RAISERROR('Fuck Error', 16, 1);
            --RETURN;
            SET @RtngType = NULL;
            IF @ParamText LIKE N'%,%'
            BEGIN
                IF
                (
                    SELECT LEN(Item) FROM dbo.SplitString(@ParamText, ',') WHERE id = 2
                ) = 3
                BEGIN
                    SELECT @OrdrCode = CASE id
                                           WHEN 1 THEN
                                               Item
                                           ELSE
                                               @OrdrCode
                                       END,
                           @RtngType = CASE id
                                           WHEN 2 THEN
                                               Item
                                           ELSE
                                               @RtngType
                                       END,
                           @Message = CASE id
                                          WHEN 3 THEN
                                              Item
                                          ELSE
                                              @Message
                                      END
                    FROM dbo.SplitString(@ParamText, ',');

                    IF NOT EXISTS
                    (
                        SELECT *
                        FROM dbo.Service_Robot_Order_Rating r
                        WHERE r.ORDR_CODE = @OrdrCode
                              AND r.RATE_TYPE = @RtngType
                    )
                        INSERT INTO dbo.Service_Robot_Order_Rating
                        (
                            SRBT_SERV_FILE_NO,
                            SRBT_ROBO_RBID,
                            ORDR_CODE,
                            CODE,
                            RATE_TYPE,
                            RATE_NUMB,
                            RATE_TEXT
                        )
                        SELECT o.SRBT_SERV_FILE_NO,
                               o.SRBT_ROBO_RBID,
                               o.CODE,
                               0,
                               @RtngType,
                               CASE LEN(@Message)
                                   WHEN 1 THEN
                                       @Message
                                   ELSE
                                       NULL
                               END,
                               CASE LEN(@Message)
                                   WHEN 1 THEN
                                       NULL
                                   ELSE
                                       @Message
                               END
                        FROM dbo.[Order] o
                        WHERE o.CODE = @OrdrCode
                              AND NOT EXISTS
                        (
                            SELECT *
                            FROM dbo.Service_Robot_Order_Rating r
                            WHERE r.ORDR_CODE = o.CODE
                                  AND r.RATE_TYPE = @RtngType
                        );
                    ELSE
                    BEGIN
                        IF LEN(@Message) = 1
                            UPDATE dbo.Service_Robot_Order_Rating
                            SET RATE_NUMB = @Message
                            WHERE ORDR_CODE = @OrdrCode
                                  AND RATE_TYPE = @RtngType;
                        ELSE
                            UPDATE dbo.Service_Robot_Order_Rating
                            SET RATE_TEXT = ISNULL(@Message, RATE_TEXT)
                            WHERE ORDR_CODE = @OrdrCode
                                  AND RATE_TYPE = @RtngType;
                    END;
                    SELECT @SrorCode = r.CODE
                    FROM dbo.Service_Robot_Order_Rating r
                    WHERE r.ORDR_CODE = @OrdrCode
                          AND r.RATE_TYPE = @RtngType;
                END;
                ELSE
                BEGIN
                    SELECT @OrdrCode = CASE id
                                           WHEN 1 THEN
                                               Item
                                           ELSE
                                               @OrdrCode
                                       END,
                           @SrorCode = CASE id
                                           WHEN 2 THEN
                                               Item
                                           ELSE
                                               @SrorCode
                                       END,
                           @Message = CASE id
                                          WHEN 3 THEN
                                              Item
                                          ELSE
                                              @Message
                                      END
                    FROM dbo.SplitString(@ParamText, ',');

                    IF LEN(@Message) = 1
                        UPDATE dbo.Service_Robot_Order_Rating
                        SET RATE_NUMB = @Message
                        WHERE CODE = @SrorCode;
                    ELSE
                        UPDATE dbo.Service_Robot_Order_Rating
                        SET RATE_TEXT = ISNULL(@Message, RATE_TEXT)
                        WHERE CODE = @SrorCode;
                END;
            END;
            ELSE
                SET @OrdrCode = @ParamText;

            IF @RtngType IS NULL
                SET @Message
                    = N'🤓 مشتری گرامی' + CHAR(10)
                      + N'⭐️ با ثبت نظر خود در  مورد گزینه هایی که از شما خواسته شده، ما را در جهت بهبود فعالیت خود همرایی کنید تا بتوانیم آنگونه که شما دوست دارید عمل کنیم.'
                      + CHAR(10) + N'🙏 با تشکر از حسن توجه شما';
            ELSE IF @RtngType = '001'
                SET @Message
                    = N'🤓 مشتری گرامی' + CHAR(10)
                      + N'این قسمت مربوط به ثبت نظرات در مورد عملکرد *نرم افزار فروشگاه* می باشد که با امتیاز دهی شما در بهبود و راحتی با نرم افزار تیم ما را حمایت میکنید';
            ELSE IF @RtngType = '002'
                SET @Message
                    = N'🤓 مشتری گرامی' + CHAR(10)
                      + N'این قسمت مربوط به ثبت نظرات در مورد عملکرد *فروشگاه* می باشد که با امتیاز دهی شما در بهبود و بالا بردن سطح کیفی فروشگاه ما را حمایت میکنید';
            ELSE IF @RtngType = '003'
                SET @Message
                    = N'🤓 مشتری گرامی' + CHAR(10)
                      + N'این قسمت مربوط به ثبت نظرات در مورد عملکرد *فروشنده* می باشد که با امتیاز دهی شما در بهبود و بالا بردن سطح روابط عمومی فروشنده ما را حمایت میکنید';
            ELSE IF @RtngType = '004'
                SET @Message
                    = N'🤓 مشتری گرامی' + CHAR(10)
                      + N'این قسمت مربوط به ثبت نظرات در مورد عملکرد *محصولات فروشگاه* می باشد که با امتیاز دهی شما در سلامت و بالا بردن سطح کیفی محصولات فروشگاه ما را حمایت میکنید';
            ELSE IF @RtngType = '005'
                SET @Message
                    = N'🤓 مشتری گرامی' + CHAR(10)
                      + N'این قسمت مربوط به ثبت نظرات در مورد عملکرد *بسته بندی سفارشات* می باشد که با امتیاز دهی شما در صحت و سالم رساندن محصولات فروشگاه ما را حمایت میکنید';
            ELSE IF @RtngType = '006'
                SET @Message
                    = N'🤓 مشتری گرامی' + CHAR(10)
                      + N'این قسمت مربوط به ثبت نظرات در مورد عملکرد *مدت زمان تحویل سفارش* می باشد که با امتیاز دهی شما در انتخاب سفیران سفارش و عملکرد بهتر فروشگاه ما را حمایت میکنید';

            SET @XTemp =
            (
                SELECT @Rbid AS '@rbid',
                       @ChatID AS '@chatid',
                       @UssdCode AS '@ussdcode',
                       @PostExec AS '@cmndtext',
                       @OrdrCode AS '@ordrcode',
                       @SrorCode AS '@srorcode'
                FOR XML PATH('RequestInLineQuery')
            );
            EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                 @XRet = @XTemp OUTPUT; -- xml

            SET @XTemp =
            (
                SELECT '1' AS '@order',
                       @Message AS '@caption',
                       @XTemp
                FOR XML PATH('InlineKeyboardMarkup')
            );
            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
        END;
        ELSE IF @MenuText IN ( 'acntman::saveordr', 'acntman::ordrrcpt::show::newrcpt', 'acntman::ordrrcpt::aprov::newrcpt', 'acntman::ordrrcpt::manual::newrcpt', 'acntman::ordrrcpt::notaprov::newrcpt' )
        BEGIN
           IF @MenuText IN ( 'acntman::saveordr' )
           BEGIN
               -- پایانی کردن درخواست مربوط به حسابدار
               UPDATE dbo.[Order]
               SET ORDR_STAT = '012'
               WHERE CODE = @ParamText;

               UPDATE dbo.[Order]
               SET ORDR_STAT = '004',
                   ARCH_STAT = '002'
               WHERE CODE = @ParamText;

               SET @Message =
               (
                   SELECT N'💾 شماره درخواست *' + @ParamText + N'* درون سیستم حسابداری ذخیره شده' + CHAR(10)
                          + CASE COUNT(o.CODE)
                                WHEN 0 THEN
                                    N'تمامی درخواستها منتصب به شما درون سیستم حسابداری ثبت شده اند، درصورت ثبت سفارش جدید به شما اطلاع رسانی میکنیم. با تشکر'
                                ELSE
                                    N'📥 در لیست کار شما *'
                                    + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(o.CODE)), 1), '.00', '')
                                    + N'* درخواست سفارش جدید وجود دارد که باید درون سیستم ثبت شوند'
                            END
                   FROM dbo.[Order] o
                   WHERE o.SRBT_ROBO_RBID = @Rbid
                         AND o.CHAT_ID = @ChatID
                         AND o.ORDR_TYPE = '017'
                         AND o.ORDR_STAT = '001'
               );
           END
           ELSE IF @MenuText IN ('acntman::ordrrcpt::show::newrcpt')
           BEGIN
               SET @XTemp =
               (
                   SELECT @Rbid AS '@rbid',
                          @ChatID AS '@chatid',
                          @PostExec AS '@cmndtext',
                          @ParamText AS '@odstcode'
                   FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml
               
               -- بدست آوردن اطلاعات شماره درخواست، مبلغ درخواست، شماره تلفن مشتری
               SELECT @OrdrCode = o.CODE,
                      @Amnt = o.DEBT_DNRM, 
                      @CellPhon = o.CELL_PHON,
                      @Name = o.OWNR_NAME
                 FROM dbo.[Order] o, dbo.Order_State os
                WHERE o.code = os.ORDR_CODE
                  AND os.code = @ParamText;
               
               SET @XMessage =
               (
                  SELECT TOP 1
                         os.FILE_ID AS '@fileid',
                         os.FILE_TYPE AS '@filetype',
                         N'👈 *بررسی تاییدیه رسید پرداخت مشتری*' + CHAR(10) + CHAR(10) +
                         N'اطلاعات ارسالی به صورت *' + CASE os.FILE_TYPE WHEN '001' THEN N'شماره پیگیری : ' + CASE WHEN os.TXID IS NULL THEN N'[ --- ]' ELSE os.TXID END WHEN '002' THEN N'عکس رسید پرداخت شده' WHEN '004' THEN N'فایل رسید پرداخت شده' END + N'* میباشد، *لطفا نهایت دقت در بررسی تایید وصولی را داشته باشید* .' + CHAR(10) + CHAR(10) +
                         N'👈 شماره فاکتور : *' + CAST(@OrdrCode AS VARCHAR(15)) + N'*' + CHAR(10) +
                         N'👤 نام مشتری : *' + @Name + N'*' + CHAR(10) +
                         N'📱 شماره موبایل : *' + @CellPhon + N'*' + CHAR(10) +
                         N'💰 مبلغ فاکتور : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @Amnt), 1), '.00', '' ) + N' ' + @AmntTypeDesc + N'*' + CHAR(10) + CHAR(10) +
                         dbo.STR_FRMT_U(N'👈 *بررسی واریزی* : [IDPay.ir](https://idpay.ir/dashboard/deposits?status=All&account=All&gateway=All&web-service=All&price={0}&phone={1}&desc={2})', CAST((CASE @AmntType WHEN '001' THEN @Amnt ELSE @Amnt * 10 END) AS NVARCHAR(100)) + N',' + @CellPhon + N',' + CAST(@OrdrCode AS VARCHAR(15)) ) AS '@caption',
                         1 AS '@order'
                  FROM dbo.Order_State os
                  WHERE os.CODE = @ParamText                    
                  FOR XML PATH('Complex_InLineKeyboardMarkup')
               );
               SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
           END 
           ELSE IF @MenuText IN ('acntman::ordrrcpt::aprov::newrcpt')
           BEGIN
               -- Param : Order_State.Code
               -- First Step : Update Record with confirmed
               UPDATE dbo.Order_State 
                  SET CONF_STAT = '002'
                WHERE CODE = @ParamText;
               
               IF EXISTS (SELECT * FROM dbo.[Order] o, dbo.Order_State os WHERE o.CODE = os.ORDR_CODE AND os.CODE = @ParamText AND o.DEBT_DNRM = 0)
               BEGIN
                  SET @XTemp = (
                      SELECT os.ORDR_CODE AS '@ordrcode',
                             '002' AS '@dircall',
                             '001' AS '@autochngamnt'
                        FROM dbo.Order_State os
                       WHERE os.CODE = @ParamText 
                         FOR XML PATH('Payment')
                  );                  
                  EXEC dbo.SAVE_PYMT_P @X = @XTemp, @xRet = @XTemp OUTPUT;                 
                  
                  -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
                  SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                         @XMessage = CAST(@XTemp.query('//Message').value('.', 'NVARCHAR(MAX)') AS XML); 
                  
                  IF @RsltCode = '002'
                  BEGIN
                     -- در این قسمت باید به مشتری هم اطلاع رسانی کنیم که سفارش شما تایید شد
                     SET @XTemp = (
                         SELECT o.SRBT_ROBO_RBID AS '@rbid',
                                '*0#' AS '@ussdcode',
                                o.CHAT_ID AS 'Order/@chatid',
                                o.CODE as 'Order/@code',
                                '012' AS 'Order/@type',
                                'poke4servordrfinl' AS 'Order/@oprt',
                                CONVERT(NVARCHAR(max), @XMessage) AS 'Order/@valu'
                           FROM dbo.[Order] o, dbo.Order_State os
                          WHERE os.CODE = @ParamText
                            AND o.CODE = os.ORDR_CODE
                            FOR XML PATH('Robot')
                     );
                     EXEC dbo.SEND_MEOJ_P @X = @XTemp, @XRet = @XTemp OUTPUT;
                     
                     SET @Message = N'✅ رسید پرداخت تایید شد';
                  END 
               END 
           END
           ELSE IF @MenuText IN ('acntman::ordrrcpt::manual::newrcpt')
           BEGIN
               UPDATE dbo.Order_State
                  SET CONF_DESC = N'رسید باید به صورت دستی تایید گردد، کد کاربر ثبت کننده : ' + CAST(@ChatID AS NVARCHAR(15)) 
                WHERE CODE = @ParamText;
                
               SET @Message = N'⚠️ لطفا *رسید* را به صورت *دستی بررسی و تایید کنید* در *غیر اینصورت* با شماره مشتری *تماس* بگیرید و در مورد رسید ارسالی هماهنگ کنید';
           END
           ELSE if @MenuText IN ('acntman::ordrrcpt::notaprov::newrcpt')
           BEGIN
               UPDATE dbo.Order_State
                  SET CONF_DESC = N'رسید مورد تایید واقع نشد، کد کاربر ثبت کننده : ' + CAST(@ChatID AS NVARCHAR(15)) ,
                      CONF_STAT = '001'
                WHERE CODE = @ParamText;
               
               -- در این قسمت باید به مشتری هم اطلاع رسانی کنیم که رسید پرداخت تایید نشده
               SET @XTemp = (
                   SELECT o.SRBT_ROBO_RBID AS '@rbid',
                          '*0#' AS '@ussdcode',
                          o.CHAT_ID AS 'Order/@chatid',
                          o.CODE as 'Order/@code',
                          '012' AS 'Order/@type',
                          'poke4servnotaprovrcptordr' AS 'Order/@oprt',
                          N'*' + o.OWNR_NAME + N' عزیز *' + CHAR(10) + 
                          N'🖐️😊 *با سلام و احترام* ' + CHAR(10) + CHAR(10) + 
                          N'⚠️ متاسفانه *رسید پرداختی شما* مورد تایید واحد حسابداری قرار نگرفته لطفا جهت رفع مشکل رسید پرداختی خود با شماره فروشگاه واحد حسابداری تماس حاصل فرمایید.' + CHAR(10) + 
                          N'با تشکر از شما' + CHAR(10) +
                          N'*واحد حسابداری فروشگاه*' AS 'Order/@valu'
                     FROM dbo.[Order] o, dbo.Order_State os
                    WHERE os.CODE = @ParamText
                      AND o.CODE = os.ORDR_CODE
                      FOR XML PATH('Robot')
               );
               EXEC dbo.SEND_MEOJ_P @X = @XTemp, @XRet = @XTemp OUTPUT;
               
               SET @Message = N'⚠️ لطفا *رسید تایید نشده* را به صورت *دستی بررسی و تایید کنید* در *غیر اینصورت* با شماره مشتری *تماس* بگیرید و در مورد رسید ارسالی هماهنگ کنید';
           END 
        END;
        ELSE IF @MenuText IN ( 'storman::doordr', 'storman::colcpackordr', 'storman::exitdelvordr' ) /* اطلاعات مربوط به انباردار */
        BEGIN
            IF @MenuText = 'storman::doordr'
            BEGIN
                -- بدست آوردن شماره درخواست سفارش
                SELECT @OrdrCode = o.ORDR_CODE
                FROM dbo.[Order] o
                WHERE o.CODE = @ParamText;

                -- محافظت از ناحیه بحرانی
                SELECT 'LockTab'
                FROM dbo.[Order] o WITH (TABLOCKX)
                WHERE o.CODE = @OrdrCode;

                -- اگر درخواست توسط انباردار دیگری گرفته شده باشد کلیه درخواست های انباردارهای دیگر حذف میشود
                IF NOT EXISTS (SELECT * FROM dbo.[Order] o WHERE o.CODE = @ParamText)
                BEGIN
                    SET @Message =
                    (
                        SELECT N'⛔️ *درخواست توسط انباردار دیگری گرفته شد*' + CHAR(10) + CHAR(10) + N'💡 کد خروجی : '
                               + N'*1*' + CHAR(10) + N'👈 لطفا منتظر درخواست *بعدی* باشید' + CHAR(10)
                               + N'🙏 با تشکر از شما'
                        FOR XML PATH('Message'), ROOT('Result')
                    );

                    -- پایان کار
                    GOTO L$EndSP;
                END;

                -- اگر سفیری درخواست اعلام آمادگی کرده که بسته را جابه جا کند
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.[Order] o
                    WHERE o.ORDR_CODE = @OrdrCode
                          AND o.ORDR_TYPE = '018'
                          AND o.CHAT_ID != @ChatID
                          AND o.ORDR_STAT = '013' /* انباردار اعلام آمادگی برای انجام سفارش کرده */
                )
                BEGIN
                    SET @Message =
                    (
                        SELECT N'⛔️ *درخواست توسط انبار دیگری گرفته شد*' + CHAR(10) + CHAR(10) + N'💡 کد خروجی : '
                               + N'*2*' + CHAR(10) + N'👈 لطفا منتظر درخواست *بعدی* باشید' + CHAR(10)
                               + N'🙏 با تشکر از شما'
                        FOR XML PATH('Message'), ROOT('Result')
                    );

                    -- پایان کار
                    GOTO L$EndSP;
                END;

                -- اگر انباردار درخواست را دوباره ارسال کرده باشد
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.[Order] o
                    WHERE o.CODE = @ParamText
                          AND o.ORDR_STAT = '013'
                )
                BEGIN
                    SET @Message =
                    (
                        SELECT N'⛔️ *درخواست توسط شما ثبت شده*' + CHAR(10) + CHAR(10) + N'💡 کد خروجی : ' + N'*4*'
                               + CHAR(10) + N'👈 لطفا *اقلام سفارش* را از انبار آماده کنید' + CHAR(10)
                               + N'🙏 با تشکر از شما'
                        FOR XML PATH('Message'), ROOT('Result')
                    );

                    -- پایان کار
                    GOTO L$EndSP;
                END;

                -- در این قسمت درخواست بدون هیچ مشکلی می تواند توسط انباردار گرفته شود
                -- تغییر وضعیت درخواست برای انباردار به حالت {جمع آوری و بسته بندی اقلام سفارش}
                UPDATE dbo.[Order]
                SET ORDR_STAT = '013'
                WHERE CODE = @ParamText
                      AND ORDR_STAT = '002';

                -- حذف مابقی درخواست های ثبت شده برای انبارداران
                DELETE FROM dbo.[Order]
                WHERE ORDR_CODE = @OrdrCode
                      AND ORDR_TYPE = '018'
                      AND CODE != @ParamText;

                SET @Message =
                (
                    SELECT N'✅️ *درخواست توسط شما ثبت شده*' + CHAR(10) + CHAR(10)
                           + N'👈 لطفا *اقلام سفارش* را از انبار آماده کنید' + CHAR(10) + N'🙏 با تشکر از شما'
                );

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @PostExec AS '@cmndtext',
                           @ParamText AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
            ELSE IF @MenuText = 'storman::colcpackordr'
            BEGIN
                -- بدست آوردن شماره درخواست سفارش
                SELECT @OrdrCode = o.ORDR_CODE
                FROM dbo.[Order] o
                WHERE o.CODE = @ParamText;

                -- جمع آوری و بسته بندی اقلام سفارش
                UPDATE dbo.[Order]
                SET ORDR_STAT = '014'
                WHERE CODE = @ParamText;

                SET @Message =
                (
                    SELECT N'👌😊 بسیار عالی' + CHAR(10)
                           + CASE o.HOW_SHIP
                                 WHEN '001' THEN
                                     N'لطفا بسته را در جای مناسبی قرار دهید و روی آن بنویسید که بسته مطلق به *'
                                     + o.OWNR_NAME
                                     + N'* می باشد که در زمانی که مشتری به فروشگاه مراجعه میکند سریعا بسته را به مشتری تحویل دهید'
                                     + CHAR(10)
                                     + N'😎 یادتان باشد که *زمان سرمایه گران بهایست* که مشتریان ما از میخواهند، کار آنها را سریع انجام دهیم'
                                 WHEN '002' THEN
                                     N'لطفا بسته را در جایی قرار دهید که سفیر بسته را از شما تحویل بگیرد و برای *'
                                     + o.OWNR_NAME + N'* ببرد'
                                 WHEN '003' THEN
                                     N'لطفا بسته را در جایی قراردهید که باربری بسته را از شما تحویل بگیرد و برای *'
                                     + o.OWNR_NAME + N'* ببرد'
                             END
                    FROM dbo.[Order] o
                    WHERE o.CODE = @OrdrCode
                );

                -- اطلاع رسانی به مشتری جهت آماده شدن بسته سفارش
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.[Order]
                    WHERE CODE = @OrdrCode
                          AND HOW_SHIP = '001' /* اگر مشتری بسته سفارش خود را درب فروشگاه تحویل میگیرد */
                )
                BEGIN
                    SET @XTemp =
                    (
                        SELECT @Rbid AS '@rbid',
                               @ChatID AS '@chatid',
                               'lesshistcart' AS '@cmndtext',
                               @OrdrCode AS '@ordrcode'
                        FOR XML PATH('RequestInLineQuery')
                    );
                    EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                         @XRet = @XTemp OUTPUT; -- xml

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                    );

                    UPDATE dbo.Personal_Robot_Job_Order
                    SET ORDR_STAT = '001'
                    WHERE ORDR_CODE =
                    (
                        SELECT o.CODE
                        FROM dbo.[Order] o
                        WHERE o.ORDR_CODE = @OrdrCode
                              AND o.CHAT_ID =
                              (
                                  SELECT ot.CHAT_ID FROM dbo.[Order] ot WHERE ot.CODE = @OrdrCode
                              )
                              AND o.ORDR_TYPE = '012'
                    );

                    -- ارسال پیام به مشتری
                    INSERT INTO dbo.Order_Detail
                    (
                        ORDR_CODE,
                        ELMN_TYPE,
                        ORDR_CMNT,
                        ORDR_DESC,
                        INLN_KEYB_DNRM
                    )
                    SELECT o.CODE,
                           '001',
                           N'تحویل بسته سفارش بابت فروش آنلاین',
                           N'مشتری عزیز *سفارش* شما 🛒 *آماده تحویل* می باشد، جهت دریافت 🏃 سفارش به *محل 🏢 فروشگاه* مراجعه نموده و دکمه *👈📦 درخواست سفارش* را انتخاب کنید',
                           @XTemp
                    FROM dbo.[Order] o
                    WHERE o.ORDR_CODE = @OrdrCode
                          AND o.CHAT_ID =
                          (
                              SELECT ot.CHAT_ID FROM dbo.[Order] ot WHERE ot.CODE = @OrdrCode
                          )
                          AND o.ORDR_TYPE = '012';
                END;

            END;
            ELSE IF @MenuText = 'storman::exitdelvordr'
            BEGIN
                -- بدست آوردن شماره درخواست سفارش
                SELECT @OrdrCode = o.ORDR_CODE
                FROM dbo.[Order] o
                WHERE o.CODE = @ParamText;

                -- جمع آوری و بسته بندی اقلام سفارش توسط انباردار
                UPDATE o1
                SET o1.ORDR_STAT = '015'
                FROM dbo.[Order] o1
                WHERE o1.CODE = @ParamText;

                SET @Message =
                (
                    SELECT N'👌😊 بسیار عالی' + CHAR(10)
                           + N'عملیات فرآیند تحویل سفارش به پایان رسید، با تشکر از شما انباردار عزیز'
                    FROM dbo.[Order] o
                    WHERE o.CODE = @OrdrCode
                );

                -- اگر که سیستم تحویل کالا توسط مشتری درب فروشگاه انجام شود
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.[Order] o
                    WHERE o.CODE = @OrdrCode
                          AND o.HOW_SHIP = '001' /* تحویل در فروشگاه */
                )
                BEGIN
                    -- فقط کافیست که پیامی به مشتری داده شود که محصول را تحویل گرفته است
                    -- فراخوانی تابع دریافت منو برای حالتی که مشتری درب فروشگاه میباشد
                    SET @XTemp =
                    (
                        SELECT @Rbid AS '@rbid',
                               @ChatID AS '@chatid',
                               'custgetordr' AS '@cmndtext',
                               @OrdrCode AS '@ordrcode'
                        FOR XML PATH('RequestInLineQuery')
                    );
                    EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                         @XRet = @XTemp OUTPUT; -- xml

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                    );

                    -- مشتری بسته را دریافت کرده و سفارش خروج خورده
                    UPDATE dbo.[Order]
                    SET ORDR_STAT = '009'
                    WHERE CODE = @OrdrCode;

                    UPDATE dbo.Personal_Robot_Job_Order
                    SET ORDR_STAT = '001'
                    WHERE ORDR_CODE =
                    (
                        SELECT o.CODE
                        FROM dbo.[Order] o
                        WHERE o.ORDR_CODE = @OrdrCode
                              AND o.CHAT_ID =
                              (
                                  SELECT ot.CHAT_ID FROM dbo.[Order] ot WHERE ot.CODE = @OrdrCode
                              )
                              AND o.ORDR_TYPE = '012'
                    );

                    -- ارسال پیام به مشتری
                    INSERT INTO dbo.Order_Detail
                    (
                        ORDR_CODE,
                        ELMN_TYPE,
                        ORDR_CMNT,
                        ORDR_DESC,
                        INLN_KEYB_DNRM
                    )
                    SELECT o.CODE,
                           '001',
                           N'تحویل بسته سفارش بابت فروش آنلاین',
                           N'مشتری عزیز جهت اتمام فرآیند خرید خود دکمه *تحویل سفارش* را انتخاب کنید',
                           @XTemp
                    FROM dbo.[Order] o
                    WHERE o.ORDR_CODE = @OrdrCode
                          AND o.CHAT_ID =
                          (
                              SELECT ot.CHAT_ID FROM dbo.[Order] ot WHERE ot.CODE = @OrdrCode
                          )
                          AND o.ORDR_TYPE = '012';
                END;
                ELSE
                BEGIN
                    -- بدست آوردن شماره درخواست سفارش
                    SELECT @OrdrCode = o.ORDR_CODE
                    FROM dbo.[Order] o
                    WHERE o.CODE = @ParamText;

                    -- Get ChatId Alopeyk
                    SELECT @ChatID = o.CHAT_ID
                    FROM dbo.[Order] o
                    WHERE o.ORDR_CODE = @OrdrCode
                          AND o.ORDR_TYPE = '019';

                    SET @XTemp =
                    (
                        SELECT @Token AS '@token',
                               '000' AS '@actncode',
                               dbo.STR_FRMT_U('*%#{0}', o.ORDR_NUMB) AS '@cmnd',
                               @ChatID AS 'Alopeyk/@chatid'
                        FROM dbo.[Order] o
                        WHERE o.CODE = @OrdrCode
                        FOR XML PATH('RequestAlopeyk')
                    );
                    EXEC dbo.SAVE_ALPK_P @X = @XTemp, @xRet = @XTemp OUTPUT;

                    -- بدست آوردن شماره درخواست سفیر و شماره کد چت
                    SELECT @OrdrCode = o.CODE
                    FROM dbo.[Order] o
                    WHERE o.ORDR_CODE = @OrdrCode
                          AND o.ORDR_TYPE = '019';

                    SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                           @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

                    IF @RsltCode = '002'
                    BEGIN
                        -- فقط کافیست که پیامی به سفیر داده شود که محصول را تحویل گرفته است
                        -- فراخوانی تابع دریافت منو برای حالتی که سفیر درب فروشگاه تحویل بسته سفارش را انجام میدهد
                        SET @XTemp =
                        (
                            SELECT @Rbid AS '@rbid',
                                   @ChatID AS '@chatid',
                                   'notinewordrtocori' AS '@cmndtext',
                                   @OrdrCode AS '@ordrcode'
                            FOR XML PATH('RequestInLineQuery')
                        );
                        EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                             @XRet = @XTemp OUTPUT; -- xml

                        SET @XTemp =
                        (
                            SELECT '1' AS '@order',
                                   --@Message AS '@caption',
                                   @XTemp
                            FOR XML PATH('InlineKeyboardMarkup')
                        );

                        -- دوباره فعال کردن درخواست ارسال پیام برای سفیر
                        UPDATE dbo.Personal_Robot_Job_Order
                        SET ORDR_STAT = '001'
                        WHERE ORDR_CODE = @OrdrCode;
                        -- ارسال پیام به انباردار
                        INSERT INTO dbo.Order_Detail
                        (
                            ORDR_CODE,
                            ELMN_TYPE,
                            ORDR_CMNT,
                            ORDR_DESC,
                            INLN_KEYB_DNRM
                        )
                        VALUES
                        (@OrdrCode, '001', N'دریافت سفارش بابت فروش آنلاین', @Message, @XTemp);

                        SET @Message = N'📦 بسته برای مشتری ارسال شد';
                    END;
                END;
            END;
        END;
        ELSE IF @MenuText IN ( 'coriman::takeordr', 'coriman::getordr', 'coriman::ordrdelvfee',
                               'coriman::ordrdelvamntfee', 'coriman::delvpackordr', 'coriman::infosorctrgtloc'
                             )
        BEGIN
            IF @MenuText = 'coriman::takeordr'
            BEGIN
                IF NOT EXISTS (SELECT * FROM dbo.[Order] o WHERE o.CODE = @ParamText)
                BEGIN
                    SET @Message
                        = N'⛔️ *سفارش توسط سفیر دیگری گرفته شد*' + CHAR(10) + CHAR(10) + N'💡 کد خروجی : ' + N'*1*'
                          + CHAR(10) + N'👈 لطفا منتظر سفارش *بعدی* باشید' + CHAR(10) + N'🙏 با تشکر از شما' + CHAR(10)
                          + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));

                    GOTO L$EndSP;
                END;
                -- بدست آوردن شماره سفارش اصلی
                SELECT @OrdrCode = o.ORDR_CODE
                FROM dbo.[Order] o
                WHERE o.CODE = @ParamText;

                SET @XTemp =
                (
                    SELECT @Token AS '@token',
                           '000' AS '@actncode',
                           dbo.STR_FRMT_U('*%*{0}', o.ORDR_NUMB) AS '@cmnd',
                           @ChatID AS 'Alopeyk/@chatid'
                    FROM dbo.[Order] o
                    WHERE o.CODE = @OrdrCode
                    FOR XML PATH('RequestAlopeyk')
                );
                EXEC dbo.SAVE_ALPK_P @X = @XTemp, @xRet = @XTemp OUTPUT;

                SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                       @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

                IF @RsltCode = '002'
                BEGIN
                    SET @XTemp =
                    (
                        SELECT @Rbid AS '@rbid',
                               @ChatID AS '@chatid',
                               @PostExec AS '@cmndtext',
                               @ParamText AS '@ordrcode'
                        FOR XML PATH('RequestInLineQuery')
                    );
                    EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                         @XRet = @XTemp OUTPUT; -- xml

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order',
                               @Message AS '@caption',
                               @XTemp
                        FOR XML PATH('InlineKeyboardMarkup')
                    );
                    SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                END;
            END;
            ELSE IF @MenuText = 'coriman::getordr'
            BEGIN
                -- بدست آوردن شماره سفارش مشتری 
                SELECT @OrdrCode = o.ORDR_CODE
                FROM dbo.[Order] o
                WHERE o.CODE = @ParamText;

                -- بررسی اینکه آیا درخواست سفارش آماده خروج و تحویل به سفیر می باشد یا خیر
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.[Order] o
                    WHERE o.ORDR_CODE = @OrdrCode
                          AND o.ORDR_TYPE = '018' /* شغل انبارداری */
                          AND o.ORDR_STAT = '014' /* جمع آوری و بسته بندی سفارش */
                )
                BEGIN
                    -- شماره درخواست مربوط به انباردار را پیدا کرده و منوی آن را برای انباردار ارسال میکنیم
                    SELECT @OrdrCode = o.CODE
                    FROM dbo.[Order] o
                    WHERE o.ORDR_CODE = @OrdrCode /* شماره درخواست سفارش */
                          AND o.ORDR_TYPE = '018';

                    SET @XTemp =
                    (
                        SELECT @Rbid AS '@rbid',
                               @ChatID AS '@chatid',
                               'notinewordrtostor' AS '@cmndtext',
                               @ParamText AS '@param',
                               @OrdrCode AS '@ordrcode'
                        FOR XML PATH('RequestInLineQuery')
                    );
                    EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                         @XRet = @XTemp OUTPUT; -- xml

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                    );

                    -- دوباره فعال کردن درخواست ارسال پیام برای انباردار
                    UPDATE dbo.Personal_Robot_Job_Order
                    SET ORDR_STAT = '001'
                    WHERE ORDR_CODE = @OrdrCode;
                    -- ارسال پیام به انباردار
                    INSERT INTO dbo.Order_Detail
                    (
                        ORDR_CODE,
                        ELMN_TYPE,
                        ORDR_CMNT,
                        ORDR_DESC,
                        INLN_KEYB_DNRM
                    )
                    VALUES
                    (@OrdrCode, '001', N'ثبت حواله بابت فروش آنلاین',
                     N'انباردار عزیز مشتری برای دریافت بسته سفارش در محل فروشگاه منتظر تحویل سفارش می باشد', @XTemp);

                    SET @Message
                        = N'😊 با تشکر از شما سفیر عزیز، بسته شما آماده تحویل می باشد، از همراهی شما بسیار متشکریم';
                END;
                ELSE
                    SET @Message
                        = N'🙆 با عرض معذرت به دلیل ازدحام سفارشات هنوز سفارش شما از انبار جمع آوری و بسته بندی نشده است، 🙏 لطفا شکیبا باشید';
            END;
            ELSE IF @MenuText = 'coriman::ordrdelvfee'
            BEGIN
                L$CorimanOrdrDelvFee:
                IF @ParamText LIKE '%,%' AND ( SELECT COUNT(id) FROM dbo.SplitString(@ParamText, ',') ) = 3
                BEGIN 
                    GOTO L$CorimanOrdrDelvAmntFee;                    
                END 
                PRINT @ParamText

                SELECT @OrdrCode = CASE id
                                       WHEN 1 THEN Item
                                       ELSE @OrdrCode
                                   END
                FROM dbo.SplitString(@ParamText, ',');

                -- اگر هزینه حق الزحمه پیک مشخص نشده باشد
                IF NOT EXISTS
                (
                    SELECT *
                      FROM dbo.[Order] o
                     WHERE o.ORDR_CODE = @OrdrCode
                       AND o.ORDR_TYPE = '023'
                )
                    SET @Message
                        = N'🙂 پیک عزیز لطفا مبلغ حق الزحمه خود را در این قسمت مشخص کنید' + CHAR(10)
                          + N'اگر مبلغ وارد شده اشتباه بود دکمه *ارسال رایگان* را وارد کنید و دوباره مبلغ خود را تصحیح کنید';
                ELSE
                BEGIN
                    -- بررسی اینکه ایا برای درخواست پیک موتوری درخواست حق الزحمه ثبت شده یا خیر
                    SELECT @Said = o.CODE
                    FROM dbo.[Order] o
                    WHERE o.ORDR_CODE = @OrdrCode
                          AND o.ORDR_TYPE = '023'; -- درخواست حق الزحمه هزینه

                    -- آماده سازی اطلاعات مربوط به خروجی به پیک
                    SET @Message =
                    (
                        SELECT CASE ISNULL(o.DEBT_DNRM, 0)
                                   WHEN 0 THEN
                                       N'⚠️ هزینه پیک را *رایگان* کرده اید و مشتری نیازی به پرداخت به شما ندارد'
                                   ELSE
                                       N'💎 هزینه پیک' + CHAR(10) + N'💰 مبلغ *'
                                       + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.DEBT_DNRM), 1), '.00', '') + N'* '
                                       + @AmntTypeDesc + CHAR(10) + N'💡 معادل *'
                                       + CASE @AmntType
                                             WHEN '001' THEN
                                                 dbo.GET_NTOS_U(o.DEBT_DNRM / 10)
                                             WHEN '002' THEN
                                                 dbo.GET_NTOS_U(o.DEBT_DNRM)
                                         END + N'* تومان ' + CHAR(10)
                                       + N'🔔 مشتری موظف به پرداخت هزینه انتخابی از جانب شما می باشد' + CHAR(10)
                                       + CHAR(10)
                                       + N'👈 سفیر عزیز لطفا در 🤔 نظر داشته باشید که اگر *هزینه بیش از حد انتظار* از مشتری گرفته شود و مشتری بعد از پرداخت به شما، بابت گران بودن هزینه ارسال پیک، *امتیاز منفی* ثبت کند سامانه هوشمند فروشگاهی شما را در انتهای لیست سفیران *خاکستری* قرار میدهد و بسته های کمتری به شما داده میشود'
                               END
                        FROM dbo.[Order] o
                        WHERE o.CODE = @Said
                    );
                END;


                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           'notinewordrtocori' AS '@cmndtext',
                           @ParamText AS '@param',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;
            ELSE IF @MenuText = 'coriman::ordrdelvamntfee'
            BEGIN                
                L$CorimanOrdrDelvAmntFee:
                IF NOT EXISTS
                (
                    SELECT *
                    FROM dbo.SplitString(@ParamText, ',')
                    WHERE id = 3
                          AND ISNUMERIC(Item) = 1
                )
                BEGIN
                    SET @Message = N'لطفا مبلغ را درست وارد کنید';
                    GOTO L$EndSP;
                END;

                SELECT @OrdrCode = CASE id
                                       WHEN 1 THEN
                                           Item
                                       ELSE
                                           @OrdrCode
                                   END,
                       @Amnt = CASE id
                                   WHEN 3 THEN
                                       Item
                                   ELSE
                                       @Amnt
                               END
                FROM dbo.SplitString(@ParamText, ',');

                SET @ParamText =
                (
                    SELECT Item + ','
                    FROM dbo.SplitString(@ParamText, ',')
                    WHERE id IN ( 1, 2 )
                    FOR XML PATH('')
                );
                SET @ParamText = LEFT(@ParamText, LEN(@ParamText) - 1);
                
                -- بررسی اینکه ایا برای درخواست پیک موتوری درخواست حق الزحمه ثبت شده یا خیر
                SELECT @Said = o.CODE
                  FROM dbo.[Order] o
                 WHERE o.ORDR_CODE = @OrdrCode
                   AND o.ORDR_TYPE = '023'; -- درخواست حق الزحمه هزینه
                
                -- 1399/08/18 * اگر سیستم بر اساس تومان باشد مبلغ باید اصلاح گردد
                IF @AmntType = '002' SET @Amnt /= 10;

                IF ISNULL(@Said, 0) != 0
                BEGIN
                    UPDATE dbo.Order_Detail
                    SET EXPN_PRIC = CASE ISNULL(@Amnt, 0)
                                         WHEN 0 THEN 0
                                         ELSE ISNULL(EXPN_PRIC, 0) + @Amnt
                                    END
                    WHERE ORDR_CODE = @Said;
                END;                
                ELSE
                BEGIN
                    -- ثبت درخواست برای پرداخت حق الزمه 
                    INSERT INTO dbo.[Order]
                    (
                        SRBT_SERV_FILE_NO,
                        SRBT_ROBO_RBID,
                        CHAT_ID,
                        SUB_SYS,
                        ORDR_CODE,
                        CODE,
                        ORDR_TYPE,
                        STRT_DATE,
                        ORDR_STAT,
                        ARCH_STAT
                    )
                    SELECT o.SRBT_SERV_FILE_NO,
                           o.SRBT_ROBO_RBID,
                           o.CHAT_ID,
                           o.SUB_SYS,
                           @OrdrCode,
                           0,
                           '023',
                           GETDATE(),
                           '001',
                           '001'
                    FROM dbo.[Order] o
                    WHERE o.CODE IN
                          (
                              SELECT op.ORDR_CODE FROM dbo.[Order] op WHERE op.CODE = @OrdrCode
                          );

                    -- مشخص کردن درخواست مربوط به پرداخت حق الزحمه پیک
                    SELECT @Said = o.CODE
                    FROM dbo.[Order] o
                    WHERE o.ORDR_TYPE = '023'
                          AND o.ORDR_CODE = @OrdrCode;

                    SET @XTemp =
                    (
                        SELECT @Rbid AS '@rbid',
                               @ChatID AS '@chatid',
                               'custgetordr' AS '@cmndtext',
                               @Said AS '@ordrcode'
                        FOR XML PATH('RequestInLineQuery')
                    );
                    EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                         @XRet = @XTemp OUTPUT; -- xml

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                    );

                    INSERT INTO dbo.Order_Detail
                    (
                        ORDR_CODE,
                        ELMN_TYPE,
                        ORDR_DESC,
                        EXPN_PRIC,
                        NUMB,
                        IMAG_PATH,
                        INLN_KEYB_DNRM
                    )
                    SELECT o.CODE,
                           '002',
                           N'پرداخت حق الزحمه ارسال بسته',
                           @Amnt,
                           1,
                           om.FILE_ID,
                           @XTemp
                    FROM dbo.[Order] o,
                         dbo.Robot r,
                         dbo.Organ_Media om
                    WHERE o.ORDR_CODE = @OrdrCode
                          AND o.ORDR_TYPE = '023'
                          AND o.SRBT_ROBO_RBID = r.RBID
                          AND om.ROBO_RBID = r.RBID
                          AND om.RBCN_TYPE = '001'
                          AND om.IMAG_TYPE = '002'
                          AND om.STAT = '002';
                END;

                -- بروزرسانی اطلاعات درخواست پرداخت هزینه حق الزحمه
                UPDATE o
                SET o.EXPN_AMNT =
                    (
                        SELECT SUM(od.EXPN_PRIC * od.NUMB)
                        FROM dbo.Order_Detail od
                        WHERE od.ORDR_CODE = o.CODE
                    ),
                    o.EXTR_PRCT =
                    (
                        SELECT SUM(od.EXTR_PRCT * od.NUMB)
                        FROM dbo.Order_Detail od
                        WHERE od.ORDR_CODE = o.CODE
                    ),
                    o.AMNT_TYPE = @AmntType
                FROM dbo.[Order] o
                WHERE o.CODE = @Said;

                -- بروزرسانی توضیحات         
                SET @Message =
                (
                    SELECT CASE ISNULL(o.DEBT_DNRM, 0)
                               WHEN 0 THEN
                                   N'هزینه پیک شما رایگان بوده و نیازی به پرداخت هزینه نیست'
                               ELSE
                                   N'هزینه پیک' + CHAR(10) + N'مبلغ *'
                                   + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.DEBT_DNRM), 1), '.00', '') + N'*'
                                   + CHAR(10) + N'لطفا جهت پرداخت یکی از موارد *نحوه پرداخت* را انتخاب کنید'
                           END
                    FROM dbo.[Order] o
                    WHERE o.CODE = @Said
                );
                UPDATE dbo.Order_Detail
                   SET ORDR_CMNT = @Message
                 WHERE ORDR_CODE = @Said;

                -- آماده سازی اطلاعات مربوط به خروجی به پیک
                SET @Message =
                (
                    SELECT CASE ISNULL(o.DEBT_DNRM, 0)
                               WHEN 0 THEN
                                   N'⚠️ هزینه پیک را *رایگان* کرده اید و مشتری نیازی به پرداخت به شما ندارد'
                               ELSE
                                   N'💎 هزینه پیک' + CHAR(10) + N'💰 مبلغ *'
                                   + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.DEBT_DNRM), 1), '.00', '') + N'* '
                                   + @AmntTypeDesc + CHAR(10) + N'💡 معادل *'
                                   + CASE @AmntType
                                         WHEN '001' THEN
                                             dbo.GET_NTOS_U(o.DEBT_DNRM / 10)
                                         WHEN '002' THEN
                                             dbo.GET_NTOS_U(o.DEBT_DNRM)
                                     END + N'* تومان ' + CHAR(10)
                                   + N'🔔 مشتری موظف به پرداخت هزینه انتخابی از جانب شما می باشد' + CHAR(10) + CHAR(10)
                                   + N'👈 سفیر عزیز لطفا در 🤔 نظر داشته باشید که اگر *هزینه بیش از حد انتظار* از مشتری گرفته شود و مشتری بعد از پرداخت به شما، بابت گران بودن هزینه ارسال پیک، *امتیاز منفی* ثبت کند سامانه هوشمند فروشگاهی شما را در انتهای لیست سفیران *خاکستری* قرار میدهد و بسته های کمتری به شما داده میشود'
                           END
                    FROM dbo.[Order] o
                    WHERE o.CODE = @Said
                );
                -- 1399/06/27 * اگر ارسال رایگان باشد                
                IF @Amnt = 0
                BEGIN 
                  SET @ParamText = @OrdrCode;
                  GOTO L$CorimanOrdrDelvFee;
                END 
                
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           'notinewordrtocori' AS '@cmndtext',
                           @ParamText AS '@param',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp, -- xml
                                     @XRet = @XTemp OUTPUT; -- xml         
                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                GOTO L$EndSP;
            END;
            ELSE IF @MenuText = 'coriman::delvpackordr'
            BEGIN
                -- شماره درخواست پیک موتوری
                SET @OrdrCode = @ParamText;

                -- تغییر وضعیت درخواست پیک موتوری به حالت تحویل سفارش
                UPDATE dbo.[Order]
                SET ORDR_STAT = '009' -- مشتری تاییدیه تحویل بسته را اعلام کرده است
                WHERE CODE = @OrdrCode;

                -- اگر هزینه رایگان نباشد
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.[Order] o
                    WHERE o.ORDR_CODE = @OrdrCode
                      AND o.ORDR_TYPE = '023'
                      AND o.DEBT_DNRM >= 0
                )
                BEGIN
                    -- مشخص کردن درخواست مربوط به پرداخت حق الزحمه پیک
                    SELECT @Said = o.CODE
                      FROM dbo.[Order] o
                     WHERE o.ORDR_TYPE = '023'
                       AND o.ORDR_CODE = @OrdrCode;

                    -- ارسال پیام به مشتری جهت پرداخت هزینه پیک
                    SET @Message =
                    (
                        SELECT N'مشتری عزیز، *' + o.OWNR_NAME + N'*' + CHAR(10)
                               + CASE ISNULL(o.DEBT_DNRM, 0)
                                     WHEN 0 THEN
                                         N'⚠️ هزینه پیک را *رایگان* میباشد و شما نیازی به پرداخت هزینه ندارید'
                                     ELSE
                                         N'💎 هزینه پیک' + CHAR(10) + N'💰 مبلغ *'
                                         + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, o.DEBT_DNRM), 1), '.00', '')
                                         + N'* ' + @AmntTypeDesc + CHAR(10) + N'💡 معادل *'
                                         + CASE @AmntType
                                               WHEN '001' THEN
                                                   dbo.GET_NTOS_U(o.DEBT_DNRM / 10)
                                               WHEN '002' THEN
                                                   dbo.GET_NTOS_U(o.DEBT_DNRM)
                                           END + N'* تومان ' + CHAR(10)
                                         + N'👈 مشتری عزیز، لطفا دقت فرمایید که هزینه پیک کاملا به عهده خود سفیر می باشد و نرخ توسط ایشان محاسبه میشود و ربطی به فروشگاه ندارد، لطفا در صورتی که سفیر مبلغی بالاتر از قیمت عرف دیگر سفیران از شما درخواست کرد موارد را در قسمت در پایان همین سفارش می توانید وارد کنید با تشکر از شما'
                                 END
                        FROM dbo.[Order] o
                        WHERE o.CODE = @Said
                    );

                    SET @XTemp =
                    (
                        SELECT @Rbid AS '@rbid',
                               @ChatID AS '@chatid',
                               'custgetordr' AS '@cmndtext',
                               @Said AS '@ordrcode'
                        FOR XML PATH('RequestInLineQuery')
                    );
                    EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                         @XRet = @XTemp OUTPUT; -- xml

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                    );
                    
                    -- بدست آوردن شماره درخواست سفارش
                    SELECT @Said = ot.CODE, @TChatId = ot.CHAT_ID
                      FROM dbo.[Order] ot
                     WHERE ot.CODE IN (
                       SELECT o.ORDR_CODE -- شماره درخواست سفارش
                         FROM dbo.[Order] o
                        WHERE o.CODE = @OrdrCode -- شماره درخواست پیک موتوری
                     );
                     
                    -- پیدا کردن شماره درخواست اعلام به مشتری
                    SELECT @OrdrCode = ot.CODE
                      FROM dbo.[Order] ot
                     WHERE EXISTS (
                              SELECT os.ORDR_CODE /* درخواست سفارش */
                              FROM dbo.[Order] os
                              WHERE os.CODE = @OrdrCode /* شماره درخواست پیک */
                                AND os.ORDR_CODE = ot.ORDR_CODE
                                --AND os.CHAT_ID = ot.CHAT_ID /* اطلاع رسانی به خودش مشتری بابت پرداخت هزینه پیک */
                           )
                       AND ot.CHAT_ID = @TChatId -- بدست آوردن شماره درخواست اطلاع رسانی به مشتری
                       AND ot.ORDR_TYPE = '012';

                    -- فعال کردن سامانه اطلاع رسانی مشتری
                    UPDATE dbo.Personal_Robot_Job_Order
                    SET ORDR_STAT = '001'
                    WHERE ORDR_CODE = @OrdrCode;
                    -- ارسال پیام به مشتری
                    INSERT INTO dbo.Order_Detail
                    (
                        ORDR_CODE,
                        ELMN_TYPE,
                        ORDR_CMNT,
                        ORDR_DESC,
                        INLN_KEYB_DNRM
                    )
                    VALUES
                    (@OrdrCode, '001', N'تحویل سفارش بابت فروش آنلاین', @Message, @XTemp);

                    SET @Message
                        = N'😊 سفیر عزیز، از شما کمال تشکر و قدردانی را داریم که بسته سفارش را به مشتری تحویل دادید';
                END
                
            END;
            ELSE IF @MenuText = 'coriman::infosorctrgtloc'
            BEGIN
               PRINT 'اگر لازم شد این قسمت رو پیاده سازی میکنیم'
            END 
        END;
        ELSE IF @MenuText IN ( 'custman::takeordr', 'custman::okgetordr' )
        BEGIN
            IF @MenuText = 'custman::takeordr'
            BEGIN
                -- بررسی اینکه آیا درخواست سفارش آماده خروج و تحویل به مشتری می باشد یا خیر
                IF EXISTS
                (
                    SELECT *
                    FROM dbo.[Order] o
                    WHERE o.ORDR_CODE = @ParamText
                          AND o.ORDR_TYPE = '018' /* شغل انبارداری */
                          AND o.ORDR_STAT = '014' /* جمع آوری و بسته بندی سفارش */
                )
                BEGIN
                    -- شماره درخواست مربوط به انباردار را پیدا کرده و منوی آن را برای انباردار ارسال میکنیم
                    SELECT @OrdrCode = o.CODE
                    FROM dbo.[Order] o
                    WHERE o.ORDR_CODE = @ParamText
                          AND o.ORDR_TYPE = '018';

                    SET @XTemp =
                    (
                        SELECT @Rbid AS '@rbid',
                               @ChatID AS '@chatid',
                               'notinewordrtostor' AS '@cmndtext',
                               @OrdrCode AS '@ordrcode'
                        FOR XML PATH('RequestInLineQuery')
                    );
                    EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                         @XRet = @XTemp OUTPUT; -- xml

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                    );

                    -- دوباره فعال کردن درخواست ارسال پیام برای انباردار
                    UPDATE dbo.Personal_Robot_Job_Order
                    SET ORDR_STAT = '001'
                    WHERE ORDR_CODE = @OrdrCode;
                    -- ارسال پیام به انباردار
                    INSERT INTO dbo.Order_Detail
                    (
                        ORDR_CODE,
                        ELMN_TYPE,
                        ORDR_CMNT,
                        ORDR_DESC,
                        INLN_KEYB_DNRM
                    )
                    VALUES
                    (@OrdrCode, '001', N'ثبت حواله بابت فروش آنلاین',
                     N'انباردار عزیز مشتری برای دریافت بسته سفارش در محل فروشگاه منتظر تحویل سفارش می باشد', @XTemp);

                    SET @Message
                        = N'😊 با تشکر از شما مشتری عزیز، بسته شما آماده تحویل می باشد، از خرید شما بسیار متشکریم';
                END;
                ELSE
                    SET @Message
                        = N'🙆 با عرض معذرت به دلیل ازدحام سفارشات هنوز سفارش شما از انبار جمع آوری و بسته بندی نشده است، 🙏 لطفا شکیبا باشید';
            END;
            ELSE IF @MenuText = 'custman::okgetordr'
            BEGIN
                IF @ParamText LIKE '%,%' /* اگر دریافت بسته توسط مشتری از طریق سفیر باشد */
                BEGIN
                    SELECT @OrdrCode = CASE id
                                           WHEN 1 THEN
                                               Item
                                           ELSE
                                               @OrdrCode
                                       END,
                           @Item = CASE id
                                       WHEN 2 THEN
                                           Item
                                       ELSE
                                           @Item
                                   END
                    FROM dbo.SplitString(@ParamText, ',');

                    IF @Item IN ( 'cashpay' )
                    BEGIN
                        INSERT INTO dbo.Order_State
                        (
                            ORDR_CODE,
                            CODE,
                            STAT_DATE,
                            STAT_DESC,
                            AMNT,
                            AMNT_TYPE,
                            RCPT_MTOD,
                            DEST_CARD_NUMB,
                            TXID,
                            CONF_STAT,
                            CONF_DATE
                        )
                        SELECT o.CODE,
                               0,
                               GETDATE(),
                               N'پرداخت مبلغ نقدی هزینه ارسال',
                               o.DEBT_DNRM,
                               '001',
                               '001',
                               o.DEST_CARD_NUMB_DNRM,
                               o.CODE,
                               '002',
                               GETDATE()
                        FROM dbo.[Order] o
                        WHERE o.CODE = @OrdrCode;

                        SET @XTemp =
                        (
                            SELECT @OrdrCode AS '@ordrcode' FOR XML PATH('Payment')
                        );
                        EXEC dbo.SAVE_PYMT_P @X = @XTemp,           -- xml
                                             @xRet = @XTemp OUTPUT; -- xml   
                    END;
                    ELSE IF @Item IN ( 'walletcreditpay', 'walletcashpay' )
                    BEGIN
                        -- بدست آوردن مبلغ هزینه حق الزحمه ارسال     
                        SELECT @Amnt = o.DEBT_DNRM,
                               @ChatID = o.CHAT_ID
                        FROM dbo.[Order] o
                        WHERE o.CODE = @OrdrCode;

                        SET @XTemp =
                        (
                            SELECT @ChatID AS '@chatid',
                                   @Rbid AS '@rbid',
                                   w.CODE AS '@wletcode',
                                   @OrdrCode AS '@ordrcode',
                                   w.WLET_TYPE AS '@wlettype'
                            FROM dbo.Wallet w
                            WHERE w.SRBT_ROBO_RBID = @Rbid
                                  AND w.CHAT_ID = @ChatID
                                  AND w.WLET_TYPE = CASE @Item
                                                        WHEN 'walletcreditpay' THEN
                                                            '001'
                                                        WHEN 'walletcashpay' THEN
                                                            '002'
                                                    END -- Cash/Credit Wallet
                            FOR XML PATH('Wallet_Detail')
                        );
                        EXEC dbo.SAVE_WLET_P @X = @XTemp,           -- xml
                                             @XRet = @XTemp OUTPUT; -- xml

                        SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                               @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

                        IF @RsltCode = '002'
                        BEGIN
                            SET @XTemp =
                            (
                                SELECT @OrdrCode AS '@ordrcode' FOR XML PATH('Payment')
                            );
                            EXEC dbo.SAVE_PYMT_P @X = @XTemp,           -- xml
                                                 @xRet = @XTemp OUTPUT; -- xml               
                        END;
                        ELSE
                        BEGIN
                            SET @Message
                                = N'⛔️ اعتبار کیف پول شما کافی نیست، لطفا از گزینه های نقدی یا پرداخت آنلاین استفاده کنید، باتشکر';
                            GOTO L$EndSP;
                        END;
                    END;
                    ELSE IF @Item IN ('free')
                    BEGIN
                       SET @ParamText = (
                           SELECT o1.CODE
                             FROM dbo.[Order] o1                               
                            WHERE o1.ORDR_TYPE = '004'
                              AND EXISTS (
                                     SELECT *
                                       FROM dbo.[Order] o2
                                      WHERE o1.CODE = o2.ORDR_CODE
                                        AND o2.ORDR_TYPE = '019'
                                        AND EXISTS (
                                               SELECT *
                                                 FROM dbo.[Order] o3
                                                WHERE o2.CODE = o3.ORDR_CODE
                                                  AND o3.CODE = @OrdrCode
                                                  AND o3.ORDR_TYPE = '023'
                                            )
                                  )
                       );
                       GOTO L$Thankyou4Buy;
                    END 

                    -- در این قسمت یک پیام به مشتری داده میشود و یک پیام به پیک موتوری
                    -- اول پیام پیک موتوری
                    SET @Message =
                    (
                        SELECT N'✅ پرداخت مبلغ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, os.AMNT), 1), '.00', '')
                               + N'* ' + @AmntTypeDesc + N' به صورت *' + r.DOMN_DESC
                               + N'* با موفقیت انجام شد، با تشکر از شما '
                        FROM dbo.Order_State os,
                             dbo.[D$RCMT] r
                        WHERE os.ORDR_CODE = @OrdrCode
                              AND os.AMNT_TYPE = '001'
                              AND os.RCPT_MTOD = r.VALU
                        FOR XML PATH('')
                    );
                    -- درخواست پیک موتوری
                    SELECT @OrdrCode = o.ORDR_CODE
                    FROM dbo.[Order] o
                    WHERE o.CODE = @OrdrCode
                          AND o.ORDR_TYPE = '023';
                    -- فعال کردن سامانه اطلاع رسانی پیک موتوری
                    UPDATE dbo.Personal_Robot_Job_Order
                    SET ORDR_STAT = '001'
                    WHERE ORDR_CODE = @OrdrCode;
                    -- ارسال پیام به پیک موتوری
                    INSERT INTO dbo.Order_Detail
                    (
                        ORDR_CODE,
                        ELMN_TYPE,
                        ORDR_CMNT,
                        ORDR_DESC
                    )
                    VALUES
                    (@OrdrCode, '001', N'پرداخت مبلغ ارسال سفارش بابت فروش آنلاین', @Message);
                END;
                ELSE /* اگر مشتری خود درب فروشگاه حاضر شده باشد */
                BEGIN
                    L$Thankyou4Buy:
                    SET @OrdrCode = @ParamText;
                    -- تمام درخواست های زیر مجموعه سفارش پایانی شود
                    UPDATE dbo.[Order]
                       SET ORDR_STAT = '004'
                     WHERE ORDR_CODE = @OrdrCode;

                    -- درخواست سفارش اصلی هم به صورت تخویل به مشتری تغییر وضعیت داده شود
                    UPDATE dbo.[Order]
                       SET ORDR_STAT = '009'
                     WHERE CODE = @OrdrCode;
                    
                    -- اگر درخواست پذیرش انلاین داشته باشیم آن را هم تحویل به مشتری و پایانی میکنیم
                    -- ####################
                    UPDATE dbo.[Order]
                       SET ORDR_STAT = '009',
                           END_DATE = GETDATE()
                     WHERE ORDR_TYPE = '025'
                       AND CODE IN (
                           SELECT o.ORDR_CODE
                             FROM dbo.[Order] o
                            WHERE o.ORDR_TYPE = '004'
                              AND o.CODE = @OrdrCode                           
                     );
                    
                    UPDATE dbo.[Order]
                       SET ORDR_STAT = '004',
                           END_DATE = GETDATE()
                     WHERE ORDR_TYPE = '025'
                       AND CODE IN (
                           SELECT o.ORDR_CODE
                             FROM dbo.[Order] o
                            WHERE o.ORDR_TYPE = '004'
                              AND o.CODE = @OrdrCode                           
                     );
                    -- ####################
                    
                    SET @Message = N'😊✋ از خرید شما متشکریم';
                END;
            END;
        END;
        ELSE IF @MenuText IN ( 'join::gropsale::accept', 'join::gropsale::reject' )
        BEGIN
            IF @MenuText = 'join::gropsale::accept'
            BEGIN
                -- اطلاعات دعوت کننده درون لیست دعوت شده قرار میگرد
                UPDATE dbo.Service_Robot
                SET REF_CHAT_ID = @ParamText
                WHERE ROBO_RBID = @Rbid
                      AND CHAT_ID = @ChatID;

                -- ارسال پیام برای مخاطب
                SET @Message =
                (
                    SELECT N'😊✋ مشتری عزیز' + CHAR(10) + N'کاربری شما در 👥 تیم فروش *' + sr.NAME
                           + N'* با موفقیت قرار گرفت' + CHAR(10)
                           + N'دوست عزیز شما هم می توانید مخاطبین خود را دعوت کنید تا در باشگاه مشتریان، *شما* صاحب امتیاز های ارزنده ی باور نکردنی می شوید'
                           + CHAR(10) + N'راهنمای دعوت مخاطبین :' + CHAR(10)
                           + N'👈 *ورود به حساب کاربری* 👈 *مجموعه فروش* 👈 *دعوت از دوستان* به همین راحتی' + CHAR(10)
                           + N'🙏 با تشکر از شما'
                    FROM dbo.Service_Robot sr
                    WHERE sr.ROBO_RBID = @Rbid
                          AND sr.CHAT_ID = @ParamText
                );

                -- ارسال پیام برای دعوت کننده
                INSERT INTO dbo.[Order]
                (
                    SRBT_SERV_FILE_NO,
                    SRBT_ROBO_RBID,
                    SUB_SYS,
                    CODE,
                    ORDR_TYPE,
                    ORDR_STAT
                )
                SELECT sr.SERV_FILE_NO,
                       sr.ROBO_RBID,
                       12,
                       dbo.GNRT_NVID_U(),
                       '012',
                       '004'
                FROM Service_Robot sr
                WHERE sr.ROBO_RBID = @Rbid
                      AND sr.CHAT_ID = @ParamText;

                -- بدست آوردن شماره درخواست
                SELECT @OrdrCode = o.CODE
                FROM dbo.[Order] o,
                     dbo.Service_Robot sr
                WHERE o.ORDR_TYPE = '012'
                      AND o.ORDR_STAT = '004'
                      AND o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                      AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                      AND sr.CHAT_ID = @ParamText
                      AND sr.ROBO_RBID = @Rbid
                      AND NOT EXISTS
                (
                    SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE
                );

                INSERT INTO dbo.Order_Detail
                (
                    ORDR_CODE,
                    ELMN_TYPE,
                    ORDR_CMNT,
                    ORDR_DESC,
                    IMAG_PATH
                )
                SELECT o.CODE,
                       '002',
                       N'سامانه اطلاع رسانی بابت اضافه شدن عضویت جدید در گروه فروش شما',
                       N'😉✋ *' + o.OWNR_NAME + N'* عزیز' + CHAR(10) + N'با سلام و احترام' + CHAR(10)
                       + N'➕ اضافه شدن عضویت جدید در تیم فروش' + CHAR(10) + CHAR(10) + N'😀 *' + sr.NAME
                       + N'* به *تیم فروش شما اضافه شده* لطفا با ایشان در تماس باشید و آموزش های لازم جهت استفاده از فروشگاه ما را به ایشان آموزش دهید. '
                       + N'این آموزش ها باید به صورت *رایگان* در اختیار *فرد جدید* قرار دهید تا بتواند از *کالا و خدمات فروشگاه* استفاده کند، فروشگاه بابت زحماتی که شما برای تیم فروشتان میکشید *پاداش* خود را '
                       + N'بعد از خرید مشتریان برای شما *محاسبه* و در *زمان مقرر* به حساب *کیف پولتان* واریز میکند'
                       + CHAR(10) + N'🙏 با تشکر از شما',
                       (
                           SELECT TOP 1
                                  om.FILE_ID
                           FROM dbo.Organ_Media om
                           WHERE om.ROBO_RBID = @Rbid
                                 AND om.RBCN_TYPE = '013'
                                 AND om.STAT = '002'
                                 AND om.IMAG_TYPE = '002'
                       )
                FROM dbo.[Order] o,
                     dbo.Service_Robot sr
                WHERE o.CODE = @OrdrCode
                      AND sr.CHAT_ID = @ChatID
                      AND sr.ROBO_RBID = @Rbid
                      AND NOT EXISTS
                (
                    SELECT * FROM dbo.Order_Detail od WHERE od.ORDR_CODE = o.CODE
                );

                SELECT @TDirPrjbCode = a.CODE
                FROM dbo.Personal_Robot_Job a,
                     dbo.Job b,
                     dbo.[Order] o
                WHERE a.PRBT_ROBO_RBID = @Rbid
                      AND a.JOB_CODE = b.CODE
                      AND b.ORDR_TYPE = '012'
                      AND o.CODE = @OrdrCode
                      AND a.PRBT_SERV_FILE_NO = o.SRBT_SERV_FILE_NO;

                SELECT @XMessage =
                (
                    SELECT @OrdrCode AS '@code',
                           @Rbid AS '@roborbid',
                           '012' '@type',
                           @TDirPrjbCode '@dirprjbcode'
                    FOR XML PATH('Order'), ROOT('Process')
                );
                EXEC Send_Order_To_Personal_Robot_Job @XMessage;
            END;
            ELSE IF @MenuText = 'join::gropsale::reject'
            BEGIN
                SET @Message
                    = N'دوست عزیز عضویت در گروه فروش به شما کمک میکند که چگونه از خدمات فروشگاه آنلاین استفاده کنید، این آموزش ها می تواند برای شما مفید واقع شود که بتوانید نیازهای روزانه خود را بهتر و راحت تر تهیه کنید';
            END;
        END;
        ELSE IF @MenuText IN ( 'location::show', 'location::select', 'location::del', 'location::del::confirmed',
                               'location::update'
                             )
        BEGIN
            IF @MenuText = 'location::show'
            BEGIN
                SELECT @UssdCode = '*1*2#',
                       @ChildUssdCode = '*1*2*2#',
                       @MenuText = N'';
                GOTO L$SelectAddress;
            END;
            IF @MenuText = 'location::select'
            BEGIN
                -- در این قسمت ابتدا نقشه آدرس را ارسال میکنیم و سپس آدرس متن که در انتها گزینه ای به نام حذف و بروزرسانی , گزینه پیشرفته تر و  بازگشت قرار میدهیم
                SET @XTemp =
                (
                    SELECT CONVERT(VARCHAR(30), CORD_X, 128) AS '@cordx',
                           CONVERT(VARCHAR(30), CORD_Y, 128) AS '@cordy',
                           1 AS '@order'
                    FROM dbo.Service_Robot_Public p
                    WHERE p.SRBT_ROBO_RBID = @Rbid
                          AND p.CHAT_ID = @ChatID
                          AND p.RWNO = @ParamText
                    FOR XML PATH('Location'), ROOT('Locations')
                );
                SET @XTemp.modify('insert attribute order {"1"} into (//Locations)[1]');
                SET @XMessage = @XTemp;

                SET @Message =
                (
                    SELECT N'📍 آدرس شما : ' + N'_' + ISNULL(p.SERV_ADRS, N'مشخص نشده') + N'_'
                    FROM dbo.Service_Robot_Public p
                    WHERE p.SRBT_ROBO_RBID = @Rbid
                          AND p.CHAT_ID = @ChatID
                          AND p.RWNO = @ParamText
                );
                --SET @XMessage.modify('insert attribute caption {sql:variable("@Message")} into (//Location)[1]');         
                --SET @XTemp.modify('insert attribute caption {sql:variable("@Message")} into (//Location)[1]');         
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @ChatID AS '@chatid',
                           'lessloctinfo' AS '@cmndtext',
                           @ParamText AS '@param'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '2' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @XMessage.modify('insert sql:variable("@xtemp") as last into (.)[1]');
                SET @XMessage =
                (
                    SELECT 1 AS '@order', @XMessage FOR XML PATH('Message')
                );
                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
            ELSE IF @MenuText = 'location::del'
            BEGIN
                SET @Message =
                (
                    SELECT N'❓ آیا با حذف آدرس مورد نظر موافق هستید؟' + CHAR(10) + N'📲 کد دستگاه شما : *'
                           + CAST(@ChatID AS NVARCHAR(30)) + N'*' + CHAR(10) + N'ردیف آدرس : *'
                           + CAST(p.RWNO AS NVARCHAR(10)) + N'*' + CHAR(10) + N'وضعیت آدرس : *'
                           + CASE
                                 WHEN p.SERV_ADRS IS NULL
                                      OR p.CORD_X IS NULL
                                      OR p.CORD_Y IS NULL THEN
                                     N'⭕️ آدرس ناقص می باشد'
                                 ELSE
                                     N'✅ آدرس کامل می باشد'
                             END + N'*' + CHAR(10) + N'آدرس پستی : *' + ISNULL(p.SERV_ADRS, '---') + N'*' + CHAR(10)
                           + N'موقعیت مکانی : * X : ' + CAST(ISNULL(p.CORD_X, 0) AS NVARCHAR(30)) + N' Y : '
                           + CAST(ISNULL(p.CORD_Y, 0) AS NVARCHAR(30)) + N'*'
                    FROM dbo.Service_Robot_Public p
                    WHERE p.SRBT_ROBO_RBID = @Rbid
                          AND p.CHAT_ID = @ChatID
                          AND p.RWNO = @ParamText
                );
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @ChatID AS '@chatid',
                           'lessloctdel' AS '@cmndtext',
                           @ParamText AS '@param'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
            ELSE IF @MenuText = 'location::del::confirmed'
            BEGIN
                UPDATE dbo.Service_Robot_Public
                SET VALD_TYPE = '001'
                WHERE SRBT_ROBO_RBID = 401
                      AND CHAT_ID = @ChatID
                      AND RWNO = @ParamText;

                IF NOT EXISTS
                (
                    SELECT *
                    FROM dbo.Service_Robot_Public p
                    WHERE p.SRBT_ROBO_RBID = @Rbid
                          AND p.CHAT_ID = @ChatID
                          AND p.VALD_TYPE = '002'
                )
                    UPDATE dbo.Service_Robot
                    SET SERV_ADRS = NULL,
                        CORD_X = NULL,
                        CORD_Y = NULL,
                        SRPB_RWNO = NULL
                    WHERE ROBO_RBID = @Rbid
                          AND CHAT_ID = @ChatID;
                ELSE
                    UPDATE sr
                    SET SERV_ADRS = p.SERV_ADRS,
                        CORD_X = p.CORD_X,
                        CORD_Y = p.CORD_Y,
                        SRPB_RWNO = p.RWNO
                    FROM dbo.Service_Robot sr,
                         dbo.Service_Robot_Public p
                    WHERE sr.SERV_FILE_NO = p.SRBT_SERV_FILE_NO
                          AND sr.ROBO_RBID = p.SRBT_ROBO_RBID
                          AND p.VALD_TYPE = '002'
                          AND p.RWNO =
                          (
                              SELECT MAX(pt.RWNO)
                              FROM dbo.Service_Robot_Public pt
                              WHERE pt.SRBT_SERV_FILE_NO = p.SRBT_SERV_FILE_NO
                                    AND pt.SRBT_ROBO_RBID = p.SRBT_ROBO_RBID
                          );

                SELECT @UssdCode = '*1*2#',
                       @ChildUssdCode = '*1*2*2#',
                       @MenuText = N'location::select';
                GOTO L$SelectAddress;
            END;
            ELSE IF @MenuText = 'location::update'
            BEGIN
                SELECT @Index = CASE id
                                    WHEN 1 THEN
                                        Item
                                    ELSE
                                        @Index
                                END,
                       @QueryStatement = CASE id
                                             WHEN 2 THEN
                                                 Item
                                             ELSE
                                                 @QueryStatement
                                         END
                FROM dbo.SplitString(@ParamText, ',');

                IF @ElmnType IN ( '001', '005' )
                   AND @QueryStatement NOT IN ( N'➕ ثبت جدید', N'🚩 نمایش', N'🛠️ مدیریت آدرسها', N'🔺 بازگشت',
                                                N'بازگشت به منوی اصلی'
                                              )
                BEGIN
                    SET @XTemp =
                    (
                        SELECT @Rbid AS '@rbid',
                               @ChatID AS '@chatid',
                               '009' AS '@actntype',
                               @QueryStatement AS '@postadrs',
                               @Index AS '@parmtext',
                               @CordX AS '@cordx',
                               @CordY AS '@cordy'
                        FOR XML PATH('Service')
                    );
                    EXEC dbo.SAVE_SRBT_P @X = @XTemp, @XRet = @XTemp OUTPUT;
                    SELECT @RsltCode = @XTemp.query('//Message').value('(Message/@rsltcode)[1]', 'VARCHAR(3)'),
                           @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');

                    IF @RsltCode = '002'
                    BEGIN
                        -- Static
                        SET @XTemp =
                        (
                            SELECT dbo.STR_FRMT_U(
                                                     './{0};location::select-{1}$del#',
                                                     @UssdCode + ',' + CAST(@Index AS VARCHAR(30))
                                                 ) AS '@data',
                                   1 AS '@order',
                                   N'💾 تایید' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );

                        SELECT @Message += CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                           + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));

                        SET @XTemp =
                        (
                            SELECT '1' AS '@order',
                                   @Message AS '@caption',
                                   @XTemp
                            FOR XML PATH('InlineKeyboardMarkup')
                        );

                        SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                    END;
                END;
                ELSE IF @QueryStatement IN ( N'➕ ثبت جدید', N'🚩 نمایش', N'🛠️ مدیریت آدرسها', N'🔺 بازگشت',
                                             N'بازگشت به منوی اصلی'
                                           )
                BEGIN
                    SET @Message
                        = N'اطلاعات جهت ویرایش آدرس: لطفا *آدرس متنی* را وارد ⌨️ نموده و سپس با استفاده از کلید ➕ ، *موقعیت مکانی* خود را ارسال کنید '
                          + CHAR(10) + N'در غیر اینصورت *❌ انصراف* را فشار دهید';
                    -- Static
                    SET @XTemp =
                    (
                        SELECT dbo.STR_FRMT_U(
                                                 './{0};location::select-{1}$del#',
                                                 @UssdCode + ',' + CAST(@Index AS VARCHAR(30))
                                             ) AS '@data',
                               1 AS '@order',
                               N'❌ انصراف' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                    );

                    SELECT @Message += CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
                                       + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order',
                               @Message AS '@caption',
                               @XTemp
                        FOR XML PATH('InlineKeyboardMarkup')
                    );

                    SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                END;
                ELSE
                BEGIN
                    SET @Message
                        = N'👈 اطلاعات جهت ویرایش آدرس: لطفا *آدرس متنی* را وارد ⌨️ نموده و سپس با استفاده از کلید ➕ ، *موقعیت مکانی* خود را ارسال کنید';
                END;
            END;
        END;
        ELSE IF @MenuText IN ( 'bankcard::showcards', 'bankcard::showinfo', 'bankcard::new', 'bankcard::deactive',
                               'bankcard::active', 'bankcard::edit', 'bankcard::reportin'
                             )
        BEGIN
            IF @MenuText = 'bankcard::showcards'
            BEGIN
                --SELECT @UssdCode = '*1*4#', @ChildUssdCode = '*1*4*2#';
                GOTO L$BankCardShow;
            END;
            ELSE IF @MenuText = 'bankcard::showinfo'
            BEGIN
                SET @Message
                    = N'*کارت بانکی خود را مدیریت کنید*' + CHAR(10)
                      + N'شما می توانید کارت خود را *غیر فعال / فعال* ، ✏️ *ویرایش* و حتی 📋 *گزارشات واریزی* را هم بدست بیاورید'
                      + CHAR(10) + CHAR(10)
                      +
                      (
                          SELECT N'💳  *' + b.CARD_NUMB_DNRM + N'*' + CHAR(10) + N'🏢  *' + b.BANK_NAME + N'*'
                                 + CHAR(10) + N'🔢  *' + ISNULL(b.SHBA_NUMB, N'---') + N'*' + CHAR(10) + N'◀️ *'
                                 + CASE
                                       WHEN b.ORDR_TYPE IN ( '004' ) THEN
                                           N'حساب فروش آنلاین'
                                       WHEN b.ORDR_TYPE IN ( '013' ) THEN
                                           N'حساب شارژ خدمات فروشنده / پیک'
                                       WHEN b.ORDR_TYPE IN ( '015' ) THEN
                                           N'حساب سپرده مشتریان'
                                       WHEN b.ORDR_TYPE IN ( '023' ) THEN
                                           N'حساب درآمد ارسال بسته'
                                       WHEN b.ORDR_TYPE IN ( '024' )
                                            AND b.ACNT_TYPE = '003' THEN
                                           N'حساب دریافت پورسانت'
                                       WHEN b.ORDR_TYPE IN ( '024' )
                                            AND b.ACNT_TYPE = '002' THEN
                                           N'حساب پرداخت پورسانت'
                                   END + N'*'
                          FROM dbo.Service_Robot_Card_Bank a,
                               dbo.Robot_Card_Bank_Account b
                          WHERE a.RCBA_CODE = b.CODE
                                AND a.CODE = @ParamText
                          FOR XML PATH('')
                      );
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @ChatID AS '@chatid',
                           'lessbkcdinfo' AS '@cmndtext',
                           @ParamText AS '@param'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @XMessage =
                (
                    SELECT TOP 1
                           om.FILE_ID AS '@fileid',
                           om.IMAG_TYPE AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                          AND om.RBCN_TYPE = '014'
                          AND om.IMAG_TYPE = '002'
                          AND om.STAT = '002'
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                );
                SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
            ELSE IF @MenuText = 'bankcard::new'
            BEGIN
                PRINT @ParamText;
                IF @ParamText IN ( '', '004', '015', '023', '024', '017' )
                BEGIN
                    SET @Message
                        = N'🖐️☺️ با سلام' + CHAR(10) + N'به واحد تعریف *کارت بانکی* خوش آمدین' + CHAR(10)
                          + N'در این قسمت لطفا 💳 *شماره کارت* و *شماره شبا* بانک مورد نظر خود را وارد کنید' + CHAR(10)
                          + N'👈 لطفا دقت داشته باشید که *صحت* _وارد کردن_ *اطلاعات* به *عهده شخص شما* می باشد'
                          + CHAR(10)
                          + N'‼️ در صورت *اشتباه* _وارد کردن_ *شماره کارت* و *شماره شبا* 💰 _مبلغ_ *شما* ممکن است به *حساب 😭 شخص دیگری* _واریز_ شود'
                          + CHAR(10) + N'نحوه صحیح وارد کردن 💳 *شماره کارت* و *شماره شبا* به صورت زیر 👇 می باشد'
                          + CHAR(10) + N'👈 *ابتدا شماره کارت* بعد علامت جداکننده *#* و سپس *شماره شبا* را وارد کنید'
                          + CHAR(10) + N' *شماره شبا* # *شماره کارت*' + CHAR(10)
                          + N' *190180000000000786100747* # *5859831090641837* ' + CHAR(10)
                          + N'👈 دقت داشته باشید که عبارت *IR* برای شماره شبا نیاز نیست که وارد شود';

                    SET @XTemp =
                    (
                        SELECT './' + @UssdCode + ';bankcard::showcards-$del#' AS '@data',
                               @Index AS '@order',
                               N'⤴️ بازگشت' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                    );

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order',
                               @Message AS '@caption',
                               @XTemp
                        FOR XML PATH('InlineKeyboardMarkup')
                    );

                    SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                END;
                ELSE IF @ParamText LIKE '%,%'
                        OR @ParamText LIKE '%#%'
                BEGIN
                    SELECT @OrdrType = CASE id
                                           WHEN 1 THEN
                                               Item
                                           ELSE
                                               @OrdrType
                                       END,
                           @ParamText = CASE id
                                            WHEN 2 THEN
                                                Item
                                            ELSE
                                                @ParamText
                                        END
                    FROM dbo.SplitString(@ParamText, ',');

                    SELECT @BankCard = CASE id
                                           WHEN 1 THEN
                                               Item
                                           ELSE
                                               @BankCard
                                       END,
                           @ShbaNumb = CASE id
                                           WHEN 2 THEN
                                               Item
                                           ELSE
                                               @ShbaNumb
                                       END
                    FROM dbo.SplitString(@ParamText, '#');

                    IF dbo.CHK_CRDT_U(@BankCard) = 0
                    BEGIN
                        SET @Message = N'❌ *شماره کارت* وارد شده صحیح نمیباشد، لطفا دقت فرمایید';
                        SET @XTemp =
                        (
                            SELECT './' + @UssdCode + ';bankcard::showcards-$del#' AS '@data',
                                   @Index AS '@order',
                                   N'⤴️ بازگشت' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );

                        SET @XTemp =
                        (
                            SELECT '1' AS '@order',
                                   @Message AS '@caption',
                                   @XTemp
                            FOR XML PATH('InlineKeyboardMarkup')
                        );

                        SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                        GOTO L$EndSP;
                    END;
                    IF EXISTS
                    (
                        SELECT *
                        FROM dbo.Robot_Card_Bank_Account a
                        WHERE a.ROBO_RBID = @Rbid
                              AND a.CARD_NUMB = @BankCard
                              AND a.ORDR_TYPE = @OrdrType /* حساب پورسانت مشتریان، فروش آنلاین فروشگاه، هزینه پیک */
                    )
                    BEGIN
                        IF EXISTS
                        (
                            SELECT *
                            FROM dbo.Service_Robot_Card_Bank a
                            WHERE a.SRBT_ROBO_RBID = @Rbid
                                  AND a.CARD_NUMB_DNRM = @BankCard
                                  AND a.ORDR_TYPE_DNRM = @OrdrType
                                  AND a.ACNT_STAT_DNRM = '001'
                        )
                        BEGIN
                            UPDATE dbo.Robot_Card_Bank_Account
                            SET ACNT_STAT = '002'
                            WHERE ROBO_RBID = @Rbid
                                  AND CARD_NUMB = @BankCard
                                  AND ORDR_TYPE = @OrdrType;
                            GOTO L$SaveBankCard;
                        END;
                        SET @Message = N'❌ *شماره کارت* وارد شده قبلا درون سیستم ثبت شده';
                        SET @XTemp =
                        (
                            SELECT './' + @UssdCode + ';bankcard::showcards-$del#' AS '@data',
                                   @Index AS '@order',
                                   N'⤴️ بازگشت' AS "text()"
                            FOR XML PATH('InlineKeyboardButton')
                        );

                        SET @XTemp =
                        (
                            SELECT '1' AS '@order',
                                   @Message AS '@caption',
                                   @XTemp
                            FOR XML PATH('InlineKeyboardMarkup')
                        );

                        SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                        GOTO L$EndSP;
                    END;

                    -- ثبت اطلاعات درون جدول ربات
                    INSERT INTO dbo.Robot_Card_Bank_Account
                    (
                        ROBO_RBID,
                        CODE,
                        CARD_NUMB,
                        SHBA_NUMB,
                        ACNT_TYPE,
                        ACNT_OWNR,
                        ACNT_DESC,
                        ORDR_TYPE,
                        ACNT_STAT
                    )
                    SELECT sr.ROBO_RBID,
                           0,
                           @BankCard,
                           @ShbaNumb,
                           CASE
                               WHEN @OrdrType IN ( '004', '015', '017' /* حساب پرداخت پورسانت */ ) THEN
                                   '002'
                               WHEN @OrdrType IN ( '023', '024' ) THEN
                                   '003'
                           END,
                           sr.NAME,
                           CASE @OrdrType
                               WHEN '004' THEN
                                   N'حساب دریافتنی بابت فروش آنلاین'
                               WHEN '015' THEN
                                   N'حساب دریافتنی بابت سپرده مشتریان'
                               WHEN '017' THEN
                                   N'حساب پرداخت پورسانت مشتریان'
                               WHEN '023' THEN
                                   N'حساب دریافتنی بابت ارسال بسته'
                               WHEN '024' THEN
                                   N'حساب دریافتنی بابت پورسانت مشتریان'
                           END,
                           @OrdrType,
                           '002'
                    FROM dbo.Service_Robot sr
                    WHERE sr.ROBO_RBID = @Rbid
                          AND sr.CHAT_ID = @ChatID;

                    -- برقراری اتصال شماره کارت به مشتری
                    INSERT INTO dbo.Service_Robot_Card_Bank
                    (
                        SRBT_SERV_FILE_NO,
                        SRBT_ROBO_RBID,
                        RCBA_CODE,
                        CODE
                    )
                    SELECT sr.SERV_FILE_NO,
                           sr.ROBO_RBID,
                           a.CODE,
                           0
                    FROM dbo.Service_Robot sr,
                         dbo.Robot_Card_Bank_Account a
                    WHERE sr.ROBO_RBID = a.ROBO_RBID
                          AND sr.CHAT_ID = @ChatID
                          AND a.ROBO_RBID = @Rbid
                          AND a.ORDR_TYPE = @OrdrType
                          AND a.ACNT_TYPE = CASE
                                                WHEN @OrdrType IN ( '004', '015', '017' ) THEN
                                                    '002'
                                                WHEN @OrdrType IN ( '023', '024' ) THEN
                                                    '003'
                                            END
                          AND a.ACNT_STAT = '002'
                          AND a.CARD_NUMB = @BankCard;

                    L$SaveBankCard:
                    SET @Message
                        = N'✅ اطلاعات *کارت بانکی* شما با موفقیت درون سیستم ثبت شد' + CHAR(10)
                          + N'😊 اگر مایل هستید می توانید *شماره کارت* های دیگری را درون سیستم ثبت کنید، که هر موقع خواستید *واریز مبلغ* به _حساب های مختلف_ داشته باشید';

                    SET @XTemp =
                    (
                        SELECT './' + @UssdCode + ';bankcard::showcards-$del#' AS '@data',
                               @Index AS '@order',
                               N'⤴️ بازگشت' AS "text()"
                        FOR XML PATH('InlineKeyboardButton')
                    );

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order',
                               @Message AS '@caption',
                               @XTemp
                        FOR XML PATH('InlineKeyboardMarkup')
                    );

                    SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                END;
            END;
            ELSE IF @MenuText = 'bankcard::deactive'
            BEGIN
                UPDATE b
                SET b.ACNT_STAT = '001'
                FROM dbo.Service_Robot_Card_Bank a,
                     dbo.Robot_Card_Bank_Account b
                WHERE a.RCBA_CODE = b.CODE
                      AND a.CODE = @ParamText;

                --SELECT @UssdCode = '*1*4#', @ChildUssdCode = '*1*4*2#';
                GOTO L$BankCardShow;
            END;
            ELSE IF @MenuText = 'bankcard::active'
            BEGIN
                UPDATE b
                SET b.ACNT_STAT = '002'
                FROM dbo.Service_Robot_Card_Bank a,
                     dbo.Robot_Card_Bank_Account b
                WHERE a.RCBA_CODE = b.CODE
                      AND a.CODE = @ParamText;

                --SELECT @UssdCode = '*1*4#', @ChildUssdCode = '*1*4*2#';
                GOTO L$BankCardShow;
            END;
            ELSE IF @MenuText = 'bankcard::edit'
            BEGIN
                IF @ParamText NOT LIKE '%,%'
                BEGIN
                    SET @Message
                        = N'*ویرایش کارت بانکی*' + CHAR(10) + N'شما می توانید شماره شبا بانک خود را تغییر دهید'
                          + CHAR(10) + N'لطفا شماره شبا خود را به صورت نمونه زیر ارسال کنید' + CHAR(10)
                          + N' *شماره شبا* ' + CHAR(10) + N' *190180000000000786100747* ' + CHAR(10)
                          + N'👈 دقت داشته باشید که عبارت *IR* برای شماره شبا نیاز نیست که وارد شود';
                END;
                ELSE IF @ParamText LIKE '%,%'
                BEGIN
                    SELECT @Said = CASE id
                                       WHEN 1 THEN
                                           Item
                                       ELSE
                                           @Said
                                   END,
                           @ShbaNumb = CASE id
                                           WHEN 2 THEN
                                               Item
                                           ELSE
                                               @ShbaNumb
                                       END
                    FROM dbo.SplitString(@ParamText, ',');

                    UPDATE b
                    SET b.SHBA_NUMB = @ShbaNumb
                    FROM dbo.Service_Robot_Card_Bank a,
                         dbo.Robot_Card_Bank_Account b
                    WHERE a.RCBA_CODE = b.CODE
                          AND a.CODE = @Said;

                    SET @ParamText = @Said;
                    SET @Message = N'✅ اطلاعات *کارت بانکی* شما با موفقیت درون سیستم ثبت شد';
                END;

                SET @XTemp =
                (
                    SELECT './' + @UssdCode + REPLACE(';bankcard::showinfo-{0}$del#', '{0}', @ParamText) AS '@data',
                           @Index AS '@order',
                           N'⤴️ بازگشت' AS "text()"
                    FOR XML PATH('InlineKeyboardButton')
                );

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
        END;
        ELSE IF @MenuText IN ( 'wallet::depositshop', 'wallet::depositshop::bankcard',
                               'wallet::depositshop::bankcard::select', 'wallet::depositshop::amount',
                               'wallet::depositshop::amount::select', 'wallet::depositshop::sendrequest',
                               'wallet::depositshop::cancelrequest', 'wallet::depositshop::statusrequest',
                               'wallet::depositmembers', 'wallet::depositmembers::selectbankcard',
                               'wallet::depositmembers::selectamount', 'wallet::depositmembers::sendrequest',
                               'wallet::historydeposits', 'wallet::deposit::homepage'
                             )
        BEGIN
            IF @MenuText = 'wallet::deposit::homepage'
            BEGIN
                SELECT @UssdCode = '*1*4#',
                       @ChildUssdCode = '*1*4*1#';
                GOTO L$CashOutProfit;
            END;
            ELSE IF @MenuText = 'wallet::depositshop'
            BEGIN
                L$WalletDepositShop:
                SELECT @XTemp =
                (
                    SELECT 12 AS '@subsys',
                           '024' AS '@ordrtype',
                           '000' AS '@typecode',
                           @ChatID AS '@chatid',
                           @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @MenuText AS '@input',
                           0 AS '@ordrcode'
                    FOR XML PATH('Action'), ROOT('Cart')
                );
                EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
                -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
                SELECT @RsltCode = @XTemp.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)'),
                       @OrdrCode = @XTemp.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');
                -- اگر درخواست واریز وجه
                IF @RsltCode = '002'
                BEGIN
                    -- بدست آوردن اطلاعات شماره کارت و مبلغ
                    SELECT @BankCard = o.SORC_CARD_NUMB_DNRM,
                           @QueryStatement = a.CARD_NUMB_DNRM,
                           @Amnt = od.EXPN_PRIC,
                           @TxfeAmnt = o.TXFE_AMNT_DNRM,
                           @SysCode = CAST(o.ORDR_TYPE_NUMB AS VARCHAR(30)) + N' - ' + o.ORDR_TYPE
                    FROM dbo.[Order] o
                        LEFT OUTER JOIN dbo.Order_Detail od
                            ON o.CODE = od.ORDR_CODE,
                         dbo.Robot_Card_Bank_Account a
                    WHERE o.CODE = @OrdrCode
                          AND o.SORC_CARD_NUMB_DNRM = a.CARD_NUMB;
                END;

                SET @Message
                    = N'*ارسال درخواست وجه برای فروشگاه*' + CHAR(10) + CHAR(10)
                      + N'💡 لطفا مراحل *درخواست وجه* را به صورت گام به گام انجام دهید' + CHAR(10)
                      + N'🔢 شماره درخواست : *' + CAST(@OrdrCode AS VARCHAR(30)) + N'*' + CHAR(10) + N'⏺️ کد سیستم : *'
                      + @SysCode + N'*' + CHAR(10) + N'*مراحل انجام کار*' + CHAR(10) + N'👈 *گام اول* :'
                      + CASE ISNULL(@BankCard, 'nocard')
                            WHEN 'nocard' THEN
                                N'💳 *شماره کارت* خود را مشخص کنید'
                            ELSE
                                N' ✅ *شماره کارت* انتخابی شما ' + CHAR(10) + N'💳 *' + @QueryStatement + N'*'
                        END + CHAR(10) + N'👈 *گام دوم* :'
                      + CASE ISNULL(@Amnt, 0)
                            WHEN 0 THEN
                                N'💵 *مبلغ درخواست وجه* خود را مشخص کنید'
                            ELSE
                                N' ✅ 💵 مبلغ واریز وجه *'
                                + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @Amnt), 1), '.00', '') + N'* '
                                + @AmntTypeDesc
                        END + CHAR(10)
                      + CASE ISNULL(@TxfeAmnt, 0)
                            WHEN 0 THEN
                                N''
                            ELSE
                                N'مبلغ *کسر کارمزد* واریز وجه *'
                                + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @TxfeAmnt), 1), '.00', '') + N'* '
                                + @AmntTypeDesc
                        END + CHAR(10) + N'👈 *گام سوم* : 💡 *ارسال درخواست وجه* را فشار دهید';

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @ChatID AS '@chatid',
                           @PostExec AS '@cmndtext',
                           @OrdrCode AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @XMessage =
                (
                    SELECT TOP 1
                           om.FILE_ID AS '@fileid',
                           om.IMAG_TYPE AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                          AND om.RBCN_TYPE = '015'
                          AND om.IMAG_TYPE = '002'
                          AND om.STAT = '002'
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                );
                SET @XMessage.modify('insert sql:variable("@XTemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
            ELSE IF @MenuText = 'wallet::depositshop::bankcard'
            BEGIN
                SET @Message
                    = N'*انتخاب شماره حساب*' + CHAR(10) + CHAR(10)
                      + N'💡 لطفا یکی از *شماره حساب* های _خود_ را انتخاب کنید';

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @ChatID AS '@chatid',
                           @PostExec AS '@cmndtext'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @XMessage =
                (
                    SELECT TOP 1
                           om.FILE_ID AS '@fileid',
                           om.IMAG_TYPE AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                          AND om.RBCN_TYPE = '015'
                          AND om.IMAG_TYPE = '002'
                          AND om.STAT = '002'
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                );
                SET @XMessage.modify('insert sql:variable("@XTemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
            ELSE IF @MenuText = 'wallet::depositshop::bankcard::select'
            BEGIN
                SELECT @XTemp =
                (
                    SELECT 12 AS '@subsys',
                           '024' AS '@ordrtype',
                           '000' AS '@typecode',
                           @ChatID AS '@chatid',
                           @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @MenuText AS '@input',
                           0 AS '@ordrcode'
                    FOR XML PATH('Action'), ROOT('Cart')
                );
                EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
                -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
                SELECT @RsltCode = @XTemp.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)'),
                       @OrdrCode = @XTemp.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');

                IF @RsltCode = '002'
                BEGIN
                    -- قرار دادن شماره کارت مشتری برای درخواست واریز وجه
                    UPDATE o
                    SET o.SORC_CARD_NUMB_DNRM = b.CARD_NUMB
                    FROM dbo.[Order] o,
                         dbo.Service_Robot_Card_Bank a,
                         dbo.Robot_Card_Bank_Account b
                    WHERE o.CODE = @OrdrCode
                          AND a.RCBA_CODE = b.CODE
                          AND a.CODE = @ParamText;

                    SET @Message = N'شماره حساب انتخاب شد';
                END;
            END;
            ELSE IF @MenuText = 'wallet::depositshop::amount'
            BEGIN
                IF ISNULL(@ParamText, '') = ''
                BEGIN
                    SET @Message
                        = N'*انتخاب مبلغ واریز وجه*' + CHAR(10) + CHAR(10)
                          + N'💡 لطفا *مبلغ واریز وجه* را 👈 *انتخاب* یا ✏️ *وارد* کنید';

                    SET @XTemp =
                    (
                        SELECT @Rbid AS '@rbid',
                               @UssdCode AS '@ussdcode',
                               @ChatID AS '@chatid',
                               @PostExec AS '@cmndtext'
                        FOR XML PATH('RequestInLineQuery')
                    );
                    EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                         @XRet = @XTemp OUTPUT; -- xml

                    SET @XTemp =
                    (
                        SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                    );

                    SET @XMessage =
                    (
                        SELECT TOP 1
                               om.FILE_ID AS '@fileid',
                               om.IMAG_TYPE AS '@filetype',
                               @Message AS '@caption',
                               1 AS '@order'
                        FROM dbo.Organ_Media om
                        WHERE om.ROBO_RBID = @Rbid
                              AND om.RBCN_TYPE = '015'
                              AND om.IMAG_TYPE = '002'
                              AND om.STAT = '002'
                        FOR XML PATH('Complex_InLineKeyboardMarkup')
                    );
                    SET @XMessage.modify('insert sql:variable("@XTemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
                    SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
                END;
                ELSE /* اگر مبلغ توسط خود مشتری وارد میشود */
                BEGIN
                    IF ISNUMERIC(@ParamText) = 0
                    BEGIN
                        SET @Message = N'⭕ خطا : ورود اطلاعات نامعتبر، لطفا ورودی باید مبلغ باشد';
                        GOTO L$EndSP;
                    END;
                    ELSE IF NOT EXISTS
                         (
                             SELECT *
                             FROM dbo.Wallet w
                             WHERE (ISNULL(w.AMNT_DNRM, 0) - ISNULL(w.TEMP_AMNT_USE, 0)) >= @ParamText
                         )
                    BEGIN
                        SET @Message
                            = N'⭕ مبلغ وارد شده از کیف پول شما بیشتر می باشد، لطفا در وارد کردن اطلاعات دقت فرمایید';
                        GOTO L$EndSP;
                    END;

                    GOTO L$WalletDepositShopAmountSelect;
                END;
            END;
            ELSE IF @MenuText = 'wallet::depositshop::amount::select'
            BEGIN
                L$WalletDepositShopAmountSelect:
                SELECT @XTemp =
                (
                    SELECT 12 AS '@subsys',
                           '024' AS '@ordrtype',
                           '000' AS '@typecode',
                           @ChatID AS '@chatid',
                           @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @MenuText AS '@input',
                           0 AS '@ordrcode'
                    FOR XML PATH('Action'), ROOT('Cart')
                );
                EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
                -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
                SELECT @RsltCode = @XTemp.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)'),
                       @OrdrCode = @XTemp.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');

                IF @RsltCode = '002'
                BEGIN
                    -- قرار دادن شماره کارت مشتری برای درخواست واریز وجه
                    MERGE dbo.Order_Detail T
                    USING
                    (SELECT @ParamText AS DPST_AMNT, @OrdrCode AS ORDR_CODE) S
                    ON (T.ORDR_CODE = S.ORDR_CODE)
                    WHEN NOT MATCHED THEN
                        INSERT
                        (
                            ORDR_CODE,
                            ELMN_TYPE,
                            ORDR_CMNT,
                            ORDR_DESC,
                            EXPN_PRIC,
                            NUMB
                        )
                        VALUES
                        (S.ORDR_CODE, '001', N'درخواست واریز وجه', N'درخواست مبلغ برای واریز وجه به حساب مشتری',
                         S.DPST_AMNT, 1)
                    WHEN MATCHED THEN
                        UPDATE SET T.EXPN_PRIC = S.DPST_AMNT,
                                   T.NUMB = 1;
                    
                    -- بروزرسانی جدول درخواست وجه
                    UPDATE o
                    SET o.EXPN_AMNT =
                        (
                            SELECT SUM(od.EXPN_PRIC * od.NUMB)
                            FROM dbo.Order_Detail od
                            WHERE od.ORDR_CODE = o.CODE
                        ),
                        o.AMNT_TYPE = @AmntType
                    FROM dbo.[Order] o
                    WHERE o.CODE = @OrdrCode;
                    
                    SET @Message = N'مبلغ ذخیره شد';

                    IF @MenuText = 'wallet::depositshop::amount'
                    BEGIN
                        SELECT @PostExec = N'lesswletdshp';
                        GOTO L$WalletDepositShop;
                    --SET @Message = N'*ثبت مبلغ درخواست وجه*' + CHAR(10) +
                    --               N'*مبلغ* _درخواست وجه_ *شما* 💾 ثبت گردید، 💡 اگر مایل هستید، میتوانید با *انتخاب کردن* یا *وارد کردن* عدد مورد نظر، 💵 *مبلغ*  خود را ✏️ *ویرایش* کنید';
                    --SET @XTemp = (
                    --   SELECT @Rbid AS '@rbid'
                    --         ,@UssdCode AS '@ussdcode'
                    --         ,@ChatID AS '@chatid'
                    --         ,'lesswletdshp'  AS '@cmndtext'
                    --      FOR XML PATH('RequestInLineQuery')
                    --);
                    --EXEC dbo.CRET_ILQM_P @X = @XTemp, -- xml
                    --    @XRet = @XTemp OUTPUT; -- xml

                    --SET @XTemp = (
                    --   SELECT '1' AS '@order',
                    --          @XTemp
                    --      FOR XML PATH('InlineKeyboardMarkup')
                    --);

                    --SET @XMessage = (
                    --   SELECT TOP 1 
                    --          om.FILE_ID AS '@fileid', 
                    --          om.IMAG_TYPE AS '@filetype',
                    --          @Message AS '@caption',
                    --          1 AS '@order'
                    --     FROM dbo.Organ_Media om
                    --    WHERE om.ROBO_RBID = @Rbid
                    --      AND om.RBCN_TYPE = '015'
                    --      AND om.IMAG_TYPE = '002'
                    --      AND om.STAT = '002'
                    --      FOR XML PATH('Complex_InLineKeyboardMarkup')
                    --);
                    --SET @XMessage.modify('insert sql:variable("@XTemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
                    --SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
                    END;
                END;
            END;
            ELSE IF @MenuText = 'wallet::depositshop::sendrequest'
            BEGIN
                SELECT @XTemp =
                (
                    SELECT 12 AS '@subsys',
                           '024' AS '@ordrtype',
                           '000' AS '@typecode',
                           @ChatID AS '@chatid',
                           @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @MenuText AS '@input',
                           0 AS '@ordrcode'
                    FOR XML PATH('Action'), ROOT('Cart')
                );
                EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
                -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
                SELECT @RsltCode = @XTemp.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)'),
                       @OrdrCode = @XTemp.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');

                IF @RsltCode = '002'
                BEGIN /* ارسال پیام به حسابدار مربوط به درخواست واریز وجه */
                    SET @XTemp =
                    (
                        SELECT RBID AS '@rbid',
                               (
                                   SELECT o.CHAT_ID AS '@chatid',
                                          o.CODE AS '@code',
                                          o.ORDR_TYPE AS '@type'
                                   FROM dbo.[Order] o
                                   WHERE o.CODE = @OrdrCode
                                   FOR XML PATH('Order'), TYPE
                               )
                        FROM dbo.Robot
                        WHERE RBID = @Rbid
                        FOR XML PATH('Robot')
                    );
                    EXEC dbo.SEND_MEOJ_P @X = @XTemp, @XRet = @XTemp OUTPUT;
                END;

                SET @Message
                    = N'درخواست شما برای فروشگاه ارسال شد، بعد از پرداخت از طریق سامانه به شما اطلاع رسانی میکنیم';
            END;
            ELSE IF @MenuText = 'wallet::depositshop::cancelrequest'
            BEGIN
                SELECT @XTemp =
                (
                    SELECT 12 AS '@subsys',
                           '024' AS '@ordrtype',
                           '000' AS '@typecode',
                           @ChatID AS '@chatid',
                           @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @MenuText AS '@input',
                           0 AS '@ordrcode'
                    FOR XML PATH('Action'), ROOT('Cart')
                );
                EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
                -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
                SELECT @RsltCode = @XTemp.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)'),
                       @OrdrCode = @XTemp.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');

                IF @RsltCode = '002'
                BEGIN /* ارسال پیام به حسابدار مربوط به درخواست واریز وجه */
                    -- شما در این قسمت می توانید درخواست خود را انصراف بزنید
                    UPDATE dbo.[Order]
                    SET ORDR_STAT = '003'
                    WHERE CODE = @OrdrCode
                          AND ORDR_STAT = '001';
                    IF @@ROWCOUNT = 1
                        SET @Message = N'درخواست شما انصراف زده شد';
                    ELSE
                        SET @Message
                            = N'شما قادر به انصراف درخواست نیستید، یا درخواست شما توسط واحد حسابداری تایید شده یا قبلا خودتان درخواست را انصراف داده اید';
                END;
                ELSE
                BEGIN
                    SET @Message
                        = N'شما قادر به انصراف درخواست نیستید، یا درخواست شما توسط واحد حسابداری تایید شده یا قبلا خودتان درخواست را انصراف داده اید';
                END;
            END;
            ELSE IF @MenuText = 'wallet::depositshop::statusrequest'
            BEGIN
                PRINT 'Status Request';
            END;
            ELSE IF @MenuText = 'wallet::depositmembers'
            BEGIN
                PRINT 'depositmembers';
            END;
            ELSE IF @MenuText = 'wallet::historydeposits'
            BEGIN
                GOTO L$ReportWithdrawWallet;
            END;
        END;
        ELSE IF @MenuText IN ( 'wallet::withdrawshop', 'wallet::withdrawshop::processing',
                               'wallet::withdrawshop::bankcard', 'wallet::withdrawshop::pay',
                               'wallet::withdrawshop::bankcard::select', 'wallet::withdrawshop::rcptpay',
                               'wallet::withdrawshop::rcptpay::select', 'wallet::withdrawshop::rcptpay::delete',
                               'wallet::withdrawshop::rcptpay::confirm'
                             )
        BEGIN
            IF @MenuText = 'wallet::withdrawshop'
            BEGIN
                L$WalletWithDrawShop:
                IF @ParamText NOT LIKE '%,%'
                    SET @OrdrCode = @ParamText;

                SET @Message
                    = N'*انتخاب شماره حساب*' + CHAR(10) + CHAR(10)
                      +
                      (
                          SELECT N'📓 شماره درخواست *برداشت* وجه *' + CAST(o.CODE AS VARCHAR(30)) + N'*' + CHAR(10)
                                 + N'🖥️ [ کد سیستم ] *' + CAST(o.ORDR_TYPE_NUMB AS VARCHAR(30)) + '-' + o.ORDR_TYPE
                                 + N'*' + CHAR(10) + CHAR(10) + N'👈 شماره کارت مبدا ✅' + CHAR(10) + N'💳 *'
                                 + dbo.GET_CRDT_U(o.SORC_CARD_NUMB_DNRM) + N'*' + CHAR(10) + CHAR(10)
                                 + N'👈 شماره کارت مقصد ✅' + CHAR(10) + N'💳 *' + dbo.GET_CRDT_U(o.DEST_CARD_NUMB_DNRM)
                                 + N'*' + CHAR(10) + N'👤 اطلاعات مشتری : *' + ou.OWNR_NAME + N'*' + CHAR(10)
                                 + N'📅 تاریخ درخواست : *' + dbo.GET_MTOS_U(ou.STRT_DATE) + N' '
                                 + CAST(CAST(ou.STRT_DATE AS TIME(0)) AS VARCHAR(5)) + N'*' + CHAR(10)
                                 + N'💵 مبلغ درخواستی : *'
                                 + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, ou.DEBT_DNRM), 1), '.00', '') + N'* '
                                 + @AmntTypeDesc + CHAR(10) + N'📱 شماره تلفن : *' + ou.CELL_PHON + N'*'
                          FROM dbo.[Order] o,
                               dbo.[Order] ou
                          WHERE o.CODE = @OrdrCode
                                AND o.ORDR_CODE = ou.CODE
                          FOR XML PATH('')
                      );

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @ChatID AS '@chatid',
                           @PostExec AS '@cmndtext',
                           @ParamText AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @XMessage =
                (
                    SELECT TOP 1
                           om.FILE_ID AS '@fileid',
                           om.IMAG_TYPE AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                          AND om.RBCN_TYPE = '015'
                          AND om.IMAG_TYPE = '002'
                          AND om.STAT = '002'
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                );
                SET @XMessage.modify('insert sql:variable("@XTemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
            --ELSE IF @MenuText = 'wallet:withdrawshop::processing'
            --BEGIN
            --   -- بررسی اینکه درخواست مشتری هنوز پابرجا هست یا خیر
            --   IF EXISTS (SELECT * FROM dbo.[Order] o WHERE o.ORDR_CODE = @ParamText AND o.ORDR_STAT NOT IN ( '003', '004' ) AND o.ORDR_TYPE = '024')
            --   BEGIN
            --      -- ارجاع درخواست واحد حسابداری برای آماده سازی برای لیست پرداخت
            --      UPDATE dbo.[Order] 
            --         SET ORDR_STAT = '002'              
            --       WHERE CODE = @ParamText
            --         AND ORDR_STAT = '001'
            --         AND ORDR_TYPE = '017';

            --      if @@ROWCOUNT != 1
            --      BEGIN 
            --         SET @Message = N'برای *ثبت درخواست پرداخت* _مشکلی_ به وجود آمده است، لطفا بررسی کنید';
            --         GOTO L$EndSP;
            --      END 

            --      SET @Message = N'درخواست توسط *شما* در _لیست پرداخت_ قرار گرفت';

            --      SET @XTemp = (
            --         SELECT @Rbid AS '@rbid'
            --               ,@UssdCode AS '@ussdcode'
            --               ,@ChatID AS '@chatid'
            --               ,@PostExec  AS '@cmndtext'
            --               ,@ParamText AS '@ordrcode'
            --            FOR XML PATH('RequestInLineQuery')
            --      );
            --      EXEC dbo.CRET_ILQM_P @X = @XTemp, -- xml
            --          @XRet = @XTemp OUTPUT; -- xml

            --      SET @XTemp = (
            --         SELECT '1' AS '@order',
            --                @XTemp
            --            FOR XML PATH('InlineKeyboardMarkup')
            --      );

            --      SET @XMessage = (
            --         SELECT TOP 1 
            --                om.FILE_ID AS '@fileid', 
            --                om.IMAG_TYPE AS '@filetype',
            --                @Message AS '@caption',
            --                1 AS '@order'
            --           FROM dbo.Organ_Media om
            --          WHERE om.ROBO_RBID = @Rbid
            --            AND om.RBCN_TYPE = '015'
            --            AND om.IMAG_TYPE = '002'
            --            AND om.STAT = '002'
            --            FOR XML PATH('Complex_InLineKeyboardMarkup')
            --      );
            --      SET @XMessage.modify('insert sql:variable("@XTemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
            --      SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            --   END 
            --   ELSE
            --   BEGIN
            --      SET @Message = N'برای *ثبت درخواست پرداخت* _مشکلی_ به وجود آمده است، لطفا بررسی کنید';
            --   END 
            --END 
            ELSE IF @MenuText = 'wallet::withdrawshop::bankcard'
            BEGIN
                SET @Message
                    = N'*انتخاب شماره حساب*' + CHAR(10) + CHAR(10)
                      + N'💡 لطفا یکی از *شماره حساب* های _خود_ را انتخاب کنید';

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @ChatID AS '@chatid',
                           @PostExec AS '@cmndtext',
                           @ParamText AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @XMessage =
                (
                    SELECT TOP 1
                           om.FILE_ID AS '@fileid',
                           om.IMAG_TYPE AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                          AND om.RBCN_TYPE = '015'
                          AND om.IMAG_TYPE = '002'
                          AND om.STAT = '002'
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                );
                SET @XMessage.modify('insert sql:variable("@XTemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
            ELSE IF @MenuText = 'wallet::withdrawshop::bankcard::select'
            BEGIN
                SELECT @OrdrCode = CASE id
                                       WHEN 1 THEN
                                           Item
                                       ELSE
                                           @OrdrCode
                                   END,
                       @Said = CASE id
                                   WHEN 2 THEN
                                       Item
                                   ELSE
                                       @Said
                               END
                FROM dbo.SplitString(@ParamText, ',');

                -- قرار دادن شماره کارت حسابدار برای درخواست واریز وجه
                UPDATE o
                SET o.SORC_CARD_NUMB_DNRM = b.CARD_NUMB
                FROM dbo.[Order] o,
                     dbo.Service_Robot_Card_Bank a,
                     dbo.Robot_Card_Bank_Account b
                WHERE o.CODE = @OrdrCode
                      AND a.RCBA_CODE = b.CODE
                      AND a.CODE = @Said;

                SELECT @ParamText = @OrdrCode;
                GOTO L$WalletWithDrawShop;
            END;
            ELSE IF @MenuText = 'wallet::withdrawshop::pay'
            BEGIN
                SET @Message = N'';
            END;
            ELSE IF @MenuText = 'wallet::withdrawshop::rcptpay'
            BEGIN
                IF @PhotoFileId IS NOT NULL
                BEGIN
                    SELECT @CallBackQuery = '001',
                           @MenuText = N'No Text';
                    GOTO L$SaveReciptWithdraw;
                END;
                SET @Message
                    = N'*ارسال تصویر رسید پرداخت شبا*' + CHAR(10) + CHAR(10)
                      + N'💡 لطفا *فایل رسید پرداخت شبا* را انتخاب کنید';

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @UssdCode AS '@ussdcode',
                           @ChatID AS '@chatid',
                           @PostExec AS '@cmndtext',
                           @ParamText AS '@ordrcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @XMessage =
                (
                    SELECT TOP 1
                           om.FILE_ID AS '@fileid',
                           om.IMAG_TYPE AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                          AND om.RBCN_TYPE = '015'
                          AND om.IMAG_TYPE = '002'
                          AND om.STAT = '002'
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                );
                SET @XMessage.modify('insert sql:variable("@XTemp") as first into (//Complex_InLineKeyboardMarkup)[1]');
                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
            ELSE IF @MenuText = 'wallet::withdrawshop::rcptpay::select'
            BEGIN
                -- بدست آوردن شماره درخواست رسید پرداختی
                SET @Message =
                (
                    SELECT N'📥 رسید ارسال شده توسط شما' + CHAR(10) + CHAR(10) + N'📋  صورتحساب شما' + CHAR(10)
                           + N'👈  شماره فاکتور *' + CAST(os.ORDR_CODE AS NVARCHAR(30)) + N'*' + CHAR(10) + CHAR(10)
                           + CASE os.CONF_STAT
                                 WHEN '001' THEN
                                     N'⛔️ '
                                 WHEN '002' THEN
                                     N'✅ '
                                 WHEN '003' THEN
                                     N'⌛️ '
                             END + N'وضعیت رسید [ *' + c.DOMN_DESC + N'* ]' + CHAR(10)
                           + CASE os.CONF_STAT
                                 WHEN '001' THEN
                                     N'👈 [ دلیل عدم تایید ] *' + ISNULL(os.CONF_DESC, N'دلیلی ثبت نشده') + N'*'
                                     + CHAR(10) + N'📆 [ تاریخ عدم تایید ] *' + dbo.GET_MTOS_U(os.CONF_DATE) + N'*'
                                     + CHAR(10)
                                 WHEN '002' THEN
                                     N'💵 [ مبلغ ] *'
                                     + REPLACE(
                                                  CONVERT(
                                                             NVARCHAR,
                                                             CONVERT(
                                                                        MONEY,
                                                                        ISNULL(
                                                                                  os.AMNT,
                                                                                  N'مبلغ متناسب با رسید ارسال شده'
                                                                              )
                                                                    ),
                                                             1
                                                         ),
                                                  '.00',
                                                  ''
                                              ) + N'* [ *' + @AmntTypeDesc + N'* ] ' + CHAR(10)
                                     + N'📆 [ تاریخ تایید ] *' + dbo.GET_MTOS_U(os.CONF_DATE) + N'*' + CHAR(10)
                                     + N'📃 [ شماره پیگیری ] *' + ISNULL(os.TXID, '0') + N'*' + CHAR(10)
                                 WHEN '003' THEN
                                     N' '
                             END
                    FROM dbo.Order_State os,
                         dbo.[D$CONF] c
                    WHERE os.CODE = @ParamText
                          AND os.CONF_STAT = c.VALU
                );

                -- اضافه کردن منوهای مربوطه
                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessinforcptpay' AS '@cmndtext',
                           @ParamText AS '@odstcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           --@Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );

                SET @XMessage =
                (
                    SELECT TOP 1
                           os.FILE_ID AS '@fileid',
                           os.FILE_TYPE AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Order_State os
                    WHERE os.CODE = @ParamText
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                );
                SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
            ELSE IF @MenuText = 'wallet::withdrawshop::rcptpay::delete'
            BEGIN
                -- بدست آوردن شماره درخواست حسابداری         
                SELECT @ParamText = os.ORDR_CODE,
                       @Said = os.CODE,
                       @PostExec = N'lesswletwshprcpt'
                FROM dbo.Order_State os
                WHERE os.CODE = @ParamText;
                DELETE dbo.Order_State
                WHERE CODE = @Said
                      AND CONF_STAT = '003';
                GOTO L$WalletWithDrawShop;
            END;
            ELSE IF @MenuText = 'wallet::withdrawshop::rcptpay::confirm'
            BEGIN
                -- بدست آوردن شماره درخواست واریز وجه مشتری
                SELECT @OrdrCode = ORDR_CODE
                FROM dbo.[Order]
                WHERE CODE = @ParamText;

                SET @XTemp =
                (
                    SELECT @OrdrCode AS '@ordrcode',
                           '013' AS '@rcptmtod',
                           '002' AS '@dircall'
                    FOR XML PATH('Payment')
                );

                EXEC dbo.SAVE_PYMT_P @X = @XTemp,           -- xml
                                     @xRet = @XTemp OUTPUT; -- xml

                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
            END;
        END;
        -- امتیاز دهی به کالا ها توسط مشتریان
        ELSE IF @MenuText IN ( 'feedback:product', 'feedback:product:rating', 'feedback:product:rate' )
        BEGIN
            IF @MenuText = 'feedback:product'
            BEGIN
                SELECT @TarfCode = CASE id
                                       WHEN 1 THEN
                                           Item
                                       ELSE
                                           @TarfCode
                                   END,
                       @SysCode = CASE id
                                      WHEN 2 THEN
                                          Item
                                      ELSE
                                          @SysCode
                                  END
                FROM dbo.SplitString(@ParamText, ',');

                IF NOT EXISTS
                (
                    SELECT *
                    FROM dbo.Service_Robot_Product_Feedback
                    WHERE SRBT_ROBO_RBID = @Rbid
                          AND CHAT_ID = @ChatID
                          AND TARF_CODE_DNRM = @TarfCode
                )
                    INSERT INTO dbo.Service_Robot_Product_Feedback
                    (
                        SRBT_SERV_FILE_NO,
                        SRBT_ROBO_RBID,
                        RBPR_CODE,
                        CODE
                    )
                    SELECT sr.SERV_FILE_NO,
                           sr.ROBO_RBID,
                           rp.CODE,
                           dbo.GNRT_NVID_U()
                    FROM dbo.Service_Robot sr,
                         dbo.Robot_Product rp
                    WHERE sr.ROBO_RBID = @Rbid
                          AND sr.CHAT_ID = @ChatID
                          AND rp.ROBO_RBID = sr.ROBO_RBID
                          AND rp.TARF_CODE = @TarfCode;

                UPDATE dbo.Service_Robot_Product_Feedback
                SET NAME_NOT_VLID = CASE @SysCode
                                        WHEN '001' THEN
                                            CASE ISNULL(NAME_NOT_VLID, '001')
                                                WHEN '001' THEN
                                                    '002'
                                                ELSE
                                                    '001'
                                            END
                                        ELSE
                                            NAME_NOT_VLID
                                    END,
                    IMAG_NOT_GOOD = CASE @SysCode
                                        WHEN '002' THEN
                                            CASE ISNULL(IMAG_NOT_GOOD, '001')
                                                WHEN '001' THEN
                                                    '002'
                                                ELSE
                                                    '001'
                                            END
                                        ELSE
                                            IMAG_NOT_GOOD
                                    END,
                    INFO_NOT_TRUE = CASE @SysCode
                                        WHEN '003' THEN
                                            CASE ISNULL(INFO_NOT_TRUE, '001')
                                                WHEN '001' THEN
                                                    '002'
                                                ELSE
                                                    '001'
                                            END
                                        ELSE
                                            INFO_NOT_TRUE
                                    END,
                    DESC_NOT_TRUE = CASE @SysCode
                                        WHEN '004' THEN
                                            CASE ISNULL(DESC_NOT_TRUE, '001')
                                                WHEN '001' THEN
                                                    '002'
                                                ELSE
                                                    '001'
                                            END
                                        ELSE
                                            DESC_NOT_TRUE
                                    END,
                    PROD_NOT_ORGN = CASE @SysCode
                                        WHEN '005' THEN
                                            CASE ISNULL(PROD_NOT_ORGN, '001')
                                                WHEN '001' THEN
                                                    '002'
                                                ELSE
                                                    '001'
                                            END
                                        ELSE
                                            PROD_NOT_ORGN
                                    END,
                    PROD_HAVE_DUPL = CASE @SysCode
                                         WHEN '006' THEN
                                             CASE ISNULL(PROD_HAVE_DUPL, '001')
                                                 WHEN '001' THEN
                                                     '002'
                                                 ELSE
                                                     '001'
                                             END
                                         ELSE
                                             PROD_HAVE_DUPL
                                     END
                WHERE SRBT_ROBO_RBID = @Rbid
                      AND CHAT_ID = @ChatID
                      AND TARF_CODE_DNRM = @TarfCode;

                GOTO L$FeedbackProd;
            END;
            ELSE IF @MenuText = 'feedback:product:rating'
            BEGIN
                SET @TarfCode = @ParamText;
                L$RateProd:
                -- To Do List On Task
                ---PRINT 'Feedback Product';

                SET @XTemp =
                (
                    SELECT @Rbid AS '@rbid',
                           @ChatID AS '@chatid',
                           @UssdCode AS '@ussdcode',
                           'lessrateprod' AS '@cmndtext',
                           @TarfCode AS '@tarfcode'
                    FOR XML PATH('RequestInLineQuery')
                );
                EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                     @XRet = @XTemp OUTPUT; -- xml

                SET @XTemp =
                (
                    SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
                );
                
                SET @Message = 
					CASE 
						WHEN EXISTS (SELECT * FROM dbo.Service_Robot_Product_Rating WHERE SRBT_ROBO_RBID = @Rbid AND CHAT_ID = @ChatID AND TARF_CODE_DNRM = @TarfCode) THEN 
							 (SELECT N'☺️ امتیاز شما به این کالا *' + CAST(RATE_NUMB AS VARCHAR(1)) + N'* ⭐ هست.'
							    FROM dbo.Service_Robot_Product_Rating 
							   WHERE SRBT_ROBO_RBID = @Rbid 
							     AND CHAT_ID = @ChatID 
							     AND TARF_CODE_DNRM = @TarfCode 
							     FOR XML PATH(''))
					    ELSE N'لطفا نظر خود را درمورد محصول برای ما وارد کنید'
					END ;

                SET @XMessage =
                (
                    SELECT TOP 1
                           om.FILE_ID AS '@fileid',
                           om.IMAG_TYPE AS '@filetype',
                           @Message AS '@caption',
                           1 AS '@order'
                    FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                          AND om.RBCN_TYPE = '021'
                          AND om.IMAG_TYPE = '002'
                          AND om.STAT = '002'
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
                );
                SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

                SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END;
            ELSE IF @MenuText = 'feedback:product:rate'
            BEGIN
                SELECT @TarfCode = CASE id
                                       WHEN 1 THEN
                                           Item
                                       ELSE
                                           @TarfCode
                                   END,
                       @SysCode = CASE id
                                      WHEN 2 THEN
                                          Item
                                      ELSE
                                          @SysCode
                                  END
                FROM dbo.SplitString(@ParamText, ',');

                IF NOT EXISTS
                (
                    SELECT *
                    FROM dbo.Service_Robot_Product_Rating
                    WHERE SRBT_ROBO_RBID = @Rbid
                          AND CHAT_ID = @ChatID
                          AND TARF_CODE_DNRM = @TarfCode
                )
                BEGIN
                    INSERT INTO dbo.Service_Robot_Product_Rating
                    (
                        SRBT_SERV_FILE_NO,
                        SRBT_ROBO_RBID,
                        RBPR_CODE,
                        CODE
                    )
                    SELECT sr.SERV_FILE_NO,
                           sr.ROBO_RBID,
                           rp.CODE,
                           dbo.GNRT_NVID_U()
                    FROM dbo.Service_Robot sr,
                         dbo.Robot_Product rp
                    WHERE sr.ROBO_RBID = @Rbid
                          AND sr.CHAT_ID = @ChatID
                          AND rp.ROBO_RBID = sr.ROBO_RBID
                          AND rp.TARF_CODE = @TarfCode;
                END;

                UPDATE dbo.Service_Robot_Product_Rating
                SET RATE_NUMB = @SysCode
                WHERE SRBT_ROBO_RBID = @Rbid
                      AND CHAT_ID = @ChatID
                      AND TARF_CODE_DNRM = @TarfCode;

                GOTO L$RateProd;
            END;
        END;
        -- مدیریت لیست محصولات موجود
        ELSE IF @MenuText IN ('product::showlistall', 'product::showlistallbutton', 'product::showimageall')
        BEGIN
			IF @MenuText = 'product::showlistall'
			BEGIN
				WITH GROPS (GEXP_CODE, CODE, GROP_DESC, LEVEL)
                AS (SELECT gp.GEXP_CODE,
                           gp.CODE,
                           gp.GROP_DESC,
                           0 AS Level
                    FROM iScsc.dbo.Group_Expense gp
                    WHERE gp.CODE = CAST(ISNULL(@ParamText, gp.CODE) AS BIGINT)
                          AND gp.GROP_TYPE = '001' -- Groups
                          AND gp.STAT = '002' -- Active
                    UNION ALL
                    SELECT gc.GEXP_CODE,
                           gc.CODE,
                           gc.GROP_DESC,
                           LEVEL + 1
                    FROM iScsc.dbo.Group_Expense gc,
                         GROPS g
                    WHERE gc.GEXP_CODE = g.CODE
                          AND gc.STAT = '002' -- Active
                          AND gc.GROP_TYPE = '001' -- Groups
                )
                SELECT @XTemp
                    =
                    (
						SELECT N'🗂️ ' + rpg.GROP_TEXT_DNRM + N' ... ' + CHAR(10) + CHAR(10) +
							   (
								SELECT DISTINCT --N'./' + @UssdCode + N';infoprod-' + CAST(rp.TARF_CODE AS NVARCHAR(100))
									   --+ N'$lessinfoprod#' AS '@data',
									   --ROW_NUMBER() OVER (ORDER BY rp.TARF_TEXT_DNRM) AS '@order',
									   CHAR(9) + N'📦  *' + rp.TARF_TEXT_DNRM + N'* ( کد : *' + rp.TARF_CODE + N'* )' + CHAR(10) + CHAR(9) + CHAR(9) + 
									   N'💵 ( *'
									   + REPLACE(
													CONVERT(
															   NVARCHAR,
															   CONVERT(MONEY, rp.EXPN_PRIC_DNRM + rp.EXTR_PRCT_DNRM),
															   1
														   ),
													'.00',
													''
												) + N'* ) ' + @AmntTypeDesc + CHAR(10)
								FROM dbo.Robot_Product rp,
									 GROPS g
								WHERE rp.ROBO_RBID = @Rbid
									  AND iScsc.dbo.LINK_GROP_U(g.CODE, rp.GROP_CODE_DNRM) = 1
									  AND rp.STAT = '002'
									  AND rp.CRNT_NUMB_DNRM > 0
									  AND rp.GROP_TEXT_DNRM = rpg.GROP_TEXT_DNRM
								--GROUP BY rp.GROP_TEXT_DNRM
								--ORDER BY rp.TARF_TEXT_DNRM
								FOR XML PATH('')
							   ) + char(10)
						  FROM dbo.Robot_Product rpg,
						       GROPS g
						 WHERE rpg.ROBO_RBID = @Rbid
                          AND iScsc.dbo.LINK_GROP_U(g.CODE, rpg.GROP_CODE_DNRM) = 1
                          AND rpg.STAT = '002'
                          AND rpg.CRNT_NUMB_DNRM > 0
                        GROUP BY rpg.GROP_TEXT_DNRM
                        ORDER BY rpg.GROP_TEXT_DNRM
                        FOR XML PATH('')
                        --FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                    );
                --SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;
                
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp)
                
                -- نمایش تمامی محصولات این قسمت
				-- Next Step #. Show Products
				-- Static
				SET @XTemp =
				(
					SELECT dbo.STR_FRMT_U('./{0};product::showlistallbutton-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
						   @Index AS '@order',
						   N'👈 انتخاب محصولات' AS "text()"
					FOR XML PATH('InlineKeyboardButton')					
				);
				SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           @Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                SET @Index += 1;
                
				SET @X =
				(
					SELECT dbo.STR_FRMT_U('./{0};product::showlistall-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
						   @Index AS '@order',
						   N'👈 بروزرسانی مجدد' AS "text()"
					FOR XML PATH('InlineKeyboardButton')
				);
				SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
				SET @Index += 1;
				
				SET @X =
				(
					SELECT dbo.STR_FRMT_U('./{0};product::showimageall-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
						   @Index AS '@order',
						   N'👈 عکس محصولات' AS "text()"
					FOR XML PATH('InlineKeyboardButton')
				);
				SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
				SET @Index += 1;
            
            -- Next Step #. More Menu
            -- Static
            SET @X = (
               SELECT dbo.STR_FRMT_U('./{0};-$del#', @UssdCode ) AS '@data',
                      @index AS '@order',
                      N'⛔ بستن' AS "text()"
                  FOR XML PATH('InlineKeyboardButton')
            );
            SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
            SET @Index += 1;
                
            SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
			END 
			ELSE IF @MenuText = 'product::showlistallbutton'
			BEGIN
				WITH GROPS (GEXP_CODE, CODE, GROP_DESC, LEVEL)
                AS (SELECT gp.GEXP_CODE,
                           gp.CODE,
                           gp.GROP_DESC,
                           0 AS Level
                    FROM iScsc.dbo.Group_Expense gp
                    WHERE gp.CODE = CAST(ISNULL(@ParamText, gp.CODE) AS BIGINT)
                          AND gp.GROP_TYPE = '001' -- Groups
                          AND gp.STAT = '002' -- Active
                    UNION ALL
                    SELECT gc.GEXP_CODE,
                           gc.CODE,
                           gc.GROP_DESC,
                           LEVEL + 1
                    FROM iScsc.dbo.Group_Expense gc,
                         GROPS g
                    WHERE gc.GEXP_CODE = g.CODE
                          AND gc.STAT = '002' -- Active
                          AND gc.GROP_TYPE = '001' -- Groups
                )
                SELECT @XTemp
                    =
                    (
                        SELECT N'./' + @UssdCode + N';infoprod-' + CAST(T.TARF_CODE AS NVARCHAR(100))
                               + N'$lessinfoprod#' AS '@data',
                               ROW_NUMBER() OVER (ORDER BY T.TARF_TEXT_DNRM) AS '@order',
                               N'📦  ' + SUBSTRING(T.TARF_TEXT_DNRM, 1, 25) + CASE WHEN LEN(T.TARF_TEXT_DNRM) > 25 THEN N' ...' ELSE N'' END + N' ( قیمت : '
                               + REPLACE( CONVERT( NVARCHAR, CONVERT(MONEY, T.EXPN_PRIC_DNRM + T.EXTR_PRCT_DNRM), 1 ), '.00', '' ) + N' ) ' + @AmntTypeDesc
                        FROM (SELECT DISTINCT rp.TARF_CODE, rp.TARF_TEXT_DNRM, rp.EXPN_PRIC_DNRM, rp.EXTR_PRCT_DNRM
                        FROM dbo.Robot_Product rp,
                             GROPS g
                        WHERE rp.ROBO_RBID = @Rbid
                              AND iScsc.dbo.LINK_GROP_U(g.CODE, rp.GROP_CODE_DNRM) = 1
                              AND rp.STAT = '002'
                              AND rp.CRNT_NUMB_DNRM > 0
                        --ORDER BY rp.TARF_TEXT_DNRM
                        --FOR XML PATH('')
                        ) T
                        FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
                    );
                SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;
                
                SET @XTemp =
                (
                    SELECT '1' AS '@order',
                           --@Message AS '@caption',
                           @XTemp
                    FOR XML PATH('InlineKeyboardMarkup')
                );
                
                -- نمایش تمامی محصولات این قسمت
				-- Next Step #. Show Products
				-- Static
				SET @X =
				(
					SELECT dbo.STR_FRMT_U('./{0};product::showlistall-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
						   @Index AS '@order',
						   N'📋 لیست محصولات' AS "text()"
					FOR XML PATH('InlineKeyboardButton')
				);
				SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
                SET @Index += 1;
                
                SET @X =
				(
					SELECT dbo.STR_FRMT_U('./{0};product::showlistallbutton-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
						   @Index AS '@order',
						   N'👈 بروزرسانی مجدد' AS "text()"
					FOR XML PATH('InlineKeyboardButton')
				);
				SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
				SET @Index += 1;
				
				SET @X =
				(
					SELECT dbo.STR_FRMT_U('./{0};product::showimageall-{1}$del#', @UssdCode + N',' + @ParamText) AS '@data',
						   @Index AS '@order',
						   N'👈 عکس محصولات' AS "text()"
					FOR XML PATH('InlineKeyboardButton')
				);
				SET @XTemp.modify('insert sql:variable("@X") as last into (//InlineKeyboardMarkup)[1]');
				SET @Index += 1;
                
                SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
			END 
			ELSE IF @MenuText = 'product::showimageall'
			BEGIN
				WITH GROPS (GEXP_CODE, CODE, GROP_DESC, LEVEL)
                AS (SELECT gp.GEXP_CODE,
                           gp.CODE,
                           gp.GROP_DESC,
                           0 AS Level
                    FROM iScsc.dbo.Group_Expense gp
                    WHERE gp.CODE = CAST(ISNULL(@ParamText, gp.CODE) AS BIGINT)
                          AND gp.GROP_TYPE = '001' -- Groups
                          AND gp.STAT = '002' -- Active
                    UNION ALL
                    SELECT gc.GEXP_CODE,
                           gc.CODE,
                           gc.GROP_DESC,
                           LEVEL + 1
                    FROM iScsc.dbo.Group_Expense gc,
                         GROPS g
                    WHERE gc.GEXP_CODE = g.CODE
                          AND gc.STAT = '002' -- Active
                          AND gc.GROP_TYPE = '001' -- Groups
                )
                SELECT @XTemp
                    =
                    (
						SELECT T.FILE_ID AS '@fileid',
                               T.FILE_TYPE AS '@filetype',
                               N'📦  *' + T.TARF_TEXT_DNRM + N'* ( کد : *' + T.TARF_CODE + N'* )' AS '@caption',
                               ROW_NUMBER() OVER (ORDER BY T.CODE) AS '@order',
                               (
								SELECT dbo.STR_FRMT_U('./{0};infoprod-{1}$del#', @UssdCode + N',' + T.TARF_CODE) AS '@data',
									   @Index AS '@order',
									   N'👈 اطلاعات محصول' AS "text()"
								FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup'), TYPE
                               )
                         FROM
                         (SELECT DISTINCT rp.CODE, rp.TARF_CODE, rp.TARF_TEXT_DNRM, rpp.FILE_ID, rpp.FILE_TYPE
						  FROM dbo.Robot_Product rp, dbo.Robot_Product_Preview rpp,
						       GROPS g
						 WHERE rp.ROBO_RBID = @Rbid
						   AND rp.code = rpp.RBPR_CODE
                           AND iScsc.dbo.LINK_GROP_U(g.CODE, rp.GROP_CODE_DNRM) = 1                          
                           AND rp.STAT = '002'
                           AND rp.CRNT_NUMB_DNRM > 0
                           AND rpp.ORDR IN (SELECT MIN(rppt.ORDR) FROM dbo.Robot_Product_Preview rppt WHERE rppt.RBPR_CODE = rp.CODE)
                         --ORDER BY rp.TARF_TEXT_DNRM
                         ) T
                        ORDER BY t.TARF_TEXT_DNRM
                        FOR XML PATH('Complex_InLineKeyboardMarkup'), ROOT('Message')
                    );
                --SELECT @Index = @XTemp.value('count(//InlineKeyboardButton)', 'INT') + 1;
                
                IF @XTemp IS NOT NULL                 
                  SET @Message = CONVERT(NVARCHAR(MAX), @XTemp)
                ELSE
                  SET @Message = N'متاسفانه در این گروه محصولات عکسی ثبت نشده';
			END 
        END 
        ELSE IF @MenuText IN (
            -- ارسال پیام به مدیریت فروشگاه
            'mailbox::sendingbox::sendto::mngrshop', 'mailbox::sendingbox::delete::mngrshop', 'mailbox::back::mngrshop',
            'mailbox::inbox::show::readysendto::mngrshop', 'mailbox::inbox::delete::readysendto::mngrshop', 'mailbox::inbox::show::sendedto::mngrshop',
            'mailbox::sendedbox::show::mngrshop', 'mailbox::sendingbox::show::mngrshop',
            'mailbox::trysend::sendto::mngrshop',
            -- ارسال پیام به مدیریت تیم پشتیبانی فروشگاه
            'mailbox::sendingbox::sendto::softteam', 'mailbox::sendingbox::delete::softteam', 'mailbox::back::softteam',
            'mailbox::inbox::show::readysendto::softteam', 'mailbox::inbox::delete::readysendto::softteam', 'mailbox::inbox::show::sendedto::softteam',
            'mailbox::sendedbox::show::softteam', 'mailbox::sendingbox::show::softteam',
            'mailbox::trysend::sendto::softteam',
            -- ارسال پیام به مدیریت تبلیغات فروشگاه
            'mailbox::sendingbox::sendto::advteam', 'mailbox::sendingbox::delete::advteam', 'mailbox::back::advteam',
            'mailbox::inbox::show::readysendto::advteam', 'mailbox::inbox::delete::readysendto::advteam', 'mailbox::inbox::show::sendedto::advteam',
            'mailbox::sendedbox::show::advteam', 'mailbox::sendingbox::show::advteam',
            'mailbox::sendingbox::aprv::sendto::advteam', 'mailbox::sendingbox::disaprv::sendto::advteam',
            'mailbox::trysend::sendto::advteam', 'mailbox::sendingbox::whois::sendto::advteam',
            'mailbox::sendingbox::now::sendto::advteam', 'mailbox::sendingbox::anothertime::sendto::advteam',
            'mailbox::sendedbox::menuadv::like::advteam', 'mailbox::sendedbox::menuadv::dislike::advteam',
            'mailbox::sendedbox::menuadv::rate::advteam',
            -- ارسال پیام کمپین تبلیغات فروشگاه
            'mailbox::sendingbox::sendto::advcamp', 'mailbox::sendingbox::delete::advcamp', 'mailbox::back::advcamp',
            'mailbox::inbox::show::readysendto::advcamp', 'mailbox::inbox::delete::readysendto::advcamp', 'mailbox::inbox::show::sendedto::advcamp',
            'mailbox::sendingbox::acpt::advcamp', 'mailbox::sendingbox::cncl::advcamp',
            'mailbox::sendedbox::show::advcamp', 'mailbox::sendingbox::show::advcamp',
            'mailbox::trysend::sendto::advcamp',
            -- صندوق پیام های دریافتی
            'mailbox::inbox::new', 'mailbox::inbox::read', 'mailbox::inbox::adv', 'mailbox::inbox::shop', 'mailbox::inbox::overhead', 'mailbox::inbox::softwareteam',
            'mailbox::back',
            'mailbox::inbox::show::rplymesg','mailbox::inbox::show::advteam', 'mailbox::inbox::show::advcamp'
        )
        BEGIN
            -- ارسال پیام به مدیریت فروشگاه
            -- مدیریت پیام آماده ارسال
            -- ##############################
            IF @MenuText LIKE 'mailbox::sendingbox::sendto::%'
            BEGIN
               L$TrySendMessage:
               -- اگر متن نیاز به منویی داشته باشد که بخواهیم برای مخاطب ارسال کنیم
               IF @UssdCode IN ('*1*11*1*3#' /* مدیریت واحد تبلیغات فروشگاه */, '*1*11*1*4#' /* مدیریت واحد کمپین تبلیغات */)
               BEGIN
                  SET @QueryStatement = 
                      CASE @UssdCode
                           WHEN '*1*11*1*3#' THEN 'moremenumailadvteam'
                           WHEN '*1*11*1*4#' THEN 'moremenumailadvcamp'
                      END;
                      
                  SET @XTemp =
                  (
                      SELECT @Rbid AS '@rbid',
                             @ChatID AS '@chatid',
                             @UssdCode AS '@ussdcode',
                             @QueryStatement AS '@cmndtext',
                             @ParamText as '@param'
                      FOR XML PATH('RequestInLineQuery')
                  );
                  EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                       @XRet = @XTemp OUTPUT; -- xml
     
                  SET @XTemp =
                  (
                      SELECT '1' AS '@order', 
                             @XTemp 
                         FOR XML PATH('InlineKeyboardMarkup')
                  );
               END 
               ELSE
                  SET @XTemp = NULL;
               
               IF @UssdCode IN ('*1*11*1*1#', '*1*11*1*2#', '*1*11*1*3#')
               BEGIN
                  UPDATE dbo.Service_Robot_Replay_Message
                     SET SEND_STAT = '005',
                         INLN_KEYB_DNRM = @XTemp
                   WHERE HEDR_CODE = @ParamText;
               END 
               ELSE IF @UssdCode IN ('*1*11*1*4#')
               BEGIN
                  -- Create Loop for Send Advertising Camp for any customers
                  INSERT INTO dbo.Send_Advertising ( ROBO_RBID ,ORDR_CODE ,ID ,PAKT_TYPE , FILE_ID,TEXT_MESG ,STAT ,TRGT_PROC_STAT ,INLN_KEYB_DNRM )
                  SELECT @Rbid,
                         o.code,
                         dbo.GNRT_NVID_U(),
                         om.IMAG_TYPE,
                         om.FILE_ID AS '@fileid',                         
                         (
                             --N'🟤 شماره درخواست [ *' + CAST(o.CODE AS VARCHAR(30)) + N'* ] ' + o.ORDR_TYPE + CHAR(10) + CHAR(10) +
                             N'*اقلام کمپین تبیلغاتی*' + CHAR(10) + CHAR(10) +
                             (
                                SELECT N'👈 [ *' + rp.TARF_CODE + N'* ] '+ rp.TARF_TEXT_DNRM + CHAR(10)
                                  FROM dbo.Order_Detail od, dbo.Robot_Product rp
                                 WHERE od.ORDR_CODE = o.CODE
                                   AND od.TARF_CODE = rp.TARF_CODE
                                   FOR XML PATH('')
                             )
                         ),
                         '005',
                         '002',
                         @xTemp
                    FROM dbo.[Order] o, dbo.Organ_Media om
                   WHERE o.CODE = @ParamText
                     AND om.ROBO_RBID = @Rbid
                     AND om.RBCN_TYPE = '025'
                     AND NOT EXISTS (
                             SELECT *
                               FROM dbo.Send_Advertising a
                              WHERE a.ORDR_CODE = o.CODE
                         );
                 
                 INSERT INTO dbo.Service_Robot_Send_Advertising ( SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,SDAD_ID ,SEND_STAT, AMNT)
                 SELECT sr.SERV_FILE_NO, sr.ROBO_RBID, sa.ID, '005', 0
                   FROM dbo.Service_Robot sr, dbo.Send_Advertising sa
                  WHERE sr.ROBO_RBID = @Rbid
                    AND sr.STAT = '002'
                    AND sa.ROBO_RBID = sr.ROBO_RBID
                    AND sa.ORDR_CODE = @ParamText
                    AND NOT EXISTS (
                            SELECT *
                              FROM dbo.Service_Robot_Send_Advertising a
                             WHERE a.SDAD_ID = sa.ID
                               AND a.CHAT_ID = sr.CHAT_ID
                        );
                 
                 UPDATE dbo.[Order]
                    SET ORDR_STAT = '004'
                  WHERE CODE = @ParamText;
               END 
               
               SET @ChildUssdCode = @UssdCode;
               SET @XTemp = NULL;
               GOTO L$SendMessage;
            END 
            ELSE IF @MenuText LIKE 'mailbox::sendingbox::delete::%'
            BEGIN
               -- حذف درخواست پیرو درخواست پیام تبلیغاتی
               DELETE dbo.[Order]
                WHERE ORDR_CODE IN (
                      SELECT ORDT_ORDR_CODE
                        FROM dbo.Service_Robot_Replay_Message
                       WHERE HEDR_CODE = @ParamText
               );
               -- حذف درخواست پیام تبلیغاتی
               DELETE dbo.[Order]
                WHERE CODE IN (
                      SELECT ORDT_ORDR_CODE
                        FROM dbo.Service_Robot_Replay_Message
                       WHERE HEDR_CODE = @ParamText
                );
               
               -- حذف درخواست های کمپین تبلیغات
               DELETE dbo.[Order]
                WHERE CODE = @ParamText;
                
               DELETE dbo.Service_Robot_Replay_Message
                WHERE HEDR_CODE = @ParamText;
               
               SET @ChildUssdCode = @UssdCode;
               GOTO L$SendMessage;
            END 
            ELSE IF @MenuText LIKE 'mailbox::back::%'
            BEGIN
               SET @ChildUssdCode = @UssdCode;
               GOTO L$SendMessage;
            END 
            -- ##############################
            -- مدیریت منوهای اولیه ورود به قسمت منوی مدیر فروشگاه
            -- ##############################
            ELSE IF @MenuText LIKE 'mailbox::inbox::delete::readysendto::%'
            BEGIN
               DELETE dbo.Service_Robot_Replay_Message
                WHERE SEND_STAT = '002'
                  AND SNDR_CHAT_ID = @ChatID
                  AND HEDR_TYPE = CASE @UssdCode 
                                       WHEN '*1*11*1*0#' /* مدیر فروشگاه */ THEN '001' 
                                       WHEN '*1*11*1*1#' /* مدیر پشتیبانی نرم افزار فروشگاه */ THEN '003' 
                                       WHEN '*1*11*1*3#' /* مدیر تبلیغات فروشگاه */ THEN '006' 
                                  END 
                  AND CHAT_ID IN (
                      SELECT sr.CHAT_ID
                        FROM dbo.Service_Robot sr, dbo.Service_Robot_Group sg
                       WHERE sr.SERV_FILE_NO = sg.SRBT_SERV_FILE_NO
                         AND sr.ROBO_RBID = sg.SRBT_ROBO_RBID
                         AND sr.ROBO_RBID = @Rbid
                         AND sg.GROP_GPID = CASE @UssdCode
                                                 WHEN '*1*11*1*0#' THEN 131
                                                 WHEN '*1*11*1*1#' THEN 135
                                                 WHEN '*1*11*1*3#' THEN 131
                                            END                          
                         AND sg.STAT = '002'
                  );
               
               -- این گزینه برای درخواست کمپین تبلیغاتی
               DELETE dbo.[Order]
                WHERE ORDR_TYPE = '027'
                  AND ORDR_STAT = '001';
               
               SET @ChildUssdCode = @UssdCode;   
               GOTO L$SendMessage;
            END 
            ELSE IF @MenuText LIKE 'mailbox::inbox::show::readysendto::%'
            BEGIN
               SELECT @QueryStatement = 
                  CASE @UssdCode
                       WHEN '*1*11*1*0#' THEN 'lesssendingmailmngrshop'
                       WHEN '*1*11*1*1#' THEN 'lesssendingmailsoftteam'
                       WHEN '*1*11*1*3#' THEN 'lesssendingmailadvteam'
                       WHEN '*1*11*1*4#' THEN 'lesssendingmailadvcamp'
                  END 
               -- منوهای اولیه ای که برای مدیریت باید ارسال شود را آماده میکنیم
               SET @XTemp =
               (
                   SELECT @Rbid AS '@rbid',
                          @ChatID AS '@chatid',
                          @UssdCode AS '@ussdcode',
                          @QueryStatement AS '@cmndtext'
                   FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml
               
               SET @XTemp =
               (
                   SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
               );
           
               SET @Message = 
                 CASE @UssdCode 
                      WHEN '*1*11*1*0#' THEN N'👨‍💼 ارسال پیام به مدیریت فروشگاه' 
                      WHEN '*1*11*1*1#' THEN N'👨‍💼 ارسال پیام به مدیریت واحد پشتیبانی فروشگاه' 
                      WHEN '*1*11*1*3#' THEN N'👨‍💼 ارسال پیام به مدیریت واحد تبلیغات فروشگاه' 
                      WHEN '*1*11*1*4#' THEN N'👨‍💼 ارسال پیام به واحد کمپین تبلیغات فروشگاه' 
                 END + CHAR(10) + CHAR(10) + 
                 CASE @UssdCode 
                      WHEN '*1*11*1*0#' THEN                    
                         N'نظرات، پيشنهادات و انتقادات ارزشمند شما کاربران گرامی در هر بخش از فعاليت های فروشگاه، ما را در شناسایی نقاط قوت و ضعف خدمات و محصولات یاری خواهد رساند.' + CHAR(10) + 
                         N'همچنين هرگونه پیشنهاد یا انتقاد در رابطه با عملكرد كارمندان، توسط مديران ارشد و مديریت عامل بررسي مي شود تا در تصمیم گیری های خرد و کلان فروشگاه لحاظ گردند.' + CHAR(10)
                      WHEN '*1*11*1*1#' THEN 
                         N'نظرات، پيشنهادات و انتقادات ارزشمند شما کاربران گرامی در هر بخش از فعاليت های فروشگاه، ما را در شناسایی نقاط قوت و ضعف خدمات و محصولات یاری خواهد رساند.' + CHAR(10) + 
                         N'همچنين هرگونه پیشنهاد یا انتقاد در رابطه با عملكرد نرم افزار، توسط تیم پشتیبانی نرم افزار بررسي مي شود تا در بهتر کردن قابلیت های نرم افزار فروشگاه لحاظ گردند.' + CHAR(10)
                      WHEN '*1*11*1*3#' THEN 
                         N'تبلیغات در اصطلاح یعنی پیامی که به مخاطب می‌رسانید تا توجهش را به ایده، محصول، خدمت یا شرکتتان جلب کنید. این پیام در واقع یک فراخوان یا call to action عمومی است که قرار است در چند دقیقه (یا حتی چند ثانیه) ما را مجاب کند که با این محصول تجربه بهتری خواهیم داشت.' + CHAR(10) + 
                         N'فقط با این تفاوت که همه در درآمدهای تبلیغاتی شریک هستن حتی مشتری' + CHAR(10)
                      WHEN '*1*11*1*4#' THEN 
                         N'کمپین تبلیغاتی مجموعه‌ای از فعالیت‌های تبلیغاتی چندجانبه است که قبل از هر چیز پیام هدف کمپین مشخص شده، مخاطب تعیین شده و با برنامه‌ریزی دقیق، بکوشد پیام مناسب در دوره زمانی مناسب با بودجه مناسب برای مخاطب مناسب ارسال شده و تعداد بیشتری از مخاطبان را برای نزدیک تر کردن ارتباط با مالک کمپین، ترغیب نماید. کمپین تبلیغاتی بدون تعریف معیار عددی مشخص برای سنجش کارایی، بی معنی است.' + CHAR(10)
                 END + CHAR(10) +
                 CASE @UssdCode 
                      WHEN '*1*11*1*0#' THEN N'با تشکر مدیریت فروشگاه'
                      WHEN '*1*11*1*1#' THEN N'با تشکر مدیریت واحد پشتیبانی فروشگاه'
                      WHEN '*1*11*1*3#' THEN N'با تشکر مدیریت واحد تبلیغات فروشگاه'
                      WHEN '*1*11*1*4#' THEN N'با تشکر واحد کمپین تبلیغات فروشگاه'
                 END;
               
               SET @XMessage =
               (
                   SELECT TOP 1
                          om.FILE_ID AS '@fileid',
                          om.IMAG_TYPE AS '@filetype',
                          @Message AS '@caption',
                          1 AS '@order'
                     FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                      AND om.RBCN_TYPE = CASE WHEN @UssdCode IN ('*1*11*1*1#', '*1*11*1*2#', '*1*11*1*3#') THEN '024' WHEN @UssdCode IN ('*1*11*1*4#') THEN '025' END 
                      AND om.IMAG_TYPE = '002'
                      AND om.STAT = '002'
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
               );
               SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');  

               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               GOTO L$EndSP;
            END 
            ELSE IF @MenuText LIKE 'mailbox::inbox::show::sendedto::%'
            BEGIN
               SELECT @QueryStatement = 
                  CASE @UssdCode
                       WHEN '*1*11*1*0#' THEN 'lesssendedmailmngrshop'
                       WHEN '*1*11*1*1#' THEN 'lesssendedmailsoftteam'
                       WHEN '*1*11*1*3#' THEN 'lesssendedmailadvteam'
                       WHEN '*1*11*1*4#' THEN 'lesssendedmailadvcamp'
                  END;
               -- منوهای اولیه ای که برای مدیریت باید ارسال شود را آماده میکنیم
               SET @XTemp =
               (
                   SELECT @Rbid AS '@rbid',
                          @ChatID AS '@chatid',
                          @UssdCode AS '@ussdcode',
                          @QueryStatement AS '@cmndtext'
                   FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml
               
               SET @XTemp =
               (
                   SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
               );
           
               SET @Message = 
                 CASE @UssdCode 
                      WHEN '*1*11*1*0#' THEN N'👨‍💼 ارسال پیام به مدیریت فروشگاه' 
                      WHEN '*1*11*1*1#' THEN N'👨‍💼 ارسال پیام به مدیریت واحد پشتیبانی فروشگاه' 
                      WHEN '*1*11*1*3#' THEN N'👨‍💼 ارسال پیام به مدیریت واحد تبلیغات فروشگاه' 
                      WHEN '*1*11*1*4#' THEN N'👨‍💼 ارسال پیام به واحد کمپین تبلیغات فروشگاه' 
                 END + CHAR(10) + CHAR(10) + 
                 CASE @UssdCode 
                      WHEN '*1*11*1*0#' THEN                    
                         N'نظرات، پيشنهادات و انتقادات ارزشمند شما کاربران گرامی در هر بخش از فعاليت های فروشگاه، ما را در شناسایی نقاط قوت و ضعف خدمات و محصولات یاری خواهد رساند.' + CHAR(10) + 
                         N'همچنين هرگونه پیشنهاد یا انتقاد در رابطه با عملكرد كارمندان، توسط مديران ارشد و مديریت عامل بررسي مي شود تا در تصمیم گیری های خرد و کلان فروشگاه لحاظ گردند.' + CHAR(10)
                      WHEN '*1*11*1*1#' THEN 
                         N'نظرات، پيشنهادات و انتقادات ارزشمند شما کاربران گرامی در هر بخش از فعاليت های فروشگاه، ما را در شناسایی نقاط قوت و ضعف خدمات و محصولات یاری خواهد رساند.' + CHAR(10) + 
                         N'همچنين هرگونه پیشنهاد یا انتقاد در رابطه با عملكرد نرم افزار، توسط تیم پشتیبانی نرم افزار بررسي مي شود تا در بهتر کردن قابلیت های نرم افزار فروشگاه لحاظ گردند.' + CHAR(10)
                      WHEN '*1*11*1*3#' THEN 
                         N'تبلیغات در اصطلاح یعنی پیامی که به مخاطب می‌رسانید تا توجهش را به ایده، محصول، خدمت یا شرکتتان جلب کنید. این پیام در واقع یک فراخوان یا call to action عمومی است که قرار است در چند دقیقه (یا حتی چند ثانیه) ما را مجاب کند که با این محصول تجربه بهتری خواهیم داشت.' + CHAR(10) + 
                         N'فقط با این تفاوت که همه در درآمدهای تبلیغاتی شریک هستن حتی مشتری' + CHAR(10)
                      WHEN '*1*11*1*4#' THEN 
                         N'کمپین تبلیغاتی مجموعه‌ای از فعالیت‌های تبلیغاتی چندجانبه است که قبل از هر چیز پیام هدف کمپین مشخص شده، مخاطب تعیین شده و با برنامه‌ریزی دقیق، بکوشد پیام مناسب در دوره زمانی مناسب با بودجه مناسب برای مخاطب مناسب ارسال شده و تعداد بیشتری از مخاطبان را برای نزدیک تر کردن ارتباط با مالک کمپین، ترغیب نماید. کمپین تبلیغاتی بدون تعریف معیار عددی مشخص برای سنجش کارایی، بی معنی است.' + CHAR(10)
                 END + CHAR(10) +
                 CASE @UssdCode 
                      WHEN '*1*11*1*0#' THEN N'با تشکر مدیریت فروشگاه'
                      WHEN '*1*11*1*1#' THEN N'با تشکر مدیریت واحد پشتیبانی فروشگاه'
                      WHEN '*1*11*1*3#' THEN N'با تشکر مدیریت واحد تبلیغات فروشگاه'
                      WHEN '*1*11*1*4#' THEN N'با تشکر واحد کمپین تبلیغات فروشگاه'
                 END;
               
               SET @XMessage =
               (
                   SELECT TOP 1
                          om.FILE_ID AS '@fileid',
                          om.IMAG_TYPE AS '@filetype',
                          @Message AS '@caption',
                          1 AS '@order'
                     FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                      AND om.RBCN_TYPE = CASE WHEN @UssdCode IN ('*1*11*1*1#', '*1*11*1*2#', '*1*11*1*3#') THEN '024' WHEN @UssdCode IN ('*1*11*1*4#') THEN '025' END 
                      AND om.IMAG_TYPE = '002'
                      AND om.STAT = '002'
                    FOR XML PATH('Complex_InLineKeyboardMarkup')
               );
               SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');  

               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               GOTO L$EndSP;
            END 
            ELSE IF @MenuText LIKE 'mailbox::sendedbox::show::%'
            BEGIN
               IF @UssdCode IN ('*1*11*1*1#', '*1*11*1*2#', '*1*11*1*3#')
               BEGIN 
                  SELECT @QueryStatement = 
                     CASE @UssdCode
                          WHEN '*1*11*1*0#' THEN 'lesstrysendmngrshop'
                          WHEN '*1*11*1*1#' THEN 'lesstrysendsoftteam'
                          WHEN '*1*11*1*3#' THEN 'lesstrysendadvteam'
                     END;
                  -- منوهای اولیه ای که برای مدیریت باید ارسال شود را آماده میکنیم
                  SET @XTemp =
                  (
                      SELECT @Rbid AS '@rbid',
                             @ChatID AS '@chatid',
                             @UssdCode AS '@ussdcode',
                             @QueryStatement AS '@cmndtext',
                             @ParamText AS '@param'
                      FOR XML PATH('RequestInLineQuery')
                  );
                  EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                       @XRet = @XTemp OUTPUT; -- xml
                  SET @XMessage = (
                      SELECT TOP 1
                             CASE 
                                 WHEN a.MESG_TYPE = '001' THEN 
                                 (
                                    SELECT 1 AS '@order',
                                           a.MESG_TEXT AS '@caption',
                                           @XTemp
                                       FOR XML PATH('InlineKeyboardMarkup'), TYPE
                                 )
                                 WHEN a.MESG_TYPE IN ('002', '003', '004') THEN                               
                                 (
                                    SELECT 1 AS '@order',
                                           a.FILE_ID AS '@fileid',
                                           a.MESG_TYPE AS '@filetype',
                                           a.MESG_TEXT AS '@caption',
                                           @XTemp
                                       FOR XML PATH('Complex_InLineKeyboardMarkup'), TYPE
                                 )
                             END 
                        FROM dbo.Service_Robot_Replay_Message a
                       WHERE a.SRBT_ROBO_RBID = @Rbid
                         AND a.SNDR_CHAT_ID = @ChatID
                         AND a.HEDR_CODE = @ParamText
                  );               
                  
                  SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
                  GOTO L$EndSP;
               END
               ELSE IF @UssdCode IN ('*1*11*1*4#')
               BEGIN 
                  SELECT @ParamText = sa.RWNO
                    FROM dbo.Service_Robot_Send_Advertising sa, dbo.Send_Advertising a
                   WHERE a.ID = sa.SDAD_ID
                     AND a.ORDR_CODE = @ParamText
                     AND sa.CHAT_ID = @ChatID;
                  
                  GOTO L$ShowAdvMessage;
               END 
            END 
            ELSE IF @MenuText LIKE 'mailbox::sendingbox::show::%'
            BEGIN
               SELECT @QueryStatement = 
                  CASE @UssdCode
                       WHEN '*1*11*1*0#' THEN 'lesssend1msgmngrshop'
                       WHEN '*1*11*1*1#' THEN 'lesssend1msgsoftteam'
                       WHEN '*1*11*1*3#' THEN 'lesssend1msgadvteam'
                       WHEN '*1*11*1*4#' THEN 'lesssend1msgadvcamp'
                  END;
               -- منوهای اولیه ای که برای مدیریت باید ارسال شود را آماده میکنیم
               SET @XTemp =
               (
                   SELECT @Rbid AS '@rbid',
                          @ChatID AS '@chatid',
                          @UssdCode AS '@ussdcode',
                          @QueryStatement AS '@cmndtext',
                          @ParamText AS '@param'
                   FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml
               IF @UssdCode IN ('*1*11*1*1#', '*1*11*1*2#', '*1*11*1*3#')
               BEGIN 
                  SET @XMessage = (                   
                      SELECT TOP 1
                             CASE 
                                 WHEN a.MESG_TYPE = '001' THEN 
                                 (
                                    SELECT 1 AS '@order',
                                           a.MESG_TEXT AS '@caption',
                                           @XTemp
                                       FOR XML PATH('InlineKeyboardMarkup'), TYPE
                                 )
                                 WHEN a.MESG_TYPE IN ( '002', '003', '004' ) THEN                               
                                 (
                                    SELECT 1 AS '@order',
                                           a.FILE_ID AS '@fileid',
                                           a.MESG_TYPE AS '@filetype',
                                           a.MESG_TEXT AS '@caption',
                                           @XTemp
                                       FOR XML PATH('Complex_InLineKeyboardMarkup'), TYPE
                                 )
                             END 
                        FROM dbo.Service_Robot_Replay_Message a
                       WHERE a.SRBT_ROBO_RBID = @Rbid
                         AND a.SNDR_CHAT_ID = @ChatID
                         AND a.HEDR_CODE = @ParamText
                  );
               END 
               ELSE IF @UssdCode IN ( '*1*11*1*4#' )
               BEGIN
                  SET @XMessage = (                   
                      SELECT 1 AS '@order', 
                             om.FILE_ID AS '@fileid',
                             om.IMAG_TYPE AS '@filetype',
                             (
                                 N'🟤 شماره درخواست [ *' + CAST(o.CODE AS VARCHAR(30)) + N'* ] ' + o.ORDR_TYPE + CHAR(10) + CHAR(10) +
                                 N'*اقلام کمپین تبیلغاتی*' + CHAR(10) + CHAR(10) +
                                 (
                                    SELECT N'👈 [ *' + rp.TARF_CODE + N'* ] '+ rp.TARF_TEXT_DNRM + CHAR(10)
                                      FROM dbo.Order_Detail od, dbo.Robot_Product rp
                                     WHERE od.ORDR_CODE = o.CODE
                                       AND od.TARF_CODE = rp.TARF_CODE
                                       FOR XML PATH('')
                                 )
                             ) AS '@caption',
                             @xTemp
                        FROM dbo.[Order] o, dbo.Organ_Media om
                       WHERE o.CODE = @ParamText
                         AND om.ROBO_RBID = @Rbid
                         AND om.RBCN_TYPE = '025'
                         FOR XML PATH('Complex_InLineKeyboardMarkup')                       
                  );
               END 
               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               GOTO L$EndSP;
            END 
            ELSE IF @MenuText LIKE 'mailbox::trysend::sendto::%'
            BEGIN
               IF @MenuText LIKE '%mngrshop' OR @MenuText LIKE '%softteam'
               BEGIN
                  GOTO L$TrySendMessage;
               END 
               ELSE IF @MenuText LIKE '%advteam'
               BEGIN
                  -- اگر پیام دیده نشده یا عدم تایید زده شده باشد
                  IF EXISTS (
                     SELECT * 
                       FROM dbo.Service_Robot_Replay_Message a 
                      WHERE a.SRBT_ROBO_RBID = @Rbid
                        AND a.HEDR_CODE = @ParamText
                        AND ISNULL(a.CONF_STAT, '001') = '001' )
                  BEGIN
                     -- پیام را دوباره برای گرفتن تایید ارسال میکنیم
                     GOTO L$TrySendMessage;
                  END 
                  ELSE
                  BEGIN
                     -- در غیر اینصورت پیام تایید شده را دوباره برای مشتریان ارسال میکنیم
                     PRINT 'Create Adv Message For Send To Customers'
                  END 
               END 
            END
            ELSE IF @MenuText LIKE 'mailbox::sendingbox::whois::sendto::%'
            BEGIN
               SET @QueryStatement = 
                   CASE @UssdCode
                        WHEN '*1*11*1*3#' THEN 'lessmenumailadvteam'                     
                   END;
                   
               SET @XTemp =
               (
                   SELECT @Rbid AS '@rbid',
                          @ChatID AS '@chatid',
                          @UssdCode AS '@ussdcode',
                          @QueryStatement AS '@cmndtext',
                          @ParamText as '@param'
                   FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml
  
               SET @XTemp =
               (
                   SELECT '1' AS '@order', 
                          @XTemp 
                      FOR XML PATH('InlineKeyboardMarkup')
               );
               SET @XMessage = (                   
                   SELECT TOP 1
                          CASE 
                              WHEN a.MESG_TYPE = '001' THEN 
                              (
                                 SELECT 1 AS '@order',
                                        N'👤 *' + b.Name + N'*' + CHAR(10) + CHAR(10) +
                                        N'📱 شماره دستگاه: *' + CAST(b.Chat_Id AS VARCHAR(30)) + N'*' + CHAR(10) + 
                                        N'📳 شماره تلفن همراه: *' + b.Cell_Phon + N'*' + CHAR(10) + 
                                        N'🇮🇷 شماره ملی: *' + b.Natl_Code + N'*' + CHAR(10) + 
                                        N'📅 تاریخ عضویت: *' + dbo.GET_MTOS_U(b.Join_Date) + N'*' + CHAR(10) + 
                                        N'📍 آدرس: *' + ISNULL(b.Serv_Adrs, N'_آدرس ثبت نشده_') + N'*' + CHAR(10) + CHAR(10) + 
                                        N'💬 پیام ارسال شده: ' + CHAR(10) + CHAR(10) + 
                                        a.MESG_TEXT AS '@caption',
                                        @XTemp
                                    FOR XML PATH('InlineKeyboardMarkup'), TYPE
                              )
                              WHEN a.MESG_TYPE IN ('002', '003', '004') THEN                               
                              (
                                 SELECT 1 AS '@order',
                                        a.FILE_ID AS '@fileid',
                                        a.MESG_TYPE AS '@filetype',
                                        N'👤 *' + b.Name + N'*' + CHAR(10) + CHAR(10) +
                                        N'📱 شماره دستگاه: *' + CAST(b.Chat_Id AS VARCHAR(30)) + N'*' + CHAR(10) + 
                                        N'📳 شماره تلفن همراه: *' + b.Cell_Phon + N'*' + CHAR(10) + 
                                        N'🇮🇷 شماره ملی: *' + b.Natl_Code + N'*' + CHAR(10) + 
                                        N'📅 تاریخ عضویت: *' + dbo.GET_MTOS_U(b.Join_Date) + N'*' + CHAR(10) + 
                                        N'📍 آدرس: *' + ISNULL(b.Serv_Adrs, N'_آدرس ثبت نشده_') + N'*' + CHAR(10) + CHAR(10) + 
                                        N'💬 پیام ارسال شده: ' + CHAR(10) + CHAR(10) + 
                                        a.MESG_TEXT AS '@caption',
                                        @XTemp
                                    FOR XML PATH('Complex_InLineKeyboardMarkup'), TYPE
                              )
                          END 
                     FROM dbo.Service_Robot_Replay_Message a, dbo.Service_Robot b
                    WHERE a.SRBT_ROBO_RBID = b.ROBO_RBID
                      AND a.SNDR_CHAT_ID = b.CHAT_ID
                      AND a.SRBT_ROBO_RBID = @Rbid
                      --AND a.SNDR_CHAT_ID = @ChatID
                      AND a.HEDR_CODE = @ParamText                      
               );               
               
               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               GOTO L$EndSP;
            END
            ELSE IF @MenuText LIKE 'mailbox::sendingbox::aprv::sendto::%'
            BEGIN
               UPDATE dbo.Service_Robot_Replay_Message
                  SET CONF_STAT = '002',
                      CONF_DATE = GETDATE()
                WHERE SRBT_ROBO_RBID = @Rbid
                  AND HEDR_CODE = @ParamText;
               
               -- بدست آوردن شماره درخواست پیام تبلیغاتی
               SELECT TOP 1 
                      @OrdrCode = a.ORDT_ORDR_CODE,
                      @TChatId = a.SNDR_CHAT_ID
                 FROM dbo.Service_Robot_Replay_Message a
                WHERE a.SRBT_ROBO_RBID = @Rbid
                  AND a.HEDR_CODE = @ParamText;
               
               -- اگر درخواست پیام تبلیغاتی ثبت نشده باشد
               IF ISNULL(@OrdrCode, 0) = 0
               BEGIN
                  SET @XTemp = (
                      SELECT 12 AS '@subsys',
                             '026' AS '@ordrtype',
                             '000' AS '@typecode', 
                             @TChatId AS '@chatid',
                             @Rbid AS '@rbid',
                             0 AS '@ordrcode'
                         FOR XML PATH('Action')
                  );
                  EXEC dbo.SAVE_EXTO_P @X = @XTemp, -- xml
                     @xRet = @XTemp OUTPUT; -- xml
                  
                  SELECT @RsltCode = @XTemp.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)');
                  
                  IF(@RsltCode = '002')
                  BEGIN
                     SELECT @OrdrCode = @XTemp.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');
                     
                     INSERT INTO dbo.Order_Detail
                     ( ORDR_CODE ,ELMN_TYPE ,ORDR_DESC )
                     SELECT TOP 1 @OrdrCode, a.MESG_TYPE, a.MESG_TEXT
                       FROM dbo.Service_Robot_Replay_Message a
                      WHERE a.SRBT_ROBO_RBID = @Rbid
                        AND a.HEDR_CODE = @ParamText
                        AND a.CHAT_ID = @ChatID;

                    
                     -- ثبت اطلاعات درخواست ارسال پیام های تبلیغاتی درون جدول ارسال پیام
                     UPDATE a
                        SET a.Ordt_Ordr_Code = od.ORDR_CODE,
                            a.Ordt_Rwno = od.RWNO 
                       FROM dbo.Service_Robot_Replay_Message a, dbo.Order_Detail od
                      WHERE a.SRBT_ROBO_RBID = @Rbid
                        AND a.HEDR_CODE = @ParamText
                        AND od.ORDR_CODE = @OrdrCode;                     
                  END
               END
               
               -- اطلاع رسانی به ارسال کننده پیام تبلیغات
               SET @XTemp = (
                   SELECT @Rbid AS '@rbid',
                          @UssdCode AS 'Order/@ussdcode',
                          @TChatId AS 'Order/@chatid',
                          @OrdrCode AS 'Order/@code',
                          '026' AS 'Order/@type',
                          'aprvadv' AS 'Order/@oprt',
                          @ParamText AS 'Order/@valu'
                      FOR XML PATH('Robot')
               );
               EXEC dbo.SEND_MEOJ_P @X = @XTemp, -- xml
                  @XRet = @XTemp OUTPUT; -- xml
               
               SET @Message = N'✅ پیام تبلیغاتی در صفت تایید قرار گرفت';
            END 
            ELSE IF @MenuText LIKE 'mailbox::sendingbox::disaprv::sendto::%'
            BEGIN
               UPDATE dbo.Service_Robot_Replay_Message
                  SET CONF_STAT = '001',
                      CONF_DATE = GETDATE()
                WHERE SRBT_ROBO_RBID = @Rbid
                  AND HEDR_CODE = @ParamText;
               
               -- بدست آوردن شماره درخواست پیام تبلیغاتی
               SELECT TOP 1 
                      @OrdrCode = a.ORDT_ORDR_CODE,
                      @TChatId = a.SNDR_CHAT_ID
                 FROM dbo.Service_Robot_Replay_Message a
                WHERE a.SRBT_ROBO_RBID = @Rbid
                  AND a.HEDR_CODE = @ParamText;
               
               -- اگر درخواست پیام تبلیغاتی ثبت نشده باشد
               IF ISNULL(@OrdrCode, 0) = 0
               BEGIN
                  SET @XTemp = (
                      SELECT 12 AS '@subsys',
                             '026' AS '@ordrtype',
                             '000' AS '@typecode', 
                             @TChatId AS '@chatid',
                             @Rbid AS '@rbid',
                             0 AS '@ordrcode'
                         FOR XML PATH('Action')
                  );
                  EXEC dbo.SAVE_EXTO_P @X = @XTemp, -- xml
                     @xRet = @XTemp OUTPUT; -- xml
                  
                  SELECT @RsltCode = @XTemp.query('//Action').value('(Action/@rsltcode)[1]', 'VARCHAR(3)');
                  
                  IF(@RsltCode = '002')
                  BEGIN
                     SELECT @OrdrCode = @XTemp.query('//Action').value('(Action/@ordrcode)[1]', 'BIGINT');
                     
                     INSERT INTO dbo.Order_Detail
                     ( ORDR_CODE ,ELMN_TYPE ,ORDR_DESC )
                     SELECT TOP 1 @OrdrCode, a.MESG_TYPE, a.MESG_TEXT
                       FROM dbo.Service_Robot_Replay_Message a
                      WHERE a.SRBT_ROBO_RBID = @Rbid
                        AND a.HEDR_CODE = @ParamText
                        AND a.CHAT_ID = @ChatID;

                    
                     -- ثبت اطلاعات درخواست ارسال پیام های تبلیغاتی درون جدول ارسال پیام
                     UPDATE a
                        SET a.Ordt_Ordr_Code = od.ORDR_CODE,
                            a.Ordt_Rwno = od.RWNO 
                       FROM dbo.Service_Robot_Replay_Message a, dbo.Order_Detail od
                      WHERE a.SRBT_ROBO_RBID = @Rbid
                        AND a.HEDR_CODE = @ParamText
                        AND od.ORDR_CODE = @OrdrCode;                     
                  END
               END
               
               -- اطلاع رسانی به ارسال کننده پیام تبلیغات
               SET @XTemp = (
                   SELECT @Rbid AS '@rbid',
                          @UssdCode AS 'Order/@ussdcode',
                          @TChatId AS 'Order/@chatid',
                          @OrdrCode AS 'Order/@code',
                          '026' AS 'Order/@type',
                          'disaprvadv' AS 'Order/@oprt',
                          @ParamText AS 'Order/@valu'
                      FOR XML PATH('Robot')
               );
               EXEC dbo.SEND_MEOJ_P @X = @XTemp, -- xml
                  @XRet = @XTemp OUTPUT; -- xml
               
               SET @Message = N'⛔ پیام تبلیغاتی در صفت عدم تایید قرار گرفت';
            END 
            ELSE IF @MenuText LIKE 'mailbox::sendingbox::now::sendto::%'
            BEGIN
               SELECT TOP 1
                      @OrdrCode = a.ORDT_ORDR_CODE,
                      @ElmnType = a.MESG_TYPE,
                      @FileId = a.FILE_ID,
                      @Message = a.MESG_TEXT
                 FROM dbo.Service_Robot_Replay_Message a
                WHERE a.SRBT_ROBO_RBID = @Rbid
                  AND a.HEDR_CODE = @ParamText;
               
               SELECT @Said = a.ID
                 FROM dbo.Send_Advertising a
                WHERE a.ROBO_RBID = @Rbid
                  AND a.ORDR_CODE = @OrdrCode;
               
               -- اگر رکورد پیام تبلیغات درون سیستم ثبت نشده باشد
               IF ISNULL(@Said, 0) = 0
               BEGIN 
                  EXEC dbo.INS_SDAD_P @ROBO_RBID = @Rbid, -- bigint
                     @ORDR_CODE = @OrdrCode, -- bigint
                     @ID = 0, -- bigint
                     @PAKT_TYPE = @ElmnType, -- varchar(3)
                     @FILE_ID = @FileId, -- varchar(200)
                     @TRGT_PROC_STAT = '002', -- varchar(3)                     
                     @TEXT_MESG = @Message,
                     @INLN_KEYB_DNRM = NULL; -- nvarchar(max)
                  
                  SET @QueryStatement = (
                      CASE @UssdCode
                           WHEN '*1*11*1*3#' THEN 'lessservadvmenu'
                      END 
                  );
                  
                  -- قراردادن منوی مربوط به پیام تبلیغاتی مشتریان
                  SET @XTemp = (
                      SELECT @Rbid AS '@rbid',
                             @ChatID AS '@chatid',
                             @UssdCode AS '@ussdcode',
                             @QueryStatement AS '@cmndtext',
                             @OrdrCode as '@ordrcode'
                      FOR XML PATH('RequestInLineQuery')
                  );
                  EXEC dbo.CRET_ILQM_P @X = @XTemp, -- xml
                     @XRet = @XTemp OUTPUT  -- xml
                  
                  SET @XTemp =
                  (
                      SELECT '1' AS '@order',                           
                             @XTemp
                      FOR XML PATH('InlineKeyboardMarkup')
                  );
                  
                  UPDATE dbo.Send_Advertising
                     SET INLN_KEYB_DNRM = @XTemp
                   WHERE ROBO_RBID = @Rbid
                     AND ORDR_CODE = @OrdrCode;
               END 
               SET @Said = NULL;               
                              
               -- ابتدا مشخص کنیم که چه افرادی در این زمینه ذینفع هستند
               -- ثابت
               --001	فروشنده
               INSERT INTO dbo.Send_Advertising_Stakeholders ( SDAD_ID ,CODE ,CHAT_ID ,STAK_HLDR_TYPE )
               SELECT TOP 1 
                      c.ID, 0, a.CHAT_ID, '001'
                 FROM dbo.Service_Robot a, dbo.Service_Robot_Group b, dbo.Send_Advertising c
                WHERE a.SERV_FILE_NO = b.SRBT_SERV_FILE_NO
                  AND a.ROBO_RBID = b.SRBT_ROBO_RBID
                  AND a.ROBO_RBID = c.ROBO_RBID
                  AND c.ORDR_CODE = @OrdrCode
                  AND a.ROBO_RBID = @Rbid
                  AND b.GROP_GPID = 131
                  AND EXISTS (
                      SELECT *
                        FROM dbo.Service_Robot_Card_Bank d
                       where d.SRBT_SERV_FILE_NO = a.SERV_FILE_NO
                         AND d.SRBT_ROBO_RBID = a.ROBO_RBID
                         AND d.ACNT_TYPE_DNRM = '002'
                         AND d.ACNT_STAT_DNRM = '002'
                         AND d.ORDR_TYPE_DNRM = '004'
                      )
                  AND NOT EXISTS (
                      SELECT *
                        FROM dbo.Send_Advertising_Stakeholders d
                       WHERE d.SDAD_ID = c.ID
                         and d.STAK_HLDR_TYPE = '001'
                      );
                  
               --002	شرکت
               INSERT INTO dbo.Send_Advertising_Stakeholders ( SDAD_ID ,CODE ,CHAT_ID ,STAK_HLDR_TYPE )
               SELECT TOP 1 
                      c.ID, 0, a.CHAT_ID, '002'
                 FROM dbo.Service_Robot a, dbo.Service_Robot_Card_Bank b, dbo.Send_Advertising c
                WHERE a.SERV_FILE_NO = b.SRBT_SERV_FILE_NO
                  AND a.ROBO_RBID = b.SRBT_ROBO_RBID
                  AND a.ROBO_RBID = c.ROBO_RBID
                  AND c.ORDR_CODE = @OrdrCode
                  AND a.ROBO_RBID = @Rbid
                  AND b.ACNT_TYPE_DNRM = '001'
                  AND b.ORDR_TYPE_DNRM = '013'
                  AND b.ACNT_STAT_DNRM = '002'
                  AND NOT EXISTS (
                      SELECT *
                        FROM dbo.Send_Advertising_Stakeholders d
                       WHERE d.SDAD_ID = c.ID
                         and d.STAK_HLDR_TYPE = '002'
                      );
               --003	مشتری
               SET @Numb = 3;
               
               -- متغیر
               --004	بازاریاب ربات
               SELECT @Said = sr.CHAT_ID
                 FROM dbo.Service_Robot sr 
                WHERE sr.ROBO_RBID = @Rbid AND sr.MRKT_STAT = '002';
               
               IF ISNULL(@Said, 0) != 0
               BEGIN
                  INSERT INTO dbo.Send_Advertising_Stakeholders ( SDAD_ID ,CODE ,CHAT_ID ,STAK_HLDR_TYPE )
                  SELECT a.ID, 0, @Said, '004'
                    FROM dbo.Send_Advertising a
                   WHERE a.ROBO_RBID = @Rbid
                     AND a.ORDR_CODE = @OrdrCode
                     AND NOT EXISTS (
                      SELECT *
                        FROM dbo.Send_Advertising_Stakeholders d
                       WHERE d.SDAD_ID = a.ID
                         and d.STAK_HLDR_TYPE = '004'
                      );
                  
                  SET @Numb += 1;
               END 
               
               --005	بازاریاب تبلیغات
               SELECT @RefChatId = sr.REF_CHAT_ID
                 FROM dbo.Service_Robot sr
                WHERE sr.ROBO_RBID = @Rbid
                  AND sr.CHAT_ID = @ChatID;
               
               IF ISNULL(@RefChatId, 0) != 0
               BEGIN
                  INSERT INTO dbo.Send_Advertising_Stakeholders ( SDAD_ID ,CODE ,CHAT_ID ,STAK_HLDR_TYPE)
                  SELECT a.ID, 0, @RefChatId, '005'
                    FROM dbo.Send_Advertising a
                   WHERE a.ROBO_RBID = @Rbid
                     AND a.ORDR_CODE = @OrdrCode
                     AND NOT EXISTS (
                      SELECT *
                        FROM dbo.Send_Advertising_Stakeholders d
                       WHERE d.SDAD_ID = a.ID
                         and d.STAK_HLDR_TYPE = '005'
                      );
                  
                  SET @Numb += 1;
               END
               
               -- محاسبه نرخ سهم هر کس برای مبلغ تبلیغات
               IF EXISTS (
                  SELECT *
                    FROM dbo.Send_Advertising a, dbo.Send_Advertising_Stakeholders b
                   WHERE a.ROBO_RBID = @Rbid
                     AND a.ORDR_CODE = @OrdrCode
                     AND a.ID = b.SDAD_ID
                     AND b.AMNT IS NULL
               )
               BEGIN
                  -- بدست آوردن مبلغ تعرفه ارسال پیام
                  SELECT @Amnt = b.AMNT
                    FROM dbo.Send_Advertising a, dbo.Send_Advertising_Tariff b
                   WHERE a.ROBO_RBID = b.ROBO_RBID
                     AND a.ROBO_RBID = @Rbid
                     AND a.ORDR_CODE = @OrdrCode
                     and a.PAKT_TYPE = b.PAKT_TYPE;
                  
                  -- محاسبه اینکه سهم هر سهامدار به چه شکلی میباشد
                  UPDATE b
                     SET b.AMNT = @Amnt / @Numb
                    FROM dbo.Send_Advertising a, dbo.Send_Advertising_Stakeholders b
                   where a.ROBO_RBID = @Rbid
                     AND a.ORDR_CODE = @OrdrCode
                     AND a.ID = b.SDAD_ID;
                    
                  IF @Amnt % @Numb != 0
                  BEGIN
                     ---- اگر مبلغ اضافه تر داشته باشیم آن را به مشتری اضافه میکنیم
                     --UPDATE b
                     --   SET b.AMNT += @Amnt % @Numb
                     --  FROM dbo.Send_Advertising a, dbo.Send_Advertising_Stakeholders b
                     -- where a.ROBO_RBID = @Rbid
                     --   AND a.ORDR_CODE = @OrdrCode
                     --   AND a.ID = b.SDAD_ID
                     --   AND b.STAK_HLDR_TYPE = '003';
                     SET @Pric = (@Amnt / @Numb) + (@Amnt % @Numb)
                  END 
                  ELSE
                     SET @Pric = @Amnt / @Numb
               END
               
               -- بدست آوردن میزان موجود کیف پول اعتباری               
               SELECT @WaltAmnt = AMNT_DNRM
                 FROM dbo.Wallet
                WHERE SRBT_ROBO_RBID = @Rbid
                  AND CHAT_ID = @ChatID
                  AND WLET_TYPE = '002'/* کیف پول نقدینگی */;
               
               IF ISNULL(@WaltAmnt, 0) = 0 AND ISNULL(@Amnt, 0) = 0
               BEGIN
                  SET @Message = 
                      N'خطا' + CHAR(10) + CHAR(10) + 
                      N'موجودی کیف پول شما : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @WaltAmnt), 1), '.00', '') + N'* ' + @AmntTypeDesc + CHAR(10) + 
                      N'مبلغ پیام ارسالی : *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, @Amnt), 1), '.00', '') + N'* ' + @AmntTypeDesc + CHAR(10) + CHAR(10) + 
                      N'لطفا بررسی نمایید';
                  GOTO L$EndSP;
               END 
               
               -- اگر هیچ مشتری برای ارسال پیام نداشته باشیم
               IF NOT EXISTS (
                  SELECT *
                    FROM dbo.Service_Robot sr
                   WHERE sr.ROBO_RBID = @Rbid
                     AND sr.STAT = '002'
                     AND NOT EXISTS (
                         SELECT *
                           FROM dbo.Send_Advertising a, dbo.Service_Robot_Send_Advertising b
                          WHERE a.ROBO_RBID = b.SRBT_ROBO_RBID
                            AND a.ID = b.SDAD_ID
                            AND a.ORDR_CODE = @OrdrCode
                            AND b.CHAT_ID = sr.CHAT_ID
                         )                   
               )
               BEGIN
                  SET @Message = N'تمامی مشتریان این پیام تبلیغاتی را دریافت کرده اند، لطفا از ارسال مجدد خودداری کنید'
                  GOTO L$EndSP;                  
               END 
               
               SET @Said = @Amnt;
               
               -- در این قسمت شروع به درج رکورد درون جدول جزئیات ارسال پیام برای مشتریان را انجام میدهیم
               -- البته اینجا باید گزینه چک کردن میزان شارژ باقیمانده را بررسی کنیم
               DECLARE C$Srsa CURSOR FOR
                  SELECT TOP (@WaltAmnt /* موجودی حساب اعتباری */ / @Amnt /* میزان مبلغ ارسال پیام */)
                         sr.SERV_FILE_NO, sr.CHAT_ID
                    FROM dbo.Service_Robot sr
                   WHERE sr.ROBO_RBID = @Rbid
                     AND sr.STAT = '002'
                     AND NOT EXISTS (
                         SELECT *
                           FROM dbo.Send_Advertising a, dbo.Service_Robot_Send_Advertising b
                          WHERE a.ROBO_RBID = b.SRBT_ROBO_RBID
                            AND a.ID = b.SDAD_ID
                            AND a.ORDR_CODE = @OrdrCode
                            AND b.CHAT_ID = sr.CHAT_ID
                         )
                   ORDER BY sr.CHAT_ID;
               
               OPEN [C$Srsa];
               L$Loop$Srsa:
               FETCH [C$Srsa] INTO @ServFileNo, @TChatId;
               
               IF @@FETCH_STATUS <> 0
                  GOTO L$EndLoop$Srsa;
               
               -- مبلغ هزینه هر پیامک
               SET @Amnt = @Said;
               
               -- درج اطلاعات درون جدول سابقه سود سهامداران
               INSERT INTO dbo.Send_Advertising_Stakeholders ( SDAD_ID ,CODE ,CHAT_ID ,STAK_HLDR_TYPE ,AMNT )
               SELECT a.ID, 0, @TChatId, '003', @Pric
                 FROM dbo.Send_Advertising a
                WHERE a.ROBO_RBID = @Rbid
                  AND a.ORDR_CODE = @OrdrCode
                  AND NOT EXISTS (
                   SELECT *
                     FROM dbo.Send_Advertising_Stakeholders d
                    WHERE d.SDAD_ID = a.ID
                      and d.STAK_HLDR_TYPE = '003'
                      AND d.CHAT_ID = @TChatId
                   );
               
               -- درج اطلاعات مربوط به مربوط به هر مشتری
               INSERT INTO dbo.Service_Robot_Send_Advertising
               ( SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,SDAD_ID ,SEND_STAT ,AMNT )
               SELECT @ServFileNo, @Rbid, a.ID, '005', b.AMNT
                 FROM dbo.Send_Advertising a, dbo.Send_Advertising_Stakeholders b
                WHERE a.ROBO_RBID = @Rbid                 
                  AND a.ORDR_CODE = @OrdrCode
                  AND a.ID = b.SDAD_ID
                  AND b.STAK_HLDR_TYPE = '003'
                  AND b.CHAT_ID = @TChatId;
               
               -- در این قسمت ذخیره کردن سود سهامداران پنجگانه               
               -- تبلیغ کننده
               INSERT INTO dbo.Wallet_Detail (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC)
               SELECT @OrdrCode, w.CODE, 0, r.AMNT_TYPE, @Amnt, GETDATE(), '002', '002', GETDATE(), N'کسر مبلغ هزینه  تبلیغ کننده بابت ارسال پیام های تبلیغاتی'
                 FROM dbo.Wallet w, dbo.Robot r
                WHERE r.RBID = w.SRBT_ROBO_RBID
                  AND w.SRBT_ROBO_RBID = @Rbid
                  AND w.CHAT_ID = @ChatID
                  AND w.WLET_TYPE = '002'; -- کیف پول نقدینگی
               
               -- ثبت سند حسابداری درون سیستم
               SELECT @xTemp = (
                  SELECT 5 AS '@subsys'
                        ,'107' AS '@cmndcode' -- عملیات جامع ذخیره سازی
                        ,12 AS '@refsubsys' -- محل ارجاعی
                        ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
                        ,o.CODE AS '@refcode'
                        ,@ChatID AS '@refnumb' -- تعداد شماره درخواست ثبت شده
                        ,o.STRT_DATE AS '@strtdate'
                        ,@ChatID AS '@chatid'
                        ,o.AMNT_TYPE AS '@amnttype'
                        ,'001' AS '@pymtmtod'
                        ,o.STRT_DATE AS '@pymtdate'
                        ,@Amnt AS '@amnt'
                        ,@OrdrCode AS '@txid'
                    FROM dbo.[Order] o
                   WHERE o.CODE = @OrdrCode
                     FOR XML PATH('Router_Command')
               );
               L$StrtCalling1:
               EXEC dbo.RouterdbCommand @X = @xTemp, @xRet = @XTemp OUTPUT -- xml      
               IF @XTemp.query('//Router_Command').value('(Router_Command/@needrecall)[1]', 'VARCHAR(3)') = '002'
               BEGIN
                  GOTO L$StrtCalling1;
               END
      
               -- مشتری   
               INSERT INTO dbo.Wallet_Detail (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC)
               SELECT @OrdrCode, w.CODE, 0, r.AMNT_TYPE, s.AMNT, GETDATE(), '001', '002', GETDATE(), N'افزایش مبلغ نقدینگی مشتری بابت دریافت پیام های تبلیغاتی'
                 FROM dbo.Wallet w, dbo.Robot r, dbo.Send_Advertising d, dbo.Send_Advertising_Stakeholders s
                WHERE r.RBID = w.SRBT_ROBO_RBID
                  AND w.CHAT_ID = @TChatId -- << حساب مشتری
                  AND w.SRBT_ROBO_RBID = @Rbid
                  AND d.ROBO_RBID = r.RBID
                  AND d.ORDR_CODE = @OrdrCode
                  AND d.ID = s.SDAD_ID
                  AND w.CHAT_ID = s.CHAT_ID
                  AND s.STAK_HLDR_TYPE = '003' -- << حساب مشتری
                  AND w.WLET_TYPE = '002'; -- کیف پول نقدینگی
               
               -- بدست آوردن شماره کد فروشنده
               SELECT @Amnt = s.AMNT
                 FROM dbo.Wallet w, dbo.Robot r, dbo.Send_Advertising d, dbo.Send_Advertising_Stakeholders s
                WHERE r.RBID = w.SRBT_ROBO_RBID
                  AND w.CHAT_ID = @TChatId -- << حساب مشتری
                  AND w.SRBT_ROBO_RBID = @Rbid
                  AND d.ROBO_RBID = r.RBID
                  AND d.ORDR_CODE = @OrdrCode
                  AND d.ID = s.SDAD_ID
                  AND w.CHAT_ID = s.CHAT_ID
                  AND s.STAK_HLDR_TYPE = '003' -- << حساب مشتری
                  AND w.WLET_TYPE = '002'; -- کیف پول نقدینگی
               
               -- ثبت سند حسابداری درون سیستم
               SELECT @xTemp = (
                  SELECT 5 AS '@subsys'
                        ,'108' AS '@cmndcode' -- عملیات جامع ذخیره سازی
                        ,12 AS '@refsubsys' -- محل ارجاعی
                        ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
                        ,o.CODE AS '@refcode'
                        ,@TChatId AS '@refnumb' -- تعداد شماره درخواست ثبت شده
                        ,o.STRT_DATE AS '@strtdate'
                        ,@TChatId AS '@chatid'
                        ,o.AMNT_TYPE AS '@amnttype'
                        ,'001' AS '@pymtmtod'
                        ,o.STRT_DATE AS '@pymtdate'
                        ,@Amnt AS '@amnt'
                        ,@OrdrCode AS '@txid'
                    FROM dbo.[Order] o
                   WHERE o.CODE = @OrdrCode
                     FOR XML PATH('Router_Command')
               );
               L$StrtCalling2:
               EXEC dbo.RouterdbCommand @X = @xTemp, @xRet = @XTemp OUTPUT -- xml      
               IF @XTemp.query('//Router_Command').value('(Router_Command/@needrecall)[1]', 'VARCHAR(3)') = '002'
               BEGIN
                  GOTO L$StrtCalling2;
               END
               
               -- شرکت
               INSERT INTO dbo.Wallet_Detail (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC)
               SELECT @OrdrCode, w.CODE, 0, r.AMNT_TYPE, s.AMNT, GETDATE(), '002', '002', GETDATE(), N'کسر مبلغ اعتباری فروشنده برای شرکت بابت ارسال پیام های تبلیغاتی'
                 FROM dbo.Wallet w, dbo.Robot r, dbo.Send_Advertising d, dbo.Send_Advertising_Stakeholders s
                WHERE r.RBID = w.SRBT_ROBO_RBID                  
                  AND w.SRBT_ROBO_RBID = @Rbid
                  AND r.RBID = d.ROBO_RBID
                  AND d.ORDR_CODE = @OrdrCode
                  AND d.ID = s.SDAD_ID
                  AND w.CHAT_ID = s.CHAT_ID
                  AND s.STAK_HLDR_TYPE = '001' -- << فروشنده * درآمد شرکت از کسر کارمزد فروشنده بدست می آید
                  AND w.WLET_TYPE = '002'; -- کیف پول اعتباری
               
               -- بدست آوردن شماره کد فروشنده
               SELECT @TChatId = s.CHAT_ID, @Amnt = s.AMNT
                 FROM dbo.Wallet w, dbo.Robot r, dbo.Send_Advertising d, dbo.Send_Advertising_Stakeholders s
                WHERE r.RBID = w.SRBT_ROBO_RBID                  
                  AND w.SRBT_ROBO_RBID = @Rbid
                  AND r.RBID = d.ROBO_RBID
                  AND d.ORDR_CODE = @OrdrCode
                  AND d.ID = s.SDAD_ID
                  AND w.CHAT_ID = s.CHAT_ID
                  AND s.STAK_HLDR_TYPE = '001' -- << فروشنده * درآمد شرکت از کسر کارمزد فروشنده بدست می آید
                  AND w.WLET_TYPE = '002'; -- کیف پول اعتباری
                  
               -- ثبت سند حسابداری درون سیستم
               SELECT @xTemp = (
                  SELECT 5 AS '@subsys'
                        ,'107' AS '@cmndcode' -- عملیات جامع ذخیره سازی
                        ,12 AS '@refsubsys' -- محل ارجاعی
                        ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
                        ,o.CODE AS '@refcode'
                        ,@TChatId AS '@refnumb' -- تعداد شماره درخواست ثبت شده
                        ,o.STRT_DATE AS '@strtdate'
                        ,@TChatId AS '@chatid'
                        ,o.AMNT_TYPE AS '@amnttype'
                        ,'001' AS '@pymtmtod'
                        ,o.STRT_DATE AS '@pymtdate'
                        ,@Amnt AS '@amnt'
                        ,@OrdrCode AS '@txid'
                    FROM dbo.[Order] o
                   WHERE o.CODE = @OrdrCode
                     FOR XML PATH('Router_Command')
               );
               L$StrtCalling3:
               EXEC dbo.RouterdbCommand @X = @xTemp, @xRet = @XTemp OUTPUT -- xml      
               IF @XTemp.query('//Router_Command').value('(Router_Command/@needrecall)[1]', 'VARCHAR(3)') = '002'
               BEGIN
                  GOTO L$StrtCalling3;
               END
               
               -- بازاریاب
               INSERT INTO dbo.Wallet_Detail (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC)
               SELECT @OrdrCode, w.CODE, 0, r.AMNT_TYPE, s.AMNT, GETDATE(), '001', '002', GETDATE(), N'افزایش مبلغ نقدینگی بازاریاب بابت ارسال پیام های تبلیغاتی'
                 FROM dbo.Wallet w, dbo.Robot r, dbo.Send_Advertising d, dbo.Send_Advertising_Stakeholders s
                WHERE r.RBID = w.SRBT_ROBO_RBID                  
                  AND w.SRBT_ROBO_RBID = @Rbid
                  AND r.RBID = d.ROBO_RBID
                  AND d.ORDR_CODE = @OrdrCode
                  AND d.ID = s.SDAD_ID
                  AND w.CHAT_ID = s.CHAT_ID
                  AND s.STAK_HLDR_TYPE = '004' -- << حساب بازاریاب
                  AND w.WLET_TYPE = '002'; -- کیف پول نقدینگی
               
               SET @TChatId = NULL;
               
               -- بدست آوردن شماره کد بازاریاب
               SELECT @TChatId = s.CHAT_ID, @Amnt = s.AMNT               
                 FROM dbo.Wallet w, dbo.Robot r, dbo.Send_Advertising d, dbo.Send_Advertising_Stakeholders s
                WHERE r.RBID = w.SRBT_ROBO_RBID                  
                  AND w.SRBT_ROBO_RBID = @Rbid
                  AND r.RBID = d.ROBO_RBID
                  AND d.ORDR_CODE = @OrdrCode
                  AND d.ID = s.SDAD_ID
                  AND w.CHAT_ID = s.CHAT_ID
                  AND s.STAK_HLDR_TYPE = '004' -- << حساب بازاریاب
                  AND w.WLET_TYPE = '002'; -- کیف پول نقدینگی
               
               IF ISNULL(@TChatId, 0) != 0
               BEGIN 
                  -- ثبت سند حسابداری درون سیستم
                  SELECT @xTemp = (
                     SELECT 5 AS '@subsys'
                           ,'108' AS '@cmndcode' -- عملیات جامع ذخیره سازی
                           ,12 AS '@refsubsys' -- محل ارجاعی
                           ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
                           ,o.CODE AS '@refcode'
                           ,@TChatId AS '@refnumb' -- تعداد شماره درخواست ثبت شده
                           ,o.STRT_DATE AS '@strtdate'
                           ,@TChatId AS '@chatid'
                           ,o.AMNT_TYPE AS '@amnttype'
                           ,'001' AS '@pymtmtod'
                           ,o.STRT_DATE AS '@pymtdate'
                           ,@Amnt AS '@amnt'
                           ,@OrdrCode AS '@txid'
                       FROM dbo.[Order] o
                      WHERE o.CODE = @OrdrCode
                        FOR XML PATH('Router_Command')
                  );
                  L$StrtCalling4:
                  EXEC dbo.RouterdbCommand @X = @xTemp, @xRet = @XTemp OUTPUT -- xml      
                  IF @XTemp.query('//Router_Command').value('(Router_Command/@needrecall)[1]', 'VARCHAR(3)') = '002'
                  BEGIN
                     GOTO L$StrtCalling4;
                  END
               END  
                 
               -- بازاریاب تبلیغ
               INSERT INTO dbo.Wallet_Detail (ORDR_CODE ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC)
               SELECT @OrdrCode, w.CODE, 0, r.AMNT_TYPE, s.AMNT, GETDATE(), '001', '002', GETDATE(), N'افزایش مبلغ نقدینگی بازاریاب تبلیغاتی بابت ارسال پیام های تبلیغاتی'
                 FROM dbo.Wallet w, dbo.Robot r, dbo.Send_Advertising d, dbo.Send_Advertising_Stakeholders s
                WHERE r.RBID = w.SRBT_ROBO_RBID                  
                  AND w.SRBT_ROBO_RBID = @Rbid
                  AND r.RBID = d.ROBO_RBID
                  AND d.ORDR_CODE = @OrdrCode
                  AND d.ID = s.SDAD_ID
                  AND w.CHAT_ID = s.CHAT_ID
                  AND s.STAK_HLDR_TYPE = '005' -- << حساب بازاریاب تبلیغاتی
                  AND w.WLET_TYPE = '002'; -- کیف پول نقدینگی
               
               SET @TChatId = NULL;
               
               -- بدست آوردن شماره کد بازاریاب تبلیغ
               SELECT @TChatId = s.CHAT_ID, @Amnt = s.AMNT
                 FROM dbo.Wallet w, dbo.Robot r, dbo.Send_Advertising d, dbo.Send_Advertising_Stakeholders s
                WHERE r.RBID = w.SRBT_ROBO_RBID                  
                  AND w.SRBT_ROBO_RBID = @Rbid
                  AND r.RBID = d.ROBO_RBID
                  AND d.ORDR_CODE = @OrdrCode
                  AND d.ID = s.SDAD_ID
                  AND w.CHAT_ID = s.CHAT_ID
                  AND s.STAK_HLDR_TYPE = '004' -- << حساب بازاریاب
                  AND w.WLET_TYPE = '002'; -- کیف پول نقدینگی
               
               IF ISNULL(@TChatId, 0) != 0
               BEGIN 
                  -- ثبت سند حسابداری درون سیستم
                  SELECT @xTemp = (
                     SELECT 5 AS '@subsys'
                           ,'108' AS '@cmndcode' -- عملیات جامع ذخیره سازی
                           ,12 AS '@refsubsys' -- محل ارجاعی
                           ,'appuser' AS '@execaslogin' -- توسط کدام کاربری اجرا شود               
                           ,o.CODE AS '@refcode'
                           ,@TChatId AS '@refnumb' -- تعداد شماره درخواست ثبت شده
                           ,o.STRT_DATE AS '@strtdate'
                           ,@TChatId AS '@chatid'
                           ,o.AMNT_TYPE AS '@amnttype'
                           ,'001' AS '@pymtmtod'
                           ,o.STRT_DATE AS '@pymtdate'
                           ,@Amnt AS '@amnt'
                           ,@OrdrCode AS '@txid'
                       FROM dbo.[Order] o
                      WHERE o.CODE = @OrdrCode
                        FOR XML PATH('Router_Command')
                  );
                  L$StrtCalling5:
                  EXEC dbo.RouterdbCommand @X = @xTemp, @xRet = @XTemp OUTPUT -- xml      
                  IF @XTemp.query('//Router_Command').value('(Router_Command/@needrecall)[1]', 'VARCHAR(3)') = '002'
                  BEGIN
                     GOTO L$StrtCalling5;
                  END
               END 
                  
               GOTO L$Loop$Srsa;
               L$EndLoop$Srsa:
               CLOSE [C$Srsa];
               DEALLOCATE [C$Srsa];
               
               -- آماده سازی پیام ها برای ارسال
               UPDATE dbo.Send_Advertising 
                  SET STAT = '005' -- آماده سازی برای ارسال
                WHERE ROBO_RBID = @Rbid
                  AND ORDR_CODE = @OrdrCode;
               
               -- پایانی کردن درخواست ارسال پیام تبلیغاتی
               UPDATE dbo.[Order]
                  SET ORDR_STAT = '004'
                WHERE CODE = @OrdrCode;
               
               SET @Message = (
                   SELECT CASE COUNT(b.RWNO)
                               WHEN 0 THEN N'⛔ متاسفانه موفق به ایجاد رکورد تبلیغاتی برای مشتریان نشدیم'
                               ELSE N'✅ تعداد *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, COUNT(b.RWNO)), 1), '.00', '') + N'* رکورد ذخیره شده و درون لیست ارسال قرار گرفتند.'
                          END 
                     FROM dbo.Send_Advertising a, dbo.Service_Robot_Send_Advertising b
                    WHERE a.ROBO_RBID = b.SRBT_ROBO_RBID
                      AND a.ROBO_RBID = @Rbid
                      AND a.ORDR_CODE = @OrdrCode
                      AND a.ID = b.SDAD_ID
                      FOR XML PATH('')
               );               
               
               GOTO L$EndSP;
            END 
            ELSE IF @MenuText LIKE 'mailbox::sendedbox::menuadv::like::%'
            BEGIN
               -- Parameter is (Ordr_Code) for Send_Advertising
               SET @OrdrCode = @ParamText;
               UPDATE b
                  SET b.LIKE_STAT = '002',
                      b.VIST_STAT = '002'
                 FROM dbo.Send_Advertising a, dbo.Service_Robot_Send_Advertising b
                WHERE a.ROBO_RBID = @Rbid
                  AND a.ORDR_CODE = @OrdrCode
                  AND a.ID = b.SDAD_ID
                  AND b.CHAT_ID = @ChatID;
               
               SET @XMessage =
               (
                  SELECT TOP 1
                         a.FILE_ID AS '@fileid',
                         a.PAKT_TYPE AS '@filetype',
                         a.TEXT_MESG + CHAR(10) + CHAR(10)+ 
                         -- اطلاعاتی که ثبت شده در مورد پیام تبلیغاتی
                         CASE ISNULL(b.VIST_STAT, '001') WHEN '001' THEN N'😵 • ' WHEN '002' THEN N'🕶️ • ' END  + 
                         CASE ISNULL(b.LIKE_STAT, '000') WHEN '001' THEN N'👎 • ' WHEN '002' THEN N'👍 • ' ELSE N'' END +
                         CASE ISNULL(b.RTNG_NUM, 0) WHEN 0 THEN N'' ELSE CAST(b.RTNG_NUM AS VARCHAR(1)) + N' ⭐️ ' END + CHAR(10) + CHAR(10) + 
                         N'🤑 _سود شما از تبلیغات دریافتی_ ( *' + REPLACE( CONVERT(NVARCHAR, CONVERT(MONEY, b.AMNT), 1), '.00', '' ) + N' ' +  @AmntTypeDesc + N'* )' AS '@caption',
                         1 AS '@order',
                         a.INLN_KEYB_DNRM
                   FROM dbo.Send_Advertising a, dbo.Service_Robot_Send_Advertising b
                  WHERE a.ROBO_RBID = @Rbid
                    AND a.ID = b.SDAD_ID
                    AND a.ORDR_CODE = @OrdrCode
                    AND b.CHAT_ID = @ChatID
                  FOR XML PATH('Complex_InLineKeyboardMarkup')
               );               

               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               -- ارسال مجدد پیام تبلیغاتی برای مشتری
            END 
            ELSE IF @MenuText LIKE 'mailbox::sendedbox::menuadv::dislike::%'
            BEGIN
               -- Parameter is (Ordr_Code) for Send_Advertising
               SET @OrdrCode = @ParamText;
               UPDATE b
                  SET b.LIKE_STAT = '001',
                      b.VIST_STAT = '002'
                 FROM dbo.Send_Advertising a, dbo.Service_Robot_Send_Advertising b
                WHERE a.ROBO_RBID = @Rbid
                  AND a.ORDR_CODE = @OrdrCode
                  AND a.ID = b.SDAD_ID
                  AND b.CHAT_ID = @ChatID;
               
               SET @XMessage =
               (
                  SELECT TOP 1
                         a.FILE_ID AS '@fileid',
                         a.PAKT_TYPE AS '@filetype',
                         a.TEXT_MESG + CHAR(10) + CHAR(10) + 
                         -- اطلاعاتی که ثبت شده در مورد پیام تبلیغاتی
                         CASE ISNULL(b.VIST_STAT, '001') WHEN '001' THEN N'😵 • ' WHEN '002' THEN N'🕶️ • ' END  + 
                         CASE ISNULL(b.LIKE_STAT, '000') WHEN '001' THEN N'👎 • ' WHEN '002' THEN N'👍 • ' ELSE N'' END +
                         CASE ISNULL(b.RTNG_NUM, 0) WHEN 0 THEN N'' ELSE CAST(b.RTNG_NUM AS VARCHAR(1)) + N' ⭐️ ' END + CHAR(10) + CHAR(10) + 
                         N'🤑 _سود شما از تبلیغات دریافتی_ ( *' + REPLACE( CONVERT(NVARCHAR, CONVERT(MONEY, b.AMNT), 1), '.00', '' ) + N' ' +  @AmntTypeDesc + N'* )' AS '@caption',
                         1 AS '@order',
                         a.INLN_KEYB_DNRM
                   FROM dbo.Send_Advertising a, dbo.Service_Robot_Send_Advertising b
                  WHERE a.ROBO_RBID = @Rbid
                    AND a.ID = b.SDAD_ID
                    AND a.ORDR_CODE = @OrdrCode
                    AND b.CHAT_ID = @ChatID
                  FOR XML PATH('Complex_InLineKeyboardMarkup')
               );               

               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               -- ارسال مجدد پیام تبلیغاتی برای مشتری
            END 
            ELSE IF @MenuText LIKE 'mailbox::sendedbox::menuadv::rate::%'
            BEGIN
               -- Parameter is (Ordr_Code, Rate_Numb) for Send_Advertising
               SELECT @OrdrCode = CASE id WHEN 1 THEN item ELSE @OrdrCode END,
                      @Numb = CASE id WHEN 2 THEN item ELSE @Numb END
                 FROM dbo.SplitString(@ParamText, ',');
              
               UPDATE b
                  SET b.RTNG_NUM = @Numb,
                      b.VIST_STAT = '002'
                 FROM dbo.Send_Advertising a, dbo.Service_Robot_Send_Advertising b
                WHERE a.ROBO_RBID = @Rbid
                  AND a.ORDR_CODE = @OrdrCode
                  AND a.ID = b.SDAD_ID
                  AND b.CHAT_ID = @ChatID;
               
               SET @XMessage =
               (
                  SELECT TOP 1
                         a.FILE_ID AS '@fileid',
                         a.PAKT_TYPE AS '@filetype',
                         a.TEXT_MESG + CHAR(10) + CHAR(10) + 
                         -- اطلاعاتی که ثبت شده در مورد پیام تبلیغاتی
                         CASE ISNULL(b.VIST_STAT, '001') WHEN '001' THEN N'😵 • ' WHEN '002' THEN N'🕶️ • ' END  + 
                         CASE ISNULL(b.LIKE_STAT, '000') WHEN '001' THEN N'👎 • ' WHEN '002' THEN N'👍 • ' ELSE N'' END +
                         CASE ISNULL(b.RTNG_NUM, 0) WHEN 0 THEN N'' ELSE CAST(b.RTNG_NUM AS VARCHAR(1)) + N' ⭐️ ' END + CHAR(10) + CHAR(10) + 
                         N'🤑 _سود شما از تبلیغات دریافتی_ ( *' + REPLACE( CONVERT(NVARCHAR, CONVERT(MONEY, b.AMNT), 1), '.00', '' ) + N' ' +  @AmntTypeDesc + N'* )' AS '@caption',
                         1 AS '@order',
                         a.INLN_KEYB_DNRM
                   FROM dbo.Send_Advertising a, dbo.Service_Robot_Send_Advertising b
                  WHERE a.ROBO_RBID = @Rbid
                    AND a.ID = b.SDAD_ID
                    AND a.ORDR_CODE = @OrdrCode
                    AND b.CHAT_ID = @ChatID
                  FOR XML PATH('Complex_InLineKeyboardMarkup')
               );               

               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
            END             
            -- ##############################
            ELSE IF @MenuText IN ( 'mailbox::inbox::new', 'mailbox::inbox::read' )
            BEGIN
               SET @ParamText = (
                   CASE @MenuText
                        WHEN 'mailbox::inbox::new' THEN '001'
                        WHEN 'mailbox::inbox::read' THEN '002'
                        ELSE '000'                        
                   END  
               );
               -- منوهای اولیه ای که برای مدیریت باید ارسال شود را آماده میکنیم
               SET @XTemp =
               (
                   SELECT @Rbid AS '@rbid',
                          @ChatID AS '@chatid',
                          @UssdCode AS '@ussdcode',
                          'lessshowmesg' AS '@cmndtext',
                          @ParamText AS '@param'
                   FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml
               
               SET @XTemp =
               (
                   SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
               );
               
               SET @XMessage = (                   
                   SELECT 1 AS '@order', 
                          om.FILE_ID AS '@fileid',
                          om.IMAG_TYPE AS '@filetype',
                          N'پیام های دریافتی جدید' AS '@caption',
                          @xTemp
                     FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                      AND om.RBCN_TYPE = '024'
                      FOR XML PATH('Complex_InLineKeyboardMarkup')                       
               );
               
               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               GOTO L$EndSP;
            END 
            ELSE IF @MenuText IN ( 'mailbox::inbox::adv' )
            BEGIN
               -- منوهای اولیه ای که برای مدیریت باید ارسال شود را آماده میکنیم
               SET @XTemp =
               (
                   SELECT @Rbid AS '@rbid',
                          @ChatID AS '@chatid',
                          @UssdCode AS '@ussdcode',
                          'lessshowadvmesg' AS '@cmndtext'
                   FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml
               
               SET @XTemp =
               (
                   SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
               );
               
               SET @XMessage = (                   
                   SELECT 1 AS '@order', 
                          om.FILE_ID AS '@fileid',
                          om.IMAG_TYPE AS '@filetype',
                          N'پیام های تبلیغاتی دریافتی' AS '@caption',
                          @xTemp
                     FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                      AND om.RBCN_TYPE = '025'
                      FOR XML PATH('Complex_InLineKeyboardMarkup')                       
               );
               
               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               GOTO L$EndSP;
            END 
            ELSE IF @MenuText = 'mailbox::back'
            BEGIN
               SELECT @UssdCode = '*1*11#', @ChildUssdCode = '*1*11*0#';
               GOTO L$ReceiveMessage;
            END 
            ELSE IF @MenuText = 'mailbox::inbox::show::rplymesg'
            BEGIN
               UPDATE dbo.Service_Robot_Replay_Message
                  SET VIST_STAT = '002'
                WHERE RWNO = @ParamText;
                  
               SET @XMessage = (
                   SELECT CASE a.MESG_TYPE
                               WHEN '001' THEN 
                               (
                                 SELECT 1 AS '@order',
                                        a.MESG_TEXT AS '@caption',
                                        a.INLN_KEYB_DNRM
                                    FOR XML PATH ('InlineKeyboardMarkup'), TYPE
                               )
                               ELSE 
                               (
                                 SELECT 1 AS '@order',
                                        a.FILE_ID AS '@fileid',
                                        a.MESG_TYPE AS '@filetype',
                                        a.MESG_TEXT AS '@caption',
                                        a.INLN_KEYB_DNRM
                                    FOR XML PATH ('Complex_InLineKeyboardMarkup'), TYPE
                                )
                          END 
                     FROM dbo.Service_Robot_Replay_Message a
                    WHERE a.RWNO = @ParamText
               );
               
               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               GOTO L$EndSP;
            END 
            ELSE IF @MenuText IN ( 'mailbox::inbox::show::advteam', 'mailbox::inbox::show::advcamp' )
            BEGIN
               L$ShowAdvMessage:
               UPDATE dbo.Service_Robot_Send_Advertising
                  SET VIST_STAT = '002'
                WHERE RWNO = @ParamText;
                
               SET @XMessage = (
                   SELECT 1 AS '@order',
                          a.FILE_ID AS '@fileid',
                          a.PAKT_TYPE AS '@filetype',
                          a.TEXT_MESG AS '@caption',
                          a.INLN_KEYB_DNRM
                     FROM dbo.Service_Robot_Send_Advertising sa, dbo.Send_Advertising a
                    WHERE sa.RWNO = @ParamText
                      AND sa.SDAD_ID = a.ID
                      FOR XML PATH('Complex_InLineKeyboardMarkup')
               );
               
               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               GOTO L$EndSP;
            END 
            ELSE IF @MenuText IN ( 'mailbox::inbox::shop', 'mailbox::inbox::overhead', 'mailbox::inbox::softwareteam')
            BEGIN
               SET @ParamText = (
                   CASE @MenuText
                        WHEN 'mailbox::inbox::shop' THEN '001'
                        WHEN 'mailbox::inbox::overhead' THEN '002'
                        WHEN 'mailbox::inbox::softwareteam' THEN '003'
                   END  
               );
               -- منوهای اولیه ای که برای مدیریت باید ارسال شود را آماده میکنیم
               SET @XTemp =
               (
                   SELECT @Rbid AS '@rbid',
                          @ChatID AS '@chatid',
                          @UssdCode AS '@ussdcode',
                          'lessshowwhosmesg' AS '@cmndtext',
                          @ParamText AS '@param'
                   FOR XML PATH('RequestInLineQuery')
               );
               EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                    @XRet = @XTemp OUTPUT; -- xml
               
               SET @XTemp =
               (
                   SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
               );
               
               SET @XMessage = (                   
                   SELECT 1 AS '@order', 
                          om.FILE_ID AS '@fileid',
                          om.IMAG_TYPE AS '@filetype',
                          N'پیام های دریافتی' AS '@caption',
                          @xTemp
                     FROM dbo.Organ_Media om
                    WHERE om.ROBO_RBID = @Rbid
                      AND om.RBCN_TYPE = '024'
                      FOR XML PATH('Complex_InLineKeyboardMarkup')                       
               );
               
               SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
               GOTO L$EndSP;
            END 
        END 
        ELSE IF @MenuText IN (
           'receptionorder::show::crnt::cart', 'receptionorder::show::waiting::cart', 'receptionorder::show::working::cart', 'receptionorder::show::ended::cart', 
           'receptionorder::show::crnt::cart::items', 'receptionorder::show::waiting::cart::items', 'receptionorder::show::working::cart::items', 'receptionorder::show::ended::cart::items', 
           'receptionorder::ok', 'receptionorder::cancel', 'receptionorder::refresh'
        )
        BEGIN
           IF @MenuText = 'receptionorder::refresh'
           BEGIN
              SELECT @UssdCode = '*0#', @ChildUssdCode = '*0*8#'
              GOTO L$ReceptionOrder;
           END 
           ELSE IF @MenuText = 'receptionorder::ok'
           BEGIN
              SET @OrdrCode = @ParamText;
              UPDATE dbo.[Order]
                 SET ORDR_STAT = '002'
               WHERE CODE = @OrdrCode;
              
              SET @Message = (
                  SELECT N'📨 *ارسال درخواست سفارش*' + CHAR(10) + CHAR(10) + 
                         N'👈 *شماره درخواست شما* [ *' + CAST(@OrdrCode AS VARCHAR(30)) + N'* ] - 025' + CHAR(10) +
                         N'🔢 تعداد سفارشات درون صف [ *' + CAST(COUNT(o.CODE) AS VARCHAR(10)) + N'* ]'
                    FROM dbo.[Order] o
                   WHERE o.ORDR_TYPE = '025'
                     AND o.ORDR_STAT = '002'
              );
           END 
           ELSE IF @MenuText = 'receptionorder::cancel'
           BEGIN
              SET @OrdrCode = @ParamText;
              DELETE dbo.[Order]
               WHERE Code = @OrdrCode;
              
              SET @Message = (
                  SELECT N'📨 *انصراف درخواست سفارش*' + CHAR(10) + CHAR(10) + 
                         N'👈 *شماره درخواست شما* [ *' + CAST(@OrdrCode AS VARCHAR(30)) + N'* ] - 025' + CHAR(10) +
                         N'❌ درخواست شما حذف شد'
              );
           END 
           ELSE IF @MenuText IN ('receptionorder::show::crnt::cart', 'receptionorder::show::waiting::cart', 'receptionorder::show::working::cart', 'receptionorder::show::ended::cart')
           BEGIN
              SET @OrdrCode = @ParamText;             
              -- ایجاد خروجی برای نمایش درخواست ثبت شده برای محصول ارسالی
              -- منوهای اولیه ای که برای مدیریت باید ارسال شود را آماده میکنیم
              SET @XTemp =
              (
                 SELECT @Rbid AS '@rbid',
                        @ChatID AS '@chatid',
                        @UssdCode AS '@ussdcode',
                        CASE @MenuText
                             WHEN 'receptionorder::show::crnt::cart' THEN 'lessnewrecpordr'
                             WHEN 'receptionorder::show::waiting::cart' THEN 'lesswaitrecpordr'
                             WHEN 'receptionorder::show::working::cart' THEN 'lessworkrecpordr'
                             WHEN 'receptionorder::show::ended::cart' THEN 'lessendrecpordr'
                        END AS '@cmndtext',
                        @OrdrCode AS '@ordrcode'
                 FOR XML PATH('RequestInLineQuery')
              );
              EXEC dbo.CRET_ILQM_P @X = @XTemp,           -- xml
                                   @XRet = @XTemp OUTPUT; -- xml
              SET @XTemp =
              (
                 SELECT '1' AS '@order', @XTemp FOR XML PATH('InlineKeyboardMarkup')
              );
                             
              SET @Message = (
                  SELECT N'🟤 شماره درخواست [ *' + CAST(o.CODE AS VARCHAR(30)) + N'* ] ' + o.ORDR_TYPE + ' - ' + CAST(o.ORDR_TYPE_NUMB AS VARCHAR(30)) + CHAR(10) + CHAR(10) +
                         N'*اقلام  پذیرش انلاین*' + CHAR(10) + CHAR(10) +
                         (
                            SELECT N'👈 [ *' + e.DOMN_DESC + N'* ] ( _' + CAST(od.RWNO AS VARCHAR(30)) + N'_ ) ' + ISNULL(od.ORDR_DESC, N' ') + CHAR(10)
                              FROM dbo.Order_Detail od, dbo.[D$ELMT] e
                             WHERE od.ORDR_CODE = o.CODE
                               AND od.ELMN_TYPE = e.VALU
                               FOR XML PATH('')
                         )
                    FROM dbo.[Order] o
                   WHERE o.CODE = @OrdrCode
              );
               
              SET @XMessage =
              (
                 SELECT TOP 1
                        om.FILE_ID AS '@fileid',
                        om.IMAG_TYPE AS '@filetype',
                        @Message AS '@caption',
                        1 AS '@order'
                 FROM dbo.Organ_Media om
                 WHERE om.ROBO_RBID = @Rbid
                       AND om.RBCN_TYPE = '007'
                       AND om.IMAG_TYPE = '002'
                       AND om.STAT = '002'
                 FOR XML PATH('Complex_InLineKeyboardMarkup')
              );
              SET @XMessage.modify('insert sql:variable("@xtemp") as first into (//Complex_InLineKeyboardMarkup)[1]');

              SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
              GOTO L$EndSP;
           END 
           ELSE IF @MenuText IN ('receptionorder::show::crnt::cart::items', 'receptionorder::show::waiting::cart::items', 'receptionorder::show::working::cart::items', 'receptionorder::show::ended::cart::items')
           BEGIN
              SET @OrdrCode = @ParamText;
              SET @XMessage =
              (
                  SELECT od.ELMN_TYPE AS '@filetype',
                         od.IMAG_PATH AS '@fileid',
                         ISNULL(od.ORDR_DESC, e.DOMN_DESC) AS '@caption',
                         ROW_NUMBER() OVER (ORDER BY od.RWNO) AS '@order'
                    FROM dbo.Order_Detail od, dbo.[D$ELMT] e
                   WHERE od.ORDR_CODE = @OrdrCode
                     AND od.ELMN_TYPE = e.VALU
                  FOR XML PATH('Complex_InLineKeyboardMarkup'), ROOT('Message')
              );
              SET @Message = CONVERT(NVARCHAR(MAX), @XMessage);
              GOTO L$EndSP;
           END 
        END 
        ELSE IF @MenuText IN ('humnreso::rqstsupl::aprov', 'humnreso::rqstsupl::notaprov')
        BEGIN
         -- تایید درخواست تامین کننده  
         IF @MenuText = 'humnreso::rqstsupl::aprov'
         BEGIN
            -- برای اینکار بایستی ابندا جدول تامین کننده ثبت شود            
            INSERT INTO dbo.Service_Robot_Seller ( SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,CODE ,CONF_STAT ,CONF_DATE )
            SELECT sr.SERV_FILE_NO, sr.ROBO_RBID, dbo.GNRT_NVID_U(), '002', GETDATE()            
              FROM dbo.Service_Robot sr
             WHERE sr.ROBO_RBID = @Rbid
               AND sr.CHAT_ID = @ParamText;
            
            -- و همچنین دسترسی به منوی تامین کننده
            MERGE dbo.Service_Robot_Group T
            USING (SELECT * FROM dbo.Service_Robot_Group) S
            ON (T.SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO AND
                T.SRBT_ROBO_RBID = S.SRBT_ROBO_RBID AND 
                T.GROP_GPID = S.GROP_GPID AND
                T.SRBT_ROBO_RBID = @Rbid AND
                T.CHAT_ID = @ParamText AND 
                t.GROP_GPID = 137)
            WHEN NOT MATCHED THEN 
               INSERT ( SRBT_SERV_FILE_NO, SRBT_ROBO_RBID, GROP_GPID, STAT ) 
               VALUES(s.SRBT_SERV_FILE_NO, s.SRBT_ROBO_RBID, 137, '002')
            WHEN MATCHED THEN 
               UPDATE SET
                  T.STAT = '002';
            
            SET @Message = N'✅ عملیات تایید درخواست تامین کننده با موفقیت ثبت شد';
         END 
         ELSE IF @MenuText = 'humnreso::rqstsupl::notaprov'
         BEGIN
            SET @Message = N'🚫 درخواست تامین کننده لغو شد';
         END 
        END 
        ELSE IF @MenuText IN ('selrtarf', 'selr')
        BEGIN
         IF @MenuText = 'selrtarf'
         BEGIN
           -- میخواهیم چک کنیم که این کالا توسط چه فروشنده ای ارائه میگردد
           SET @Message = (
               SELECT CASE 
                        WHEN ISNULL(s.SHOP_NAME, '') != '' THEN -- اگر فروشگاه ثبت شده باشد
                             N'*' + s.SHOP_NAME + CHAR(10) + N'* @' + ISNULL(s.SHOP_BOT, N'') + CHAR(10) + CHAR(10)                              
                        ELSE -- اگر ثبت نشده باشد
                             N''
                      END +
                      N'👤 *' + sr.NAME + N'*' + CHAR(10) + 
                      N'📱 *' + sr.CELL_PHON + N'*' + CHAR(10) + CHAR(10) + 
                      N'📌 *' + ISNULL(s.SHOP_POST_ADRS, N'آدرس ثبت شده وجود ندارد') + N'*' + CHAR(10) +
                      CASE WHEN ISNULL(s.SHOP_CORD_X, 0) != 0 AND ISNULL(s.SHOP_CORD_Y, 0) != 0 THEN  
                           dbo.STR_FRMT_U(N'[📍 مکان فروشگاه](https://www.google.com/maps?q=loc:{0},{1})', CAST(s.SHOP_CORD_X AS VARCHAR(30)) + N',' + CAST(s.SHOP_CORD_Y AS VARCHAR(30))) + CHAR(10) 
                           ELSE N''
                      END + CHAR(10) + 
                      N'* توضیحات :' + ISNULL(s.SHOP_DESC, N'توضیحاتی ثبت نشده') + N'*'
                 FROM dbo.Service_Robot_Seller_Product sp, dbo.Service_Robot_Seller s, dbo.Service_Robot sr
                WHERE sp.SRBS_CODE = s.CODE
                  AND sp.TARF_CODE = @ParamText
                  AND s.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                  AND s.SRBT_ROBO_RBID = sr.ROBO_RBID
           );
         END 
         ELSE IF @MenuText = 'selr'
         BEGIN
            -- میخواهیم چک کنیم که این کالا توسط چه فروشنده ای ارائه میگردد
           SET @Message = (
               SELECT CASE 
                        WHEN ISNULL(s.SHOP_NAME, '') != '' THEN -- اگر فروشگاه ثبت شده باشد
                             N'*' + s.SHOP_NAME + CHAR(10) + N'* @' + ISNULL(s.SHOP_BOT, N'') + CHAR(10) + CHAR(10)                              
                        ELSE -- اگر ثبت نشده باشد
                             N''
                      END +
                      N'👤 *' + sr.NAME + N'*' + CHAR(10) + 
                      N'📱 *' + sr.CELL_PHON + N'*' + CHAR(10) + CHAR(10) + 
                      N'📌 *' + ISNULL(s.SHOP_POST_ADRS, N'آدرس ثبت شده وجود ندارد') + N'*' + CHAR(10) +
                      CASE WHEN ISNULL(s.SHOP_CORD_X, 0) != 0 AND ISNULL(s.SHOP_CORD_Y, 0) != 0 THEN  
                           dbo.STR_FRMT_U(N'[📍 مکان فروشگاه](https://www.google.com/maps?q=loc:{0},{1})', CAST(s.SHOP_CORD_X AS VARCHAR(30)) + N',' + CAST(s.SHOP_CORD_Y AS VARCHAR(30))) + CHAR(10) 
                           ELSE N''
                      END + CHAR(10) + 
                      N'* توضیحات :' + ISNULL(s.SHOP_DESC, N'توضیحاتی ثبت نشده') + N'*'
                 FROM dbo.Service_Robot_Seller s, dbo.Service_Robot sr
                WHERE s.CODE = @ParamText
                  AND s.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                  AND s.SRBT_ROBO_RBID = sr.ROBO_RBID
           );
         END 
        END 
        -- #######################################################################

        L$EndSP:
        COMMIT TRANSACTION [T$ANAR_SHOP_P];
        IF @Message IS NULL
            SET @Message = N'🚫 خطا' + CHAR(10) + N'در اجرای دستور مشکلی به وجود آمده است';
        SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
        SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
    END TRY
    BEGIN CATCH
        DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR(@ErorMesg, 16, 1);
        ROLLBACK TRANSACTION [T$ANAR_SHOP_P];
    END CATCH;
END;
GO
