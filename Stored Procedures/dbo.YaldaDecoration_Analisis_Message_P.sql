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
 PROCEDURE [dbo].[YaldaDecoration_Analisis_Message_P] @X XML, @XResult XML OUT
AS
BEGIN
    DECLARE @UssdCode VARCHAR(250) ,
        @ChildUssdCode VARCHAR(250) ,
        @MenuText NVARCHAR(250) ,
        @Message NVARCHAR(MAX) ,
        @XMessage XML ,
        @XTemp XML ,
        @ChatID BIGINT ,
        @CordX FLOAT ,
        @CordY FLOAT ,
        @PhotoFileId VARCHAR(MAX) ,
        @VideoFileId VARCHAR(MAX) ,
        @DocumentFileId VARCHAR(MAX) ,
        @ElmnType VARCHAR(3) ,
        @Item NVARCHAR(1000) ,
        @Name NVARCHAR(100) ,
        @Numb NVARCHAR(100) ,
        @MimeType VARCHAR(100) ,
        @Index BIGINT = 0 ,
        @Token VARCHAR(100) ,
        @Rbid BIGINT;
	
    SELECT  @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]',
                                                    'VARCHAR(250)') ,
            @Token = @X.query('/Robot').value('(Robot/@token)[1]',
                                              'VARCHAR(100)') ,
            @ChildUssdCode = @X.query('//Message').value('(Message/@childussd)[1]',
                                                         'VARCHAR(250)') ,
            @ChatID = @X.query('//Message').value('(Message/@chatid)[1]',
                                                  'BIGINT') ,
            @ElmnType = @X.query('//Message').value('(Message/@elmntype)[1]',
                                                    'VARCHAR(3)') ,
            @MimeType = @X.query('//Message').value('(Message/@mimetype)[1]',
                                                    'VARCHAR(100)') ,
            @MenuText = @X.query('//Text').value('.', 'NVARCHAR(250)') ,
            @CordX = @X.query('//Location').value('(Location/@latitude)[1]',
                                                  'FLOAT') ,
            @CordY = @X.query('//Location').value('(Location/@longitude)[1]',
                                                  'FLOAT') ,
            @PhotoFileId = @X.query('//Photo').value('(Photo/@fileid)[1]',
                                                     'NVARCHAR(MAX)') ,
            @VideoFileId = @X.query('//Video').value('(Video/@fileid)[1]',
                                                     'NVARCHAR(MAX)') ,
            @DocumentFileId = @X.query('//Document').value('(Document/@fileid)[1]',
                                                           'NVARCHAR(MAX)');
	
    SELECT  @Rbid = RBID
    FROM    dbo.Robot
    WHERE   TKON_CODE = @Token;
   --insert into logs (x) values (@x); 

    IF @UssdCode IN ( '*6*0#' )
        BEGIN
            SELECT  @Message = dbo.GET_ODST_U('<Request robotokn="' + @Token
                                              + '" chatid="'
                                              + CAST(@ChatID AS VARCHAR(32))
                                              + '" ordrnumb="' + @MenuText
                                              + '" allstat="002"/>');
            GOTO L$EndSP;
        END;   
    ELSE
        IF @UssdCode IN ( '*6*1#' )
            BEGIN
                SELECT  @Message = dbo.GET_ODST_U('<Request robotokn="'
                                                  + @Token + '" chatid="'
                                                  + CAST(@ChatID AS VARCHAR(32))
                                                  + '" ownrname="%'
                                                  + @MenuText
                                                  + '%" allstat="002"/>');
                GOTO L$EndSP;
            END;   
    IF @UssdCode IN ( '*1*1#' )
        BEGIN
            DECLARE @LowDate DATE ,
                @HighDate DATE = GETDATE() ,
                @OrdrApbsRwno INT = 1;
            SELECT  @LowDate = DATEADD(DAY,
                                       ( 1 + ( ( 6 + DATEPART(dw, GETDATE())
                                                 + @@DATEFIRST ) % 7 ) ) * -1,
                                       GETDATE());    
            IF @ChildUssdCode IN ( '*1*1*0#' )
                BEGIN
                    L$BaseSaleQuery:
                    SELECT  @Message = ( SELECT T.TITL_DESC + N' - '
                                                + CAST(T.SALE_CONT AS NVARCHAR(10))
                                                + CHAR(10) + T.SALE_DESC
                                                + CHAR(10)
                                         FROM   ( SELECT    abd_o.TITL_DESC ,
                                                            COUNT(*) AS SALE_CONT ,
                                                            ( SELECT
                                                              N'👈 '
                                                              + CAST(o1.ORDR_NUMB AS VARCHAR(10))
                                                              + N' '
                                                              + o1.OWNR_NAME
                                                              + N' - '
                                                              + pr1.NAME
                                                              + CHAR(10)
                                                              FROM
                                                              dbo.[Order] o1 ,
                                                              dbo.Order_State os1 ,
                                                              dbo.Order_Access oa1 ,
                                                              dbo.Personal_Robot pr1 ,
                                                              dbo.App_Base_Define abd_o1 ,
                                                              dbo.App_Base_Define abd_os1
                                                              WHERE
                                                              o1.PROB_ROBO_RBID = @Rbid
                                                              AND o1.PROB_SERV_FILE_NO = pr1.SERV_FILE_NO
                                                              AND o1.PROB_ROBO_RBID = pr1.ROBO_RBID
                                                              AND o1.CODE = os1.ORDR_CODE
                                                              AND os1.APBS_CODE = abd_os1.CODE
                                                              AND abd_os1.RWNO IN (
                                                              3 )
                                                              AND o1.CODE = oa1.ORDR_CODE
                                                              AND oa1.CHAT_ID = @ChatID
                                                              AND o1.APBS_CODE = abd_o1.CODE
                                                              AND abd_o1.TITL_DESC = abd_o.TITL_DESC
                                                              AND CAST(o1.STRT_DATE AS DATE) BETWEEN @LowDate
                                                              AND
                                                              @HighDate
                                                            FOR
                                                              XML
                                                              PATH('')
                                                            ) AS SALE_DESC
                                                  FROM      dbo.[Order] o ,
                                                            dbo.Order_State os ,
                                                            dbo.Order_Access oa ,
                                                            dbo.App_Base_Define abd_oa ,
                                                            dbo.App_Base_Define abd_o
                                                  WHERE     o.PROB_ROBO_RBID = @Rbid
                                                            AND o.CODE = os.ORDR_CODE
                                                            AND o.CODE = oa.ORDR_CODE
                                                            AND os.APBS_CODE = abd_oa.CODE
                                                            AND o.APBS_CODE = abd_o.CODE
                                                            AND CAST(o.STRT_DATE AS DATE) BETWEEN @LowDate
                                                              AND
                                                              @HighDate
                                                            AND ( oa.CHAT_ID = @ChatID )
                                                            AND abd_oa.RWNO IN (
                                                            3 )
                                                  GROUP BY  abd_o.TITL_DESC
                                                ) T
                                       FOR
                                         XML PATH('')
                                       );
                END;
            ELSE
                IF @ChildUssdCode = '*1*1*1#'
                    BEGIN
                        SET @LowDate = GETDATE();
                        SET @HighDate = GETDATE();
                        GOTO L$BaseSaleQuery;
                    END;
                ELSE
                    IF @ChildUssdCode = '*1*1*2#'
                        BEGIN
                            L$BaseSale1Query:
                            SELECT  @Message = ( SELECT T.TITL_DESC + N' - '
                                                        + CAST(T.SALE_CONT AS NVARCHAR(10))
                                                        + CHAR(10)
                                                        + T.SALE_DESC
                                                        + CHAR(10)
                                                 FROM   ( SELECT
                                                              abd_o.TITL_DESC ,
                                                              COUNT(*) AS SALE_CONT ,
                                                              ( SELECT
                                                              N'👈 '
                                                              + CAST(o1.ORDR_NUMB AS VARCHAR(10))
                                                              + N' '
                                                              + o1.OWNR_NAME
                                                              + N' - '
                                                              + pr1.NAME
                                                              + CHAR(10)
                                                              FROM
                                                              dbo.[Order] o1 ,
                                                              dbo.Order_State os1 ,
                                                              dbo.Order_Access oa1 ,
                                                              dbo.Personal_Robot pr1 ,
                                                              dbo.App_Base_Define abd_o1 ,
                                                              dbo.App_Base_Define abd_os1
                                                              WHERE
                                                              o1.PROB_ROBO_RBID = @Rbid
                                                              AND o1.PROB_SERV_FILE_NO = pr1.SERV_FILE_NO
                                                              AND o1.PROB_ROBO_RBID = pr1.ROBO_RBID
                                                              AND o1.CODE = os1.ORDR_CODE
                                                              AND os1.APBS_CODE = abd_os1.CODE
                                                              AND abd_os1.RWNO IN (
                                                              3 )
                                                              AND o1.CODE = oa1.ORDR_CODE
                                                              AND oa1.CHAT_ID = @ChatID
                                                              AND o1.APBS_CODE = abd_o1.CODE
                                                              AND abd_o1.TITL_DESC = abd_o.TITL_DESC
                                                              AND CAST(o1.STRT_DATE AS DATE) BETWEEN @LowDate
                                                              AND
                                                              @HighDate
                                                              AND abd_o1.RWNO IN (
                                                              @OrdrApbsRwno )
                                                              FOR
                                                              XML
                                                              PATH('')
                                                              ) AS SALE_DESC
                                                          FROM
                                                              dbo.[Order] o ,
                                                              dbo.Order_State os ,
                                                              dbo.Order_Access oa ,
                                                              dbo.App_Base_Define abd_oa ,
                                                              dbo.App_Base_Define abd_o
                                                          WHERE
                                                              o.PROB_ROBO_RBID = @Rbid
                                                              AND o.CODE = os.ORDR_CODE
                                                              AND o.CODE = oa.ORDR_CODE
                                                              AND os.APBS_CODE = abd_oa.CODE
                                                              AND o.APBS_CODE = abd_o.CODE
                                                              AND CAST(o.STRT_DATE AS DATE) BETWEEN @LowDate
                                                              AND
                                                              @HighDate
                                                              AND ( oa.CHAT_ID = @ChatID )
                                                              AND abd_oa.RWNO IN (
                                                              3 )
                                                              AND abd_o.RWNO IN (
                                                              @OrdrApbsRwno )
                                                          GROUP BY abd_o.TITL_DESC
                                                        ) T
                                               FOR
                                                 XML PATH('')
                                               );
                        END;
                    ELSE
                        IF @ChildUssdCode = '*1*1*3#'
                            BEGIN
                                SET @OrdrApbsRwno = 2;
                                GOTO L$BaseSale1Query;
                            END;
                        ELSE
                            IF @ChildUssdCode = '*1*1*4#'
                                BEGIN
                                    DECLARE C$SumSale114 CURSOR
                                    FOR
                                    SELECT  pr.CHAT_ID ,
                                            pr.NAME ,
                                            ao.TITL_DESC ,
                                            COUNT(*) AS Cont_Sale ,
                                            SUM(ISNULL(os.AMNT, 0)) AS Amnt_Sale
                                    FROM    dbo.App_Base_Define ao ,
                                            dbo.[Order] o ,
                                            dbo.Personal_Robot pr ,
                                            dbo.Order_State os ,
                                            dbo.App_Base_Define aos ,
                                            dbo.Order_Access oa
                                    WHERE   ao.CODE = o.APBS_CODE
                                            AND o.PROB_SERV_FILE_NO = pr.SERV_FILE_NO
                                            AND o.PROB_ROBO_RBID = pr.ROBO_RBID
                                            AND o.CODE = os.ORDR_CODE
                                            AND os.APBS_CODE = aos.CODE
                                            AND aos.RWNO IN ( 3 ) -- بیعانه داده باشد
                                            AND o.CODE = oa.ORDR_CODE
                                            AND oa.CHAT_ID = @ChatID
                                            AND pr.ROBO_RBID = @Rbid
                                            AND os.AMNT_TYPE = '001' -- درآمد
                                    GROUP BY pr.CHAT_ID ,
                                            pr.NAME ,
                                            ao.TITL_DESC
                                    ORDER BY pr.CHAT_ID;
            
                                    DECLARE @ContSale BIGINT ,
                                        @SumAmntSale BIGINT ,
                                        @TotlSumAmntSale BIGINT = 0;
                                    SET @Index = NULL;
                                    SET @Message = '';
                                    OPEN [C$SumSale114];
                                    L$Loop114:
                                    FETCH NEXT FROM [C$SumSale114] INTO @ChatID,
                                        @Name, @MenuText, @ContSale,
                                        @SumAmntSale;
            
                                    IF @@FETCH_STATUS <> 0
                                        GOTO L$EndLoop114;
            
                                    IF @Index IS NOT NULL
                                        AND @Index != @ChatID
                                        BEGIN
                                            SET @Message += CHAR(10)
                                                + N'جمع مبلغ فروش : 💰 '
                                                + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, @TotlSumAmntSale), 1),
                                                          '.00', '') + CHAR(10)
                                                + CHAR(10);
                                            SET @TotlSumAmntSale = 0;
                                        END;
            
                                    IF @Index IS NULL
                                        OR @Index != @ChatID
                                        BEGIN
                                            SET @Index = @ChatID;
                                            SET @Message += N'👤 ' + @Name
                                                + N' : ';
                                        END;
            
                                    SET @TotlSumAmntSale += @SumAmntSale;               
                                    SET @Message += N'🛍 ' + @MenuText
                                        + N' : '
                                        + CAST(@ContSale AS VARCHAR(10))
                                        + N', ';                  
            
                                    GOTO L$Loop114;
                                    L$EndLoop114:
                                    SET @Message += CHAR(10)
                                        + N'جمع مبلغ فروش : 💰 '
                                        + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, @TotlSumAmntSale), 1),
                                                  '.00', '') + CHAR(10);
                                    CLOSE [C$SumSale114];
                                    DEALLOCATE [C$SumSale114];     
                                END;
        END;
    ELSE
        IF @UssdCode IN ( '*1*3#' )
            BEGIN
                SET @LowDate = GETDATE();
                SET @HighDate = GETDATE();

                IF @ChildUssdCode IN ( '*1*3*0#' )
                    BEGIN
                        SELECT  @Message = N'💳 گزارش پیش پرداختها ' + CHAR(10)
                                + ( SELECT DISTINCT
                                            N'👤 ' + o.OWNR_NAME + N' ( '
                                            + CAST(o.ORDR_NUMB AS VARCHAR(10))
                                            + N' ) - ' + pr.NAME + CHAR(10)
                                    FROM    dbo.[Order] o ,
                                            dbo.Order_State os ,
                                            dbo.App_Base_Define aos ,
                                            dbo.Personal_Robot pr ,
                                            dbo.Order_Access oa
                                    WHERE   o.CODE = os.ORDR_CODE
                                            AND os.APBS_CODE = aos.CODE
                                            AND aos.RWNO IN ( 3 )
                                            AND pr.SERV_FILE_NO = o.PROB_SERV_FILE_NO
                                            AND pr.ROBO_RBID = o.PROB_ROBO_RBID
                                            AND o.CODE = oa.ORDR_CODE
                                            AND oa.CHAT_ID = @ChatID
                                            AND pr.ROBO_RBID = @Rbid
                                            AND CAST(os.STAT_DATE AS DATE) BETWEEN CAST(DATEADD(DAY,
                                                              -1, GETDATE()) AS DATE)
                                                              AND
                                                              CAST(GETDATE() AS DATE)
                                  FOR
                                    XML PATH('')
                                  );
                    END;   
                ELSE
                    IF @ChildUssdCode IN ( '*1*3*2#' )
                        BEGIN
                            SELECT  @Message = ( SELECT DISTINCT
                                                        N'👤 ' + o.OWNR_NAME
                                                        + N' ( '
                                                        + CAST(o.ORDR_NUMB AS VARCHAR(10))
                                                        + N' ) 💰 کل مبلغ : '
                                                        + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, ( ISNULL(o.EXPN_AMNT,
                                                              0)
                                                              + ISNULL(o.EXTR_PRCT,
                                                              0) )), 1), '.00',
                                                              '')
                                                        + N' 💳 میزان بدهی : '
                                                        + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, ISNULL(o.DEBT_DNRM,
                                                              0)), 1), '.00',
                                                              '') + N' - '
                                                        + pr.NAME + CHAR(10)
                                                 FROM   dbo.[Order] o ,
                                                        dbo.Order_State os ,
                                                        dbo.App_Base_Define aos ,
                                                        dbo.Personal_Robot pr ,
                                                        dbo.Order_Access oa
                                                 WHERE  o.CODE = os.ORDR_CODE
                                                        AND os.APBS_CODE = aos.CODE
                                                        AND aos.RWNO NOT IN (
                                                        8 )
                                                        AND pr.SERV_FILE_NO = o.PROB_SERV_FILE_NO
                                                        AND pr.ROBO_RBID = o.PROB_ROBO_RBID
                                                        AND o.CODE = oa.ORDR_CODE
                                                        AND oa.CHAT_ID = @ChatID
                                                        AND pr.ROBO_RBID = @Rbid
                                                        AND ( ( ISNULL(o.EXPN_AMNT,
                                                              0)
                                                              + ISNULL(o.EXTR_PRCT,
                                                              0) ) / 2 ) >= ISNULL(o.DEBT_DNRM,
                                                              0)
                 --AND CAST(os.STAT_DATE AS DATE) BETWEEN CAST(DATEADD(DAY, -1, GETDATE()) AS DATE) AND CAST(GETDATE() AS DATE)
                                               FOR
                                                 XML PATH('')
                                               );
                        END;
                    ELSE
                        IF @ChildUssdCode IN ( '*1*3*3#' )
                            BEGIN
                                SELECT  @Message = ( SELECT DISTINCT
                                                            N'👤 '
                                                            + o.OWNR_NAME
                                                            + N' ( '
                                                            + CAST(o.ORDR_NUMB AS VARCHAR(10))
                                                            + N' ) - '
                                                            + pr.NAME
                                                            + CHAR(10)
                                                     FROM   dbo.[Order] o ,
                                                            dbo.Order_State os ,
                                                            dbo.App_Base_Define aos ,
                                                            dbo.Personal_Robot pr ,
                                                            dbo.Order_Access oa
                                                     WHERE  o.CODE = os.ORDR_CODE
                                                            AND os.APBS_CODE = aos.CODE
                                                            AND aos.RWNO NOT IN (
                                                            8 )
                                                            AND pr.SERV_FILE_NO = o.PROB_SERV_FILE_NO
                                                            AND pr.ROBO_RBID = o.PROB_ROBO_RBID
                                                            AND o.CODE = oa.ORDR_CODE
                                                            AND oa.CHAT_ID = @ChatID
                                                            AND pr.ROBO_RBID = @Rbid
                                                            AND ISNULL(o.DEBT_DNRM,
                                                              0) <= 0
                 --AND CAST(os.STAT_DATE AS DATE) BETWEEN CAST(DATEADD(DAY, -1, GETDATE()) AS DATE) AND CAST(GETDATE() AS DATE)
                                                   FOR
                                                     XML PATH('')
                                                   );
                            END;
                        ELSE
                            IF @ChildUssdCode IN ( '*1*3*4#' )
                                BEGIN
                                    L$PaymentAmnt:
                                    SELECT  @Message = ( SELECT
                                                              CAST(ROW_NUMBER() OVER ( ORDER BY os.STAT_DATE DESC ) AS VARCHAR(10))
                                                              + N' - '
                                                              + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, os.AMNT), 1),
                                                              '.00', '')
                                                              + N' 💰 ( '
                                                              + CASE RIGHT(CONVERT(VARCHAR(15), CAST(os.STAT_DATE AS TIME), 100),
                                                              2)
                                                              WHEN 'AM'
                                                              THEN N'قبل از ظهر'
                                                              ELSE N'بعد از ظهر'
                                                              END + N' )'
                                                              + CHAR(10)
                                                         FROM dbo.[Order] o ,
                                                              dbo.Order_State os ,
                                                              dbo.App_Base_Define aos ,
                                                              dbo.Personal_Robot pr ,
                                                              dbo.Order_Access oa
                                                         WHERE
                                                              o.CODE = os.ORDR_CODE
                                                              AND os.APBS_CODE = aos.CODE
                                                              AND aos.RWNO IN (
                                                              3 )
                                                              AND pr.SERV_FILE_NO = o.PROB_SERV_FILE_NO
                                                              AND pr.ROBO_RBID = o.PROB_ROBO_RBID
                                                              AND o.CODE = oa.ORDR_CODE
                                                              AND oa.CHAT_ID = @ChatID
                                                              AND pr.ROBO_RBID = @Rbid
                                                              AND CAST(os.STAT_DATE AS DATE) BETWEEN CAST(@LowDate AS DATE)
                                                              AND
                                                              CAST(@HighDate AS DATE)
                                                       FOR
                                                         XML PATH('')
                                                       );
                                END; 
                            ELSE
                                IF @ChildUssdCode IN ( '*1*3*5#' )
                                    BEGIN
                                        SELECT  @LowDate = DATEADD(DAY,
                                                              ( 1 + ( ( 6
                                                              + DATEPART(dw,
                                                              GETDATE())
                                                              + @@DATEFIRST )
                                                              % 7 ) ) * -1,
                                                              GETDATE());    
                                        SET @HighDate = GETDATE();
            
                                        SELECT  @Message = ( SELECT
                                                              dbo.GET_CDWD_U(os.STAT_DATE)
                                                              + N' : '
                                                              + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(ISNULL(os.AMNT,
                                                              0))), 1), '.00',
                                                              '') + N' 💰'
                                                              + CHAR(10)
                                                             FROM
                                                              dbo.[Order] o ,
                                                              dbo.Order_State os ,
                                                              dbo.App_Base_Define aos ,
                                                              dbo.Personal_Robot pr ,
                                                              dbo.Order_Access oa
                                                             WHERE
                                                              o.CODE = os.ORDR_CODE
                                                              AND os.APBS_CODE = aos.CODE
                                                              AND aos.RWNO IN (
                                                              3 )
                                                              AND pr.SERV_FILE_NO = o.PROB_SERV_FILE_NO
                                                              AND pr.ROBO_RBID = o.PROB_ROBO_RBID
                                                              AND o.CODE = oa.ORDR_CODE
                                                              AND oa.CHAT_ID = @ChatID
                                                              AND pr.ROBO_RBID = @Rbid
                                                              AND CAST(os.STAT_DATE AS DATE) BETWEEN CAST(@LowDate AS DATE)
                                                              AND
                                                              CAST(@HighDate AS DATE)
                                                             GROUP BY dbo.GET_CDWD_U(os.STAT_DATE)
                                                             ORDER BY dbo.GET_CDWD_U(os.STAT_DATE)
                                                           FOR
                                                             XML
                                                              PATH('')
                                                           );  
                                    END;
                                ELSE
                                    IF @ChildUssdCode IN ( '*1*3*6#' )
                                        BEGIN
                                            SELECT  @LowDate = DATEADD(DAY,
                                                              RIGHT(dbo.GET_MTOS_U(GETDATE()),
                                                              2) * -1,
                                                              GETDATE());    
                                            SET @HighDate = GETDATE();
            
                                            SELECT  @Message = ( SELECT
                                                              dbo.GET_CDWM_U(os.STAT_DATE)
                                                              + N' : '
                                                              + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(ISNULL(os.AMNT,
                                                              0))), 1), '.00',
                                                              '') + N' 💰'
                                                              + CHAR(10)
                                                              FROM
                                                              dbo.[Order] o ,
                                                              dbo.Order_State os ,
                                                              dbo.App_Base_Define aos ,
                                                              dbo.Personal_Robot pr ,
                                                              dbo.Order_Access oa
                                                              WHERE
                                                              o.CODE = os.ORDR_CODE
                                                              AND os.APBS_CODE = aos.CODE
                                                              AND aos.RWNO IN (
                                                              3 )
                                                              AND pr.SERV_FILE_NO = o.PROB_SERV_FILE_NO
                                                              AND pr.ROBO_RBID = o.PROB_ROBO_RBID
                                                              AND o.CODE = oa.ORDR_CODE
                                                              AND oa.CHAT_ID = @ChatID
                                                              AND pr.ROBO_RBID = @Rbid
                                                              AND CAST(os.STAT_DATE AS DATE) BETWEEN CAST(@LowDate AS DATE)
                                                              AND
                                                              CAST(@HighDate AS DATE)
                                                              GROUP BY dbo.GET_CDWM_U(os.STAT_DATE)
                                                              ORDER BY dbo.GET_CDWM_U(os.STAT_DATE)
                                                              FOR
                                                              XML
                                                              PATH('')
                                                              );  
                                        END;
            END;
        ELSE
            IF @UssdCode IN ( '*1#' )
                BEGIN
                    IF @ChildUssdCode IN ( '*1*4#' )
                        BEGIN
                            SELECT  @Message = ( SELECT DISTINCT
                                                        N'👤 ' + o.OWNR_NAME
                                                        + N' ( '
                                                        + CAST(o.ORDR_NUMB AS VARCHAR(10))
                                                        + N' ) - ' + pr.NAME
                                                        + CHAR(10)
                                                 FROM   dbo.[Order] o ,
                                                        dbo.Personal_Robot pr ,
                                                        dbo.Order_Access oa
                                                 WHERE  pr.SERV_FILE_NO = o.PROB_SERV_FILE_NO
                                                        AND pr.ROBO_RBID = o.PROB_ROBO_RBID
                                                        AND o.CODE = oa.ORDR_CODE
                                                        AND oa.CHAT_ID = @ChatID
                                                        AND pr.ROBO_RBID = @Rbid
                                                        AND ISNULL(o.PYMT_AMNT_DNRM,
                                                              0) = 0
                                               FOR
                                                 XML PATH('')
                                               );
                        END;
                    ELSE
                        IF @ChildUssdCode IN ( '*1*6#' )
                            BEGIN
                                SELECT  @Message = ( SELECT DISTINCT
                                                            N'👤 '
                                                            + o.OWNR_NAME
                                                            + N' ( '
                                                            + CAST(o.ORDR_NUMB AS VARCHAR(10))
                                                            + N' ) - '
                                                            + pr.NAME
                                                            + CHAR(10)
                                                     FROM   dbo.[Order] o ,
                                                            dbo.Order_State os ,
                                                            dbo.App_Base_Define aos ,
                                                            dbo.Personal_Robot pr ,
                                                            dbo.Order_Access oa
                                                     WHERE  o.CODE = os.ORDR_CODE
                                                            AND os.APBS_CODE = aos.CODE
                                                            AND aos.RWNO IN (
                                                            7 )
                                                            AND pr.SERV_FILE_NO = o.PROB_SERV_FILE_NO
                                                            AND pr.ROBO_RBID = o.PROB_ROBO_RBID
                                                            AND o.CODE = oa.ORDR_CODE
                                                            AND oa.CHAT_ID = @ChatID
                                                            AND pr.ROBO_RBID = @Rbid
                                                   FOR
                                                     XML PATH('')
                                                   );
                            END;
                END;
            ELSE
                IF @UssdCode IN ( '*1*5#' )
                    BEGIN
      
                        IF @ChildUssdCode IN ( '*1*5*0#' )
                            BEGIN
                                SELECT  @Message = ( SELECT DISTINCT
                                                            +N'📅  '
                                                            + dbo.GET_CDTS_U(dbo.GET_MTOS_U(os.STAT_DATE))
                                                            + N'👤 '
                                                            + o.OWNR_NAME
                                                            + N' ( '
                                                            + CAST(o.ORDR_NUMB AS VARCHAR(10))
                                                            + N' ) - '
                                                            + pr.NAME
                                                            + CHAR(10)
                                                     FROM   dbo.[Order] o ,
                                                            dbo.Order_State os ,
                                                            dbo.App_Base_Define aos ,
                                                            dbo.Personal_Robot pr ,
                                                            dbo.Order_Access oa
                                                     WHERE  o.CODE = os.ORDR_CODE
                                                            AND os.APBS_CODE = aos.CODE
                                                            AND aos.RWNO IN (
                                                            6 )
                                                            AND CAST(os.STAT_DATE AS DATE) <> CAST(GETDATE() AS DATE)
                                                            AND pr.SERV_FILE_NO = o.PROB_SERV_FILE_NO
                                                            AND pr.ROBO_RBID = o.PROB_ROBO_RBID
                                                            AND o.CODE = oa.ORDR_CODE
                                                            AND oa.CHAT_ID = @ChatID
                                                            AND pr.ROBO_RBID = @Rbid
                                                   FOR
                                                     XML PATH('')
                                                   );      
                            END;      
                        ELSE
                            IF @ChildUssdCode IN ( '*1*5*1#' )
                                BEGIN
                                    SELECT  @Message = ( SELECT DISTINCT
                                                              +N'📅  '
                                                              + dbo.GET_CDTS_U(dbo.GET_MTOS_U(os.STAT_DATE))
                                                              + N'👤 '
                                                              + o.OWNR_NAME
                                                              + N' ( '
                                                              + CAST(o.ORDR_NUMB AS VARCHAR(10))
                                                              + N' ) - '
                                                              + pr.NAME
                                                              + CHAR(10)
                                                         FROM dbo.[Order] o ,
                                                              dbo.Order_State os ,
                                                              dbo.App_Base_Define aos ,
                                                              dbo.Personal_Robot pr ,
                                                              dbo.Order_Access oa
                                                         WHERE
                                                              o.CODE = os.ORDR_CODE
                                                              AND os.APBS_CODE = aos.CODE
                                                              AND aos.RWNO IN (
                                                              6 )
                                                              AND CAST(os.STAT_DATE AS DATE) = CAST(GETDATE() AS DATE)
                                                              AND pr.SERV_FILE_NO = o.PROB_SERV_FILE_NO
                                                              AND pr.ROBO_RBID = o.PROB_ROBO_RBID
                                                              AND o.CODE = oa.ORDR_CODE
                                                              AND oa.CHAT_ID = @ChatID
                                                              AND pr.ROBO_RBID = @Rbid
                                                       FOR
                                                         XML PATH('')
                                                       );      
                                END;
                    END;

    IF @UssdCode IN ( '*3*0#' )
        BEGIN
         -- پیشنهادات
            DECLARE @OrdrCode BIGINT ,
                @OrdrType VARCHAR(3);

            SELECT  @OrdrCode = MAX(CODE)
            FROM    dbo.[Order]
            WHERE   SRBT_ROBO_RBID = @Rbid
                    AND CHAT_ID = @ChatID
                    AND ORDR_TYPE = '001'
                    AND ORDR_STAT = '001';
      
            IF @MenuText = N'*#'
                GOTO L$EndMessageOrder1;
      
            IF @OrdrCode IS NULL
                BEGIN
                    INSERT  INTO dbo.[Order]
                            ( SRBT_SERV_FILE_NO ,
                              SRBT_ROBO_RBID ,
                              SRBT_SRPB_RWNO ,
                              ORDR_TYPE ,
                              STRT_DATE ,
                              ORDR_STAT
	                         )
                            SELECT  SERV_FILE_NO ,
                                    @Rbid ,
                                    SRPB_RWNO ,
                                    '001' ,
                                    GETDATE() ,
                                    '001' -- ثبت مرحله اولیه
                            FROM    dbo.Service_Robot
                            WHERE   CHAT_ID = @ChatID
                                    AND ROBO_RBID = @Rbid;
                END;   
      
            SELECT  @OrdrCode = MAX(CODE) ,
                    @OrdrType = ORDR_TYPE
            FROM    dbo.[Order] o ,
                    dbo.Service_Robot sr
            WHERE   o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                    AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                    AND sr.CHAT_ID = @ChatID
                    AND sr.ROBO_RBID = @Rbid
                    AND o.ORDR_TYPE = '001'
            GROUP BY ORDR_TYPE;
      
            INSERT  dbo.Order_Detail
                    ( ORDR_CODE ,
                      ELMN_TYPE ,
                      MIME_TYPE ,
                      ORDR_DESC ,
                      NUMB ,
                      ORDR_CMNT ,
                      BASE_USSD_CODE
                    )
            VALUES  ( @OrdrCode , -- ORDR_CODE - bigint
                      @ElmnType , -- ELMN_TYPE - varchar(3)
                      @MimeType ,
                      CASE @ElmnType
                        WHEN '001' THEN @MenuText
                        WHEN '005'
                        THEN CONVERT(VARCHAR(MAX), @CordX, 128) + ','
                             + CONVERT(VARCHAR(MAX), @CordY, 128)
                        WHEN '002' THEN @PhotoFileId
                        WHEN '003' THEN @VideoFileId
                        WHEN '004' THEN @DocumentFileId
                      END , -- ORDR_DESC - nvarchar(max)
                      @Numb , -- NUMB - int
                      @MenuText ,
                      @UssdCode
                    );
      
            L$EndMessageOrder1:
            IF @MenuText = N'*#'
                BEGIN
                    UPDATE  dbo.[Order]
                    SET     ORDR_STAT = '002'
                    WHERE   CODE = @OrdrCode;
         
                    DECLARE @OrdrNumb BIGINT ,
                        @ServOrdrRwno BIGINT;
         
                    SELECT  @OrdrNumb = ORDR_NUMB ,
                            @ServOrdrRwno = SERV_ORDR_RWNO ,
                            @OrdrType = ORDR_TYPE
                    FROM    dbo.[Order]
                    WHERE   CODE = @OrdrCode;
          
                    SELECT  @XMessage = ( SELECT    @OrdrCode AS '@code' ,
                                                    @Rbid AS '@roborbid' ,
                                                    @OrdrType '@type'
                                        FOR
                                          XML PATH('Order') ,
                                              ROOT('Process')
                                        );
                    EXEC Send_Order_To_Personal_Robot_Job @XMessage;
         
                    SET @Message = N'کاربر گرامی پیام شما در سیستم با موفقیت ثبت شد'
                        + CHAR(10) + N' شماره درخواست '
                        + CAST(@OrdrNumb AS NVARCHAR(32))
                        + N' جهت پیگیری در سیستم ذخیره گردیده شده است';
                END;
            ELSE
                SET @Message = N'📥اطلاعات  ارسالی شما دریافت شد.
