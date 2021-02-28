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
 PROCEDURE [dbo].[ArtaSportGym_Analisis_Message_P] @X XML, @XResult XML OUT
AS
BEGIN
    DECLARE @UssdCode VARCHAR(250) ,
        @ChildUssdCode VARCHAR(250) ,
        @CallBackQuery VARCHAR(3),
        @RunTheActionCallBackQuery VARCHAR(3),
        @ListActionsCallBackQuery VARCHAR(3),
        @MenuText NVARCHAR(MAX) , -- Command Text
        @ParamText NVARCHAR(MAX), -- Param Text
        @Message NVARCHAR(MAX) ,
        @XMessage XML ,
        @XTemp XML ,
        @ChatID BIGINT ,
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
        @AmntType VARCHAR(3),
        @AmntTypeDesc NVARCHAR(20),
        @Said BIGINT,
        @SrbtServFileNo BIGINT,
        @OrdrCode BIGINT;
	 
    SELECT  @Token = @X.query('/Robot').value('(Robot/@token)[1]', 'VARCHAR(100)') ,
            @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]', 'VARCHAR(250)') ,            
            @ChildUssdCode = @X.query('//Message').value('(Message/@childussd)[1]','VARCHAR(250)') ,
            @CallBackQuery = @X.query('//Message').value('(Message/@cbq)[1]','VARCHAR(3)') ,
            @RunTheActionCallBackQuery = @X.query('//Message').value('(Message/@racbq)[1]','VARCHAR(3)') ,
            @ListActionsCallBackQuery = @X.query('//Message').value('(Message/@lacbq)[1]','VARCHAR(3)') ,
            @CallBackQuery = @X.query('//Message').value('(Message/@cbq)[1]','VARCHAR(3)') ,
            @ChatID = @X.query('//Message').value('(Message/@chatid)[1]','BIGINT') ,
            @ElmnType = @X.query('//Message').value('(Message/@elmntype)[1]', 'VARCHAR(3)') ,
            @MimeType = @X.query('//Message').value('(Message/@mimetype)[1]','VARCHAR(100)') ,
            @MenuText = @X.query('//Text').value('.', 'NVARCHAR(MAX)') ,
            @ParamText = @X.query('//Text').value('(Text/@param)[1]', 'NVARCHAR(MAX)') ,
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
	 
	 SELECT @AmntType = rg.AMNT_TYPE, 
	        @AmntTypeDesc = d.DOMN_DESC
	   FROM iScsc.dbo.Regulation rg, iScsc.dbo.[D$ATYP] d
	  WHERE rg.TYPE = '001'
	    AND rg.REGL_STAT = '002'
	    AND rg.AMNT_TYPE = d.VALU;
	 
    SELECT  @Rbid = RBID
    FROM    dbo.Robot
    WHERE   TKON_CODE = @Token;
    
    DECLARE @CochFileNo BIGINT
           ,@CochNameDnrm NVARCHAR(250)
           ,@SexDesc NVARCHAR(50)
           ,@FileNo BIGINT
           ,@FromDate DATE = GETDATE()
           ,@ToDate DATE = GETDATE();
    
    -- Call Back Query
    IF @CallBackQuery = '002'
    BEGIN
      GOTO L$CallBackQuery;
    END
    
    IF @UssdCode IN (
      '*4*1*1*1#', '*4*1*0*1#', '*4*0*0*1#', '*4*0*1*1#', '*4*0*1*3*1#',
      '*4*0*2*1#', '*4*0*3*1#', '*4*0*5*1#', '*4*0*7*0*4#', '*4*0*7*1*4#', '*4*0*7*2*4#',
      '*4*6*0*2*0*4#', '*4*6*0*2*1*4#', '*4*6*1*2*0*4#' , '*4*6*1*2*1*4#', '*1*12*5#',
      '*7*0*6*5#', '*7*1*6*5#'
    )
    BEGIN
      BEGIN TRY
         DECLARE C$Items CURSOR FOR
            SELECT Item FROM dbo.SplitString(@MenuText, '*');
         SET @Index = 0;
         OPEN [C$Items];
         L$FetchC$Item_DATE:
         FETCH NEXT FROM [C$Items] INTO @Item;
         
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
         
         IF (@UssdCode = '*4*1*1*1#')
            GOTO L$ATTN;
         ELSE IF (@UssdCode = '*4*1*0*1#')
            GOTO L$ADMC;
         ELSE IF (@UssdCode = '*4*0*0*1#')
            GOTO L$USERACTN;
         ELSE IF (@UssdCode = '*4*0*1*1#')
            GOTO L$PYMT;
         ELSE IF (@UssdCode = '*4*0*1*3*1#')
            GOTO L$OTHRPYMT;
         ELSE IF (@UssdCode = '*4*0*2*1#')
            GOTO L$COCHPYMT;  
         ELSE IF (@UssdCode = '*4*0*3*1#')
            GOTO L$CLUBEXPN;
         ELSE IF (@UssdCode = '*4*0*5*1#')
            GOTO L$ORGNDEBT;
         ELSE IF (@UssdCode = '*4*0*7*0*4#')
            GOTO L$PYDS;
         ELSE IF (@UssdCode = '*4*0*7*1*4#')
            GOTO L$PYNP;
         ELSE IF (@UssdCode = '*4*0*7*2*4#')
            GOTO L$PYDP;  
         ELSE IF (@UssdCode = '*4*6*0*2*0*4#')
            GOTO L$CRDT013;
         ELSE IF (@UssdCode = '*4*6*0*2*1*4#')
            GOTO L$TXFE013;
         ELSE IF (@UssdCode = '*4*6*1*2*0*4#')
            GOTO L$CRDT014;
         ELSE IF (@UssdCode = '*4*6*1*2*1*4#')
            GOTO L$TXFE014;
         ELSE IF (@UssdCode IN ( '*1*12*5#', '*7*0*6*5#', '*7*1*6*5#'))
            GOTO L$ServAttn;
            
       END TRY
       BEGIN CATCH
         SET @Message = N'تاریخ شروع و پایان به درستی وارد نشده، لطفا بررسی و اصلاح کنید';
       END CATCH   
    END    
    -- زمان های آماده برای سریع
    IF @UssdCode IN ('*4*0*7*0#', '*4*0*7*1#', '*4*0*7*2#', 
                     '*4*0*0#'  , '*4*0*1#'  , '*4*0*1*3#',
                     '*4*0*2#'  , '*4*0*3#'  , '*4*1*0#',
                     '*4*1*7*0*0#', '*4*6*0*2*0#', '*4*6*0*2*1#', '*4*6*1*2*0#', '*4*6*1*2*1#',
                     '*1*12#', '*7*0*6#', '*7*1*6#') AND 
       @ChildUssdCode IN ('*4*0*7*0*0#', '*4*0*7*1*0#', '*4*0*7*2*0#',
                          '*4*0*7*0*1#', '*4*0*7*1*1#', '*4*0*7*2*1#',
                          '*4*0*7*0*2#', '*4*0*7*1*2#', '*4*0*7*2*2#',
                          '*4*0*7*0*3#', '*4*0*7*1*3#', '*4*0*7*2*3#',
                          '*4*0*0*3#'  , '*4*0*0*4#'  , '*4*0*0*5#'  ,
                          '*4*0*1*4#'  , '*4*0*1*5#'  , '*4*0*1*6#'  ,
                          '*4*0*1*3*3#', '*4*0*1*3*4#', '*4*0*1*3*5#',
                          '*4*0*2*3#'  , '*4*0*2*4#'  , '*4*0*2*5#'  ,
                          '*4*0*3*3#'  , '*4*0*3*4#'  , '*4*0*3*5#'  ,
                          '*4*1*0*3#'  , '*4*1*0*4#'  , '*4*1*0*5#'  ,
                          '*4*1*7*0*0*0#', '*4*1*7*0*0*1#', '*4*1*7*0*0*2#', '*4*1*7*0*0*3#', '*4*1*7*0*0*4#',
                          '*4*6*0*2*0*0#', '*4*6*0*2*0*1#', '*4*6*0*2*0*2#', '*4*6*0*2*0*3#',
                          '*4*6*0*2*1*0#', '*4*6*0*2*1*1#', '*4*6*0*2*1*2#', '*4*6*0*2*1*3#',
                          '*4*6*1*2*0*0#', '*4*6*1*2*0*1#', '*4*6*1*2*0*2#', '*4*6*1*2*0*3#',
                          '*4*6*1*2*1*0#', '*4*6*1*2*1*1#', '*4*6*1*2*1*2#', '*4*6*1*2*1*3#',
                          '*1*12*1#', '*1*12*2#', '*1*12*3#', '*1*12*4#',
                          '*7*0*6*1#', '*7*0*6*2#', '*7*0*6*3#', '*7*0*6*4#',
                          '*7*1*6*1#', '*7*1*6*2#', '*7*1*6*3#', '*7*1*6*4#'
                          )
    BEGIN
      SET @MenuText = NULL;
      -- Today
      SELECT @FromDate = GETDATE(), @ToDate = GETDATE();
      
      IF @UssdCode = '*4*0*7*0#' AND @ChildUssdCode = '*4*0*7*0*0#'
         GOTO L$PYDS;
      ELSE IF @UssdCode = '*4*0*7*1#' AND @ChildUssdCode = '*4*0*7*1*0#'
         GOTO L$PYNP;
      ELSE IF @UssdCode = '*4*0*7*2#' AND @ChildUssdCode = '*4*0*7*2*0#'
         GOTO L$PYDP;
      ELSE IF @UssdCode = '*4*6*0*2*0#' AND @ChildUssdCode = '*4*6*0*2*0*0#'
         GOTO L$CRDT013;
      ELSE IF @UssdCode = '*4*6*0*2*1#' AND @ChildUssdCode = '*4*6*0*2*1*0#'
         GOTO L$TXFE013;
      ELSE IF @UssdCode = '*4*6*1*2*0#' AND @ChildUssdCode = '*4*6*1*2*0*0#'
         GOTO L$CRDT014;
      ELSE IF @UssdCode = '*4*6*1*2*1#' AND @ChildUssdCode = '*4*6*1*2*1*0#'
         GOTO L$TXFE014;
      ELSE IF @UssdCode IN ( '*1*12#', '*7*0*6#', '*7*1*6#' ) AND @ChildUssdCode IN ( '*1*12*1#', '*7*0*6*1#', '*7*1*6*1#' )
         GOTO L$ServAttn;
      
      
      -- Weekday
      SELECT @ToDate = GETDATE(), 
             @FromDate = 
               DATEADD(Day, 
                       CASE DATEPART(WEEKDAY, GETDATE()) 
                            WHEN 7 THEN 0 
                            ELSE DATEPART(WEEKDAY, GETDATE()) * -1
                       END, 
                       GETDATE());
      
      IF @UssdCode = '*4*0*7*0#' AND @ChildUssdCode = '*4*0*7*0*1#'
         GOTO L$PYDS;
      ELSE IF @UssdCode = '*4*0*7*1#' AND @ChildUssdCode = '*4*0*7*1*1#'
         GOTO L$PYNP;
      ELSE IF @UssdCode = '*4*0*7*2#' AND @ChildUssdCode = '*4*0*7*2*1#'
         GOTO L$PYDP;         
      ELSE IF @UssdCode = '*4*0*0#' AND @ChildUssdCode = '*4*0*0*3#'
         GOTO L$USERACTN;
      ELSE IF @UssdCode = '*4*0*1#' AND @ChildUssdCode = '*4*0*1*4#'
         GOTO L$PYMT;
      ELSE IF @UssdCode = '*4*0*1*3#' AND @ChildUssdCode = '*4*0*1*3*3#'
         GOTO L$OTHRPYMT;
      ELSE IF @UssdCode = '*4*0*2#' AND @ChildUssdCode = '*4*0*2*3#'
         GOTO L$COCHPYMT;
      ELSE IF @UssdCode = '*4*0*3#' AND @ChildUssdCode = '*4*0*3*3#'
         GOTO L$CLUBEXPN;
      ELSE IF @UssdCode = '*4*1*0#' AND @ChildUssdCode = '*4*1*0*3#'
         GOTO L$ADMC;
      ELSE IF @UssdCode = '*4*6*0*2*0#' AND @ChildUssdCode = '*4*6*0*2*0*1#'
         GOTO L$CRDT013;
      ELSE IF @UssdCode = '*4*6*0*2*1#' AND @ChildUssdCode = '*4*6*0*2*1*1#'
         GOTO L$TXFE013;
      ELSE IF @UssdCode = '*4*6*1*2*0#' AND @ChildUssdCode = '*4*6*1*2*0*1#'
         GOTO L$CRDT014;
      ELSE IF @UssdCode = '*4*6*1*2*1#' AND @ChildUssdCode = '*4*6*1*2*1*1#'
         GOTO L$TXFE014;
      ELSE IF @UssdCode IN ( '*1*12#', '*7*0*6#', '*7*1*6#' ) AND @ChildUssdCode IN ( '*1*12*2#', '*7*0*6*2#', '*7*1*6*2#' )
         GOTO L$ServAttn;

      -- Monthly
      SELECT @ToDate = GETDATE(), 
             @FromDate = dbo.GET_STOM_U(LEFT(dbo.GET_MTOS_U(GETDATE()), 7) + '/01');
      
      IF @UssdCode = '*4*0*7*0#' AND @ChildUssdCode = '*4*0*7*0*2#'
         GOTO L$PYDS;
      ELSE IF @UssdCode = '*4*0*7*1#' AND @ChildUssdCode = '*4*0*7*1*2#'
         GOTO L$PYNP;
      ELSE IF @UssdCode = '*4*0*7*2#' AND @ChildUssdCode = '*4*0*7*2*2#'
         GOTO L$PYDP;
      ELSE IF @UssdCode = '*4*0*0#' AND @ChildUssdCode = '*4*0*0*4#'
         GOTO L$USERACTN;
      ELSE IF @UssdCode = '*4*0*1#' AND @ChildUssdCode = '*4*0*1*5#'
         GOTO L$PYMT;
      ELSE IF @UssdCode = '*4*0*1*3#' AND @ChildUssdCode = '*4*0*1*3*4#'
         GOTO L$OTHRPYMT;
      ELSE IF @UssdCode = '*4*0*2#' AND @ChildUssdCode = '*4*0*2*4#'
         GOTO L$COCHPYMT;
      ELSE IF @UssdCode = '*4*0*3#' AND @ChildUssdCode = '*4*0*3*4#'
         GOTO L$CLUBEXPN;
      ELSE IF @UssdCode = '*4*1*0#' AND @ChildUssdCode = '*4*1*0*4#'
         GOTO L$ADMC;
      ELSE IF @UssdCode = '*4*6*0*2*0#' AND @ChildUssdCode = '*4*6*0*2*0*2#'
         GOTO L$CRDT013;
      ELSE IF @UssdCode = '*4*6*0*2*1#' AND @ChildUssdCode = '*4*6*0*2*1*2#'
         GOTO L$TXFE013;
      ELSE IF @UssdCode = '*4*6*1*2*0#' AND @ChildUssdCode = '*4*6*1*2*0*2#'
         GOTO L$CRDT014;
      ELSE IF @UssdCode = '*4*6*1*2*1#' AND @ChildUssdCode = '*4*6*1*2*1*2#'
         GOTO L$TXFE014;
      ELSE IF @UssdCode IN ( '*1*12#', '*7*0*6#', '*7*1*6#' ) AND @ChildUssdCode IN ( '*1*12*3#', '*7*0*6*3#', '*7*1*6*3#' )
         GOTO L$ServAttn;
         
      -- Year
      SELECT @ToDate = GETDATE(), 
             @FromDate = dbo.GET_STOM_U(LEFT(dbo.GET_MTOS_U(GETDATE()), 4) + '/01/01');
      
      IF @UssdCode = '*4*0*7*0#' AND @ChildUssdCode = '*4*0*7*0*3#'
         GOTO L$PYDS;
      ELSE IF @UssdCode = '*4*0*7*1#' AND @ChildUssdCode = '*4*0*7*1*3#'
         GOTO L$PYNP;
      ELSE IF @UssdCode = '*4*0*7*2#' AND @ChildUssdCode = '*4*0*7*2*3#'
         GOTO L$PYDP;
         
      ELSE IF @UssdCode = '*4*0*0#' AND @ChildUssdCode = '*4*0*0*5#'
         GOTO L$USERACTN;
      ELSE IF @UssdCode = '*4*0*1#' AND @ChildUssdCode = '*4*0*1*6#'
         GOTO L$PYMT;
      ELSE IF @UssdCode = '*4*0*1*3#' AND @ChildUssdCode = '*4*0*1*3*5#'
         GOTO L$OTHRPYMT;
      ELSE IF @UssdCode = '*4*0*2#' AND @ChildUssdCode = '*4*0*2*5#'
         GOTO L$COCHPYMT;
      ELSE IF @UssdCode = '*4*0*3#' AND @ChildUssdCode = '*4*0*3*5#'
         GOTO L$CLUBEXPN;
      ELSE IF @UssdCode = '*4*1*0#' AND @ChildUssdCode = '*4*1*0*5#'
         GOTO L$ADMC; 
      ELSE IF @UssdCode = '*4*6*0*2*0#' AND @ChildUssdCode = '*4*6*0*2*0*3#'
         GOTO L$CRDT013;  
      ELSE IF @UssdCode = '*4*6*0*2*1#' AND @ChildUssdCode = '*4*6*0*2*1*3#'
         GOTO L$TXFE013;
      ELSE IF @UssdCode = '*4*6*1*2*0#' AND @ChildUssdCode = '*4*6*1*2*0*3#'
         GOTO L$CRDT014;  
      ELSE IF @UssdCode = '*4*6*1*2*1#' AND @ChildUssdCode = '*4*6*1*2*1*3#'
         GOTO L$TXFE014;
      ELSE IF @UssdCode IN ( '*1*12#', '*7*0*6#', '*7*1*6#' ) AND @ChildUssdCode IN ( '*1*12*4#', '*7*0*6*4#', '*7*1*6*4#' )
         GOTO L$ServAttn;
         
      SELECT @FromDate = NULL, @ToDate = NULL
      
      -- Unlimited
      IF @UssdCode = '*4*1*7*0*0#' AND @ChildUssdCode = '*4*1*7*0*0*0#'
      BEGIN
         SELECT 1;
      END
    END
    -- نمایش برنامه های ورزشی و امکانات باشگاه
    IF @UssdCode = '*0#' AND @ChildUssdCode = '*0*6#'
    BEGIN
      SELECT @Message = (
         SELECT N'👈 ' + CAST(ROW_NUMBER() OVER (ORDER BY m.CODE) AS NVARCHAR(10)) + N' ) ' + m.MTOD_DESC + CHAR(10)
           FROM iScsc.dbo.Method m
          WHERE m.MTOD_STAT = '002'
            FOR XML PATH('')
      )
    END;
    -- لیست مربیان
    ELSE IF @UssdCode = '*0#' AND @ChildUssdCode = '*0*2#'
    BEGIN
      SELECT @Message = (
         SELECT CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'👱 ' WHEN '002' THEN N'👩 ' END + 
                N'*' + 
                f.NAME_DNRM + N'*' + char(10) + 
                N'👈 تخصص و مهارت' + char(10) + 
                (
                  select distinct N'🏅 *' + m.MTOD_DESC + N'*' + CHAR(10)
                    from iScsc.dbo.Club_Method cm, iScsc.dbo.Method m
                   where cm.MTOD_CODE = m.CODE
                     and cm.COCH_FILE_NO = f.FILE_NO
                     for xml path('')                     
                ) + CHAR(10)
           FROM iScsc.dbo.Fighter f
          WHERE FGPB_TYPE_DNRM = '003'
            AND ACTV_TAG_DNRM = '101'       
       ORDER BY FILE_NO
       FOR XML PATH('')
      );
    END;
    -- نمایش کل کلاس های ورزشی
    ELSE IF (
      (@UssdCode = '*0*3#' AND  @ChildUssdCode = '*0*3*0#') or
      (@UssdCode = '*1*11*0#' and @ChildUssdCode = '*1*11*0*0#') OR
      (@UssdCode = '*7*0*5*0#' and @ChildUssdCode = '*7*0*5*0*0#') OR
      (@UssdCode = '*7*1*5*0#' and @ChildUssdCode = '*7*1*5*0*0#') OR
      (@UssdCode = '*0*7*1#' and @ChildUssdCode = '*0*7*1*0#')
    )--@MenuText = N'🔎 نمایش کل کلاس ها'
    BEGIN
      SELECT @Message = (         
       SELECT  N'📔  *' + m.MTOD_DESC + N'*'+ CHAR(10) +
              (
                 SELECT CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'👱 ' WHEN '002' THEN N'👩 ' END + N'*'+ f.NAME_DNRM + N'*'+ CASE s.VALU WHEN '001' THEN N' 👬 ' WHEN '002' THEN N' 👭 ' WHEN '003' THEN N' 👫 ' END + N'[ *' + s.DOMN_DESC + N'* ] ☀️ [ *' + d.DOMN_DESC + N'* ] [ *' +  CAST(cm.STRT_TIME AS VARCHAR(5)) + N'* ] - [ *' + CAST(cm.END_TIME AS VARCHAR(5)) + N'* ]'+ CHAR(10) +
                        (
                           SELECT CHAR(9) + N'📦 ' + cb.CTGY_DESC + N' 💵 *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, cb.PRIC), 1), '.00', '') + N'* [ ' + @AmntTypeDesc + N' ] ' + CHAR(10) + 
                                  CHAR(9) + N'👈 [ کد تعرفه ] *' + m.NATL_CODE + cb.NATL_CODE + cm.NATL_CODE + N'*' + CHAR(10)
                             FROM iScsc.dbo.Category_Belt cb
                            WHERE cb.MTOD_CODE = m.CODE
                              AND cb.NATL_CODE IS NOT NULL
                            FOR XML PATH('')
                        ) 
                   FROM iScsc.dbo.Club_Method cm, iScsc.dbo.Fighter f, iScsc.dbo.[D$DYTP] d, iScsc.dbo.[D$SXTP] s
                  WHERE cm.COCH_FILE_NO = f.FILE_NO
                    AND m.CODE = cm.MTOD_CODE
                    AND f.ACTV_TAG_DNRM >= '101'
                    AND cm.MTOD_STAT = '002'
                    AND cm.NATL_CODE IS NOT NULL
                    AND cm.DAY_TYPE = d.VALU
                    AND cm.SEX_TYPE = s.VALU
                    FOR XML PATH('')
              ) + CHAR(10) 
         FROM iScsc.dbo.Method m
        WHERE m.NATL_CODE IS NOT NULL
          AND m.MTOD_STAT = '002'
     ORDER BY m.MTOD_DESC
          FOR XML PATH('')
      ) + CHAR(10) + N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)) ;
    END 
    -- جستجوی کلاسی
    ELSE IF @UssdCode IN ( '*0*3*2#', '*1*11*0*1#', '*7*0*5*0*1#', '*7*1*5*0*1#', '*0*7*1*1#' ) --AND @MenuText != N'🔎 نمایش کل کلاس ها'
    BEGIN
      DECLARE @MtodDesc NVARCHAR(250)
             ,@CochName NVARCHAR(250)
             ,@NumbAttn NVARCHAR(250)
             ,@CtgyDesc NVARCHAR(250);
             
      DECLARE C$Items CURSOR FOR
         SELECT Item FROM dbo.SplitString(@MenuText, '#');
      SET @Index = 0;
      OPEN [C$Items];
      L$FetchC$Item_DATA1:
      FETCH NEXT FROM [C$Items] INTO @Item;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndC$Item_DATA1;
      
      IF @Index = 0
         SET @MtodDesc = @Item;
      ELSE IF @Index = 1
         SET @CochName = @Item;
      ELSE IF @Index = 2
         SET @NumbAttn = @Item;
      ELSE IF @Index = 3
         SET @CtgyDesc = @Item;
      
      SET @Index += 1;
      GOTO L$FetchC$Item_DATA1;
      L$EndC$Item_DATA1:
      CLOSE [C$Items];
      DEALLOCATE [C$Items];
      
      SELECT @Message = (      
         SELECT  N'📔  *' + m.MTOD_DESC + N'*'+ CHAR(10) +
                 (
                    SELECT CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'👱 ' WHEN '002' THEN N'👩 ' END + N'*'+ f.NAME_DNRM + N'*'+ CASE s.VALU WHEN '001' THEN N' 👬 ' WHEN '002' THEN N' 👭 ' WHEN '003' THEN N' 👫 ' END + N'[ *' + s.DOMN_DESC + N'* ] ☀️ [ *' + d.DOMN_DESC + N'* ] [ *' +  CAST(cm.STRT_TIME AS VARCHAR(5)) + N'* ] - [ *' + CAST(cm.END_TIME AS VARCHAR(5)) + N'* ]'+ CHAR(10) +
                           (
                              SELECT CHAR(9) + N'📦 ' + cb.CTGY_DESC + N' 💵 *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, cb.PRIC), 1), '.00', '') + N'* [ ' + @AmntTypeDesc + N' ] ' + CHAR(10) + 
                                     CHAR(9) + N'👈 [ کد تعرفه ] *' + m.NATL_CODE + cb.NATL_CODE + cm.NATL_CODE + N'*' + CHAR(10)
                                FROM iScsc.dbo.Category_Belt cb
                               WHERE cb.MTOD_CODE = m.CODE
                                 AND cb.NATL_CODE IS NOT NULL
                                 and (
                                       ( ISNULL(@NumbAttn, '') != '' OR cb.NUMB_OF_ATTN_MONT = @NumbAttn ) OR
                                       ( ISNULL(@CtgyDesc, '') != '' OR cb.CTGY_DESC like N'%' + ISNULL(@CtgyDesc, N'%') + N'%' )
                                     )                                      
                               FOR XML PATH('')
                           ) 
                      FROM iScsc.dbo.Club_Method cm, iScsc.dbo.Fighter f, iScsc.dbo.[D$DYTP] d, iScsc.dbo.[D$SXTP] s
                     WHERE cm.COCH_FILE_NO = f.FILE_NO
                       AND m.CODE = cm.MTOD_CODE
                       AND f.ACTV_TAG_DNRM >= '101'
                       AND cm.MTOD_STAT = '002'
                       AND cm.NATL_CODE IS NOT NULL
                       AND cm.DAY_TYPE = d.VALU
                       AND cm.SEX_TYPE = s.VALU
                       AND f.NAME_DNRM LIKE N'%' + ISNULL(@CochName, N'%') + N'%'
                       FOR XML PATH('')
                 ) + CHAR(10)
            FROM iScsc.dbo.Method m
           WHERE m.NATL_CODE IS NOT NULL
             AND m.MTOD_STAT = '002'
             AND m.MTOD_DESC LIKE (N'%' + ISNULL(@MtodDesc, N'%') + N'%')
        ORDER BY m.MTOD_DESC
             FOR XML PATH('')
      ) + CHAR(10) + N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = 
            N'😊 کاربر گرامی لطفا اطلاعات 🔍 جستجو خود را بر اساس ✏️ قالب زیر ارسال کنید با تشکر' + CHAR(10) + CHAR(10) + 
            N'✏️ قالب ارسالی از سمت شما : ' + CHAR(10) +
            N'*عنوان گروه*' + N' # ' + N'*نام سرپرست*' + N' # ' + N'*تعداد جلسات*' + N' # ' + N'*عنوان زیر گروه*' + CHAR(10) + CHAR(10) + 
            N'👈 مثال :' + CHAR(10) + 
            N'*بدنسازی*' + N' # ' + N'*روح الله قیصری*' + N' # ' + N'*12*' + N' # ' + N'*جلسه*'
         ;
      END 
    END
    -- تعداد آمار دعوتی من
    ELSE IF @UssdCode = '*0#' AND @ChildUssdCode = '*0*5#'
    BEGIN
      -- در این قسمت تعداد آمارهای ورودی در خود ربات را نشان دهد
      
      -- گام سوم تعداد مشتریانی که به صورت غیر مستقیم وارد ربات شده اند
      -- گام چهارم تعداد هنرجویانی که به صورت غیرمستقیم عضو باشگاه شده اند 
      SELECT @Message = (
         SELECT N'👥 تعداد مشترکین دعوتی من ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' ) ' + CHAR(10)
           FROM dbo.Service_Robot
          WHERE ROBO_RBID = @Rbid
            AND REF_CHAT_ID = @ChatID
        FOR XML PATH('')
      );
      
      -- گام دوم تعداد هنرجویانی که بعد از دعوت شدن در سیستم باشگاه ثبت نام کرده اند
      SELECT @Message += (
         SELECT N'😎 تعداد اعضا دعوتی من ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' ) ' + CHAR(10)
           FROM iScsc.dbo.Fighter
          WHERE CONF_STAT = '002'
            AND CHAT_ID_DNRM IN (
               SELECT CHAT_ID
                 FROM dbo.Service_Robot
                WHERE ROBO_RBID = @Rbid
                  AND REF_CHAT_ID = @ChatID
            )
      );
      
      SELECT @Message += ISNULL((
         SELECT NAME_DNRM + N' , ' + dbo.GET_MTOS_U(CONF_DATE) + CHAR(10)
           FROM iScsc.dbo.Fighter
          WHERE CONF_STAT = '002'
            AND CHAT_ID_DNRM IN (
               SELECT CHAT_ID
                 FROM dbo.Service_Robot
                WHERE ROBO_RBID = @Rbid
                  AND REF_CHAT_ID = @ChatID
            )
            FOR XML PATH('')            
      ), '');
      
      SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END
    -- ثبت شماره پرونده 
    ELSE IF @UssdCode = '*1*0*0#'
    BEGIN
      BEGIN TRY      
         UPDATE fp
            SET fp.CHAT_ID = @ChatID
           FROM iScsc.dbo.Fighter f, iScsc.dbo.Fighter_Public fp
          WHERE f.FILE_NO = fp.FIGH_FILE_NO
            AND f.FGPB_RWNO_DNRM = fp.RWNO
            AND fp.RECT_CODE = '004'
			AND f.FGPB_TYPE_DNRM = '001'
            AND fp.CHAT_ID IS NULL
            AND f.FILE_NO = CONVERT(BIGINT, @MenuText)
            AND NOT EXISTS(
               SELECT *
                 FROM iScsc.dbo.Fighter ft
                WHERE f.FILE_NO != ft.FILE_NO
                  AND ft.CHAT_ID_DNRM = @ChatID
            );
         
         IF @@ROWCOUNT != 1
         BEGIN
            RAISERROR(N'Error in save data!', 16, 1);
         END
         ELSE
            SELECT @Message = (
               SELECT N'🎉 تبریک ' + s.DOMN_DESC + N' ' +
                      f.NAME_DNRM + N' با شماره پرونده ' + @MenuText + N' اطلاعات کاربری بله شما در سیستم باشگاه ثبت شد '
                 FROM iScsc.dbo.Fighter f, iScsc.dbo.[D$SXDC] s                 
                WHERE f.FILE_NO = CONVERT(BIGINT, @MenuText)
                  AND f.SEX_TYPE_DNRM = s.VALU
            );
      END TRY
      BEGIN CATCH
         SET @Message = N'شماره پرونده ارسالی قابل ثبت در سیستم نیست، لطفا با قسمت پذیرش هماهنگی به عمل آورید';
      END CATCH 
    END
    -- ثبت کد دستگاه 
    ELSE IF @UssdCode = '*1*0*1#'
    BEGIN
      BEGIN TRY      
         UPDATE fp
            SET fp.CHAT_ID = @ChatID
           FROM iScsc.dbo.Fighter f, iScsc.dbo.Fighter_Public fp
          WHERE f.FILE_NO = fp.FIGH_FILE_NO
            AND f.FGPB_RWNO_DNRM = fp.RWNO
            AND fp.RECT_CODE = '004'
			AND f.FGPB_TYPE_DNRM = '001'
            AND fp.CHAT_ID IS NULL
            AND f.FNGR_PRNT_DNRM = @MenuText
            AND NOT EXISTS(
               SELECT *
                 FROM iScsc.dbo.Fighter ft
                WHERE f.FILE_NO != ft.FILE_NO
                  AND ft.CHAT_ID_DNRM = @ChatID
            );
         
         IF @@ROWCOUNT != 1
         BEGIN
            RAISERROR(N'Error in save data!', 16, 1);
         END
         ELSE
            SELECT @Message = (
               SELECT N'🎉 تبریک ' + s.DOMN_DESC + N' ' +
                      f.NAME_DNRM + N' با شماره پرونده ' + CONVERT(NVARCHAR(14), f.FILE_NO) + N' با کد سیستمی ' + F.FNGR_PRNT_DNRM + N' اطلاعات کاربری بله شما در سیستم باشگاه ثبت شد '
                 FROM iScsc.dbo.Fighter f, iScsc.dbo.[D$SXDC] s                 
                WHERE f.FNGR_PRNT_DNRM = @MenuText
                  AND f.SEX_TYPE_DNRM = s.VALU
            );
      END TRY
      BEGIN CATCH
         SET @Message = N'شماره دستگاه ارسالی قابل ثبت در سیستم نیست، لطفا با قسمت پذیرش هماهنگی به عمل آورید';
      END CATCH 
    END    
    -- نمایش کد بله
    ELSE IF (
      (@UssdCode = '*1*0#' AND @ChildUssdCode = '*1*0*2#') OR 
      (@UssdCode = '*7*0*0#' AND @ChildUssdCode = '*7*0*0*0#') OR 
      (@UssdCode = '*7*1*0#' AND @ChildUssdCode = '*7*1*0*0#')
    )
    BEGIN
      SET @Message = N'کد بله شما ' + CONVERT(NVARCHAR(14), @ChatID) + N' می باشد';
    END
    -- ثبت از طریق شماره موبایل و کد ملی
    IF @UssdCode IN ( '*1*0*7#', '*7*0*0*3#', '*7*1*0*3#' )
    BEGIN
      BEGIN TRY
         DECLARE @NatlCode NVARCHAR(10);

         DECLARE C$Items CURSOR FOR
            SELECT Item FROM dbo.SplitString(@MenuText, '*');
         SET @Index = 0;
         OPEN [C$Items];
         L$FetchC$Item:
         FETCH NEXT FROM [C$Items] INTO @Item;
         
         IF @@FETCH_STATUS <> 0
            GOTO L$EndC$Item;
         
         IF @Index = 0
            SET @CellPhon = @Item;
         ELSE IF @Index = 1
            SET @NatlCode = @Item;
         
         SET @Index += 1;
         GOTO L$FetchC$Item;
         L$EndC$Item:
         CLOSE [C$Items];
         DEALLOCATE [C$Items];    
         
         IF @UssdCode = '*1*0*7#'
            UPDATE fp
               SET fp.CHAT_ID = @ChatID
              FROM iScsc.dbo.Fighter f, iScsc.dbo.Fighter_Public fp
             WHERE f.FILE_NO = fp.FIGH_FILE_NO
               AND f.FGPB_RWNO_DNRM = fp.RWNO
               AND fp.RECT_CODE = '004'
			      AND f.FGPB_TYPE_DNRM = '001'
               AND fp.CHAT_ID IS NULL
               AND f.NATL_CODE_DNRM = @NatlCode
               AND f.CELL_PHON_DNRM = @CellPhon
               AND NOT EXISTS(
                  SELECT *
                    FROM iScsc.dbo.Fighter ft
                   WHERE f.FILE_NO != ft.FILE_NO
                     AND ft.CHAT_ID_DNRM = @ChatID
               );
         ELSE IF @UssdCode = '*7*0*0*3#'
            UPDATE fp
               SET fp.DAD_CHAT_ID = @ChatID
              FROM iScsc.dbo.Fighter f, iScsc.dbo.Fighter_Public fp
             WHERE f.FILE_NO = fp.FIGH_FILE_NO
               AND f.FGPB_RWNO_DNRM = fp.RWNO
               AND fp.RECT_CODE = '004'
			      AND f.FGPB_TYPE_DNRM = '001'
               AND fp.DAD_CHAT_ID IS NULL
               AND f.NATL_CODE_DNRM = @NatlCode
               AND f.DAD_CELL_PHON_DNRM = @CellPhon;
         ELSE IF @UssdCode = '*7*1*0*3#'
            UPDATE fp
               SET fp.MOM_CHAT_ID = @ChatID
              FROM iScsc.dbo.Fighter f, iScsc.dbo.Fighter_Public fp
             WHERE f.FILE_NO = fp.FIGH_FILE_NO
               AND f.FGPB_RWNO_DNRM = fp.RWNO
               AND fp.RECT_CODE = '004'
			      AND f.FGPB_TYPE_DNRM = '001'
               AND fp.MOM_CHAT_ID IS NULL
               AND f.NATL_CODE_DNRM = @NatlCode
               AND f.MOM_CELL_PHON_DNRM = @CellPhon;
         
         IF @@ROWCOUNT != 1
         BEGIN
            RAISERROR(N'Error in save data!', 16, 1);
         END
         ELSE
            SELECT @Message = (
               SELECT N'🎉 تبریک ' + s.DOMN_DESC + N' ' +
                      f.NAME_DNRM + N' با شماره پرونده ' + CONVERT(NVARCHAR(14), f.FILE_NO) + N' با کد سیستمی ' + F.FNGR_PRNT_DNRM + N' اطلاعات کاربری بله شما در سیستم اتوماسیون ثبت شد '
                 FROM iScsc.dbo.Fighter f, iScsc.dbo.[D$SXDC] s                 
                WHERE @ChatID = (
                        CASE @UssdCode 
                             WHEN '*1*0*7#' THEN f.CHAT_ID_DNRM
                             WHEN '*7*0*0*3#' THEN f.DAD_CHAT_ID_DNRM
                             WHEN '*7*1*0*3#' THEN f.MOM_CHAT_ID_DNRM
                        END 
                      )
                  AND f.SEX_TYPE_DNRM = s.VALU
            );
       END TRY
       BEGIN CATCH
         SET @Message = N'شماره موبایل و کد ملی ارسالی قابل ثبت در سیستم نیست، لطفا با قسمت پذیرش هماهنگی به عمل آورید';
       END CATCH   
    END
    -- ثبت از طریق شماره موبایل از سمت بله
    IF @UssdCode = '*1*0#' AND @ChildUssdCode = '*1*0*9#'
    BEGIN
      BEGIN TRY
         UPDATE fp
            SET fp.CHAT_ID = @ChatID
           FROM iScsc.dbo.Fighter f, iScsc.dbo.Fighter_Public fp
          WHERE f.FILE_NO = fp.FIGH_FILE_NO
            AND f.FGPB_RWNO_DNRM = fp.RWNO
            AND fp.RECT_CODE = '004'
			AND f.FGPB_TYPE_DNRM = '001'
            AND fp.CHAT_ID IS NULL
            AND f.CELL_PHON_DNRM = @CellPhon
            AND NOT EXISTS(
               SELECT *
                 FROM iScsc.dbo.Fighter ft
                WHERE f.FILE_NO != ft.FILE_NO
                  AND ft.CHAT_ID_DNRM = @ChatID
            );
         
         IF @@ROWCOUNT != 1
         BEGIN
            RAISERROR(N'Error in save data!', 16, 1);
         END
         ELSE
            SELECT @Message = (
               SELECT N'🎉 تبریک ' + s.DOMN_DESC + N' ' +
                      f.NAME_DNRM + N' با شماره پرونده ' + CONVERT(NVARCHAR(14), f.FILE_NO) + N' با کد سیستمی ' + F.FNGR_PRNT_DNRM + N' اطلاعات کاربری بله شما در سیستم باشگاه ثبت شد '
                 FROM iScsc.dbo.Fighter f, iScsc.dbo.[D$SXDC] s                 
                WHERE f.CHAT_ID_DNRM = @ChatID
                  AND f.SEX_TYPE_DNRM = s.VALU
            );
            
            SELECT @XTemp = (
               SELECT @Token AS '@token'                
                     ,'002' AS 'Order/@dfltaces'
                     ,'012' AS 'Order/@type'
                     ,'001' AS 'Order/@elmntype'
                     ,@UssdCode AS 'Order/@ussdcode'
                     ,@ChildUssdCode AS 'Order/@childussdcode'
                     ,(SELECT s.DOMN_DESC + N' ' +
                              f.NAME_DNRM + N' با شماره پرونده ' + CONVERT(NVARCHAR(14), f.FILE_NO) + N' با کد سیستمی ' + F.FNGR_PRNT_DNRM + N' پروفایل خود را در سیستم ثبت کردند '
                         FROM iScsc.dbo.Fighter f, iScsc.dbo.[D$SXDC] s                 
                        WHERE f.CHAT_ID_DNRM = @ChatID
                          AND f.SEX_TYPE_DNRM = s.VALU) AS 'Order'
              FOR XML PATH('Robot')
            );
            
            -- ثبت پیام به مدیریت باشگاه
            EXEC dbo.SEND_PJRB_P @X = @XTemp -- xml
            
       END TRY
       BEGIN CATCH
         DECLARE @SqlErm NVARCHAR(MAX);
         SELECT @SqlErm = ERROR_MESSAGE();
         RAISERROR (@SqlErm, 16, 1);
         SET @Message = N'شماره موبایل ارسالی قابل ثبت در سیستم نیست، لطفا با قسمت پذیرش هماهنگی به عمل آورید';
       END CATCH   
    END
    -- نمایش اطلاعات من
    ELSE IF (
      (@UssdCode = '*1*0#' AND @ChildUssdCode = '*1*0*4#') OR
      (@UssdCode = '*7*0*0#' AND @ChildUssdCode = '*7*0*0*1#') OR
      (@UssdCode = '*7*1*0#' AND @ChildUssdCode = '*7*1*0*1#')
    )
    BEGIN
      IF EXISTS(
         SELECT *
           FROM iScsc.dbo.Fighter f
          WHERE @ChatID = (
                  CASE @UssdCode 
                       WHEN '*1*0#' THEN f.CHAT_ID_DNRM 
                       WHEN '*7*0*0#' THEN f.DAD_CHAT_ID_DNRM
                       WHEN '*7*1*0#' THEN f.MOM_CHAT_ID_DNRM
                  END
                )
      )
      BEGIN
         SELECT @Message = (
            SELECT CASE @UssdCode 
                       WHEN '*1*0#' THEN N'با سلام و احترام به شما *مشترک* عزیز' + CHAR(10) + s.DOMN_DESC + N' *'+ f.FRST_NAME_DNRM + N' ' + f.LAST_NAME_DNRM + N'*'
                       WHEN '*7*0*0#' THEN N'با سلام و احترام به شما *پدر* عزیز'
                       WHEN '*7*1*0#' THEN N'با سلام و احترام به شما *مادر* مهربان'
                   END  + CHAR(10) +                    
                   CASE @UssdCode 
                       WHEN '*1*0#' THEN N'اطلاعات ثبت شده از *شما* به شرح زیر می باشد'
                       WHEN '*7*0*0#' THEN N'اطلاعات ثبت شده از *فرزند شما* به شرح زیر می باشد'
                       WHEN '*7*1*0#' THEN N'اطلاعات ثبت شده از *فرزند شما* به شرح زیر می باشد'
                   END + CHAR(10) + CHAR(10) +
                   N'نام : *' + f.FRST_NAME_DNRM + N'*' + CHAR(10) + 
                   N'نام خانوادگی : *' + f.LAST_NAME_DNRM + N'*' + CHAR(10) + 
                   N'آدرس پستی : *' + ISNULL(f.POST_ADRS_DNRM, N' --- ') + N'*' + CHAR(10) + 
                   N'جنسیت : *' + sx.DOMN_DESC + N'*' + CHAR(10) + 
                   N'تاریخ تولد : *' + dbo.GET_MTOS_U(f.BRTH_DATE_DNRM) + N'*' + CHAR(10) +
                   N'تلفن همراه : *' + ISNULL(f.CELL_PHON_DNRM, N' --- ') + N'*' + CHAR(10) + 
                   N'تلفن ثابت : *' + ISNULL(f.TELL_PHON_DNRM, N' --- ') + N'*' + CHAR(10) + 
                   N'موقعیت افقی : *' + CONVERT(NVARCHAR(20), ISNULL(f.CORD_X_DNRM, 0)) + N'*' + CHAR(10) + 
                   N'موقعیت عمودی : *' + CONVERT(NVARCHAR(20), ISNULL(f.CORD_Y_DNRM, 0)) + N'*' + CHAR(10) + 
                   N'کد اشتراک : *' + ISNULL(f.SERV_NO_DNRM, N' --- ') + N'*' + CHAR(10) + 
                   N'کد ملی : *' + ISNULL(f.NATL_CODE_DNRM, N' --- ') + N'*' + CHAR(10) 
              FROM iScsc.dbo.Fighter f, iScsc.dbo.[D$SXDC] s, iScsc.dbo.[D$SXTP] sx
            WHERE @ChatID = (
                     CASE @UssdCode 
                          WHEN '*1*0#' THEN f.CHAT_ID_DNRM 
                          WHEN '*7*0*0#' THEN f.DAD_CHAT_ID_DNRM
                          WHEN '*7*1*0#' THEN f.MOM_CHAT_ID_DNRM
                     END
                  )
              AND f.SEX_TYPE_DNRM = s.VALU
              AND s.VALU = sx.VALU
			  AND f.FGPB_TYPE_DNRM = '001'
          FOR XML PATH('')
         );
         
         SELECT @Message += CHAR(10) + N'⏰ '+ dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      END
      ELSE
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END      
    END
    -- نمایش اطلاعات بیمه من
    ELSE IF (
      (@UssdCode = '*1*0#' AND @ChildUssdCode = '*1*0*5#') OR 
      (@UssdCode = '*7*0*0#' AND @ChildUssdCode = '*7*0*0*2#') OR 
      (@UssdCode = '*7*1*0#' AND @ChildUssdCode = '*7*1*0*2#') 
    )
    BEGIN
      IF EXISTS(
         SELECT *
           FROM iScsc.dbo.Fighter f
          WHERE @ChatID = (
                   CASE @UssdCode
                     WHEN '*1*0#' THEN f.CHAT_ID_DNRM
                     WHEN '*7*0*0#' THEN f.DAD_CHAT_ID_DNRM
                     WHEN '*7*1*0#' THEN f.MOM_CHAT_ID_DNRM
                   END          
                )
      )
      BEGIN
         SELECT @Message = (
            SELECT CASE @UssdCode 
                       WHEN '*1*0#' THEN N'با سلام و احترام به شما *مشترک* عزیز' + CHAR(10) + s.DOMN_DESC + N' *'+ f.FRST_NAME_DNRM + N' ' + f.LAST_NAME_DNRM + N'*'
                       WHEN '*7*0*0#' THEN N'با سلام و احترام به شما *پدر* عزیز'
                       WHEN '*7*1*0#' THEN N'با سلام و احترام به شما *مادر* مهربان'
                   END  + CHAR(10) +                    
                   CASE @UssdCode 
                       WHEN '*1*0#' THEN N'اطلاعات ثبت شده از *شما* برای بیمه به شرح زیر می باشد'
                       WHEN '*7*0*0#' THEN N'اطلاعات ثبت شده از *فرزند شما* برای بیمه به شرح زیر می باشد'
                       WHEN '*7*1*0#' THEN N'اطلاعات ثبت شده از *فرزند شما* برای بیمه به شرح زیر می باشد'
                   END + CHAR(10) +
                   N'شماره بیمه ورزشی : *' + ISNULL(f.INSR_NUMB_DNRM, N' --- ') + N'*' + CHAR(10) + 
                   N'تاریخ اعتبار بیمه ورزشی : *' + CASE WHEN F.INSR_DATE_DNRM IS NULL THEN N' --- ' ELSE dbo.GET_MTOS_U(f.INSR_DATE_DNRM) END + N'*' + CHAR(10) 
              FROM iScsc.dbo.Fighter f, iScsc.dbo.[D$SXDC] s, iScsc.dbo.[D$SXTP] sx
            WHERE @ChatID = (
                      CASE @UssdCode
                        WHEN '*1*0#' THEN f.CHAT_ID_DNRM
                        WHEN '*7*0*0#' THEN f.DAD_CHAT_ID_DNRM
                        WHEN '*7*1*0#' THEN f.MOM_CHAT_ID_DNRM
                      END          
                  )
              AND f.SEX_TYPE_DNRM = s.VALU
              AND s.VALU = sx.VALU
			  AND f.FGPB_TYPE_DNRM = '001'
          FOR XML PATH('')
         );
         
         SELECT @Message += CHAR(10) + N'⏰ '+ dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      END
      ELSE
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END      
    END
    -- لیست برنامه های کلاسی من
    ELSE IF (
      (@UssdCode = '*1#' AND @ChildUssdCode = '*1*1#') OR
      (@UssdCode = '*7*0#' AND @ChildUssdCode = '*7*0*1#') OR
      (@UssdCode = '*7*1#' AND @ChildUssdCode = '*7*1*1#')      
    )
    BEGIN
      IF EXISTS( 
         SELECT *
           FROM iScsc.dbo.Fighter f
          WHERE @ChatID = (
                  CASE @UssdCode
                     WHEN '*1#' THEN f.CHAT_ID_DNRM
                     WHEN '*7*0#' THEN f.DAD_CHAT_ID_DNRM
                     WHEN '*7*1#' THEN f.MOM_CHAT_ID_DNRM
                  END 
                )
      )
      BEGIN
         SELECT @Message = (
            SELECT N'💡 دوره *' + CAST(ms.RWNO AS NVARCHAR(10)) + N'* از *' + dbo.GET_MTOS_U(ms.STRT_DATE) + N'* تا *' + dbo.GET_MTOS_U(ms.END_DATE) + N'* ' +
                   N'👤  با *' + c.NAME_DNRM + N'* در *' + mt.MTOD_DESC + N'* ، *' + cb.CTGY_DESC + N'* ثبت نام کرده اید.' + CHAR(10) +
                   CASE WHEN ms.NUMB_OF_ATTN_MONT != 0 THEN 
                     /*N' برای ' + CAST(ms.NUMB_OF_ATTN_MONT AS NVARCHAR(10)) + N' جلسه ثبت نام کرده اید که '  + CAST( ms.NUMB_OF_ATTN_MONT - ms.SUM_ATTN_MONT_DNRM AS NVARCHAR(10)) + N' جلسه دیگر باقیمانده است ' */
                     N'👈 تعداد جلسات باقیمانده [ *' + CAST( ms.NUMB_OF_ATTN_MONT - ms.SUM_ATTN_MONT_DNRM AS NVARCHAR(10)) + N'* ]'
                     ELSE N' '
                   END + CHAR(10) + 
                   N'👈 تعداد روز باقیمانده [ *' + CAST(DATEDIFF(DAY, GETDATE(), ms.END_DATE) AS NVARCHAR(10)) + N'* ]' + CHAR(10) + CHAR(10)
              FROM iScsc.dbo.Fighter f, iScsc.dbo.Member_Ship ms, iScsc.dbo.Fighter_Public fp, iScsc.dbo.Method mt, iScsc.dbo.Category_Belt cb, iScsc.dbo.Fighter c
             WHERE f.FILE_NO = ms.FIGH_FILE_NO
               AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
               AND ms.FGPB_RWNO_DNRM = fp.RWNO
               AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
               AND ms.RECT_CODE = '004'
               AND ms.VALD_TYPE = '002'
			      AND f.FGPB_TYPE_DNRM = '001'
               AND fp.MTOD_CODE = mt.CODE
               AND fp.CTGY_CODE = cb.CODE
               AND fp.COCH_FILE_NO = c.FILE_NO
               AND @ChatID = (
                     CASE @UssdCode
                        WHEN '*1#' THEN f.CHAT_ID_DNRM
                        WHEN '*7*0#' THEN f.DAD_CHAT_ID_DNRM
                        WHEN '*7*1#' THEN f.MOM_CHAT_ID_DNRM
                     END 
                   )
               AND (ms.NUMB_OF_ATTN_MONT = 0 OR ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM)
               AND (CAST(ms.END_DATE AS DATE) >= CAST(GETDATE() AS DATE))
          ORDER BY ms.RWNO DESC 
          FOR XML PATH('')
         );
         
         SELECT @Message += N'⏰ '+ dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      END;
      ELSE
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END
    END;
    -- بدهی هنرجو
    ELSE IF (
      (@UssdCode = '*1#' AND @ChildUssdCode = '*1*2#') OR
      (@UssdCode = '*7*0#' AND @ChildUssdCode = '*7*0*2#') OR
      (@UssdCode = '*7*1#' AND @ChildUssdCode = '*7*1*2#') 
    )
    BEGIN
      IF EXISTS(
         SELECT * 
           FROM iScsc.dbo.Fighter f
          WHERE @ChatID = (
                  CASE @UssdCode
                     WHEN '*1#' THEN f.CHAT_ID_DNRM
                     WHEN '*7*0#' THEN f.DAD_CHAT_ID_DNRM
                     WHEN '*7*1#' THEN f.MOM_CHAT_ID_DNRM
                  END 
          )
      )
      BEGIN
         SELECT @Message = (
            SELECT CASE @UssdCode
                        WHEN '*1#' THEN N'*مشترک* گرامی ' + CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'جناب آقای' ELSE N'سرکار خانم' END + N' *' + f.FRST_NAME_DNRM + N'* *' + f.LAST_NAME_DNRM + N'* '
                        WHEN '*7*0#' THEN N'*پدر* گرامی ' + CASE f.SEX_TYPE_DNRM WHEN '002' THEN N'*' + f.FRST_NAME_DNRM + N'* خانم' WHEN '001' THEN N'آقا *' + f.FRST_NAME_DNRM + N'* ' END 
                        WHEN '*7*1#' THEN N'*مادر* گرامی ' + CASE f.SEX_TYPE_DNRM WHEN '002' THEN N'*' + f.FRST_NAME_DNRM + N'* خانم' WHEN '001' THEN N'آقا *' + f.FRST_NAME_DNRM + N'* ' END 
                   END +
                   CASE WHEN f.DEBT_DNRM > 0 THEN N' بدهی شما *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, f.DEBT_DNRM), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] می باشد'
                   ELSE N' شما مشترک *خوش حساب* ما هستین '
                   END + CHAR(10)
              FROM iScsc.dbo.Fighter f
             WHERE @ChatID = (
                     CASE @UssdCode
                        WHEN '*1#' THEN f.CHAT_ID_DNRM
                        WHEN '*7*0#' THEN f.DAD_CHAT_ID_DNRM
                        WHEN '*7*1#' THEN f.MOM_CHAT_ID_DNRM
                     END 
                   )
			      AND f.FGPB_TYPE_DNRM = '001'
         );
         
         SELECT @Message += N'⏰ '+ dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      END
      ELSE
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END;
    END;
    -- میزان سپرده
    ELSE IF (
      (@UssdCode = '*1#' AND @ChildUssdCode = '*1*8#') OR
      (@UssdCode = '*7*0#' AND @ChildUssdCode = '*7*0*4#') OR
      (@UssdCode = '*7*1#' AND @ChildUssdCode = '*7*1*4#') 
    )
    BEGIN
      IF EXISTS(
         SELECT * 
           FROM iScsc.dbo.Fighter f 
          WHERE @ChatID = 
                  CASE @UssdCode
                        WHEN '*1#' THEN f.CHAT_ID_DNRM
                        WHEN '*7*0#' THEN f.DAD_CHAT_ID_DNRM
                        WHEN '*7*1#' THEN f.MOM_CHAT_ID_DNRM
                   END
      )
      BEGIN
         SELECT @Message = (
            SELECT CASE @UssdCode
                        WHEN '*1#' THEN N'*مشترک* گرامی ' + CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'جناب آقای' ELSE N'سرکار خانم' END + N' *' + f.FRST_NAME_DNRM + N'* *' + f.LAST_NAME_DNRM + N'* '
                        WHEN '*7*0#' THEN N'*پدر* گرامی ' + CASE f.SEX_TYPE_DNRM WHEN '002' THEN N'*' + f.FRST_NAME_DNRM + N'* خانم' WHEN '001' THEN N'آقا *' + f.FRST_NAME_DNRM + N'* ' END 
                        WHEN '*7*1#' THEN N'*مادر* گرامی ' + CASE f.SEX_TYPE_DNRM WHEN '002' THEN N'*' + f.FRST_NAME_DNRM + N'* خانم' WHEN '001' THEN N'آقا *' + f.FRST_NAME_DNRM + N'* ' END 
                    END +
                   N'مبلغ *سپرده* شما *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, f.DPST_AMNT_DNRM), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] می باشد ' + CHAR(10) + CHAR(10)
              FROM iScsc.dbo.Fighter f
             WHERE @ChatID = (
                     CASE @UssdCode
                        WHEN '*1#' THEN f.CHAT_ID_DNRM
                        WHEN '*7*0#' THEN f.DAD_CHAT_ID_DNRM
                        WHEN '*7*1#' THEN f.MOM_CHAT_ID_DNRM
                     END
                   )
			      AND f.FGPB_TYPE_DNRM = '001'
         );
         
         SELECT @Message += N'⏰ '+ dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      END
      ELSE
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END;
    END;    
    -- صورتحساب های هنرجو
    ELSE IF (
      (@UssdCode = '*1#' AND @ChildUssdCode = '*1*6#') OR
      (@UssdCode = '*7*0#' AND @ChildUssdCode = '*7*0*3#') OR
      (@UssdCode = '*7*1#' AND @ChildUssdCode = '*7*1*3#')
    )
    BEGIN
      IF EXISTS(
         SELECT * 
           FROM iScsc.dbo.Fighter f
          WHERE @ChatID = (
                  CASE @UssdCode
                     WHEN '*1#' THEN f.CHAT_ID_DNRM
                     WHEN '*7*0#' THEN f.DAD_CHAT_ID_DNRM
                     WHEN '*7*1#' THEN f.MOM_CHAT_ID_DNRM
                  END
                )
      )
      BEGIN
         SELECT @Message = (
            SELECT CASE @UssdCode
                        WHEN '*1#' THEN N'*مشترک* گرامی ' + CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'جناب آقای' ELSE N'سرکار خانم' END + N' *' + f.FRST_NAME_DNRM + N'* *' + f.LAST_NAME_DNRM + N'* '
                        WHEN '*7*0#' THEN N'*پدر* گرامی ' + CASE f.SEX_TYPE_DNRM WHEN '002' THEN N'*' + f.FRST_NAME_DNRM + N'* خانم' WHEN '001' THEN N'آقا *' + f.FRST_NAME_DNRM + N'* ' END 
                        WHEN '*7*1#' THEN N'*مادر* گرامی ' + CASE f.SEX_TYPE_DNRM WHEN '002' THEN N'*' + f.FRST_NAME_DNRM + N'* خانم' WHEN '001' THEN N'آقا *' + f.FRST_NAME_DNRM + N'* ' END 
                    END + N'صورتحساب های شما به شرح زیر میباشد' + CHAR(10) + CHAR(10)
              FROM iScsc.dbo.Fighter f
             WHERE @ChatID = (
                     CASE @UssdCode
                        WHEN '*1#' THEN f.CHAT_ID_DNRM
                        WHEN '*7*0#' THEN f.DAD_CHAT_ID_DNRM
                        WHEN '*7*1#' THEN f.MOM_CHAT_ID_DNRM
                     END
                   )
			      AND f.FGPB_TYPE_DNRM = '001'
         );
         
         SELECT @FileNo = f.FILE_NO
            FROM iScsc.dbo.Fighter f
           WHERE @ChatID = (
                     CASE @UssdCode
                        WHEN '*1#' THEN f.CHAT_ID_DNRM
                        WHEN '*7*0#' THEN f.DAD_CHAT_ID_DNRM
                        WHEN '*7*1#' THEN f.MOM_CHAT_ID_DNRM
                     END
                 )
		     AND f.FGPB_TYPE_DNRM = '001';           
         
         --SELECT @Message += (
         --   SELECT N'👈 ' + CAST(ROW_NUMBER() OVER (ORDER BY SAVE_DATE) AS NVARCHAR(10)) + N' ) *' /*+ N' نوع صورتحساب '*/ + RQTP_DESC + N'* در تاریخ *' + dbo.GET_MTOS_U(SAVE_DATE) /*+ N' کاربر ثبت کننده ' + CRET_BY*/ + N'* [ مبلغ کل ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, TOTL_AMNT), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' + N' [ مبلغ پرداختی ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, TOTL_RCPT_AMNT), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' + CASE TOTL_DSCT_AMNT WHEN 0 THEN N' ' ELSE + N'[ مبلغ تخفیف ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, TOTL_DSCT_AMNT), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' END + CHAR(10) + CHAR(10)
         --     FROM iScsc.dbo.[VF$Request_Changing](@FileNo) 
         --    WHERE RQTT_CODE != '004'
         -- ORDER BY SAVE_DATE
         --  FOR XML PATH('')
         --);
         SELECT @Message += (
            SELECT N'👈 *' + CAST(PYMT_NO AS NVARCHAR(10)) + N'* ) ' + 
                   N'*' + PYMT_TYPE_DESC + N'* *'+ RQTP_DESC + N'* *' + PYMT_STAT_DESC + N'* ' +
                   N'💥 تاریخ صدور *' + dbo.GET_MTOS_U(PYMT_CRET_DATE) + N'* ' +
                   CASE PYMT_STAT WHEN '002' THEN N'⛔️ تاریخ ابطال *' + dbo.GET_MTOS_U(PYMT_MDFY_DATE) + N'* ' ELSE N' ' END +
                   CASE PYMT_STAT 
                        WHEN '001' THEN 
                           N'[ مبلغ کل ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' + 
                           N'[ مبلغ پرداختی ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, SUM_RCPT_EXPN_PRIC), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' + 
                           CASE SUM_PYMT_DSCN_DNRM 
                              WHEN 0 THEN N' ' 
                              ELSE + N'[ مبلغ تخفیف ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, SUM_PYMT_DSCN_DNRM), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' 
                           END +
                           CASE (SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT) - (SUM_RCPT_EXPN_PRIC + SUM_PYMT_DSCN_DNRM)
                              WHEN 0 THEN N'✅ [ *تسویه کامل* ]'
                              ELSE N'⚠️ [ مانده ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, ((SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT) - (SUM_RCPT_EXPN_PRIC + SUM_PYMT_DSCN_DNRM))), 1), '.00', '') + N'* [ *' + @AmntTypeDesc + N'* ] ' 
                           END 
                        ELSE N'❌ [ *صورتحساب نامعتبر* ]' 
                   END + CHAR(10) + CHAR(10)
              FROM iScsc.dbo.[VF$Save_Payments](NULL, @FileNo)
             ORDER BY PYMT_NO
               FOR XML PATH('')
         );
         
         SELECT @Message += N'⏰ '+ dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      END
      ELSE
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END;
    END
    -- تعداد آمار دعوتی من
    ELSE IF @UssdCode = '*1#' AND @ChildUssdCode = '*1*7#'
    BEGIN
      -- در این قسمت تعداد آمارهای ورودی در خود ربات را نشان دهد
      
      -- گام سوم تعداد مشتریانی که به صورت غیر مستقیم وارد ربات شده اند
      -- گام چهارم تعداد هنرجویانی که به صورت غیرمستقیم عضو باشگاه شده اند 
      SELECT @Message = (
         SELECT N'👥 تعداد مشترکین دعوتی من ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' ) ' + CHAR(10)
           FROM dbo.Service_Robot
          WHERE ROBO_RBID = @Rbid
            AND REF_CHAT_ID = @ChatID
        FOR XML PATH('')
      );
      
      -- گام دوم تعداد هنرجویانی که بعد از دعوت شدن در سیستم باشگاه ثبت نام کرده اند
      SELECT @Message += (
         SELECT N'😎 تعداد اعضا دعوتی من ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' ) ' + CHAR(10)
           FROM iScsc.dbo.Fighter
          WHERE CONF_STAT = '002'
            AND CHAT_ID_DNRM IN (
               SELECT CHAT_ID
                 FROM dbo.Service_Robot
                WHERE ROBO_RBID = @Rbid
                  AND REF_CHAT_ID = @ChatID
            )
      );
      
      SELECT @Message += ISNULL((
         SELECT NAME_DNRM + N' , ' + dbo.GET_MTOS_U(CONF_DATE) + CHAR(10)
           FROM iScsc.dbo.Fighter
          WHERE CONF_STAT = '002'
            AND CHAT_ID_DNRM IN (
               SELECT CHAT_ID
                 FROM dbo.Service_Robot
                WHERE ROBO_RBID = @Rbid
                  AND REF_CHAT_ID = @ChatID
            )
            FOR XML PATH('')            
      ), '');

      
      SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END
    -- تعداد اعضا کلاس مربی
    ELSE IF @UssdCode = '*2*0#' AND @ChildUssdCode = '*2*0*0#'
    BEGIN
      SELECT @CochFileNo = f.FILE_NO
            ,@CochNameDnrm = f.NAME_DNRM
            ,@SexDesc = s.DOMN_DESC
        FROM iScsc.dbo.Fighter f, dbo.[D$SXDC] s
       WHERE f.CHAT_ID_DNRM = @ChatID
         AND f.FGPB_TYPE_DNRM = '003'
         AND f.SEX_TYPE_DNRM = s.VALU;
      
      IF @CochFileNo IS NOT NULL
      BEGIN
         SELECT @Message = (
            SELECT @SexDesc + N' ' + @CochNameDnrm + N' تعداد هنرجویان شما ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' می باشد '
              FROM iScsc.dbo.Member_Ship ms, iScsc.dbo.Fighter_Public fp, iScsc.dbo.Fighter f
             WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
               AND ms.FGPB_RWNO_DNRM = fp.RWNO
               AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
               AND ms.FIGH_FILE_NO = f.FILE_NO
               AND ms.RECT_CODE = '004'
               AND ms.VALD_TYPE = '002'
               AND CAST(ms.END_DATE AS DATE) >= CAST(GETDATE() AS DATE)
               AND (ms.NUMB_OF_ATTN_MONT = 0 OR ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM)
               AND fp.COCH_FILE_NO = @CochFileNo
               AND f.ACTV_TAG_DNRM >= '101'
         );
         
         SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      END 
      ELSE
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END      
    END;
    -- لیست اعضا کلاس مربی
    ELSE IF @UssdCode = '*2*0#' AND @ChildUssdCode = '*2*0*1#'
    BEGIN
      SELECT @CochFileNo = f.FILE_NO
            ,@CochNameDnrm = f.NAME_DNRM
            ,@SexDesc = s.DOMN_DESC
        FROM iScsc.dbo.Fighter f, dbo.[D$SXDC] s
       WHERE f.CHAT_ID_DNRM = @ChatID
         AND f.FGPB_TYPE_DNRM = '003'
         AND f.SEX_TYPE_DNRM = s.VALU;
      
      IF @CochFileNo IS NOT NULL
      BEGIN
         SELECT @Message = @SexDesc + N' ' + @CochNameDnrm + N' لیست هنرجویان شما به شرح زیر می باشد '  + CHAR(10) + (
            SELECT CAST(ROW_NUMBER() OVER (ORDER BY ms.FIGH_FILE_NO) AS NVARCHAR(10)) + N' ) ' + 
                   CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'🙍‍♂️' ELSE N'🙎' END + f.NAME_DNRM + N' ، ' + m.MTOD_DESC + N' ، ' + 
                   CAST(cm.STRT_TIME AS NVARCHAR(5)) + N' * ' + CAST(cm.END_TIME AS NVARCHAR(5)) + N' ، ' +
                   d.DOMN_DESC + N' ' + 
                   CASE WHEN ms.NUMB_OF_ATTN_MONT > 0 THEN N' تعداد جلسات باقیمانده ' + CAST(ms.NUMB_OF_ATTN_MONT - ms.SUM_ATTN_MONT_DNRM AS NVARCHAR(10)) + N' می باشد ' 
                        ELSE N' '
                   END + N' ' + 
                   N' تاریخ پایان عضویت ' + iScsc.dbo.get_mtos_u(ms.End_Date) +                    
                   CHAR(10)
              FROM iScsc.dbo.Member_Ship ms, iScsc.dbo.Fighter_Public fp, iScsc.dbo.Fighter f, iScsc.dbo.Method m, iScsc.dbo.Category_Belt cb, iScsc.dbo.Club_Method cm, iScsc.dbo.[D$DYTP] d
             WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
               AND ms.FGPB_RWNO_DNRM = fp.RWNO
               AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
               AND ms.FIGH_FILE_NO = f.FILE_NO
               AND fp.MTOD_CODE = m.CODE
               AND fp.CTGY_CODE = cb.CODE
               AND fp.CBMT_CODE = cm.CODE
               AND cm.DAY_TYPE = d.VALU
               AND ms.RECT_CODE = '004'
               AND ms.VALD_TYPE = '002'
               AND CAST(ms.END_DATE AS DATE) >= CAST(GETDATE() AS DATE)
               AND (ms.NUMB_OF_ATTN_MONT = 0 OR ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM)
               AND fp.COCH_FILE_NO = @CochFileNo
               AND f.ACTV_TAG_DNRM >= '101'
           FOR XML PATH('')
         );
         
         SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      END 
      ELSE
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END      
    END;
    -- تعداد حضور غیاب اعضا
    ELSE IF @UssdCode = '*2*1#' AND @ChildUssdCode = '*2*1*0#'
    BEGIN
        SELECT @CochFileNo = f.FILE_NO
            ,@CochNameDnrm = f.NAME_DNRM
            ,@SexDesc = s.DOMN_DESC
        FROM iScsc.dbo.Fighter f, dbo.[D$SXDC] s
       WHERE f.CHAT_ID_DNRM = @ChatID
         AND f.FGPB_TYPE_DNRM = '003'
         AND f.SEX_TYPE_DNRM = s.VALU;
        
        IF @CochFileNo IS NOT NULL
        BEGIN
          SELECT @Message = @SexDesc + N' ' + @CochNameDnrm + N' برنامه کلاسی امروز شما به شرح زیر می باشد ' + CHAR(10) + (
            SELECT CHAR(10) + N'👈 ' + T.MTOD_DESC + N' ( ' + CAST(T.END_TIME AS NVARCHAR(5)) + N' * ' + CAST(T.STRT_TIME AS NVARCHAR(5)) + N') تعداد ' + CAST(T.ATTN_CONT AS NVARCHAR(5)) + N' نفر '
              FROM (
               SELECT m.MTOD_DESC, cm.STRT_TIME, cm.END_TIME, COUNT(a.CODE) AS ATTN_CONT
                 FROM iScsc.dbo.Attendance a, iScsc.dbo.Member_Ship ms, iScsc.dbo.Fighter_Public fp, iScsc.dbo.Club_Method cm, iScsc.dbo.Method m
                WHERE a.FIGH_FILE_NO = ms.FIGH_FILE_NO
                  AND a.MBSP_RWNO_DNRM = ms.RWNO
                  AND a.MBSP_RECT_CODE_DNRM = ms.RECT_CODE
                  AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                  AND ms.FGPB_RWNO_DNRM = fp.RWNO
                  AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                  AND ms.RECT_CODE = '004'
                  AND fp.CBMT_CODE = cm.CODE
                  AND fp.MTOD_CODE = m.CODE
                  AND a.COCH_FILE_NO = @CochFileNo
                  AND CAST(a.ATTN_DATE AS DATE) = CAST(GETDATE() AS DATE)
             GROUP BY m.MTOD_DESC, cm.STRT_TIME, cm.END_TIME
            ) T
           FOR XML PATH('')
          );
          
          SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
        END
        ELSE 
        BEGIN
          SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
        END 
    END 
    -- لیست حضور غیاب اعضا
    ELSE IF @UssdCode = '*2*1#' AND @ChildUssdCode = '*2*1*1#'
    BEGIN
      SELECT @CochFileNo = f.FILE_NO
            ,@CochNameDnrm = f.NAME_DNRM
            ,@SexDesc = s.DOMN_DESC
        FROM iScsc.dbo.Fighter f, dbo.[D$SXDC] s
       WHERE f.CHAT_ID_DNRM = @ChatID
         AND f.FGPB_TYPE_DNRM = '003'
         AND f.SEX_TYPE_DNRM = s.VALU;
        
        IF @CochFileNo IS NOT NULL
        BEGIN
          SELECT @Message = @SexDesc + N' ' + @CochNameDnrm + N' برنامه کلاسی امروز شما به شرح زیر می باشد ' + CHAR(10) + (
            SELECT CASE fp.SEX_TYPE WHEN '001' THEN N'🙍‍♂️' ELSE N'🙎' END + fp.FRST_NAME + N' ' + fp.LAST_NAME + N' ' + m.MTOD_DESC + N' ( ' + CAST(cm.STRT_TIME AS NVARCHAR(5)) + N' - ' + CAST(cm.END_TIME AS NVARCHAR(5))+ N' ) 👈 جلسه ' + CAST(a.SUM_ATTN_MONT_DNRM AS NVARCHAR(5))+ N' ام '+ CHAR(10)
              FROM iScsc.dbo.Attendance a, iScsc.dbo.Member_Ship ms, iScsc.dbo.Fighter_Public fp, iScsc.dbo.Club_Method cm, iScsc.dbo.Method m
             WHERE a.FIGH_FILE_NO = ms.FIGH_FILE_NO
               AND a.MBSP_RWNO_DNRM = ms.RWNO
               AND a.MBSP_RECT_CODE_DNRM = ms.RECT_CODE
               AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
               AND ms.FGPB_RWNO_DNRM = fp.RWNO
               AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
               AND ms.RECT_CODE = '004'
               AND fp.CBMT_CODE = cm.CODE
               AND fp.MTOD_CODE = m.CODE
               AND a.COCH_FILE_NO = @CochFileNo
               AND CAST(a.ATTN_DATE AS DATE) = CAST(GETDATE() AS DATE)
           FOR XML PATH('')
          );
          
          SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
        END
        ELSE 
        BEGIN
          SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
        END 
    END 
    -- تعداد ثبت نامی
    ELSE IF @UssdCode = '*2*3#' AND @ChildUssdCode = '*2*3*0#'
    BEGIN
      SELECT @CochFileNo = f.FILE_NO
            ,@CochNameDnrm = f.NAME_DNRM
            ,@SexDesc = s.DOMN_DESC
        FROM iScsc.dbo.Fighter f, dbo.[D$SXDC] s
       WHERE f.CHAT_ID_DNRM = @ChatID
         AND f.FGPB_TYPE_DNRM = '003'
         AND f.SEX_TYPE_DNRM = s.VALU;
        
        IF @CochFileNo IS NOT NULL
        BEGIN
         SELECT @XTemp = (
            SELECT DATEADD(d, (DAY(GETDATE())-1)*-1, CAST(GETDATE() AS date)) AS '@fromrqstdate'
                  ,@CochFileNo AS 'Club_Method/@cochfileno'
           FOR XML PATH('Request')
         );
         
         SELECT @Message = @SexDesc + N' ' + @CochNameDnrm + N' برنامه های ثبت نامی این ماه شما به شرح زیر می باشد ' + CHAR(10) + (
            SELECT N'👈 ' + MTOD_DESC + N' * ' + CTGY_DESC + CHAR(10) + N' تعداد نفرات  👥  ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' ) ثبت نام کرده اند'+ CHAR(10)
              FROM iScsc.dbo.[VF$Coach_Payment](@XTemp)
          GROUP BY MTOD_DESC, CTGY_DESC
           FOR XML PATH('')
         );
         
         SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
        END 
        ELSE 
        BEGIN
          SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
        END 
    END;
    -- لیست ثبت نامی
    ELSE IF @UssdCode = '*2*3#' AND @ChildUssdCode = '*2*3*1#'
    BEGIN
      SELECT @CochFileNo = f.FILE_NO
            ,@CochNameDnrm = f.NAME_DNRM
            ,@SexDesc = s.DOMN_DESC
        FROM iScsc.dbo.Fighter f, dbo.[D$SXDC] s
       WHERE f.CHAT_ID_DNRM = @ChatID
         AND f.FGPB_TYPE_DNRM = '003'
         AND f.SEX_TYPE_DNRM = s.VALU;
        
        IF @CochFileNo IS NOT NULL
        BEGIN
         SELECT @XTemp = (
            SELECT DATEADD(d, (DAY(GETDATE())-1)*-1, CAST(GETDATE() AS date)) AS '@fromrqstdate'
                  ,@CochFileNo AS 'Club_Method/@cochfileno'
           FOR XML PATH('Request')
         );
         
         SELECT @Message = @SexDesc + N' ' + @CochNameDnrm + N' برنامه های ثبت نامی این ماه شما به شرح زیر می باشد ' + CHAR(10) + (
            SELECT N'👤 ' + FIGH_NAME_DNRM + N' ' + MTOD_DESC + N' * ' + CTGY_DESC + N' ( ' + MBSP_END_DATE + N' * ' + MBSP_STRT_DATE + N' ) ' + CHAR(10)
              FROM iScsc.dbo.[VF$Coach_Payment](@XTemp)
          ORDER BY MBSP_STRT_DATE
           FOR XML PATH('')
         );
         
         SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
        END 
        ELSE 
        BEGIN
          SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
        END 
    END;
    -- نمایش اطلاعات من
    ELSE IF @UssdCode = '*2*7#' AND @ChildUssdCode = '*2*7*0#'
    BEGIN
      IF EXISTS(
         SELECT *
           FROM iScsc.dbo.Fighter f
          WHERE f.CHAT_ID_DNRM = @ChatID
		    AND f.FGPB_TYPE_DNRM = '003'
      )
      BEGIN
         SELECT @Message = (
            SELECT N'با سلام و احترام به شما مربی عزیز' + CHAR(10) + 
                   s.DOMN_DESC + N' '+ f.FRST_NAME_DNRM + N' ' + f.LAST_NAME_DNRM + N' اطلاعات ثبت شده از شما به شرح زیر می باشد' + CHAR(10) + 
                   N'نام : ' + f.FRST_NAME_DNRM + CHAR(10) + 
                   N'نام خانوادگی : ' + f.LAST_NAME_DNRM + CHAR(10) + 
                   N'آدرس پستی : ' + ISNULL(f.POST_ADRS_DNRM, N' --- ') + CHAR(10) + 
                   N'جنسیت : ' + sx.DOMN_DESC + CHAR(10) + 
                   N'تاریخ تولد : ' + iScsc.dbo.GET_MTOS_U(f.BRTH_DATE_DNRM) + CHAR(10) +
                   N'تلفن همراه : ' + ISNULL(f.CELL_PHON_DNRM, N' --- ') + CHAR(10) + 
                   N'تلفن ثابت : ' + ISNULL(f.TELL_PHON_DNRM, N' --- ') + CHAR(10) + 
                   N'موقعیت افقی : ' + CONVERT(NVARCHAR(20), ISNULL(f.CORD_X_DNRM, N' ')) + CHAR(10) + 
                   N'موقعیت عمودی : ' + CONVERT(NVARCHAR(20), ISNULL(f.CORD_Y_DNRM, N' ')) + CHAR(10) + 
                   N'کد اشتراک : ' + ISNULL(f.SERV_NO_DNRM, N' --- ') + CHAR(10) + 
                   N'کد ملی : ' + ISNULL(f.NATL_CODE_DNRM, N' --- ') + CHAR(10) +
                   N'درجه مربیگری : ' + ISNULL((SELECT DOMN_DESC FROM iScsc.dbo.[D$DEGR] WHERE VALU = fp.Coch_Deg), N' --- ')
              FROM iScsc.dbo.Fighter f, iScsc.dbo.[D$SXDC] s, iScsc.dbo.[D$SXTP] sx, iScsc.dbo.Fighter_Public fp
            WHERE f.CHAT_ID_DNRM = @ChatID
              AND f.SEX_TYPE_DNRM = s.VALU
              AND s.VALU = sx.VALU
              AND f.FILE_NO = fp.FIGH_FILE_NO
              AND f.FGPB_RWNO_DNRM = fp.RWNO
			  AND f.FGPB_TYPE_DNRM = '003'
              AND fp.RECT_CODE = '004'              
          FOR XML PATH('')
         );
      END
      ELSE
      BEGIN
         SET @Message = N'مربی گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END      
    END
    -- شماره حساب حقوقی
    ELSE IF @UssdCode = '*2*7#' AND @ChildUssdCode = '*2*7*2#'
    BEGIN
      IF EXISTS(
         SELECT *
           FROM iScsc.dbo.Fighter f
          WHERE f.CHAT_ID_DNRM = @ChatID
      )
      BEGIN
         SELECT @Message = (
            SELECT N'با سلام و احترام به شما مربی عزیز' + CHAR(10) + 
                   s.DOMN_DESC + N' '+ f.FRST_NAME_DNRM + N' ' + f.LAST_NAME_DNRM + N' اطلاعات ثبت شده از شما به شرح زیر می باشد' + CHAR(10) + 
                   N'بانک : ' + fp.DPST_ACNT_SLRY_BANK + CHAR(10) + 
                   N'شماره حساب : ' + fp.DPST_ACNT_SLRY + CHAR(10) + 
                   N' 👈 توجه : درصورت روئیت هر گونه مغایرتی در اطلاعات با مدیریت مجموعه اطلاع دهید '
              FROM iScsc.dbo.Fighter f, iScsc.dbo.[D$SXDC] s, iScsc.dbo.[D$SXTP] sx, iScsc.dbo.Fighter_Public fp
            WHERE f.CHAT_ID_DNRM = @ChatID
              AND f.SEX_TYPE_DNRM = s.VALU
              AND s.VALU = sx.VALU
              AND f.FILE_NO = fp.FIGH_FILE_NO
              AND f.FGPB_RWNO_DNRM = fp.RWNO
              AND fp.RECT_CODE = '004'
			  AND f.FGPB_TYPE_DNRM = '003'
          FOR XML PATH('')
         );
      END
      ELSE
      BEGIN
         SET @Message = N'مربی گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END      
    END
    -- بدهی مربی
    ELSE IF @UssdCode = '*2*7#' AND @ChildUssdCode = '*2*7*5#'
    BEGIN
      IF EXISTS(SELECT * FROM iScsc.dbo.Fighter WHERE CHAT_ID_DNRM = @ChatID)
      BEGIN
         SELECT @Message = (
            SELECT N'مربی گرامی' + CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'🙍‍♂️' ELSE N'🙎' END + N' ' + f.FRST_NAME_DNRM + N' ' + f.LAST_NAME_DNRM + 
                   CASE WHEN f.DEBT_DNRM > 0 THEN N' بدهی شما ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, f.DEBT_DNRM), 1), '.00', '') + N' ' + @AmntTypeDesc + N' می باشد'
                   ELSE N' شما مربی خوش حساب ما هستین '
                   END 
              FROM iScsc.dbo.Fighter f
             WHERE f.CHAT_ID_DNRM = @ChatID
			   AND f.FGPB_TYPE_DNRM = '003'
         );
         
         SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      END
      ELSE
      BEGIN
         SET @Message = N'مربی گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END;
    END;
    -- میزان سپرده
    ELSE IF @UssdCode = '*2*7#' AND @ChildUssdCode = '*2*7*7#'
    BEGIN
      IF EXISTS(SELECT * FROM iScsc.dbo.Fighter WHERE CHAT_ID_DNRM = @ChatID)
      BEGIN
         SELECT @Message = (
            SELECT N'مربی گرامی' + CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'🙍‍♂️' ELSE N'🙎' END + N' ' + f.FRST_NAME_DNRM + N' ' + f.LAST_NAME_DNRM + 
                   N' سپرده شما ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, f.DPST_AMNT_DNRM), 1), '.00', '') + N' ' + @AmntTypeDesc + N' می باشد '                   
              FROM iScsc.dbo.Fighter f
             WHERE f.CHAT_ID_DNRM = @ChatID
			   AND f.FGPB_TYPE_DNRM = '003'
         );
         
         SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      END
      ELSE
      BEGIN
         SET @Message = N'مربی گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END;
    END;    
    -- صورتحساب های مربی
    ELSE IF @UssdCode = '*2*7#' AND @ChildUssdCode = '*2*7*6#'
    BEGIN
      IF EXISTS(SELECT * FROM iScsc.dbo.Fighter WHERE CHAT_ID_DNRM = @ChatID)
      BEGIN
         SELECT @Message = (
            SELECT N'مربی گرامی' + CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'🙍‍♂️' ELSE N'🙎' END + N' ' + f.FRST_NAME_DNRM + N' ' + f.LAST_NAME_DNRM + CHAR(10)
              FROM iScsc.dbo.Fighter f
             WHERE f.CHAT_ID_DNRM = @ChatID
			   AND f.FGPB_TYPE_DNRM = '003'
         );
         
         SELECT @FileNo = f.FILE_NO
            FROM iScsc.dbo.Fighter f
           WHERE f.CHAT_ID_DNRM = @ChatID
		     AND f.FGPB_TYPE_DNRM = '003';           
         
         SELECT @Message += (
            SELECT CAST(ROW_NUMBER() OVER (ORDER BY SAVE_DATE) AS NVARCHAR(10)) + N' ) ' /*+ N' نوع صورتحساب '*/ + RQTP_DESC + N' در تاریخ ' + iScsc.dbo.GET_MTOS_U(SAVE_DATE) /*+ N' کاربر ثبت کننده ' + CRET_BY*/ + N' مبلغ کل ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, TOTL_AMNT), 1), '.00', '') + N' مبلغ پرداختی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, TOTL_RCPT_AMNT), 1), '.00', '') + N' مبلغ تخفیف ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, TOTL_DSCT_AMNT), 1), '.00', '') + CHAR(10)
              FROM iScsc.dbo.[VF$Request_Changing](@FileNo) 
             WHERE RQTT_CODE NOT IN ('003', '004')
          ORDER BY SAVE_DATE
           FOR XML PATH('')
         );
         
         SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      END
      ELSE
      BEGIN
         SET @Message = N'مربی گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END;
    END
    -- پرداختی های مربی
    ELSE IF @UssdCode = '*2*7#' AND @ChildUssdCode = '*2*7*4#'
    BEGIN
      IF EXISTS(SELECT * FROM iScsc.dbo.Fighter WHERE CHAT_ID_DNRM = @ChatID)
      BEGIN
         SELECT @Message = (
            SELECT N'مربی گرامی' + CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'🙍‍♂️' ELSE N'🙎' END + N' ' + f.FRST_NAME_DNRM + N' ' + f.LAST_NAME_DNRM + CHAR(10)
              FROM iScsc.dbo.Fighter f
             WHERE f.CHAT_ID_DNRM = @ChatID
			   AND f.FGPB_TYPE_DNRM = '003'
         );
         
         SELECT @FileNo = f.FILE_NO
            FROM iScsc.dbo.Fighter f
           WHERE f.CHAT_ID_DNRM = @ChatID
		     AND f.FGPB_TYPE_DNRM = '003';           
         
         SELECT @Message += (
            SELECT CAST(ROW_NUMBER() OVER (ORDER BY DELV_DATE) AS NVARCHAR(10)) + N' ) ' + iScsc.dbo.GET_MTOS_U(DELV_DATE) + N' مبلغ پرداختی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, me.EXPN_AMNT), 1), '.00', '') + N' بابت ' + ei.EPIT_DESC + CHAR(10)
              FROM [iScsc].[dbo].[Misc_Expense] me, iScsc.dbo.Expense_Item ei
             WHERE me.EPIT_CODE = ei.CODE
               AND me.VALD_TYPE = '002'
               AND me.COCH_FILE_NO = @FileNo
             ORDER BY me.DELV_DATE 
           FOR XML PATH('')
         );
         
         SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      END
      ELSE
      BEGIN
         SET @Message = N'مربی گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره پرونده یا کد سیستمی اطلاعات کد بله خود را در سیستم باشگاه ثبت کنید';
      END;
    END
    -- ثبت از طریق شماره موبایل از سمت بله
    IF @UssdCode = '*2*7#' AND @ChildUssdCode = '*2*7*10#'
    BEGIN
      BEGIN TRY
         UPDATE fp
            SET fp.CHAT_ID = @ChatID
           FROM iScsc.dbo.Fighter f, iScsc.dbo.Fighter_Public fp
          WHERE f.FILE_NO = fp.FIGH_FILE_NO
            AND f.FGPB_RWNO_DNRM = fp.RWNO
            AND fp.RECT_CODE = '004'
			   AND f.FGPB_TYPE_DNRM = '003'
            AND fp.CHAT_ID IS NULL
            AND f.CELL_PHON_DNRM = @CellPhon
            AND NOT EXISTS(
               SELECT *
                 FROM iScsc.dbo.Fighter ft
                WHERE f.FILE_NO != ft.FILE_NO
                  AND ft.CHAT_ID_DNRM = @ChatID
            );
         
         IF @@ROWCOUNT != 1
         BEGIN
            RAISERROR(N'Error in save data!', 16, 1);
         END
         ELSE
            SELECT @Message = (
               SELECT N'🎉 تبریک ' + s.DOMN_DESC + N' ' +
                      f.NAME_DNRM + N' با شماره پرونده ' + CONVERT(NVARCHAR(14), f.FILE_NO) + N' با کد سیستمی ' + F.FNGR_PRNT_DNRM + N' اطلاعات کاربری بله شما در سیستم باشگاه ثبت شد '
                 FROM iScsc.dbo.Fighter f, iScsc.dbo.[D$SXDC] s                 
                WHERE f.CHAT_ID_DNRM = @ChatID
                  AND f.SEX_TYPE_DNRM = s.VALU
                  AND f.FGPB_TYPE_DNRM = '003'
            );
       END TRY
       BEGIN CATCH
         SET @Message = N'شماره موبایل ارسالی قابل ثبت در سیستم نیست، لطفا با قسمت پذیرش هماهنگی به عمل آورید';
       END CATCH   
    END
    -- نمایش کل کلاس های ورزشی
    ELSE IF @UssdCode = '*2*7#' AND @ChildUssdCode = '*2*7*8#'
    BEGIN
      SELECT @Message = (
         SELECT CAST(ROW_NUMBER() OVER (ORDER BY cm.COCH_FILE_NO) AS NVARCHAR(10)) + N' ) ' + CASE SEX_TYPE_DNRM WHEN '001' THEN N'🙍‍♂️' ELSE N'🙎' END + N' ' + 
                m.MTOD_DESC + N' ' + d.DOMN_DESC + N' از ساعت ' + CAST(cm.STRT_TIME AS VARCHAR(5)) + N' تا ساعت ' + CAST(cm.END_TIME AS VARCHAR(5)) + CHAR(10)
           FROM iScsc.dbo.Club_Method cm, 
                iScsc.dbo.Fighter f, 
                iScsc.dbo.Method m, 
                iScsc.dbo.[D$DYTP] d, 
                iScsc.dbo.[D$SXTP] s
          WHERE cm.COCH_FILE_NO = f.FILE_NO
            AND cm.MTOD_CODE = m.CODE
            AND cm.MTOD_STAT = '002'
            AND f.ACTV_TAG_DNRM = '101'
            AND m.MTOD_STAT = '002'
            AND s.VALU = cm.SEX_TYPE
            AND d.VALU = cm.DAY_TYPE
            AND f.CHAT_ID_DNRM = @ChatID
			AND f.FGPB_TYPE_DNRM = '003'
       ORDER BY cm.SEX_TYPE
       FOR XML PATH('')
      );
      
      SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END 
    -- تعداد آمار دعوتی من
    ELSE IF @UssdCode = '*2#' AND @ChildUssdCode = '*2*9#'
    BEGIN
      -- در این قسمت تعداد آمارهای ورودی در خود ربات را نشان دهد
      
      -- گام سوم تعداد مشتریانی که به صورت غیر مستقیم وارد ربات شده اند
      -- گام چهارم تعداد هنرجویانی که به صورت غیرمستقیم عضو باشگاه شده اند 
      SELECT @Message = (
         SELECT N'👥 تعداد مشترکین دعوتی من ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' ) ' + CHAR(10)
           FROM dbo.Service_Robot
          WHERE ROBO_RBID = @Rbid
            AND REF_CHAT_ID = @ChatID
        FOR XML PATH('')
      );
      
      -- گام دوم تعداد هنرجویانی که بعد از دعوت شدن در سیستم باشگاه ثبت نام کرده اند
      SELECT @Message += (
         SELECT N'😎 تعداد اعضا دعوتی من ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' ) ' + CHAR(10)
           FROM iScsc.dbo.Fighter
          WHERE CONF_STAT = '002'
            AND CHAT_ID_DNRM IN (
               SELECT CHAT_ID
                 FROM dbo.Service_Robot
                WHERE ROBO_RBID = @Rbid
                  AND REF_CHAT_ID = @ChatID
            )
      );
      
      SELECT @Message += ISNULL((
         SELECT NAME_DNRM + N' , ' + dbo.GET_MTOS_U(CONF_DATE) + CHAR(10)
           FROM iScsc.dbo.Fighter
          WHERE CONF_STAT = '002'
            AND CHAT_ID_DNRM IN (
               SELECT CHAT_ID
                 FROM dbo.Service_Robot
                WHERE ROBO_RBID = @Rbid
                  AND REF_CHAT_ID = @ChatID
            )
            FOR XML PATH('')            
      ), '');
      
      SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END
    -- عملکرد پرسنلی
    ELSE IF @UssdCode = '*4*0*0#' AND @ChildUssdCode = '*4*0*0*0#'
    BEGIN
      L$USERACTN:
      SELECT @XTemp = (
         SELECT CAST(@FromDate AS DATE) AS '@fromrqstdate'
               ,CAST(@ToDate AS DATE) AS '@torqstdate'
        FOR XML PATH('Request')
      );
      SELECT @Message = (
         SELECT N'👤 ' + CRET_BY + N' ' + MTOD_DESC + CHAR(10) +
                N' 💰 ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(CASE RCPT_MTOD WHEN '001' THEN AMNT ELSE 0 END )), 1), '.00', '') + CHAR(10) + 
                N' 💳 ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(CASE RCPT_MTOD WHEN '003' THEN AMNT ELSE 0 END )), 1), '.00', '') + CHAR(10)
           FROM iScsc.dbo.[VF$Payment_Method](@XTemp)
       GROUP BY CRET_BY, MTOD_DESC
        FOR XML PATH('')
      );
      
      SELECT @Message = ISNULL(@Message, N'عملکرد پرسنلی امروز یافت نشد') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END 
    -- درآمد
    ELSE IF @UssdCode = '*4*0*1#' AND @ChildUssdCode = '*4*0*1*0#'
    BEGIN
      L$PYMT:
      SELECT @XTemp = (
         SELECT CAST(@FromDate AS DATE) AS '@fromrqstdate'
               ,CAST(@ToDate AS DATE) AS '@torqstdate'
        FOR XML PATH('Request')
      );
      SELECT @Message = (
         SELECT N' 💰 ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(CASE RCPT_MTOD WHEN '001' THEN AMNT ELSE 0 END )), 1), '.00', '') + CHAR(10) + 
                N' 💳 ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(CASE RCPT_MTOD WHEN '003' THEN AMNT ELSE 0 END )), 1), '.00', '') + CHAR(10)
           FROM iScsc.dbo.[VF$Payment_Method](@XTemp)
        FOR XML PATH('')
      );
      
      IF @Message IS NOT NULL
         SELECT @Message += (
            SELECT CASE WHEN P.NAME = '' THEN N'درآمد متفرقه' ELSE P.NAME END + N' : ' + CHAR(10) + 
                   N' 💰 ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(CASE RCPT_MTOD WHEN '001' THEN AMNT ELSE 0 END )), 1), '.00', '') + CHAR(10) + 
                   N' 💳 ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(CASE RCPT_MTOD WHEN '003' THEN AMNT ELSE 0 END )), 1), '.00', '') + CHAR(10)
              FROM iScsc.dbo.[VF$Payment_Method](@XTemp) P
          GROUP BY P.NAME
           FOR XML PATH('')
         );
      
      SELECT @Message = ISNULL(@Message, N' مبلغ درآمدی برای امروز ثبت نشده') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END 
    -- سایر درآمدها
    ELSE IF @UssdCode = '*4*0*1*3#' AND @ChildUssdCode = '*4*0*1*3*0#'
    BEGIN
      L$OTHRPYMT:
      SELECT @XTemp = (
         SELECT CAST(@FromDate AS DATE) AS '@fromrqstdate'
               ,CAST(@ToDate AS DATE) AS '@torqstdate'
        FOR XML PATH('Request')
      );
      SELECT @Message = (
         SELECT N' 💰 ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(CASE RCPT_MTOD WHEN '001' THEN AMNT ELSE 0 END )), 1), '.00', '') + CHAR(10) + 
                N' 💳 ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(CASE RCPT_MTOD WHEN '003' THEN AMNT ELSE 0 END )), 1), '.00', '') + CHAR(10)
           FROM iScsc.dbo.[VF$Payment_Method](@XTemp)
          WHERE RQTP_CODE = '016'
        FOR XML PATH('')
      );
      
      SELECT @Message = ISNULL(@Message, N' مبلغ درآمدی برای امروز ثبت نشده') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END     
    -- مالی مربیان
    ELSE IF @UssdCode = '*4*0*2#' AND @ChildUssdCode = '*4*0*2*0#'
    BEGIN
      L$COCHPYMT:
      SELECT @XTemp = (
         SELECT CAST(@FromDate AS DATE) AS '@fromrqstdate'
               ,CAST(@ToDate AS DATE) AS '@torqstdate'
        FOR XML PATH('Request')
      );
      SELECT @Message = (
         SELECT N'👤 ' + NAME_DNRM + N' ' + MTOD_DESC + CHAR(10) + 
                N' 💰 ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(AMNT )), 1), '.00', '') + CHAR(10)  
           FROM iScsc.dbo.[VF$Payment_Method](@XTemp)
       GROUP BY NAME_DNRM, MTOD_DESC
        FOR XML PATH('')
      );
      
      SELECT @Message = ISNULL(@Message, N' هیچ درآمدی از جانب مربیان وجود ندارد') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END 
    -- هزینه های باشگاه
    ELSE IF @UssdCode = '*4*0*3#' AND @ChildUssdCode = '*4*0*3*0#'
    BEGIN
      L$CLUBEXPN:
      SELECT @Message = (
         SELECT ei.EPIT_DESC + N' 👈 ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(EXPN_AMNT) ), 1), '.00', '') + N' * ( ' + CAST(COUNT(me.CODE) AS NVARCHAR(10)) + N' )' + CHAR(10)  
           FROM iScsc.dbo.Misc_Expense me, iScsc.dbo.Expense_Item ei
          WHERE me.EPIT_CODE = ei.CODE
            AND me.DELV_DATE BETWEEN @FromDate AND @ToDate
            AND me.VALD_TYPE = '002'
       GROUP BY ei.EPIT_DESC
        FOR XML PATH('')
      );
      
      SELECT @Message = ISNULL(@Message, N' هزینه ای برای امروز ثبت نشده ') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END 
    -- بدهی موسسات
    ELSE IF @UssdCode = '*4*0*5#' AND @ChildUssdCode = '*4*0*5*0#'
    BEGIN
      L$ORGNDEBT:
      SELECT @XTemp = (
         SELECT dbo.GET_STOM_U(SUBSTRING(dbo.GET_MTOS_U(@FromDate), 1, 8) + '01') AS '@fromsavedate'
               ,dbo.GET_STOM_U(SUBSTRING(dbo.GET_MTOS_U(@ToDate), 1, 8) + '30') AS '@tosavedate'
        FOR XML PATH('Request')
      );
      SELECT @Message = (
         SELECT N'👈 ' + SUNT_DESC + N' تعداد بدهی 👥 ( ' + CAST(COUNT(RWNO) AS NVARCHAR(10)) + N' ) ' + 
                N' مبلغ کل بدهی 💵 ( ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(DEBT_AMNT)), 1), '.00', '') + N' )' + CHAR(10)
           FROM iScsc.dbo.[VF$SystemPaymentSummery](@XTemp)
          WHERE DEBT_AMNT > 0
          GROUP BY SUNT_DESC
        FOR XML PATH('')
      );
      
      IF @Message IS NOT NULL
         SET @Message = N' بدهی کل موسسات از تاریخ ' + SUBSTRING(dbo.GET_MTOS_U(@FromDate), 1, 8) + '01' + N' تا تاریخ ' + SUBSTRING(dbo.GET_MTOS_U(@ToDate), 1, 8) + '30' +  N' به شرح زیر می باشد: ' + CHAR(10) + @Message;
      
      SELECT @Message = ISNULL(@Message, N' هیچ موسسه ای بدهی ندارد ') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END
    -- لیست بدهکاران
    ELSE IF @UssdCode = '*4*0#' AND @ChildUssdCode = '*4*0*6#'
    BEGIN
      SELECT @Message = (
         SELECT CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'👨🏻‍💼' ELSE N'👩🏻‍💼' END + N' ' + f.NAME_DNRM + 
                N' کل بدهی 💵 ( ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, DEBT_DNRM), 1), '.00', '') + N' )' + CHAR(10)
           FROM iScsc.dbo.Fighter f
          WHERE f.CONF_STAT = '002'
            AND f.DEBT_DNRM > 0  
            AND f.ACTV_TAG_DNRM >= '101'     
            FOR XML PATH('')
      );
      
      IF @Message IS NOT NULL
         SELECT @Message += (
            SELECT N' مبلغ کل بدهی 💵 ( ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(DEBT_DNRM)), 1), '.00', '') + N' )' + CHAR(10) + 
                   N' تعداد بدهکاران  ( ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, COUNT(DEBT_DNRM)), 1), '.00', '') + N' )' + CHAR(10)            
              FROM iScsc.dbo.Fighter f
             WHERE f.CONF_STAT = '002'
               AND f.DEBT_DNRM > 0   
               AND f.ACTV_TAG_DNRM >= '101'       
         );
      
      IF @Message IS NOT NULL
         SET @Message = N' بدهی کل اعضا در تاریخ ' + dbo.GET_MTOS_U(GETDATE()) + N' : ' + CHAR(10) + @Message;
      
      SELECT @Message = ISNULL(@Message, N' تمامی اعضا بدون بدهی می باشند ') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END
    -- نمایش تخفیفات
    ELSE IF @UssdCode = '*4*0*7*0#' AND @ChildUssdCode = '*4*0*7*0*0#'
    BEGIN
      L$PYDS:
      SELECT @Message = (
         SELECT  N' 👤 توسط کاربر ' + T.CRET_BY + CHAR(10) +
                 --N' 💎 مبلغ کل ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(T.TOTL_AMNT)), 1), '.00', '') + CHAR(10) +
                 N' 💸 مبلغ تخفیف ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(t.TOTL_DSCT_AMNT)), 1), '.00', '') + CHAR(10)
          FROM  iScsc.dbo.[VF$Request_Changing](NULL) T
         WHERE  RQTT_CODE != '003'
           AND RQST_RQID IS NULL
           AND RQTP_CODE IN ( '001', '009', '016' )
           AND T.TOTL_DSCT_AMNT > 0
           AND EXISTS (SELECT * FROM iScsc.dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = t.RQID AND CAST(pd.CRET_DATE AS DATE) BETWEEN @FromDate AND @ToDate)
         GROUP BY T.CRET_BY
        FOR XML PATH('')
      );
      
      SELECT @Message += (
         SELECT  dbo.GET_MTOS_U(T.SAVE_DATE) + 
                 N' 👥 تعداد ' + CAST(COUNT(T.RQID) AS NVARCHAR(10)) + N' ( ' +
                 T.RQTP_DESC + N' ) ' + CHAR(10) +
                 N' 👤 توسط کاربر ' + T.CRET_BY + CHAR(10) +
                 N' 💸 مبلغ تخفیف ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(t.TOTL_DSCT_AMNT)), 1), '.00', '') + CHAR(10)
         FROM    iScsc.dbo.[VF$Request_Changing](NULL) T
         WHERE RQTT_CODE != '003'
           AND RQST_RQID IS NULL
           AND RQTP_CODE IN ( '001', '009', '016' )
           AND T.TOTL_DSCT_AMNT > 0
           AND EXISTS(SELECT * FROM iScsc.dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = t.RQID AND CAST(Pd.CRET_DATE AS DATE) BETWEEN @FromDate AND @ToDate)
         GROUP BY dbo.GET_MTOS_U(T.SAVE_DATE) ,
                 T.RQTP_DESC ,
                 T.CRET_BY
         ORDER BY dbo.GET_MTOS_U(T.SAVE_DATE)
        FOR XML PATH('')
      );
      
      SELECT @Message = ISNULL(@Message, N' تخفیفات ثبت نشده') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));      
    END
    -- نمایش صورتحساب های پرداخت نشده
    ELSE IF @UssdCode = '*4*0*7*1#' AND @ChildUssdCode = '*4*0*7*1*0#'
    BEGIN
      L$PYNP:
      SELECT @Message = (
         SELECT  N' 👤 توسط کاربر ' + T.CRET_BY + CHAR(10) +
                 --T.RQTP_DESC + N' ) ' + CHAR(10) +
                 N' 💎 مبلغ کل ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(T.TOTL_AMNT)), 1), '.00', '') + CHAR(10) 
         FROM    iScsc.dbo.[VF$Request_Changing](NULL) T
         WHERE   RQTT_CODE != '003'
                 AND RQST_RQID IS NULL
                 AND RQTP_CODE IN ( '001', '009', '016' )
                 AND t.TOTL_AMNT - t.TOTL_DSCT_AMNT > 0
                 AND T.TOTL_RCPT_AMNT = 0
                 AND CAST(T.SAVE_DATE AS DATE) BETWEEN @FromDate AND @ToDate
         GROUP BY T.CRET_BY
        FOR XML PATH('')
      );
      
      SELECT @Message += (
         SELECT  dbo.GET_MTOS_U(T.SAVE_DATE) + 
                 N' 👥 تعداد ' + CAST(COUNT(T.RQID) AS NVARCHAR(10)) + N' ( ' +
                 T.RQTP_DESC + N' ) ' + CHAR(10) +
                 N' 👤 توسط کاربر ' + T.CRET_BY + CHAR(10) +
                 N' 💎 مبلغ کل ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(T.TOTL_AMNT)), 1), '.00', '') + CHAR(10) 
         FROM    iScsc.dbo.[VF$Request_Changing](NULL) T
         WHERE   RQTT_CODE != '003'
                 AND RQST_RQID IS NULL
                 AND RQTP_CODE IN ( '001', '009', '016' )
                 AND t.TOTL_AMNT - t.TOTL_DSCT_AMNT > 0
                 AND T.TOTL_RCPT_AMNT = 0
                 AND CAST(T.SAVE_DATE AS DATE) BETWEEN @FromDate AND @ToDate
         GROUP BY dbo.GET_MTOS_U(T.SAVE_DATE) ,
                 T.RQTP_DESC ,
                 T.CRET_BY
         ORDER BY dbo.GET_MTOS_U(T.SAVE_DATE)
        FOR XML PATH('')
      );
      
      SELECT @Message = ISNULL(@Message, N' صورتحساب های بدون عدم پرداختی ثبت نشده') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));      
    END
    -- نمایش صورتحساب های پرداخت شده با حالت بدهکار
    ELSE IF @UssdCode = '*4*0*7*2#' AND @ChildUssdCode = '*4*0*7*2*0#'
    BEGIN
      L$PYDP:
      SELECT @Message = (
         SELECT  N' 👤 توسط کاربر ' + T.CRET_BY + CHAR(10) +
                 --T.RQTP_DESC + N' ) ' + CHAR(10) +
                 N' 💎 مبلغ کل ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(T.TOTL_AMNT)), 1), '.00', '') + CHAR(10) +
                 N' 💰 مبلغ پرداختی ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(T.TOTL_RCPT_AMNT)), 1), '.00', '') + CHAR(10) 
         FROM    iScsc.dbo.[VF$Request_Changing](NULL) T
         WHERE   RQTT_CODE != '003'
                 AND RQST_RQID IS NULL
                 AND RQTP_CODE IN ( '001', '009', '016' )
                 AND t.TOTL_AMNT > (T.TOTL_RCPT_AMNT + t.TOTL_DSCT_AMNT)
                 AND CAST(T.SAVE_DATE AS DATE) BETWEEN @FromDate AND @ToDate
         GROUP BY T.CRET_BY
        FOR XML PATH('')
      );
      
      SELECT @Message += (
         SELECT  dbo.GET_MTOS_U(T.SAVE_DATE) + 
                 N' 👥 تعداد ' + CAST(COUNT(T.RQID) AS NVARCHAR(10)) + N' ( ' +
                 T.RQTP_DESC + N' ) ' + CHAR(10) +
                 N' 👤 توسط کاربر ' + T.CRET_BY + CHAR(10) +
                 N' 💎 مبلغ کل ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(T.TOTL_AMNT)), 1), '.00', '') + CHAR(10) +                 
                 N' 💰 مبلغ پرداختی ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(T.TOTL_RCPT_AMNT)), 1), '.00', '') + CHAR(10) 
         FROM    iScsc.dbo.[VF$Request_Changing](NULL) T
         WHERE   RQTT_CODE != '003'
                 AND RQST_RQID IS NULL
                 AND RQTP_CODE IN ( '001', '009', '016' )
                 AND t.TOTL_AMNT > (T.TOTL_RCPT_AMNT + t.TOTL_DSCT_AMNT)
                 AND CAST(T.SAVE_DATE AS DATE) BETWEEN @FromDate AND @ToDate
         GROUP BY dbo.GET_MTOS_U(T.SAVE_DATE) ,
                 T.RQTP_DESC ,
                 T.CRET_BY
         ORDER BY dbo.GET_MTOS_U(T.SAVE_DATE)
        FOR XML PATH('')
      );
      
      SELECT @Message = ISNULL(@Message, N' صورتحساب های با بدهکاری ثبت نشده') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));      
    END    
    -- ثبت نام / تمدید
    ELSE IF @UssdCode = '*4*1*0#' AND @ChildUssdCode = '*4*1*0*0#'
    BEGIN
      L$ADMC:
      SELECT @Message = (
         SELECT  dbo.GET_MTOS_U(T.SAVE_DATE) + 
                 N' 👥 تعداد ' + CAST(COUNT(T.RQID) AS NVARCHAR(10)) + N' ( ' +
                 T.RQTP_DESC + N' ) ' + CHAR(10) +
                 N' 👤 توسط کاربر ' + T.CRET_BY + CHAR(10) +
                 N' 💎 مبلغ کل ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(T.TOTL_AMNT)), 1), '.00', '') + CHAR(10) +
                 N' 💰 مبلغ پرداختی ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(T.TOTL_RCPT_AMNT)), 1), '.00', '') + CHAR(10) +
                 N' 💸 مبلغ تخفیف ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, SUM(T.TOTL_DSCT_AMNT)), 1), '.00', '') + CHAR(10)
         FROM    iScsc.dbo.[VF$Request_Changing](NULL) T
         WHERE   RQTT_CODE != '003'
                 AND RQST_RQID IS NULL
                 AND RQTP_CODE IN ( '001', '009' )
                 AND CAST(T.SAVE_DATE AS DATE) BETWEEN @FromDate AND @ToDate
         GROUP BY dbo.GET_MTOS_U(T.SAVE_DATE) ,
                 T.RQTP_DESC ,
                 T.CRET_BY
         ORDER BY dbo.GET_MTOS_U(T.SAVE_DATE)
        FOR XML PATH('')
      );
      
      SELECT @Message = ISNULL(@Message, N' تعداد ثبت نام و تمدید برای امروز ثبت نشده') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END 
    -- گزارش تردد اعضا امروز
    ELSE IF @UssdCode = '*4*1*1#' AND @ChildUssdCode = '*4*1*1*0#'
    BEGIN
      L$Attn:
      SELECT @Message = (
         SELECT  dbo.GET_MTOS_U(a.ATTN_DATE) + CHAR(10) +
                 su.SUNT_DESC + N' به تعداد ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' )' + CHAR(10)
         FROM    iScsc.dbo.Attendance a ,
                 iScsc.dbo.Member_Ship ms ,
                 iScsc.dbo.Fighter_Public fp ,
                 iScsc.dbo.Sub_Unit su
         WHERE   a.FIGH_FILE_NO = ms.FIGH_FILE_NO
                 AND a.MBSP_RWNO_DNRM = ms.RWNO
                 AND a.MBSP_RECT_CODE_DNRM = ms.RECT_CODE
                 AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                 AND ms.FGPB_RWNO_DNRM = fp.RWNO
                 AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                 AND fp.SUNT_BUNT_DEPT_ORGN_CODE = su.BUNT_DEPT_ORGN_CODE
                 AND fp.SUNT_BUNT_DEPT_CODE = su.BUNT_DEPT_CODE
                 AND fp.SUNT_BUNT_CODE = su.BUNT_CODE
                 AND fp.SUNT_CODE = su.CODE
                 AND fp.TYPE = '001'
                 AND a.ATTN_DATE BETWEEN @FromDate AND @ToDate
         GROUP BY dbo.GET_MTOS_U(a.ATTN_DATE) ,
                 su.SUNT_DESC
         FOR XML PATH('')         
      );
      
      SELECT @Message = ISNULL(@Message, N' گزارش تردد اعضا برای امروز ثبت نشده') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END 
    -- گزارش تردد اعضا ماه
    ELSE IF @UssdCode = '*4*1*1#' AND @ChildUssdCode = '*4*1*1*4#'
    BEGIN
      SELECT @Message = (
         SELECT  SUBSTRING(dbo.GET_MTOS_U(a.ATTN_DATE), 1, 7) + CHAR(10) +
                 su.SUNT_DESC + N' به تعداد ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' )'
         FROM    iScsc.dbo.Attendance a ,
                 iScsc.dbo.Member_Ship ms ,
                 iScsc.dbo.Fighter_Public fp ,
                 iScsc.dbo.Sub_Unit su
         WHERE   a.FIGH_FILE_NO = ms.FIGH_FILE_NO
                 AND a.MBSP_RWNO_DNRM = ms.RWNO
                 AND a.MBSP_RECT_CODE_DNRM = ms.RECT_CODE
                 AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                 AND ms.FGPB_RWNO_DNRM = fp.RWNO
                 AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                 AND fp.SUNT_BUNT_DEPT_ORGN_CODE = su.BUNT_DEPT_ORGN_CODE
                 AND fp.SUNT_BUNT_DEPT_CODE = su.BUNT_DEPT_CODE
                 AND fp.SUNT_BUNT_CODE = su.BUNT_CODE
                 AND fp.SUNT_CODE = su.CODE
                 AND fp.TYPE = '001'
                 AND SUBSTRING(dbo.GET_MTOS_U(a.ATTN_DATE), 1, 7) = SUBSTRING(dbo.GET_MTOS_U(GETDATE()), 1 , 7)
         GROUP BY SUBSTRING(dbo.GET_MTOS_U(a.ATTN_DATE), 1, 7) ,
                 su.SUNT_DESC
         ORDER BY SUBSTRING(dbo.GET_MTOS_U(a.ATTN_DATE), 1, 7)
         FOR XML PATH('')         
      );
      
      SELECT @Message = ISNULL(@Message, N' گزارش تردد اعضا برای امروز ثبت نشده') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END 
    -- گزارش تردد اعضا سال
    ELSE IF @UssdCode = '*4*1*1#' AND @ChildUssdCode = '*4*1*1*5#'
    BEGIN
      SELECT @Message = (
         SELECT  SUBSTRING(dbo.GET_MTOS_U(a.ATTN_DATE), 1, 4) + CHAR(10) +
                 su.SUNT_DESC + N' به تعداد ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' )'
         FROM    iScsc.dbo.Attendance a ,
                 iScsc.dbo.Member_Ship ms ,
                 iScsc.dbo.Fighter_Public fp ,
                 iScsc.dbo.Sub_Unit su
         WHERE   a.FIGH_FILE_NO = ms.FIGH_FILE_NO
                 AND a.MBSP_RWNO_DNRM = ms.RWNO
                 AND a.MBSP_RECT_CODE_DNRM = ms.RECT_CODE
                 AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                 AND ms.FGPB_RWNO_DNRM = fp.RWNO
                 AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                 AND fp.SUNT_BUNT_DEPT_ORGN_CODE = su.BUNT_DEPT_ORGN_CODE
                 AND fp.SUNT_BUNT_DEPT_CODE = su.BUNT_DEPT_CODE
                 AND fp.SUNT_BUNT_CODE = su.BUNT_CODE
                 AND fp.SUNT_CODE = su.CODE
                 AND fp.TYPE = '001'
                 AND SUBSTRING(dbo.GET_MTOS_U(a.ATTN_DATE), 1, 4) = SUBSTRING(dbo.GET_MTOS_U(GETDATE()), 1 , 4)
         GROUP BY SUBSTRING(dbo.GET_MTOS_U(a.ATTN_DATE), 1, 4) ,
                 su.SUNT_DESC
         FOR XML PATH('')         
      );
      
      SELECT @Message = ISNULL(@Message, N' گزارش تردد اعضا برای امروز ثبت نشده') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END 
    -- گزارش کارت فروخته شده
    ELSE IF @UssdCode = '*4*1*2#' AND @ChildUssdCode = '*4*1*2*0#'
    BEGIN
      SELECT @Message = (
         SELECT N' تعداد کارت فروخته شده ( ' + CAST(COUNT( DISTINCT fp.FNGR_PRNT ) AS NVARCHAR(10)) + N' )' + CHAR(10)
           FROM iScsc.dbo.Fighter_Public fp
          WHERE fp.RECT_CODE = '004'
            AND fp.FNGR_PRNT IS NOT NULL
            AND LEN(fp.FNGR_PRNT) >= 8
        FOR XML PATH('')
      );
      
      SET @Message += N'--------------------------' + CHAR(10);
      
      SELECT @Message += (
         SELECT su.SUNT_DESC + N' 🏷 ( ' + CAST(COUNT(f.FILE_NO) AS NVARCHAR(10)) + N' )' + CHAR(10)
           FROM iScsc.dbo.Fighter f, iScsc.dbo.Sub_Unit su
          WHERE f.SUNT_BUNT_DEPT_ORGN_CODE_DNRM = su.BUNT_DEPT_ORGN_CODE
            AND f.SUNT_BUNT_DEPT_CODE_DNRM = su.BUNT_DEPT_CODE
            AND f.SUNT_BUNT_CODE_DNRM = su.BUNT_CODE
            AND f.SUNT_CODE_DNRM = su.CODE
            AND f.FNGR_PRNT_DNRM IS NOT NULL
            AND LEN(f.FNGR_PRNT_DNRM) >= 8
       GROUP BY su.SUNT_DESC
         FOR XML PATH('')
      );
      
      SELECT @Message = ISNULL(@Message, N' کارتی برای فروش ثبت نشده است ') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END
    -- گزارش کارت المثنی
    ELSE IF @UssdCode = '*4*1*2#' AND @ChildUssdCode = '*4*1*2*1#'
    BEGIN
      SELECT @Message = (
         SELECT N' تعداد کارت المثنی صادر شده ( ' + CAST(COUNT( DISTINCT fpt.FNGR_PRNT ) AS NVARCHAR(10)) + N' )' + CHAR(10)
           FROM iScsc.dbo.Fighter_Public fpt, iScsc.dbo.Fighter_Public fps
          WHERE fps.FIGH_FILE_NO = fpt.FIGH_FILE_NO
            AND fps.RWNO = (fpt.RWNO + 1)
            AND fps.RECT_CODE = '004'
            AND fpt.RECT_CODE = '004'
            AND fpt.FNGR_PRNT IS NOT NULL
            AND LEN(fpt.FNGR_PRNT) >= 8
            AND fps.FNGR_PRNT IS NOT NULL
            AND LEN(fps.FNGR_PRNT) >= 8
            AND fps.FNGR_PRNT != fpt.FNGR_PRNT
        FOR XML PATH('')
      );
      
      SELECT @Message = ISNULL(@Message, N' کارت المثنی ثبت نشده است ') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END
    -- گزارش تردد مربیان
    ELSE IF @UssdCode = '*4*1*3#' AND @ChildUssdCode = '*4*1*3*0#'
    BEGIN
      SELECT @Message = (
         SELECT  dbo.GET_MTOS_U(a.ATTN_DATE) + CHAR(10) +
                 su.SUNT_DESC + N' به تعداد ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' )'
         FROM    iScsc.dbo.Attendance a ,
                 iScsc.dbo.Member_Ship ms ,
                 iScsc.dbo.Fighter_Public fp ,
                 iScsc.dbo.Sub_Unit su
         WHERE   a.FIGH_FILE_NO = ms.FIGH_FILE_NO
                 AND a.MBSP_RWNO_DNRM = ms.RWNO
                 AND a.MBSP_RECT_CODE_DNRM = ms.RECT_CODE
                 AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                 AND ms.FGPB_RWNO_DNRM = fp.RWNO
                 AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                 AND fp.SUNT_BUNT_DEPT_ORGN_CODE = su.BUNT_DEPT_ORGN_CODE
                 AND fp.SUNT_BUNT_DEPT_CODE = su.BUNT_DEPT_CODE
                 AND fp.SUNT_BUNT_CODE = su.BUNT_CODE
                 AND fp.SUNT_CODE = su.CODE
                 AND fp.TYPE = '003'
                 AND a.ATTN_DATE = CAST(GETDATE() AS DATE)
         GROUP BY dbo.GET_MTOS_U(a.ATTN_DATE) ,
                 su.SUNT_DESC
      );
      
      SELECT @Message = ISNULL(@Message, N' گزارش تردد اعضا برای امروز ثبت نشده') + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END 
    -- پشتیبان گیری
    ELSE IF @UssdCode = '*4*2#' AND @ChildUssdCode = '*4*2*0#'
    BEGIN
      SELECT @XTemp = (
         SELECT TOP 1 
                'Normal' AS '@type',
                CLUB_CODE AS '@clubcode'
           FROM iScsc.dbo.Settings
        FOR XML PATH('Backup'), ROOT('Request')        
      );
      
      EXEC iScsc.dbo.TAK_BKUP_P @X = @XTemp -- xml
      EXEC dbo.TAK_BKUP_P @X = @XTemp -- xml      
      
      SELECT @Message = N' پشتیبان گیری نرم افزار به صورت کامل انجام شد ' + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END
    -- آمار مشترکین
    ELSE IF @UssdCode = '*4*1#' AND @ChildUssdCode = '*4*1*5#'
    BEGIN
      SELECT @Message = (
         SELECT N' 👥 آمار کل مشترکین ' + CAST(COUNT(*) AS NVARCHAR(10)) + CHAR(10)
           FROM dbo.Service_Robot
          WHERE ROBO_RBID = @Rbid          
      );
      
      SELECT @Message += (
         SELECT N' 👥 آمار مشترکین امروز ' + CAST(COUNT(*) AS NVARCHAR(10)) + CHAR(10)
           FROM dbo.Service_Robot
          WHERE ROBO_RBID = @Rbid          
            AND JOIN_DATE = CAST(GETDATE() AS DATE)
      );
      
      SELECT @Message += (
         SELECT N' 👥 آمار سیستمی اعضا ' + CAST(COUNT(*) AS NVARCHAR(10)) + CHAR(10)
           FROM dbo.Service_Robot, iScsc.dbo.Fighter 
          WHERE ROBO_RBID = @Rbid          
            AND CHAT_ID = CHAT_ID_DNRM
      );
      
      SELECT @Message += (
         SELECT N' 👥 آمار کلی  اعضا ' + CAST(COUNT(*) AS NVARCHAR(10)) + CHAR(10) +
                N' 👥 آمار اعضا فعال ' + CAST(SUM(CASE WHEN MBSP_END_DATE >= CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) AS NVARCHAR(10)) + CHAR(10) + 
                N' 👥 آمار اعضا غیرفعال ' + CAST(SUM(CASE WHEN MBSP_END_DATE < CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) AS NVARCHAR(10)) + CHAR(10) +
                
                N' 👨🏻‍💼 آمار کلی اقایان ' + CAST(SUM(CASE SEX_TYPE_DNRM WHEN '001' THEN 1 ELSE 0 END) AS NVARCHAR(10)) + CHAR(10) +
                N' 👨🏻‍💼 آمار آقایان فعال ' + CAST(SUM(CASE WHEN MBSP_END_DATE >= CAST(GETDATE() AS DATE) AND SEX_TYPE_DNRM = '001' THEN 1 ELSE 0 END) AS NVARCHAR(10)) + CHAR(10) + 
                N' 👨🏻‍💼 آمار آقایان غیرفعال ' + CAST(SUM(CASE WHEN MBSP_END_DATE < CAST(GETDATE() AS DATE) AND SEX_TYPE_DNRM = '001' THEN 1 ELSE 0 END) AS NVARCHAR(10)) + CHAR(10) +
                
                N' 👩🏻‍💼 آمار کلی بانوان ' + CAST(SUM(CASE SEX_TYPE_DNRM WHEN '002' THEN 1 ELSE 0 END) AS NVARCHAR(10)) + CHAR(10) +
                N' 👩🏻‍💼 آمار بانوان فعال ' + CAST(SUM(CASE WHEN MBSP_END_DATE >= CAST(GETDATE() AS DATE) AND SEX_TYPE_DNRM = '002' THEN 1 ELSE 0 END) AS NVARCHAR(10)) + CHAR(10) + 
                N' 👩🏻‍💼 آمار بانوان غیرفعال ' + CAST(SUM(CASE WHEN MBSP_END_DATE < CAST(GETDATE() AS DATE) AND SEX_TYPE_DNRM = '002' THEN 1 ELSE 0 END) AS NVARCHAR(10)) + CHAR(10) 
           FROM iScsc.dbo.Fighter
          WHERE CONF_STAT = '002'
            AND FGPB_TYPE_DNRM = '001'
      );
      
      SELECT @Message += N' آمار سیستمی مشتریان و اعضا ' + CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));      
    END    
    -- ارسال پیام در قسمت مدیریت
    ELSE IF @UssdCode = '*4*3*0#' -- ارسال برای همه مشترکین
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
    ELSE IF @UssdCode = '*4*3*1#' -- ارسال برای همه اعضا
    BEGIN
      DECLARE C$FIGH001 CURSOR FOR
         SELECT CHAT_ID_DNRM
           FROM iScsc.dbo.Fighter
          WHERE CONF_STAT = '002'
            AND CHAT_ID_DNRM IS NOT NULL
            AND FGPB_TYPE_DNRM = '001';
      
      OPEN [C$FIGH001];
      L$Loop_Figh001:
      FETCH [C$FIGH001] INTO @ChatID;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoop_Figh001;
      
      SET @SrbtServFileNo = NULL;
      SELECT @SrbtServFileNo = SERV_FILE_NO
        FROM dbo.Service_Robot
       WHERE ROBO_RBID = @Rbid
         AND CHAT_ID = @ChatID;
      
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
      
      GOTO L$Loop_Figh001;
      L$EndLoop_Figh001:
      CLOSE [C$FIGH001];
      DEALLOCATE [C$FIGH001];
      
      SELECT @Message = N'پیام شما برای همه اعضا باشگاه با موفقیت ثبت شد لطفا دکمه بازگشت جهت ارسال پیام را فشار دهید';
    END
    ELSE IF @UssdCode = '*4*3*4#' -- ارسال برای مربیان
    BEGIN
      DECLARE C$FIGH003 CURSOR FOR
         SELECT CHAT_ID_DNRM
           FROM iScsc.dbo.Fighter
          WHERE CONF_STAT = '002'
            AND CHAT_ID_DNRM IS NOT NULL
            AND FGPB_TYPE_DNRM = '003';
      
      OPEN [C$FIGH003];
      L$Loop_Figh003:
      FETCH [C$FIGH003] INTO @ChatID;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoop_Figh003;
         
      SET @SrbtServFileNo = NULL;
      SELECT @SrbtServFileNo = SERV_FILE_NO
        FROM dbo.Service_Robot
       WHERE ROBO_RBID = @Rbid
         AND CHAT_ID = @ChatID;
      
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
      
      GOTO L$Loop_Figh003;
      L$EndLoop_Figh003:
      CLOSE [C$FIGH003];
      DEALLOCATE [C$FIGH003];
      
      SELECT @Message = N'پیام شما برای مربیان با موفقیت ثبت شد لطفا دکمه بازگشت جهت ارسال پیام را فشار دهید';
    END
    ELSE IF @UssdCode = '*4*3#' AND @ChildUssdCode = '*4*3*6#' -- برای تسویه بدهی
    BEGIN
      DECLARE C$FIGHDEBT CURSOR FOR
         SELECT CHAT_ID_DNRM
           FROM iScsc.dbo.Fighter
          WHERE CONF_STAT = '002'
            AND DEBT_DNRM > 0
            AND CHAT_ID_DNRM IS NOT NULL;
      
      OPEN [C$FIGHDEBT];
      L$Loop_FighDebt:
      FETCH [C$FIGHDEBT] INTO @ChatID;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoop_FighDebt;
      
      SELECT @Message = (
         SELECT N'❗️ ' + s.DOMN_DESC + N' ' + f.FRST_NAME_DNRM + N' ' + f.LAST_NAME_DNRM + N' مبلغ بدهی شما ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, f.DEBT_DNRM), 1), '.00', '') + N' ' + @AmntTypeDesc + N' لطفا جهت پرداخت بدهی خود ظرف 2 روز آینده اقدام فرمایید ' + CHAR(10) + N' با تشکر مدیریت باشگاه '
           FROM iScsc.dbo.Fighter f, dbo.[D$SXDC] s
          WHERE CHAT_ID_DNRM = @ChatID          
            AND f.SEX_TYPE_DNRM = s.VALU
      );
      
      SET @SrbtServFileNo = NULL;
      SELECT @SrbtServFileNo = SERV_FILE_NO
        FROM dbo.Service_Robot
       WHERE ROBO_RBID = @Rbid
         AND CHAT_ID = @ChatID;
      
      IF @SrbtServFileNo IS NOT NULL
      BEGIN
         EXEC dbo.INS_SRRM_P @SRBT_SERV_FILE_NO = @SrbtServFileNo, -- bigint
             @SRBT_ROBO_RBID = @Rbid, -- bigint
             @RWNO = 0, -- bigint
             @SRMG_RWNO = NULL, -- bigint
             @Ordt_Ordr_Code = NULL, -- bigint
             @Ordt_Rwno = NULL, -- bigint
             @MESG_TEXT = @Message, -- nvarchar(max)
             @FILE_ID = NULL, -- varchar(200)
             @FILE_PATH = NULL, -- nvarchar(max)
             @MESG_TYPE = '001', -- varchar(3)
             @LAT = NULL, -- float
             @LON = NULL, -- float
             @CONT_CELL_PHON = NULL; -- varchar(11)      
      END;
      
      GOTO L$Loop_FighDebt;
      L$EndLoop_FighDebt:
      CLOSE [C$FIGHDEBT];
      DEALLOCATE [C$FIGHDEBT];
      
      SELECT @Message = N'پیام شما برای تسویه بدهی با موفقیت ثبت شد لطفا دکمه بازگشت جهت ارسال پیام را فشار دهید';
    END
    -- ارسال پیام در قسمت مربیان
    ELSE IF @UssdCode = '*2*5*0#' -- ارسال برای همه اعضا
    BEGIN
      SELECT @FileNo = File_No, @Name = NAME_DNRM
        FROM iScsc.dbo.Fighter
       WHERE CHAT_ID_DNRM = @ChatID;
      
      SET @MenuText = N' 👨‍🔬 ' + @Name + N' : ' + CHAR(10) + @MenuText;
       
      DECLARE C$FIGH001OF003 CURSOR FOR
         SELECT DISTINCT CHAT_ID_DNRM
           FROM iScsc.dbo.Fighter f
          WHERE CONF_STAT = '002'
            AND CHAT_ID_DNRM IS NOT NULL
            AND FGPB_TYPE_DNRM = '001'
            AND EXISTS(
                SELECT *
                  FROM iScsc.dbo.Member_Ship ms, iScsc.dbo.Fighter_Public fp
                 WHERE ms.FIGH_FILE_NO = F.FILE_NO
                   AND ms.RECT_CODE = '004'
                   AND fp.FIGH_FILE_NO = f.FILE_NO
                   AND fp.RECT_CODE = '004'
                   AND ms.FGPB_RWNO_DNRM = fp.RWNO
                   AND fp.COCH_FILE_NO = @FileNo
                   AND ( ms.END_DATE >= CAST(GETDATE() AS DATE) AND 
                           (
                            (ms.NUMB_OF_ATTN_MONT = 0) OR 
                            (ms.NUMB_OF_ATTN_MONT != 0 AND ms.NUMB_OF_ATTN_MONT >= ms.SUM_ATTN_MONT_DNRM)
                           )                             
                       )
            );
      
      OPEN [C$FIGH001OF003];
      L$Loop_Figh001OF003:
      FETCH [C$FIGH001OF003] INTO @ChatID;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoop_Figh001OF003;
      
      SET @SrbtServFileNo = NULL;
      SELECT @SrbtServFileNo = SERV_FILE_NO
        FROM dbo.Service_Robot
       WHERE ROBO_RBID = @Rbid
         AND CHAT_ID = @ChatID;
      
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
      GOTO L$Loop_Figh001OF003;
      L$EndLoop_Figh001OF003:
      CLOSE [C$FIGH001OF003];
      DEALLOCATE [C$FIGH001OF003];
      
      SELECT @Message = N'پیام شما برای  همه اعضا با موفقیت ثبت شد لطفا دکمه بازگشت جهت ارسال پیام را فشار دهید';
    END
    ELSE IF @UssdCode = '*2*5*3#' -- ارسال برای مدیریت
    BEGIN
      SELECT @Message = N'پیام شما برای مدیریت باشگاه با موفقیت ثبت شد لطفا دکمه بازگشت جهت ارسال پیام را فشار دهید';
    END
	 -- ارسال پیام در قسمت اعضا
    ELSE IF @UssdCode = '*1*9*0#' -- ارسال برای مربی
    BEGIN
      SELECT @Message = N'پیام شما برای  مربی با موفقیت ثبت شد لطفا دکمه بازگشت جهت ارسال پیام را فشار دهید';
    END
    ELSE IF @UssdCode = '*1*9*1#' -- ارسال برای مدیریت
    BEGIN
      SELECT @Message = N'پیام شما برای مدیر باشگاه با موفقیت ثبت شد لطفا دکمه بازگشت جهت ارسال پیام را فشار دهید';
    END
	 -- تعداد آمار دعوتی من
    ELSE IF @UssdCode = '*4#' AND @ChildUssdCode = '*4*5#'
    BEGIN
      -- در این قسمت تعداد آمارهای ورودی در خود ربات را نشان دهد
      
      -- گام سوم تعداد مشتریانی که به صورت غیر مستقیم وارد ربات شده اند
      -- گام چهارم تعداد هنرجویانی که به صورت غیرمستقیم عضو باشگاه شده اند 
      SELECT @Message = (
         SELECT N'👥 تعداد مشترکین دعوتی من ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' ) ' + CHAR(10)
           FROM dbo.Service_Robot
          WHERE ROBO_RBID = @Rbid
            AND REF_CHAT_ID = @ChatID
        FOR XML PATH('')
      );
      
      -- گام دوم تعداد هنرجویانی که بعد از دعوت شدن در سیستم باشگاه ثبت نام کرده اند
      SELECT @Message += (
         SELECT N'😎 تعداد اعضا دعوتی من ( ' + CAST(COUNT(*) AS NVARCHAR(10)) + N' ) ' + CHAR(10)
           FROM iScsc.dbo.Fighter
          WHERE CONF_STAT = '002'
            AND CHAT_ID_DNRM IN (
               SELECT CHAT_ID
                 FROM dbo.Service_Robot
                WHERE ROBO_RBID = @Rbid
                  AND REF_CHAT_ID = @ChatID
            )
      );
      
      SELECT @Message += ISNULL((
         SELECT NAME_DNRM + N' , ' + dbo.GET_MTOS_U(CONF_DATE) + CHAR(10)
           FROM iScsc.dbo.Fighter
          WHERE CONF_STAT = '002'
            AND CHAT_ID_DNRM IN (
               SELECT CHAT_ID
                 FROM dbo.Service_Robot
                WHERE ROBO_RBID = @Rbid
                  AND REF_CHAT_ID = @ChatID
            )
            FOR XML PATH('')            
      ), '');      
      
      SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END
    -- تعداد اعضا کلاس مربی
    ELSE IF @UssdCode = '*4*1*6#' AND @ChildUssdCode = '*4*1*6*0#'
    BEGIN
      SELECT @Message = (
         SELECT sx.DOMN_DESC + N' ' + c.NAME_DNRM + 
                N' تعداد اعضا 👥 ' + CAST(COUNT(*) AS NVARCHAR(10)) + CHAR(10)
           FROM iScsc.dbo.Member_Ship ms, 
                iScsc.dbo.Fighter_Public fp, 
                iScsc.dbo.Fighter f,
                iScsc.dbo.Fighter c,
                iScsc.dbo.[D$SXDC] sx
          WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
            AND ms.FGPB_RWNO_DNRM = fp.RWNO
            AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
            AND ms.FIGH_FILE_NO = f.FILE_NO
            AND f.SEX_TYPE_DNRM = sx.VALU
            AND fp.COCH_FILE_NO = c.FILE_NO
            AND ms.RECT_CODE = '004'
            AND ms.VALD_TYPE = '002'
            AND CAST(ms.END_DATE AS DATE) >= CAST(GETDATE() AS DATE)
            AND (ms.NUMB_OF_ATTN_MONT = 0 OR ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM)
            AND f.ACTV_TAG_DNRM >= '101'
       GROUP BY sx.DOMN_DESC, c.NAME_DNRM
       FOR XML PATH('')
      );
      
      SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      IF @Message IS NULL
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره موبایل و کد ملی اطلاعات خود را درون سیستم اتوماسیون ثبت کنید';
      END      
    END;
    -- لیست اعضا کلاس مربی
    ELSE IF @UssdCode = '*4*1*6#' AND @ChildUssdCode = '*4*1*6*1#'
    BEGIN
      SELECT @Message = (
         SELECT sx.DOMN_DESC + N' ' + c.NAME_DNRM + N' لیست هنرجویان شما به شرح زیر می باشد '  + CHAR(10) +
                (
                   SELECT CAST(ROW_NUMBER() OVER (ORDER BY ms.FIGH_FILE_NO) AS NVARCHAR(10)) + N' ) ' + 
                      CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'🙍‍♂️' ELSE N'🙎' END + f.NAME_DNRM + N' ، ' + m.MTOD_DESC + N' ، ' + 
                      CAST(cm.STRT_TIME AS NVARCHAR(5)) + N' * ' + CAST(cm.END_TIME AS NVARCHAR(5)) + N' ، ' +
                      d.DOMN_DESC + N' ' + 
                      CASE WHEN ms.NUMB_OF_ATTN_MONT > 0 THEN N' تعداد جلسات باقیمانده ' + CAST(ms.NUMB_OF_ATTN_MONT - ms.SUM_ATTN_MONT_DNRM AS NVARCHAR(10)) + N' می باشد ' 
                           ELSE N' '
                      END + N' ' + 
                      N' تاریخ پایان عضویت ' + iScsc.dbo.get_mtos_u(ms.End_Date) +                    
                      CHAR(10)
                 FROM iScsc.dbo.Member_Ship ms, 
                      iScsc.dbo.Fighter_Public fp, 
                      iScsc.dbo.Fighter f, 
                      iScsc.dbo.Method m, 
                      iScsc.dbo.Category_Belt cb, 
                      iScsc.dbo.Club_Method cm, 
                      iScsc.dbo.[D$DYTP] d
                WHERE ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
                  AND ms.FGPB_RWNO_DNRM = fp.RWNO
                  AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                  AND ms.FIGH_FILE_NO = f.FILE_NO
                  AND fp.MTOD_CODE = m.CODE
                  AND fp.CTGY_CODE = cb.CODE
                  AND fp.CBMT_CODE = cm.CODE
                  AND cm.DAY_TYPE = d.VALU
                  AND ms.RECT_CODE = '004'
                  AND ms.VALD_TYPE = '002'
                  AND CAST(ms.END_DATE AS DATE) >= CAST(GETDATE() AS DATE)
                  AND (ms.NUMB_OF_ATTN_MONT = 0 OR ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM)
                  AND fp.COCH_FILE_NO = c.FILE_NO
                  AND f.ACTV_TAG_DNRM >= '101'                  
                  FOR XML PATH('')
                ) + N'🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸' + CHAR(10)
           FROM iScsc.dbo.Fighter c, iScsc.dbo.[D$SXDC] sx
          WHERE c.ACTV_TAG_DNRM >= '101'
            AND c.FGPB_TYPE_DNRM = '003'
            AND sx.VALU = c.SEX_TYPE_DNRM            
            FOR XML PATH('')           
      );
      
      SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره موبایل و کد ملی اطلاعات خود را درون سیستم اتوماسیون ثبت کنید';
      END      
    END;
    -- آمار کلی نظرسنجی باشگاه
    ELSE IF @UssdCode = '*4*1*7*0*0#' AND @ChildUssdCode = '*4*1*7*0*0*0#'
    BEGIN
      L$CLUBVOTE:
      SELECT @Message = N'نظرسنجی باشگاه :' + CHAR(10) + (
         SELECT MESG_TEXT + N' تعداد ' + CAST(COUNT(DISTINCT MESG_ID) AS NVARCHAR(10)) + CHAR(10)
           FROM dbo.Service_Robot_Message
          WHERE SRBT_ROBO_RBID = @Rbid
            AND USSD_CODE = '*1*10*0#'
            AND (@MenuText IS NULL OR MESG_TEXT = @MenuText)
            AND (MESG_TEXT IN (N'❤️ عالی', N'💛 خوب', N'💜 متوسط', N'💔 ضعیف'))
            AND CAST(RECV_DATE AS DATE) BETWEEN ISNULL(@FromDate, CAST(RECV_DATE AS DATE)) AND ISNULL(@ToDate, CAST(RECV_DATE AS DATE))
       GROUP BY MESG_TEXT
        FOR XML PATH('')
      );
      
      SELECT @Message += CHAR(10) + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه نظرسنجی در این زمینه اتفاق نیوفتاده است، اگر میخواهید نظرسنجی در این زمینه صورت گیرد در قسمت ارسال پیام های مدیریتی  پیام نظرسنجی را فشار دهید تا برای اعضا و مشترکین ربات ارسال شود.';         
      END      
    END 
    -- خرید های فروشگاهی
    -- اضافه کردن به سبد خرید
    ELSE IF (
      (@UssdCode = '*5*0*5#' AND @ChildUssdCode = '*5*0*5*0#') OR
      (@UssdCode = '*5*0*10#' AND @ChildUssdCode = '*5*0*10*0#')
    )
    BEGIN
      -- اضافه کردن یک بسته کارت خام به سبد خرید مشتری
      SELECT @XTemp = (        
         SELECT TOP 1 
                '004' AS '@ordrtype',
                '001' AS '@typecode',
                'Add to Cart' AS '@typedesc',
                gi.CODE AS '@prodcode', 
                gi.PRIC AS '@pric', 
                gi.TAX_PRCT AS '@taxprct', 
                g.OFF_PRCT AS '@offprct',
                1 AS '@numb',
                @ChatID AS '@chatid',
                @Rbid AS '@rbid',
                m.MUID AS '@muid',
                @UssdCode AS '@ussdcode',
                @ChildUssdCode AS '@childussdcode'
           FROM dbo.Menu_Ussd m, dbo.Group_Menu_Ussd gm, dbo.[Group] g, dbo.Group_Header_Item gi
          WHERE m.ROBO_RBID = gm.MNUS_ROBO_RBID
            AND m.MUID = gm.MNUS_MUID
            AND gm.GROP_GPID = g.GPID
            AND gi.GRMU_GROP_GPID = gm.GROP_GPID
            AND gi.GRMU_MNUS_ROBO_RBID = gm.MNUS_ROBO_RBID
            AND gi.GRMU_MNUS_MUID = gm.MNUS_MUID
            AND m.USSD_CODE = @UssdCode
            AND m.ROBO_RBID = @Rbid
            AND gm.STAT = '002'
            AND g.STAT = '002'
            AND gi.STAT = '002'
       ORDER BY gi.PRIC DESC 
       FOR XML PATH('Action'), ROOT('Cart')
      );      
      
      EXEC dbo.SAVE_CART_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
      
      --SET @Message = N'محصول مورد نظر شما با موفقیت در سبد خرید قرار گرفت';
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
      
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ ' + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END      
    END     
    -- حذف کردن از سبد خرید    
    ELSE IF (
      (@UssdCode = '*5*0*5#' AND @ChildUssdCode = '*5*0*5*1#') OR
      (@UssdCode = '*5*0*10#' AND @ChildUssdCode = '*5*0*10*1#')
    )
    BEGIN
      -- حذف کردن یک بسته کارت خام به سبد خرید مشتری
      SELECT @XTemp = (        
         SELECT TOP 1 
                '004' AS '@ordrtype',
                '002' AS '@typecode',
                'Delete from Cart' AS '@typedesc',
                gi.CODE AS '@prodcode', 
                gi.PRIC AS '@pric', 
                gi.TAX_PRCT AS '@taxprct', 
                g.OFF_PRCT AS '@offprct',
                1 AS '@numb',
                @ChatID AS '@chatid',
                @Rbid AS '@rbid',
                m.MUID AS '@muid',
                @UssdCode AS '@ussdcode',
                @ChildUssdCode AS '@childussdcode'
           FROM dbo.Menu_Ussd m, dbo.Group_Menu_Ussd gm, dbo.[Group] g, dbo.Group_Header_Item gi
          WHERE m.ROBO_RBID = gm.MNUS_ROBO_RBID
            AND m.MUID = gm.MNUS_MUID
            AND gm.GROP_GPID = g.GPID
            AND gi.GRMU_GROP_GPID = gm.GROP_GPID
            AND gi.GRMU_MNUS_ROBO_RBID = gm.MNUS_ROBO_RBID
            AND gi.GRMU_MNUS_MUID = gm.MNUS_MUID
            AND m.USSD_CODE = @UssdCode
            AND m.ROBO_RBID = @Rbid
            AND gm.STAT = '002'
            AND g.STAT = '002'
            AND gi.STAT = '002'
       ORDER BY gi.PRIC DESC 
       FOR XML PATH('Action'), ROOT('Cart')
      );      
      
      EXEC dbo.SAVE_CART_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
      
      --SET @Message = N'محصول مورد نظر شما از سبد خرید حذف گردید';
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
      
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END      
    END
    -- مشخص کردن تعداد
    ELSE IF (
      @UssdCode IN ( '*5*0*5*3#', '*5*0*10*3#' )
    )
    BEGIN
      -- وارد کردن دستی کالا
      -- بدست آوردن کد مربوط به منوی کالا یا خدمات      
      SELECT @UssdCode =  REPLACE(@UssdCode, REVERSE(SUBSTRING(REVERSE(@UssdCode), 0, CHARINDEX('*', REVERSE(@UssdCode)) + 1)), '#');
      IF ISNUMERIC(@MenuText) = 1
      BEGIN
         SELECT @XTemp = (        
            SELECT TOP 1 
                   '004' AS '@ordrtype',
                   '003' AS '@typecode',
                   'Update Number from Cart' AS '@typedesc',
                   gi.CODE AS '@prodcode', 
                   gi.PRIC AS '@pric', 
                   gi.TAX_PRCT AS '@taxprct', 
                   g.OFF_PRCT AS '@offprct',
                   @MenuText AS '@numb',
                   @ChatID AS '@chatid',
                   @Rbid AS '@rbid',
                   m.MUID AS '@muid',
                   @UssdCode AS '@ussdcode',
                   @ChildUssdCode AS '@childussdcode'
              FROM dbo.Menu_Ussd m, dbo.Group_Menu_Ussd gm, dbo.[Group] g, dbo.Group_Header_Item gi
             WHERE m.ROBO_RBID = gm.MNUS_ROBO_RBID
               AND m.MUID = gm.MNUS_MUID
               AND gm.GROP_GPID = g.GPID
               AND gi.GRMU_GROP_GPID = gm.GROP_GPID
               AND gi.GRMU_MNUS_ROBO_RBID = gm.MNUS_ROBO_RBID
               AND gi.GRMU_MNUS_MUID = gm.MNUS_MUID
               AND m.USSD_CODE = @UssdCode
               AND m.ROBO_RBID = @Rbid
               AND gm.STAT = '002'
               AND g.STAT = '002'
               AND gi.STAT = '002'
          ORDER BY gi.PRIC DESC 
          FOR XML PATH('Action'), ROOT('Cart')
         );      
         
         EXEC dbo.SAVE_CART_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
         
         --SET @Message = N'محصول مورد نظر شما از سبد خرید حذف گردید';
         SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
      END
      ELSE
         SELECT @Message = N'لطفا جهت وارد کردن اطلاعات تعداد کالا یا خدمات دقت فرمایید';
         
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END      
    END
    -- نمایش سبد خرید
    ELSE IF (
      (@UssdCode = '*5*0*5#' AND @ChildUssdCode IN ( '*5*0*5*4#', '*5*0*5*2#' ))       
    )
    BEGIN
      -- وارد کردن دستی کالا
      -- بدست آوردن کد مربوط به منوی کالا یا خدمات      
      --SELECT @UssdCode =  REPLACE(@UssdCode, REVERSE(SUBSTRING(REVERSE(@UssdCode), 0, CHARINDEX('*', REVERSE(@UssdCode)) + 1)), '#');
      SELECT @XTemp = (        
         SELECT TOP 1 
                '004' AS '@ordrtype',
                '004' AS '@typecode',
                'Show Items in Cart' AS '@typedesc',
                gi.CODE AS '@prodcode', 
                gi.PRIC AS '@pric', 
                gi.TAX_PRCT AS '@taxprct', 
                g.OFF_PRCT AS '@offprct',
                0 AS '@numb',
                @ChatID AS '@chatid',
                @Rbid AS '@rbid',
                m.MUID AS '@muid',
                @UssdCode AS '@ussdcode',
                @ChildUssdCode AS '@childussdcode'
           FROM dbo.Menu_Ussd m, dbo.Group_Menu_Ussd gm, dbo.[Group] g, dbo.Group_Header_Item gi
          WHERE m.ROBO_RBID = gm.MNUS_ROBO_RBID
            AND m.MUID = gm.MNUS_MUID
            AND gm.GROP_GPID = g.GPID
            AND gi.GRMU_GROP_GPID = gm.GROP_GPID
            AND gi.GRMU_MNUS_ROBO_RBID = gm.MNUS_ROBO_RBID
            AND gi.GRMU_MNUS_MUID = gm.MNUS_MUID
            AND m.USSD_CODE = @UssdCode
            AND m.ROBO_RBID = @Rbid
            AND gm.STAT = '002'
            AND g.STAT = '002'
            AND gi.STAT = '002'
       ORDER BY gi.PRIC DESC 
       FOR XML PATH('Action'), ROOT('Cart')
      );      
      
      EXEC dbo.SAVE_CART_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
      
      --SET @Message = N'محصول مورد نظر شما از سبد خرید حذف گردید';
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END      
    END
    -- عملیات شارژ
    -- شارژ کارمزد پرداخت
    -- شارژ خدمات شبکه های اجتماعی
    -- نمایش موجودی
    ELSE IF (
      (@UssdCode = '*4*6*0#' AND @ChildUssdCode = '*4*6*0*0#') OR
      (@UssdCode = '*4*6*1#' AND @ChildUssdCode = '*4*6*1*0#')
    )
    BEGIN      
      --SET @XTemp = (
      --   SELECT @Rbid AS '@rbid'
      --         ,12 AS '@subsys'
      --         ,(
      --            SELECT CASE @UssdCode
      --                     WHEN '*4*6*0#' THEN '013'
      --                     when '*4*6*1#' THEN '014'
      --                   END AS '@type'
      --                  ,'001' AS '@mainactncode'
      --            FOR XML PATH('Credit'), TYPE
      --         )
      --  FOR XML PATH('Robot')
      --);
      
      --EXEC dbo.MNGR_CRDT_P @X = @XTemp, @xRet = @XTemp OUTPUT;
      
      --SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
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
              );
            --+
            --(
            --    SELECT /*CASE ISNULL(r.MIN_WITH_DRAW, 0) 
            --         WHEN 0 THEN /* فروشگاه مبلغ پرداخت نقدی ندارد ولی اعضا میتواند پول اعتبارات خود را باهم خرید و فروش کنند */ 
            --              /*N'🙂 مشتری عزیز 💎 _مبلغ اعتبار شما_ *قابلیت نقد شوندگی* برای 🏢 *فروشگاه ندارد* ، ولی شما می توانید 💎 *مبلغ اعتبار* خود را یا دیگر 👥 *اعضا* در میان بگذارید که اگر 🙋 *متقاضی* _خواهان اعتبار شما_ بود پول به صورت 💳 *کارت به کارت* پرداخت کرده و اعتبار خود را به دیگری واگذار کنید و شما به پول نقد دست یابید.'*/
            --              N'مبلغ کیف پول *اعتباری* تنها جهت 🛒 *خرید* از فروشگاه بوده و *قابل برداشت* به صورت *پول نقد* نمیباشد؛ در صورت تمایل میتوانید آن را در میان اعضای فروشگاه به فروش بگذارید.' + CHAR(10) +
            --              N'مبلغ کیف پول نقدینگی قابل برداشت میباشد که فرایند انتقال وجه حدود 48 ساعت به طول می انجامد؛ در صورت تمایل به برداشت وجه در زمان کمتر، میتوانید آن را در میان اعضای فروشگاه به فروش بگذارید.'                                
            --         ELSE /* فروشگاه قابلیت نقدشوندگی را دارد و همچنین می توانید اعتبار خود را به دیگر اعضا بفروشید، برای فروشگاه حداقل مبلغ برداشت اهمیت زیادی دارد */ 
            --              /*N'😊 مشتری عزیز برای 💰 *برداشت مبلغ* خود می توانید از طریق 🏢 *فروشگاه* یا 👥 *مشتریان فروشگاه* استفاده کنید، فقط برای _فروشگاه مبلغ حداقل برداشت_ *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, r.MIN_WITH_DRAW), 1), '.00', '') + N'* ' + @AmntTypeDesc + N' میباشد که ممکن است 💸 *درخواست انتقال 48 ساعت* طول بینجامد ولی، 💳 *پرداخت بین اعضا 👥 * درصورتی که 🙋🏻 متقاضی باشد که به 💎 *اعتبار کیف پول شما* نیاز داشته باشد به صورت *انی* به 💳 _حساب شما_ *واریز* میگردد.'*/
                          
            --    END*/
            --        N'💳 مبلغ کیف پول *اعتباری* تنها جهت 🛒 *خرید* از فروشگاه بوده و *قابل برداشت* به صورت *مستقیم نمیباشد* ؛ در صورت تمایل میتوانید آن را در میان اعضای فروشگاه به *فروش* بگذارید.'
            --        + CHAR(10) + CHAR(10)
            --        + N'💵 مبلغ کیف پول *نقدینگی قابل برداشت میباشد* که فرایند انتقال وجه حدود *48 ساعت* به طول می انجامد؛ در صورت تمایل به برداشت وجه در زمان کمتر، میتوانید آن را در میان اعضای فروشگاه به *فروش* بگذارید.'
            --        + CHAR(10) + N'⚠️ *حداقل* مبلغ قابل برداشت از فروشگاه *'
            --        + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, r.MIN_WITH_DRAW), 1), '.00', '') + N' '
            --        + @AmntTypeDesc + N'* میباشد'
            --    FROM dbo.Robot r
            --    WHERE r.RBID = @Rbid
            --    FOR XML PATH('')
            --) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' '
            --+ CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
              
      SELECT @Message += N'⏰ '+ iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END      
    END
    -- گزارش شارژ
    -- عملیات شارژ کارمزد پرداخت
    -- عملیات شارژ خدمات شبکه های اجتماعی
    ELSE IF (
      (@UssdCode = '*4*6*0*1#' AND @ChildUssdCode IN( '*4*6*0*1*0#' , '*4*6*0*1*1#', '*4*6*0*1*2#', '*4*6*0*1*3#')) OR
      (@UssdCode = '*4*6*1*1#' AND @ChildUssdCode IN( '*4*6*1*1*0#' , '*4*6*1*1*1#', '*4*6*1*1*2#', '*4*6*1*1*3#'))
    )
    BEGIN
      -- در این قسمت کارفرما بر اساس میزانی که خود انتخاب میکند میتواند مبلغ کارمزد خود را شارژ کند
      -- در این قسمت ما باید یک شماره درخواست ایجاد کنیم و شماره درخواست را برای کارفرما ارسال کنیم
      SELECT @XTemp = (        
         SELECT TOP 1 
                CASE @UssdCode
                  WHEN '*4*6*0*1#' THEN '013'
                  WHEN '*4*6*1*1#' THEN '014'
                END AS '@ordrtype',
                '001' AS '@typecode',
                'Insert Items in Cart' AS '@typedesc',
                gi.CODE AS '@prodcode', 
                gi.PRIC AS '@pric', 
                gi.TAX_PRCT AS '@taxprct', 
                g.OFF_PRCT AS '@offprct',
                1 AS '@numb',
                @ChatID AS '@chatid',
                @Rbid AS '@rbid',
                m.MUID AS '@muid',
                @UssdCode AS '@ussdcode',
                @ChildUssdCode AS '@childussdcode'
           FROM dbo.Menu_Ussd m, dbo.Group_Menu_Ussd gm, dbo.[Group] g, dbo.Group_Header_Item gi
          WHERE m.ROBO_RBID = gm.MNUS_ROBO_RBID
            AND m.MUID = gm.MNUS_MUID
            AND gm.GROP_GPID = g.GPID
            AND gi.GRMU_GROP_GPID = gm.GROP_GPID
            AND gi.GRMU_MNUS_ROBO_RBID = gm.MNUS_ROBO_RBID
            AND gi.GRMU_MNUS_MUID = gm.MNUS_MUID
            AND m.USSD_CODE = @childUssdCode
            AND m.ROBO_RBID = @Rbid
            AND gm.STAT = '002'
            AND g.STAT = '002'
            AND gi.STAT = '002'
       ORDER BY gi.PRIC DESC 
       FOR XML PATH('Action'), ROOT('Cart')
      );      
      
      EXEC dbo.SAVE_CART_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
      
      --SET @Message = N'محصول مورد نظر شما از سبد خرید حذف گردید';
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END 
    END  
    -- عملیات شارژ
    -- شارژ کارمزد پرداخت
    -- شارژ خدمات شبکه های اجتماعی
    -- حذف کلیه فاکتورها
    ELSE IF (
      (@UssdCode IN ('*4*6*0*1#') AND @ChildUssdCode IN ('*4*6*0*1*4#')) OR 
      (@UssdCode IN ('*4*6*1*1#') AND @ChildUssdCode IN ('*4*6*1*1*4#'))
    )
    BEGIN
      SELECT @XTemp = (        
         SELECT TOP 1 
                CASE @UssdCode
                  WHEN '*4*6*0*1#' THEN '013'
                  when '*4*6*1*1#' THEN '014'
                END AS '@ordrtype',
                '005' AS '@typecode',
                'Delete Current Cart' AS '@typedesc',                
                @ChatID AS '@chatid',
                @Rbid AS '@rbid'                
       FOR XML PATH('Action'), ROOT('Cart')
      );      
      
      EXEC dbo.SAVE_CART_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
      
      --SET @Message = N'محصول مورد نظر شما از سبد خرید حذف گردید';
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END 
    END 
    -- گزارش شارژ
    -- گزارش شارژ کارمزد پرداخت
    -- گزارش شارژ خدمات شبکه های اجتماعی
    -- گزارش افزایش اعتبار
    ELSE IF (
      (@UssdCode IN ( '*4*6*0*2*0#' ) AND 
       @ChildUssdCode IN ('*4*6*0*2*0*0#', '*4*6*0*2*0*1#', '*4*6*0*2*0*2#', '*4*6*0*2*0*3#')) OR
      (@UssdCode IN ( '*4*6*1*2*0#' ) AND 
       @ChildUssdCode IN ('*4*6*1*2*0*0#', '*4*6*1*2*0*1#', '*4*6*1*2*0*2#', '*4*6*1*2*0*3#'))
    )
    BEGIN
      L$CRDT013:
      L$CRDT014:
      SET @XTemp = (
         SELECT @Rbid AS '@rbid'
               ,12 AS '@subsys'
               ,(
                  SELECT CASE @UssdCode
                           WHEN '*4*6*0*2*0#' THEN '013'
                           WHEN '*4*6*0*2*0*4#' THEN '013'
                           WHEN '*4*6*1*2*0#' THEN '014'
                           WHEN '*4*6*1*2*0*4#' THEN '014'
                         END AS '@type'
                        ,'002' AS '@mainactncode'
                        ,'001' AS '@subactncode'
                        ,@FromDate AS '@fromdate'
                        ,@ToDate AS '@todate'
                  FOR XML PATH('Credit'), TYPE
               )
        FOR XML PATH('Robot')
      );
      
      EXEC dbo.MNGR_CRDT_P @X = @XTemp, @xRet = @XTemp OUTPUT;
      
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END 
    END 
    -- گزارش شارژ
    -- گزارش کارمزد پرداخت
    -- گزارش خدمات شبکه های اجتماعی
    -- گزارش کارمزد
    ELSE IF (
      (@UssdCode IN ( '*4*6*0*2*1#' ) AND 
       @ChildUssdCode IN ('*4*6*0*2*1*0#', '*4*6*0*2*1*1#', '*4*6*0*2*1*2#', '*4*6*0*2*1*3#')) OR
      (@UssdCode IN ( '*4*6*1*2*1#' ) AND 
       @ChildUssdCode IN ('*4*6*1*2*1*0#', '*4*6*1*2*1*1#', '*4*6*1*2*1*2#', '*4*6*1*2*1*3#'))       
    )
    BEGIN
      L$TXFE013:
      L$TXFE014:
      SET @XTemp = (
         SELECT @Rbid AS '@rbid'
               ,12 AS '@subsys'
               ,(
                  SELECT CASE @UssdCode
                           WHEN '*4*6*0*2*1#' THEN '013'
                           WHEN '*4*6*0*2*1*4#' THEN '013'
                           WHEN '*4*6*1*2*1#' THEN '014'
                           WHEN '*4*6*1*2*1*4#' THEN '014'
                         END AS '@type'
                        ,'002' AS '@mainactncode'
                        ,'002' AS '@subactncode'
                        ,@FromDate AS '@fromdate'
                        ,@ToDate AS '@todate'
                  FOR XML PATH('Credit'), TYPE
               )
        FOR XML PATH('Robot')
      );
      
      EXEC dbo.MNGR_CRDT_P @X = @XTemp, @xRet = @XTemp OUTPUT;
      
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END 
    END;
    -- ثبت دوره جدید برای مشتری 
    ELSE IF @UssdCode IN ( '*1*11*0*2#', '*7*0*5*0*2#', '*7*1*5*0*2#', '*0*7*1*2#' )
    BEGIN
      -- مرحله اول باید متوجه شویم که ایا این کد درون سیستم ثبت شده یا خیر      
      IF @UssdCode != '*0*7*1*2#' 
      BEGIN         
         IF NOT EXISTS(
            SELECT f.FILE_NO
              FROM iScsc.dbo.Fighter f
             WHERE @ChatID = (
                     CASE @UssdCode 
                        WHEN '*1*11*0*2#' THEN f.CHAT_ID_DNRM
                        WHEN '*7*0*5*0*2#' THEN f.DAD_CHAT_ID_DNRM
                        WHEN '*7*1*5*0*2#' THEN f.MOM_CHAT_ID_DNRM                  
                     END 
                   )
         )
         BEGIN
            SET @ChatID = NULL;            
         END

         SELECT @ChatID = f.CHAT_ID_DNRM
           FROM iScsc.dbo.Fighter f
          WHERE @ChatID = (
                  CASE @UssdCode 
                     WHEN '*1*11*0*2#' THEN f.CHAT_ID_DNRM
                     WHEN '*7*0*5*0*2#' THEN f.DAD_CHAT_ID_DNRM
                     WHEN '*7*1*5*0*2#' THEN f.MOM_CHAT_ID_DNRM                  
                  END 
                );
         
         IF @ChatID IS NULL
         BEGIN
            SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره موبایل و کد ملی اطلاعات خود را درون سیستم اتوماسیون ثبت کنید';
            GOTO L$EndSP;
         END
      END
      -- در این قسمت کارفرما بر اساس میزانی که خود انتخاب میکند میتواند مبلغ کارمزد خود را شارژ کند
      -- در این قسمت ما باید یک شماره درخواست ایجاد کنیم و شماره درخواست را برای کارفرما ارسال کنیم
      SELECT @XTemp = (        
         SELECT 5 AS '@subsys',
                '004' AS '@ordrtype',
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
      SELECT @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT');
      
      --SET @Message = N'محصول مورد نظر شما از سبد خرید حذف گردید';
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
            
      -- 1399/12/07 * اضافه کردن منوی مربوط به فاکتور فروش
      -- اضافه کردن منوهای اولیه مربوط به فاکتور فروش مشتری         
      SET @XTemp =
      (
          SELECT @Rbid AS '@rbid',
                 @ChatID AS '@chatid',
                 @UssdCode AS '@ussdcode',
                 'lesspaycart' AS '@cmndtext',
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
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END 
    END 
    --  نمایش سبد خرید دوره های انتخابی مشتری
    ELSE IF (
      (@UssdCode IN ( '*1*11*0#' ) AND @ChildUssdCode IN ( '*1*11*0*3#', '*1*11*0*4#' )) OR 
      (@UssdCode IN ( '*7*0*5*0#' ) AND @ChildUssdCode IN ( '*7*0*5*0*3#', '*7*0*5*0*4#' )) OR 
      (@UssdCode IN ( '*7*1*5*0#' ) AND @ChildUssdCode IN ( '*7*1*5*0*3#', '*7*1*5*0*4#' )) OR
      (@UssdCode IN ( '*0*7*1#' ) AND @ChildUssdCode IN ( '*0*7*1*3#', '*0*7*1*4#' )) 
    )
    BEGIN
      -- مرحله اول باید متوجه شویم که ایا این کد درون سیستم ثبت شده یا خیر
      IF @UssdCode != '*0*7*1#'
      BEGIN
         IF NOT EXISTS(
            SELECT f.FILE_NO
              FROM iScsc.dbo.Fighter f
             WHERE @ChatID = (
                     CASE @UssdCode 
                        WHEN '*1*11*0#' THEN f.CHAT_ID_DNRM
                        WHEN '*7*0*5*0#' THEN f.DAD_CHAT_ID_DNRM
                        WHEN '*7*1*5*0#' THEN f.MOM_CHAT_ID_DNRM
                     END 
                   )
         )
         BEGIN
            SET @ChatID = NULL;
         END
         
         SELECT @ChatID = f.CHAT_ID_DNRM
           FROM iScsc.dbo.Fighter f
          WHERE @ChatID = (
                  CASE @UssdCode 
                     WHEN '*1*11*0#' THEN f.CHAT_ID_DNRM
                     WHEN '*7*0*5*0#' THEN f.DAD_CHAT_ID_DNRM
                     WHEN '*7*1*5*0#' THEN f.MOM_CHAT_ID_DNRM
                  END 
                );
         
         IF @ChatID IS NULL
         BEGIN
            SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره موبایل و کد ملی اطلاعات خود را درون سیستم اتوماسیون ثبت کنید';
            GOTO L$EndSP;
         END
      END
      
      -- در این قسمت کارفرما بر اساس میزانی که خود انتخاب میکند میتواند مبلغ کارمزد خود را شارژ کند
      -- در این قسمت ما باید یک شماره درخواست ایجاد کنیم و شماره درخواست را برای کارفرما ارسال کنیم
      SELECT @XTemp = (        
         SELECT 5 AS '@subsys',
                '004' AS '@ordrtype',
                '000' AS '@typecode',                
                @ChatID AS '@chatid',
                @Rbid AS '@rbid',                
                @UssdCode AS '@ussdcode',
                'show' AS '@input',
                0 AS '@ordrcode'
          -- FROM iScsc.dbo.Fighter f
          --WHERE @ChatId = (
          --      CASE @UssdCode
          --        WHEN '*1*11*0#' THEN f.CHAT_ID_DNRM
          --        WHEN '*7*0*5*0#' THEN f.DAD_CHAT_ID_DNRM
          --        WHEN '*7*1*5*0#' THEN f.MOM_CHAT_ID_DNRM
          --      END 
          --)
       FOR XML PATH('Action'), ROOT('Cart')
      );      
      
      EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
      
            -- بدست آوردن اینکه آیا عملیات به درستی انجام شده یا خیر
      SELECT @OrdrCode = @XTemp.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT');
      
      --SET @Message = N'محصول مورد نظر شما از سبد خرید حذف گردید';
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
            
      -- 1399/12/07 * اضافه کردن منوی مربوط به فاکتور فروش
      -- اضافه کردن منوهای اولیه مربوط به فاکتور فروش مشتری         
      SET @XTemp =
      (
          SELECT @Rbid AS '@rbid',
                 @ChatID AS '@chatid',
                 @UssdCode AS '@ussdcode',
                 'lesspaycart' AS '@cmndtext',
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
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END 
    END
    -- ثبت بیمه ورزشی
    ELSE IF (
      (@UssdCode = '*1*11#' AND @ChildUssdCode = '*1*11*2#') OR
      (@UssdCode = '*7*0*5#' AND @ChildUssdCode = '*7*0*5*2#') OR
      (@UssdCode = '*7*1*5#' AND @ChildUssdCode = '*7*1*5*2#')
      
    )
    BEGIN
      -- مرحله اول باید متوجه شویم که ایا این کد درون سیستم ثبت شده یا خیر
      SELECT @ChatID = f.CHAT_ID_DNRM
        FROM iScsc.dbo.Fighter f
       WHERE @ChatID = (
               CASE @UssdCode 
                  WHEN '*1*11#' THEN f.CHAT_ID_DNRM
                  WHEN '*7*0*5#' THEN f.DAD_CHAT_ID_DNRM
                  WHEN '*7*1*5#' THEN f.MOM_CHAT_ID_DNRM
               END 
             );
      
      IF @ChatID IS NULL
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره موبایل و کد ملی اطلاعات خود را درون سیستم اتوماسیون ثبت کنید';
         GOTO L$EndSP;
      END
      
      -- اضافه کردن یک بسته کارت خام به سبد خرید مشتری
      SELECT @XTemp = (        
         SELECT TOP 1 
                '004' AS '@ordrtype',
                '006' AS '@typecode',
                'Create One Invoice' AS '@typedesc',
                gi.CODE AS '@prodcode', 
                gi.PRIC AS '@pric', 
                gi.TAX_PRCT AS '@taxprct', 
                g.OFF_PRCT AS '@offprct',
                1 AS '@numb',
                @ChatID AS '@chatid',
                @Rbid AS '@rbid',
                m.MUID AS '@muid',
                @UssdCode AS '@ussdcode',
                @ChildUssdCode AS '@childussdcode',
                5 AS '@subsys',
                '012' AS '@tarfcode',
                GETDATE() AS '@tarfdate',
                '012' AS '@rqtpcode'
           FROM dbo.Menu_Ussd m, dbo.Group_Menu_Ussd gm, dbo.[Group] g, dbo.Group_Header_Item gi
          WHERE m.ROBO_RBID = gm.MNUS_ROBO_RBID
            AND m.MUID = gm.MNUS_MUID
            AND gm.GROP_GPID = g.GPID
            AND gi.GRMU_GROP_GPID = gm.GROP_GPID
            AND gi.GRMU_MNUS_ROBO_RBID = gm.MNUS_ROBO_RBID
            AND gi.GRMU_MNUS_MUID = gm.MNUS_MUID
            AND m.USSD_CODE = @ChildUssdCode
            AND m.ROBO_RBID = @Rbid
            AND gm.STAT = '002'
            AND g.STAT = '002'
            AND gi.STAT = '002'
       ORDER BY gi.PRIC DESC 
       FOR XML PATH('Action'), ROOT('Cart')
      );      
      
      EXEC dbo.SAVE_CART_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
      
      --SET @Message = N'محصول مورد نظر شما با موفقیت در سبد خرید قرار گرفت';
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)');
      
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ ' + iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END      
    END    
    -- عملیات شارژ افزایش اعتبار    
    ELSE IF (
      (@UssdCode = '*1*11*3#' AND @ChildUssdCode IN( '*1*11*3*0#' , '*1*11*3*1#', '*1*11*3*2#')) OR
      (@UssdCode = '*7*0*5*3#' AND @ChildUssdCode IN( '*7*0*5*3*0#' , '*7*0*5*3*1#', '*7*0*5*3*2#')) OR
      (@UssdCode = '*7*1*5*3#' AND @ChildUssdCode IN( '*7*1*5*3*0#' , '*7*1*5*3*1#', '*7*1*5*3*2#')) 
    )
    BEGIN
      -- مرحله اول باید متوجه شویم که ایا این کد درون سیستم ثبت شده یا خیر
      SELECT @ChatID = f.CHAT_ID_DNRM
        FROM iScsc.dbo.Fighter f
       WHERE @ChatID = (
               CASE @UssdCode 
                  WHEN '*1*11*3#' THEN f.CHAT_ID_DNRM
                  WHEN '*7*0*5*3#' THEN f.DAD_CHAT_ID_DNRM
                  WHEN '*7*1*5*3#' THEN f.MOM_CHAT_ID_DNRM
               END 
             );
      
      IF @ChatID IS NULL
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره موبایل و کد ملی اطلاعات خود را درون سیستم اتوماسیون ثبت کنید';
         GOTO L$EndSP;
      END
      -- در این قسمت کارفرما بر اساس میزانی که خود انتخاب میکند میتواند مبلغ کارمزد خود را شارژ کند
      -- در این قسمت ما باید یک شماره درخواست ایجاد کنیم و شماره درخواست را برای کارفرما ارسال کنیم
      SELECT @XTemp = (        
         SELECT TOP 1 
                '004' AS '@ordrtype',
                '001' AS '@typecode',
                'Insert Items in Cart' AS '@typedesc',
                gi.CODE AS '@prodcode', 
                gi.PRIC AS '@pric', 
                gi.TAX_PRCT AS '@taxprct', 
                g.OFF_PRCT AS '@offprct',
                1 AS '@numb',
                @ChatID AS '@chatid',
                @Rbid AS '@rbid',
                m.MUID AS '@muid',
                @UssdCode AS '@ussdcode',
                @ChildUssdCode AS '@childussdcode',
                5 AS '@subsys',
                '020' AS '@tarfcode',
                GETDATE() AS '@tarfdate',
                '020' AS '@rqtpcode'
           FROM dbo.Menu_Ussd m, dbo.Group_Menu_Ussd gm, dbo.[Group] g, dbo.Group_Header_Item gi
          WHERE m.ROBO_RBID = gm.MNUS_ROBO_RBID
            AND m.MUID = gm.MNUS_MUID
            AND gm.GROP_GPID = g.GPID
            AND gi.GRMU_GROP_GPID = gm.GROP_GPID
            AND gi.GRMU_MNUS_ROBO_RBID = gm.MNUS_ROBO_RBID
            AND gi.GRMU_MNUS_MUID = gm.MNUS_MUID
            AND m.USSD_CODE = @childUssdCode
            AND m.ROBO_RBID = @Rbid
            AND gm.STAT = '002'
            AND g.STAT = '002'
            AND gi.STAT = '002'
       ORDER BY gi.PRIC DESC 
       FOR XML PATH('Action'), ROOT('Cart')
      );      
      
      EXEC dbo.SAVE_CART_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
      
      --SET @Message = N'محصول مورد نظر شما از سبد خرید حذف گردید';
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END 
    END            
    -- حذف کلیه فاکتورها
    ELSE IF (
      (@UssdCode IN ('*1*11*3#') AND @ChildUssdCode IN ('*1*11*3*3#')) OR
      (@UssdCode IN ('*7*0*5*3#') AND @ChildUssdCode IN ('*7*0*5*3*3#')) OR
      (@UssdCode IN ('*7*1*5*3#') AND @ChildUssdCode IN ('*7*1*5*3*3#')) 
    )
    BEGIN
      -- مرحله اول باید متوجه شویم که ایا این کد درون سیستم ثبت شده یا خیر
      SELECT @ChatID = f.CHAT_ID_DNRM
        FROM iScsc.dbo.Fighter f
       WHERE @ChatID = (
               CASE @UssdCode 
                  WHEN '*1*11*3#' THEN f.CHAT_ID_DNRM
                  WHEN '*7*0*5*3#' THEN f.DAD_CHAT_ID_DNRM
                  WHEN '*7*1*5*3#' THEN f.MOM_CHAT_ID_DNRM
               END 
             );
      
      IF @ChatID IS NULL
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره موبایل و کد ملی اطلاعات خود را درون سیستم اتوماسیون ثبت کنید';
         GOTO L$EndSP;
      END
      
      SELECT @XTemp = (        
         SELECT TOP 1 
                '004' AS '@ordrtype',
                '005' AS '@typecode',
                'Delete Current Cart' AS '@typedesc',                
                @ChatID AS '@chatid',
                @Rbid AS '@rbid'
          -- FROM iScsc.dbo.Fighter f
          --WHERE @ChatID = (
          --        CASE @UssdCode
          --           WHEN '*1*11*3#' THEN f.CHAT_ID_DNRM
          --           WHEN '*7*0*5*3#' THEN f.DAD_CHAT_ID_DNRM
          --           WHEN '*7*1*5*3#' THEN f.MOM_CHAT_ID_DNRM
          --        END 
          --      )
       FOR XML PATH('Action'), ROOT('Cart')
      );      
      
      EXEC dbo.SAVE_CART_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
      
      --SET @Message = N'محصول مورد نظر شما از سبد خرید حذف گردید';
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iScsc.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END 
    END
    -- نمایش کل آیتم های درآمد متفرقه
    ELSE IF (
      (@UssdCode = '*1*11*1#' AND  @ChildUssdCode = '*1*11*1*0#') OR
      (@UssdCode = '*7*0*5*1#' AND  @ChildUssdCode = '*7*0*5*1*0#') OR 
      (@UssdCode = '*7*1*5*1#' AND  @ChildUssdCode = '*7*1*5*1*0#')
    )
    BEGIN
      SELECT @Message = (         
       SELECT  N'📔  *' + e.EXPN_DESC + N'* ' + CHAR(10) + N'👈 [ کد ] *' + ISNULL(CAST(e.ORDR_ITEM AS NVARCHAR(100)), ' --- ') + N'* [ مبلغ ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, e.PRIC + ISNULL(e.EXTR_PRCT, 0)), 1), '.00', '') + N'* [ ' + @AmntTypeDesc + N' ] ' + CHAR(10) + CHAR(10)
         FROM iScsc.dbo.Expense e, iScsc.dbo.Expense_Type et, iScsc.dbo.Request_Requester rr
        WHERE e.EXTP_CODE = et.CODE
          AND et.RQRQ_CODE = rr.CODE
          AND rr.RQTP_CODE = '016'
          AND rr.RQTT_CODE = '001' 
          AND e.EXPN_STAT = '002'         
     ORDER BY e.ORDR_ITEM
          FOR XML PATH('')
      ) + CHAR(10) + N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)) ;
    END 
    -- جستجوی کالا
    ELSE IF @UssdCode IN ( '*1*11*1*1#', '*7*0*5*1*1#', '*7*1*5*1*1#' ) 
    BEGIN
      SELECT @Message = (         
       SELECT  N'📔  *' + e.EXPN_DESC + N'* ' + CHAR(10) + N'👈 [ کد ] *' + ISNULL(CAST(e.ORDR_ITEM AS NVARCHAR(100)), ' --- ') + N'* [ مبلغ ] *' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, e.PRIC + ISNULL(e.EXTR_PRCT, 0)), 1), '.00', '') + N'* [ ' + @AmntTypeDesc + N' ] ' + CHAR(10) + CHAR(10)
         FROM iScsc.dbo.Expense e, iScsc.dbo.Expense_Type et, iScsc.dbo.Request_Requester rr
        WHERE e.EXTP_CODE = et.CODE
          AND et.RQRQ_CODE = rr.CODE
          AND rr.RQTP_CODE = '016'
          AND rr.RQTT_CODE = '001' 
          AND e.EXPN_STAT = '002'
          AND (
              e.EXPN_DESC LIKE REPLACE(N'%{0}%', '{0}', @MenuText) OR 
              CAST(e.ORDR_ITEM AS NVARCHAR(MAX)) = @MenuText
          )
     ORDER BY e.ORDR_ITEM
          FOR XML PATH('')
      ) + CHAR(10) + N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)) ;
    END
    -- ثبت کالا جدید برای مشتری 
    ELSE IF @UssdCode IN ( '*1*11*1*2#', '*7*0*5*1*2#', '*7*1*5*1*2#' )
    BEGIN
      -- مرحله اول باید متوجه شویم که ایا این کد درون سیستم ثبت شده یا خیر
      SELECT @ChatID = f.CHAT_ID_DNRM
        FROM iScsc.dbo.Fighter f
       WHERE @ChatID = (
               CASE @UssdCode 
                  WHEN '*1*11*1*2#' THEN f.CHAT_ID_DNRM
                  WHEN '*7*0*5*1*2#' THEN f.DAD_CHAT_ID_DNRM
                  WHEN '*7*1*5*1*2#' THEN f.MOM_CHAT_ID_DNRM
               END 
             );
      
      IF @ChatID IS NULL
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره موبایل و کد ملی اطلاعات خود را درون سیستم اتوماسیون ثبت کنید';
         GOTO L$EndSP;
      END
      
      -- در این قسمت کارفرما بر اساس میزانی که خود انتخاب میکند میتواند مبلغ کارمزد خود را شارژ کند
      -- در این قسمت ما باید یک شماره درخواست ایجاد کنیم و شماره درخواست را برای کارفرما ارسال کنیم
      SELECT @XTemp = (        
         SELECT 5 AS '@subsys',
                '004' AS '@ordrtype',
                '000' AS '@typecode',                
                @ChatID AS '@chatid',
                @Rbid AS '@rbid',                
                @UssdCode AS '@ussdcode',
                @MenuText AS '@input',
                0 AS '@ordrcode'
          -- FROM iScsc.dbo.Fighter f
          --WHERE @ChatID = (
          --        CASE @UssdCode
          --           WHEN '*1*11*1*2#' THEN f.CHAT_ID_DNRM
          --           WHEN '*7*0*5*1*2#' THEN f.DAD_CHAT_ID_DNRM
          --           WHEN '*7*1*5*1*2#' THEN f.MOM_CHAT_ID_DNRM
          --        END             
          --      )
       FOR XML PATH('Action'), ROOT('Cart')
      );      
      
      EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
      
      --SET @Message = N'محصول مورد نظر شما از سبد خرید حذف گردید';
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END 
    END 
    --  نمایش سبد خرید کالا های انتخابی مشتری
    ELSE IF (
      (@UssdCode IN ( '*1*11*1#' ) AND @ChildUssdCode IN ( '*1*11*1*3#', '*1*11*1*4#' )) OR
      (@UssdCode IN ( '*7*0*5*1#' ) AND @ChildUssdCode IN ( '*7*0*5*1*3#', '*7*0*5*1*4#' )) OR
      (@UssdCode IN ( '*7*1*5*1#' ) AND @ChildUssdCode IN ( '*7*1*5*1*3#', '*7*1*5*1*4#' )) 
    )
    BEGIN
      -- مرحله اول باید متوجه شویم که ایا این کد درون سیستم ثبت شده یا خیر
      SELECT @ChatID = f.CHAT_ID_DNRM
        FROM iScsc.dbo.Fighter f
       WHERE @ChatID = (
               CASE @UssdCode 
                  WHEN '*1*11*1#' THEN f.CHAT_ID_DNRM
                  WHEN '*7*0*5*1#' THEN f.DAD_CHAT_ID_DNRM
                  WHEN '*7*1*5*1#' THEN f.MOM_CHAT_ID_DNRM
               END 
             );
      
      IF @ChatID IS NULL
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره موبایل و کد ملی اطلاعات خود را درون سیستم اتوماسیون ثبت کنید';
         GOTO L$EndSP;
      END
      
      -- در این قسمت کارفرما بر اساس میزانی که خود انتخاب میکند میتواند مبلغ کارمزد خود را شارژ کند
      -- در این قسمت ما باید یک شماره درخواست ایجاد کنیم و شماره درخواست را برای کارفرما ارسال کنیم
      SELECT @XTemp = (        
         SELECT 5 AS '@subsys',
                '004' AS '@ordrtype',
                '000' AS '@typecode',                
                @ChatID AS '@chatid',
                @Rbid AS '@rbid',                
                @UssdCode AS '@ussdcode',
                'show' AS '@input',
                0 AS '@ordrcode'
          -- FROM iScsc.dbo.Fighter f
          --WHERE @ChatID = (
          --        CASE @UssdCode
          --           WHEN '*1*11*1#' THEN f.CHAT_ID_DNRM
          --           WHEN '*7*0*5*1#' THEN f.DAD_CHAT_ID_DNRM
          --           WHEN '*7*1*5*1#' then f.MOM_CHAT_ID_DNRM
          --        END 
          --      )
       FOR XML PATH('Action'), ROOT('Cart')
      );      
      
      EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
      
      --SET @Message = N'محصول مورد نظر شما از سبد خرید حذف گردید';
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END 
    END
    ELSE IF (
      @UssdCode IN ('*1*12*0#', '*7*0*6*0#', '*7*1*6*0#')
    )
    BEGIN
      SELECT @FromDate = NULL
            ,@ToDate = NULL;
            
      L$ServAttn:
      -- مرحله اول باید متوجه شویم که ایا این کد درون سیستم ثبت شده یا خیر
      IF NOT EXISTS(
         SELECT *
           FROM iScsc.dbo.Fighter f
          WHERE @ChatID = (
                  CASE  
                     WHEN @UssdCode IN ('*1*12#', '*1*12*0#',  '*1*12*5#') THEN f.CHAT_ID_DNRM
                     WHEN @UssdCode IN ('*7*0*6#', '*7*0*6*0#', '*7*0*6*5#') THEN f.DAD_CHAT_ID_DNRM
                     WHEN @UssdCode IN ('*7*1*6#', '*7*1*6*0#', '*7*1*6*5#') THEN f.MOM_CHAT_ID_DNRM
                  END 
                )
      )
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره موبایل و کد ملی اطلاعات خود را درون سیستم اتوماسیون ثبت کنید';
         GOTO L$EndSP;
      END
      
      SELECT @ChatID = f.CHAT_ID_DNRM
        FROM iScsc.dbo.Fighter f
       WHERE @ChatID = (
               CASE  
                  WHEN @UssdCode IN ('*1*12#', '*1*12*0#',  '*1*12*5#') THEN f.CHAT_ID_DNRM
                  WHEN @UssdCode IN ('*7*0*6#', '*7*0*6*0#', '*7*0*6*5#') THEN f.DAD_CHAT_ID_DNRM
                  WHEN @UssdCode IN ('*7*1*6#', '*7*1*6*0#', '*7*1*6*5#') THEN f.MOM_CHAT_ID_DNRM
               END 
             );
      
      SELECT @Message = (
         SELECT N'👈 *' + dbo.GET_MTOS_U(a.ATTN_DATE) + N'* 📔 *' + m.MTOD_DESC + N'* ' + CHAR(10) + 
                N'👣 *' + CAST(a.ENTR_TIME AS VARCHAR(5)) + N' ' + CASE WHEN a.EXIT_TIME IS NULL THEN N' ' ELSE CAST(a.EXIT_TIME AS VARCHAR(5)) END  + 
                N'* مدت زمان حضور [ *' + CASE WHEN DATEDIFF(MINUTE, a.ENTR_TIME, ISNULL(a.EXIT_TIME, GETDATE())) > 60 THEN 
                                                   CAST(DATEDIFF(MINUTE, a.ENTR_TIME, ISNULL(a.EXIT_TIME, GETDATE())) / 60 AS NVARCHAR(10)) + N' ساعت : ' + CAST(DATEDIFF(MINUTE, a.ENTR_TIME, ISNULL(a.EXIT_TIME, GETDATE())) % 60 AS NVARCHAR(10)) 
                                              ELSE 
                                                   CAST(DATEDIFF(MINUTE, a.ENTR_TIME, ISNULL(a.EXIT_TIME, GETDATE())) AS NVARCHAR(10)) 
                                         END + 
                N' دقیقه * ]' + CHAR(10) + CHAR(10)
           FROM iScsc.dbo.Attendance a, iScsc.dbo.Fighter f, iScsc.dbo.Method m, iScsc.dbo.[D$ATTP] da
          WHERE f.FILE_NO = a.FIGH_FILE_NO
            AND a.MTOD_CODE_DNRM = m.CODE
            AND a.ATTN_TYPE = da.VALU
            AND a.ATTN_STAT = '002'
            AND f.CHAT_ID_DNRM = @ChatID
            AND a.MBSP_RWNO_DNRM = CONVERT(SMALLINT, ISNULL(@MenuText, a.MBSP_RWNO_DNRM))
            AND a.ATTN_DATE BETWEEN ISNULL(@FromDate, a.ATTN_DATE) AND ISNULL(@ToDate, a.ATTN_DATE)
          ORDER BY a.ATTN_DATE DESC 
            FOR XML PATH('')
      );
      
      IF @Message IS NOT NULL
      BEGIN
         SELECT @Message = (
            SELECT CASE 
                     WHEN @UssdCode IN ('*1*12#', '*1*12*0#',  '*1*12*5#') THEN N'*مشترک* گرامی ' + CASE f.SEX_TYPE_DNRM WHEN '001' THEN N'جناب آقای' ELSE N'سرکار خانم' END + N' *' + f.FRST_NAME_DNRM + N'* *' + f.LAST_NAME_DNRM + N'* '
                     WHEN @UssdCode IN ('*7*0*6#', '*7*0*6*0#', '*7*0*6*5#') THEN N'*پدر* گرامی ' + CASE f.SEX_TYPE_DNRM WHEN '002' THEN N'*' + f.FRST_NAME_DNRM + N'* خانم' WHEN '001' THEN N'آقا *' + f.FRST_NAME_DNRM + N'* ' END 
                     WHEN @UssdCode IN ('*7*1*6#', '*7*1*6*0#', '*7*1*6*5#') THEN N'*مادر* گرامی ' + CASE f.SEX_TYPE_DNRM WHEN '002' THEN N'*' + f.FRST_NAME_DNRM + N'* خانم' WHEN '001' THEN N'آقا *' + f.FRST_NAME_DNRM + N'* ' END 
                   END + N' دفتر *حضور و غیاب* شما به شرح زیر می باشد'+ CHAR(10) 
             FROM iScsc.dbo.Fighter f
            WHERE f.CHAT_ID_DNRM = @ChatID
         ) + CHAR(10) + @Message;
      END
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'هیچ حضور و غیابی ثبت نشده است';
      END 
      
      SELECT @Message += N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END
    -- درخواست عضویت جدید
    -- ورود اطلاعات مشتری
    ELSE IF @UssdCode = '*0*7*0#'
    BEGIN
      DECLARE @FrstName NVARCHAR(250),
              @LastNamr NVARCHAR(250);
              
      DECLARE C$Items CURSOR FOR
         SELECT Item FROM dbo.SplitString(@MenuText, '#');
      SET @Index = 0;
      OPEN [C$Items];
      L$FetchC$Item1:
      FETCH NEXT FROM [C$Items] INTO @Item;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndC$Item1;
      
      IF @Index = 0
         SET @FrstName = @Item;
      ELSE IF @Index = 1
         SET @LastNamr = @Item;
      ELSE IF @Index = 2
         SET @CellPhon = @Item
      ELSE IF @Index = 3
         SET @NatlCode = @Item
      
      SET @Index += 1;
      GOTO L$FetchC$Item1;
      L$EndC$Item1:
      CLOSE [C$Items];
      DEALLOCATE [C$Items];
      
      SET @XTemp = (
         SELECT @FrstName AS '@frstname',
                @LastNamr AS '@lastname',
                @CellPhon AS '@cellphon',
                @NatlCode AS '@natlcode',
                '05' AS '@subsys',
                @ChatID AS '@chatid',
                @Rbid AS '@rbid',
                '001' AS '@actntype',
                'Save data' AS '@actndesc'
            FOR XML PATH('Service')
      );
      
      EXEC dbo.SAVE_SRBT_P @X = @XTemp, -- xml
          @XRet = @XTemp output -- xml
      
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
      
      IF @Message IS NULL
      BEGIN
         SET @Message = N'متاسفانه در این قسمت مشکلی بوجود آمده، لطفا با مدیریت یا پشتیبانی تماس بگیرید 09033927103';
      END 
    END
    ELSE IF @UssdCode = '*0*7#' AND @ChildUssdCode = '*0*7*3#'
    BEGIN
      SET @XTemp = (
         SELECT '05' AS '@subsys',
                @ChatID AS '@chatid',
                @Rbid AS '@rbid',
                '005' AS '@actntype',
                'Show data' AS '@actndesc'
            FOR XML PATH('Service')
      );
      
      EXEC dbo.SAVE_SRBT_P @X = @XTemp, -- xml
          @XRet = @XTemp output -- xml
      
      SELECT @Message = @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
      
      
      -- بررسی اینکه آیا درخواست هزینه ای پرداخت شده برای ثبت نام خود دارد یا خیر
      SELECT @OrdrCode = o.CODE
        FROM dbo.[Order] o
            ,dbo.Order_Detail od
            ,dbo.Order_State os
       WHERE o.CODE = od.ORDR_CODE
         AND o.CODE = os.ORDR_CODE
         AND o.SRBT_ROBO_RBID = @Rbid
         AND o.CHAT_ID = @ChatID
         AND o.ORDR_TYPE = '004' -- سفارشات
         AND od.RQTP_CODE_DNRM = '001' -- درخواست ثبت نام
         AND os.AMNT_TYPE = '001'; -- پرداخت هزینه
      
      -- اگر درخواست پرداختی داشته باشیم
      IF @OrdrCode IS NOT NULL
      BEGIN
         -- نمایش اطلاعات فاکتور همراه با ردیف هزینه پرداخت شده
         SELECT @XTemp = (        
            SELECT 5 AS '@subsys',
                   '004' AS '@ordrtype',
                   '006' AS '@typecode',                
                   @ChatID AS '@chatid',
                   @Rbid AS '@rbid',                
                   @UssdCode AS '@ussdcode',
                   'show_invoice_payment' AS '@input',
                   @OrdrCode AS '@ordrcode'
          FOR XML PATH('Action'), ROOT('Cart')
         );
      END    
      ELSE 
      BEGIN      
         SELECT @XTemp = (        
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
      END 
      
      EXEC dbo.SAVE_EXTO_P @X = @XTemp, @xRet = @XTemp OUTPUT; -- xml
      
      SELECT @Message += CHAR(10) + CHAR(10) + @XTemp.query('//Message').value('.', 'NVARCHAR(MAX)'); 
              
      SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ '+ iRoboTech.dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    END 
    ELSE IF @UssdCode = '*1#' AND @ChildUssdCode = '*1*13#'
    BEGIN
      -- مرحله اول باید متوجه شویم که ایا این کد درون سیستم ثبت شده یا خیر
      IF NOT EXISTS(
         SELECT *
           FROM iScsc.dbo.Fighter f
          WHERE @ChatID = (
                  CASE  
                     WHEN @UssdCode IN ('*1#') THEN f.CHAT_ID_DNRM
                     WHEN @UssdCode IN ('') THEN f.DAD_CHAT_ID_DNRM
                     WHEN @UssdCode IN ('') THEN f.MOM_CHAT_ID_DNRM
                  END 
                )
      )
      BEGIN
         SET @Message = N'مشترک گرامی اطلاعات شما قابل دسترس نیست. لطفا از گزینه ارسال شماره موبایل و کد ملی اطلاعات خود را درون سیستم اتوماسیون ثبت کنید';
         GOTO L$EndSP;
      END
      
      SELECT @ChatID = f.CHAT_ID_DNRM
        FROM iScsc.dbo.Fighter f
       WHERE @ChatID = (
               CASE  
                  WHEN @UssdCode IN ('*1#') THEN f.CHAT_ID_DNRM
                  WHEN @UssdCode IN ('') THEN f.DAD_CHAT_ID_DNRM
                  WHEN @UssdCode IN ('') THEN f.MOM_CHAT_ID_DNRM
               END 
             );
             
      SELECT @XTemp = (
         SELECT '@/DefaultGateway:Scsc:MAIN_PAGE_F;Attn-' + f.FNGR_PRNT_DNRM + N',' + CAST(m.RWNO AS NVARCHAR(5)) + '$#'  AS '@data'
               ,ROW_NUMBER() OVER ( ORDER BY m.RWNO DESC ) AS '@order'
               ,N'💡 [ ' + CAST(m.RWNO AS NVARCHAR(5))+ N' ] ' + mt.MTOD_DESC + 
                CASE 
                  WHEN m.NUMB_OF_ATTN_MONT = 0 THEN N', تعداد روز باقیمانده [ ' + CAST(DATEDIFF(DAY, GETDATE(), m.END_DATE) AS NVARCHAR(5)) + N' ]'
                  ELSE N', تعداد جلسات باقیمانده [ ' + CAST((m.NUMB_OF_ATTN_MONT - m.SUM_ATTN_MONT_DNRM) AS NVARCHAR(5)) + N' ]'
                END 
           FROM iScsc.dbo.Fighter f, iScsc.dbo.Fighter_Public fp, iScsc.dbo.Member_Ship m, iScsc.dbo.Method mt
          WHERE f.FILE_NO = fp.FIGH_FILE_NO
            AND f.FILE_NO = m.FIGH_FILE_NO
            AND m.FGPB_RWNO_DNRM = fp.RWNO
            AND m.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
            AND m.RECT_CODE = '004'
            AND m.VALD_TYPE = '002'
            AND f.CHAT_ID_DNRM = @ChatID
            AND fp.MTOD_CODE = mt.CODE
            AND CAST(GETDATE() AS DATE) BETWEEN CAST(m.STRT_DATE AS DATE) AND CAST(m.END_DATE AS DATE)
            AND (m.NUMB_OF_ATTN_MONT = 0 OR m.NUMB_OF_ATTN_MONT >= m.SUM_ATTN_MONT_DNRM)
            AND (
                  m.NUMB_OF_ATTN_MONT = 0 OR 
                  m.NUMB_OF_ATTN_MONT != m.SUM_ATTN_MONT_DNRM OR
                  (  
                     m.NUMB_OF_ATTN_MONT = m.SUM_ATTN_MONT_DNRM AND 
                     EXISTS(
                      select *
                        FROM iScsc.dbo.Attendance a
                       WHERE a.FIGH_FILE_NO = f.FILE_NO
                         AND a.MTOD_CODE_DNRM = mt.CODE
                         AND a.MBSP_RWNO_DNRM = m.RWNO
                         AND a.ATTN_DATE = CAST(GETDATE() AS DATE)
                         AND a.EXIT_TIME IS NULL                   
                     )
                  )
            )
            FOR XML PATH('InlineKeyboardButton'), ROOT('InlineKeyboardMarkup')
      );
      
      SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
      SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
       -- اینجا بخاطر اینکه متن 
       -- XML 
       -- که ساخته شده خراب نشود بخاطر اون عبارت زمان که آخر پیام اضافه میشود
      GOTO L$EndSP; 
    END
    
    -- Start Operation Call Back Query
    L$CallBackQuery:
    IF @CallBackQuery = '002'
    BEGIN    
      PRINT 'Call Back Query'
      PRINT 'I have create section for generate inlinekeyboardmarkup for return to ui'
      PRINT 'I have create another section for invoke action selected by "default section"'
      
      --IF @RunTheActionCallBackQuery = '002'
      --BEGIN
      --   PRINT 'در این قسمت درخواستی که از جانب کیبورد رسیده را پردازش میکنیم'
      --END
      
      IF @ListActionsCallBackQuery = '002'
      BEGIN
         PRINT N'در این قسمت اگر درخواست لیست جدید داشته باشیم';
         IF @MenuText = 'getalopyks'
         BEGIN
            SELECT @ordrcode = @x.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT');
            DECLARE @OrdrStat VARCHAR(3)
                   ,@OrdrNumb BIGINT;
            SELECT @OrdrStat = oa.ORDR_STAT
                  ,@OrdrNumb = om.ORDR_NUMB
              FROM dbo.[Order] oa,  dbo.[Order] om
             WHERE oa.CODE = @OrdrCode
               AND oa.ORDR_CODE = om.CODE;
            
            IF @OrdrStat = '002' -- ارجاع داده شده
            BEGIN
               SET @XTemp = (
                  SELECT 
                     REPLACE(
                        REPLACE (
                           N'<InlineKeyboardMarkup>
                              <InlineKeyboardButton data="./;*%*{0}-{1}" ordr="1">من میبرم</InlineKeyboardButton>
                              <InlineKeyboardButton data="./;*%!{0}-{1}" ordr="2">انصراف</InlineKeyboardButton>
                            </InlineKeyboardMarkup>', '{0}', @OrdrNumb 
                        ), '{1}', @OrdrCode
                     )
               );
               
               SET @XTemp.modify('insert attribute order {"1"} into (//InlineKeyboardMarkup)[1]');
               SET @Message = CONVERT(NVARCHAR(MAX), @XTemp);
                -- اینجا بخاطر اینکه متن 
                -- XML 
                -- که ساخته شده خراب نشود بخاطر اون عبارت زمان که آخر پیام اضافه میشود
               GOTO L$EndSP; 
            END 
         END   
      END
    END
    -- End Operation Call Back Query
    
    L$EndSP:
    SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
    SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END;
GO