لطفا بعد از اتمام عبارت 👈 #* را وارد کنید تا کارشناس به شما پاسخ دهد.';
        END;
    ELSE
        IF @UssdCode IN ( '*3*1#' )
            BEGIN
      -- انتقادات
                SELECT  @OrdrCode = MAX(CODE)
                FROM    dbo.[Order]
                WHERE   SRBT_ROBO_RBID = @Rbid
                        AND CHAT_ID = @ChatID
                        AND ORDR_TYPE = '003'
                        AND ORDR_STAT = '001';
   
                IF @MenuText = N'*#'
                    GOTO L$EndMessageOrder3;
   
                IF @OrdrCode IS NULL
                    BEGIN
                        INSERT  INTO dbo.[Order]
                                ( SRBT_SERV_FILE_NO ,
                                  SRBT_ROBO_RBID ,
                                  SRBT_SRPB_RWNO ,
                                  ORDR_TYPE ,
                                  STRT_DATE ,
                                  ORDR_STAT
                                )
                                SELECT  SERV_FILE_NO ,
                                        @Rbid ,
                                        SRPB_RWNO ,
                                        '003' ,
                                        GETDATE() ,
                                        '001' -- ثبت مرحله اولیه
                                FROM    dbo.Service_Robot
                                WHERE   CHAT_ID = @ChatID
                                        AND ROBO_RBID = @Rbid;
                    END;   
   
                SELECT  @OrdrCode = MAX(CODE) ,
                        @OrdrType = ORDR_TYPE
                FROM    dbo.[Order] o ,
                        dbo.Service_Robot sr
                WHERE   o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                        AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                        AND sr.CHAT_ID = @ChatID
                        AND sr.ROBO_RBID = @Rbid
                        AND o.ORDR_TYPE = '003'
                GROUP BY ORDR_TYPE;
   
                INSERT  dbo.Order_Detail
                        ( ORDR_CODE ,
                          ELMN_TYPE ,
                          MIME_TYPE ,
                          ORDR_DESC ,
                          NUMB ,
                          ORDR_CMNT ,
                          BASE_USSD_CODE
                        )
                VALUES  ( @OrdrCode , -- ORDR_CODE - bigint
                          @ElmnType , -- ELMN_TYPE - varchar(3)
                          @MimeType ,
                          CASE @ElmnType
                            WHEN '001' THEN @MenuText
                            WHEN '005'
                            THEN CONVERT(VARCHAR(MAX), @CordX, 128) + ','
                                 + CONVERT(VARCHAR(MAX), @CordY, 128)
                            WHEN '002' THEN @PhotoFileId
                            WHEN '003' THEN @VideoFileId
                            WHEN '004' THEN @DocumentFileId
                          END , -- ORDR_DESC - nvarchar(max)
                          @Numb , -- NUMB - int
                          @MenuText ,
                          @UssdCode
                        );
   
                L$EndMessageOrder3:
                IF @MenuText = N'*#'
                    BEGIN
                        UPDATE  dbo.[Order]
                        SET     ORDR_STAT = '002'
                        WHERE   CODE = @OrdrCode;
      
                        SELECT  @OrdrNumb = ORDR_NUMB ,
                                @ServOrdrRwno = SERV_ORDR_RWNO ,
                                @OrdrType = ORDR_TYPE
                        FROM    dbo.[Order]
                        WHERE   CODE = @OrdrCode;
       
                        SELECT  @XMessage = ( SELECT    @OrdrCode AS '@code' ,
                                                        @Rbid AS '@roborbid' ,
                                                        @OrdrType '@type'
                                            FOR
                                              XML PATH('Order') ,
                                                  ROOT('Process')
                                            );
                        EXEC Send_Order_To_Personal_Robot_Job @XMessage;
      
                        SET @Message = N'کاربر گرامی پیام شما در سیستم با موفقیت ثبت شد'
                            + CHAR(10) + N' شماره درخواست '
                            + CAST(@OrdrNumb AS NVARCHAR(32))
                            + N' جهت پیگیری در سیستم ذخیره گردیده شده است';
                    END;
                ELSE
                    SET @Message = N'📥اطلاعات  ارسالی شما دریافت شد.
لطفا بعد از اتمام عبارت 👈 #* را وارد کنید تا کارشناس به شما پاسخ دهد.';
            END;
        ELSE
            IF @UssdCode IN ( '*0*0#' )
                BEGIN
      -- پرسش
                    SELECT  @OrdrCode = MAX(CODE)
                    FROM    dbo.[Order]
                    WHERE   SRBT_ROBO_RBID = @Rbid
                            AND CHAT_ID = @ChatID
                            AND ORDR_TYPE = '006'
                            AND ORDR_STAT = '001';
   
                    IF @MenuText = N'*#'
                        GOTO L$EndMessageOrder6;
   
                    IF @OrdrCode IS NULL
                        BEGIN
                            INSERT  INTO dbo.[Order]
                                    ( SRBT_SERV_FILE_NO ,
                                      SRBT_ROBO_RBID ,
                                      SRBT_SRPB_RWNO ,
                                      ORDR_TYPE ,
                                      STRT_DATE ,
                                      ORDR_STAT
                                    )
                                    SELECT  SERV_FILE_NO ,
                                            @Rbid ,
                                            SRPB_RWNO ,
                                            '006' ,
                                            GETDATE() ,
                                            '001' -- ثبت مرحله اولیه
                                    FROM    dbo.Service_Robot
                                    WHERE   CHAT_ID = @ChatID
                                            AND ROBO_RBID = @Rbid;
                        END;   
   
                    SELECT  @OrdrCode = MAX(CODE) ,
                            @OrdrType = ORDR_TYPE
                    FROM    dbo.[Order] o ,
                            dbo.Service_Robot sr
                    WHERE   o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                            AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                            AND sr.CHAT_ID = @ChatID
                            AND sr.ROBO_RBID = @Rbid
                            AND o.ORDR_TYPE = '006'
                    GROUP BY ORDR_TYPE;
   
                    INSERT  dbo.Order_Detail
                            ( ORDR_CODE ,
                              ELMN_TYPE ,
                              MIME_TYPE ,
                              ORDR_DESC ,
                              NUMB ,
                              ORDR_CMNT ,
                              BASE_USSD_CODE
                            )
                    VALUES  ( @OrdrCode , -- ORDR_CODE - bigint
                              @ElmnType , -- ELMN_TYPE - varchar(3)
                              @MimeType ,
                              CASE @ElmnType
                                WHEN '001' THEN @MenuText
                                WHEN '005'
                                THEN CONVERT(VARCHAR(MAX), @CordX, 128) + ','
                                     + CONVERT(VARCHAR(MAX), @CordY, 128)
                                WHEN '002' THEN @PhotoFileId
                                WHEN '003' THEN @VideoFileId
                                WHEN '004' THEN @DocumentFileId
                              END , -- ORDR_DESC - nvarchar(max)
                              @Numb , -- NUMB - int
                              @MenuText ,
                              @UssdCode
                            );
   
                    L$EndMessageOrder6:
                    IF @MenuText = N'*#'
                        BEGIN
                            UPDATE  dbo.[Order]
                            SET     ORDR_STAT = '002'
                            WHERE   CODE = @OrdrCode;
      
                            SELECT  @OrdrNumb = ORDR_NUMB ,
                                    @ServOrdrRwno = SERV_ORDR_RWNO ,
                                    @OrdrType = ORDR_TYPE
                            FROM    dbo.[Order]
                            WHERE   CODE = @OrdrCode;
       
                            SELECT  @XMessage = ( SELECT    @OrdrCode AS '@code' ,
                                                            @Rbid AS '@roborbid' ,
                                                            @OrdrType '@type'
                                                FOR
                                                  XML PATH('Order') ,
                                                      ROOT('Process')
                                                );
                            EXEC Send_Order_To_Personal_Robot_Job @XMessage;
      
                            SET @Message = N'کاربر گرامی پیام شما در سیستم با موفقیت ثبت شد'
                                + CHAR(10) + N' شماره درخواست '
                                + CAST(@OrdrNumb AS NVARCHAR(32))
                                + N' جهت پیگیری در سیستم ذخیره گردیده شده است';
                        END;
                    ELSE
                        SET @Message = N'📥اطلاعات  ارسالی شما دریافت شد.
لطفا بعد از اتمام عبارت 👈 #* را وارد کنید تا کارشناس به شما پاسخ دهد.';
                END;
            ELSE
                IF @UssdCode IN ( '*3#' )
                    BEGIN
                        IF @ChildUssdCode IN ( '*3*2#' )
                            BEGIN         
                                SELECT  @Message = N' 👈 پیشنهادات ارسال شده'
                                        + CHAR(10)
                                        + ( SELECT  N'📅 '
                                                    + dbo.GET_MTOS_U(o.STRT_DATE)
                                                    + N' 📨 '
                                                    + CAST(COUNT(o.CODE) AS NVARCHAR(10))
                                                    + CHAR(10)
                                            FROM    dbo.[Order] o ,
                                                    dbo.Service_Robot sr
                                            WHERE   o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                                                    AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                                                    AND sr.ROBO_RBID = @Rbid
                                                    AND o.ORDR_STAT != '004'
                                                    AND o.ORDR_TYPE = '001'
                                            GROUP BY dbo.GET_MTOS_U(o.STRT_DATE)
                                            ORDER BY 1
                                          FOR
                                            XML PATH('')
                                          );
                            END;
                        ELSE
                            IF @ChildUssdCode IN ( '*3*3#' )
                                BEGIN         
                                    SELECT  @Message = N' 👈 انتقادات ارسال شده'
                                            + CHAR(10)
                                            + ( SELECT  N'📅 '
                                                        + dbo.GET_MTOS_U(o.STRT_DATE)
                                                        + N' 📨 '
                                                        + CAST(COUNT(o.CODE) AS NVARCHAR(10))
                                                        + CHAR(10)
                                                FROM    dbo.[Order] o ,
                                                        dbo.Service_Robot sr
                                                WHERE   o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                                                        AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                                                        AND sr.ROBO_RBID = @Rbid
                                                        AND o.ORDR_STAT != '004'
                                                        AND o.ORDR_TYPE = '003'
                                                GROUP BY dbo.GET_MTOS_U(o.STRT_DATE)
                                                ORDER BY 1
                                              FOR
                                                XML PATH('')
                                              );
                                END;
                    END;
                ELSE
                    IF @UssdCode IN ( '*7#' )
                        BEGIN
      -- ثبت اخطار
                            SELECT  @OrdrCode = MAX(CODE)
                            FROM    dbo.[Order]
                            WHERE   SRBT_ROBO_RBID = @Rbid
                                    AND CHAT_ID = @ChatID
                                    AND ORDR_TYPE = '011'
                                    AND ORDR_STAT = '001';
   
                            IF @MenuText = N'*#'
                                GOTO L$EndMessageOrder11;
   
                            IF @OrdrCode IS NULL
                                BEGIN
                                    INSERT  INTO dbo.[Order]
                                            ( SRBT_SERV_FILE_NO ,
                                              SRBT_ROBO_RBID ,
                                              SRBT_SRPB_RWNO ,
                                              ORDR_TYPE ,
                                              STRT_DATE ,
                                              ORDR_STAT
                                            )
                                            SELECT  SERV_FILE_NO ,
                                                    @Rbid ,
                                                    SRPB_RWNO ,
                                                    '011' ,
                                                    GETDATE() ,
                                                    '001' -- ثبت مرحله اولیه
                                            FROM    dbo.Service_Robot
                                            WHERE   CHAT_ID = @ChatID
                                                    AND ROBO_RBID = @Rbid;
                                END;   
   
                            SELECT  @OrdrCode = MAX(CODE) ,
                                    @OrdrType = ORDR_TYPE
                            FROM    dbo.[Order] o ,
                                    dbo.Service_Robot sr
                            WHERE   o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
                                    AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
                                    AND sr.CHAT_ID = @ChatID
                                    AND sr.ROBO_RBID = @Rbid
                                    AND o.ORDR_TYPE = '011'
                            GROUP BY ORDR_TYPE;
   
                            INSERT  dbo.Order_Detail
                                    ( ORDR_CODE ,
                                      ELMN_TYPE ,
                                      MIME_TYPE ,
                                      ORDR_DESC ,
                                      NUMB ,
                                      ORDR_CMNT ,
                                      BASE_USSD_CODE
                                    )
                            VALUES  ( @OrdrCode , -- ORDR_CODE - bigint
                                      @ElmnType , -- ELMN_TYPE - varchar(3)
                                      @MimeType ,
                                      CASE @ElmnType
                                        WHEN '001' THEN @MenuText
                                        WHEN '005'
                                        THEN CONVERT(VARCHAR(MAX), @CordX, 128)
                                             + ','
                                             + CONVERT(VARCHAR(MAX), @CordY, 128)
                                        WHEN '002' THEN @PhotoFileId
                                        WHEN '003' THEN @VideoFileId
                                        WHEN '004' THEN @DocumentFileId
                                      END , -- ORDR_DESC - nvarchar(max)
                                      @Numb , -- NUMB - int
                                      @MenuText ,
                                      @UssdCode
                                    );
   
                            L$EndMessageOrder11:
                            IF @MenuText = N'*#'
                                BEGIN
                                    UPDATE  dbo.[Order]
                                    SET     ORDR_STAT = '002'
                                    WHERE   CODE = @OrdrCode;
      
                                    SELECT  @OrdrNumb = ORDR_NUMB ,
                                            @ServOrdrRwno = SERV_ORDR_RWNO ,
                                            @OrdrType = ORDR_TYPE
                                    FROM    dbo.[Order]
                                    WHERE   CODE = @OrdrCode;
       
                                    SELECT  @XMessage = ( SELECT
                                                              @OrdrCode AS '@code' ,
                                                              @Rbid AS '@roborbid' ,
                                                              @OrdrType '@type'
                                                        FOR
                                                          XML PATH('Order') ,
                                                              ROOT('Process')
                                                        );
                                    EXEC Send_Order_To_Personal_Robot_Job @XMessage;
      
                                    SET @Message = N'کاربر گرامی پیام شما در سیستم با موفقیت ثبت شد'
                                        + CHAR(10) + N' شماره درخواست '
                                        + CAST(@OrdrNumb AS NVARCHAR(32))
                                        + N' جهت پیگیری در سیستم ذخیره گردیده شده است';
                                END;
                            ELSE
                                SET @Message = N'📥اطلاعات  ارسالی شما دریافت شد.
لطفا بعد از اتمام عبارت 👈 #* را وارد کنید تا کارشناس به شما پاسخ دهد.';
                        END;
	
    L$EndSP:
    SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
    SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END;

GO
