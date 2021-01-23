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
 PROCEDURE [dbo].[WoodLock_Analisis_Message_P] @X XML, @XResult XML OUT
AS
BEGIN
    DECLARE @UssdCode VARCHAR(250) ,
        @ChildUssdCode VARCHAR(250) ,
        @MenuText NVARCHAR(MAX) ,
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
        @SuprGrop VARCHAR(100),
        @ContArtc FLOAT,
        @UserContArtc FLOAT = NULL,
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
    IF @UssdCode IN (   
    -- صفحه کابینت
    '*0*9*0#', '*0*9*1#', '*0*9*2#',
    -- تاپکو    
    '*0*8*0*0#', '*0*8*0*1#', '*0*8*0*2#',
    '*0*8*1#', '*0*8*2#', '*0*8*3#', '*0*8*4#', '*0*8*5#', 
    '*0*8*6#', '*0*8*7#', '*0*8*8#', '*0*8*9#', '*0*8*10#', 
    '*0*8*11#', '*0*8*12#', '*0*8*13#', 
    -- فوم 
    '*0*7*0#', '*0*7*1#',
    -- چسب
    '*0*6*0#', '*0*6*1#', '*0*6*2#', '*0*6*3#',
    -- پروفیل PVC
    '*0*5*0#', '*0*5*1#', '*0*5*2#', '*0*5*3#', '*0*5*4#',
    '*0*5*5*0#', '*0*5*5*1#', 
    -- پروفیل MDF
    '*0*4*0#', '*0*4*1#', 
    '*0*4*2*0#', '*0*4*2*1#', 
    '*0*4*3#', '*0*4*4#',
    '*0*4*5#', '*0*4*6#', '*0*4*7#', '*0*4*8#', '*0*4*9#',
    '*0*4*10#', 
    '*0*4*11*0#', '*0*4*11*1#', '*0*4*11*2#', '*0*4*11*3#', '*0*4*11*4#', '*0*4*11*4#',
    '*0*4*12*0#', '*0*4*12*1#', '*0*4*12*2#', '*0*4*12*3#', '*0*4*12*4#', '*0*4*12*4#',
    '*0*4*13*0#', '*0*4*13*1#', 
    '*0*4*14*0#', '*0*4*14*1#',
    '*0*4*15*0#', '*0*4*15*1#', 
    '*0*4*16#', '*0*4*17#', '*0*4*18#', '*0*4*18#',
    '*0*4*19*0#', '*0*4*19*1#', 
    '*0*4*20*0#', '*0*4*20*1#', '*0*4*20*2#', 
    '*0*4*21#', '*0*4*22#', '*0*4*23#',
    -- ورق
    '*0*3*0#', '*0*3*1#', '*0*3*1#',
    -- لمینت
    '*0*0*0#', '*0*0*1#',
    -- کاغذ دیواری
    '*0*1*0#', '*0*1*1#', '*0*1*2#', '*0*1*3#', '*0*1*4#', 
    '*0*1*5#', '*0*1*6#', '*0*1*7#', '*0*1*8#', '*0*1*9#', '*0*1*10#',
    '*0*1*11#', '*0*1*12#', '*0*1*13#', '*0*1*14#', '*0*1*15#', '*0*1*16#',
    '*0*1*17#', '*0*1*18#', '*0*1*19#', '*0*1*20#', '*0*1*21#', '*0*1*22#',
    '*0*1*23#', '*0*1*24#', '*0*1*25#', '*0*1*26#', '*0*1*27#', '*0*1*29#',
    '*0*1*30#', '*0*1*31#', '*0*1*32#', '*0*1*33#', '*0*1*34#', '*0*1*35#'
    )    
    BEGIN
	  SELECT @SuprGrop = MNUS_DESC
		FROM dbo.Menu_Ussd
	   WHERE ROBO_RBID = @Rbid
		 AND USSD_CODE = @UssdCode;
	  
	  SET @MenuText = REPLACE(@MenuText, ' ', '%');
	  
	  IF (CHARINDEX('*', @MenuText) != 0)
	  BEGIN
	     DECLARE C$Items CURSOR FOR
			 SELECT Item FROM dbo.SplitString(@MenuText, '*');
		  SET @Index = 0;
		  OPEN [C$Items];
		  L$FetchC$Item_2:
		  FETCH NEXT FROM [C$Items] INTO @Item;
         
		  IF @@FETCH_STATUS <> 0
	 		 GOTO L$EndC$Item_2;
	 	  
	 	  IF @Index = 0
	 	     SET @MenuText = @Item;
	 	  ELSE IF @Index = 1
	 	     SET @UserContArtc = CONVERT(FLOAT, @Item);
	 	  
	 	  SET @Index += 1;	 	  
	 	  
	 	  GOTO L$FetchC$Item_2;
	 	  L$EndC$Item_2:
	 	  CLOSE [C$Items];
	 	  DEALLOCATE [C$Items];				
	  END
	  ELSE
	  BEGIN
	     SET @UserContArtc = NULL;
	  END
	  	 
      -- USSD_CODE NOT IN    
	  IF @ChildUssdCode NOT IN (
	   -- لمینت - WoodLock
		'*0*0*0*1#',
		-- لمینت - Quick Floor Tex
		'*0*0*1*1#',
		-- کاغذ دیواری
		'*0*1*0*1#', '*0*1*1*1#', '*0*1*2*1#', '*0*1*3*1#', '*0*1*4*1#', 		
		'*0*1*5*1#', '*0*1*6*1#', '*0*1*7*1#', '*0*1*8*1#', '*0*1*9*1#', 
		'*0*1*10*1#', '*0*1*11*1#', '*0*1*12*1#', '*0*1*13*1#', '*0*1*14*1#',
		'*0*1*15*1#', '*0*1*16*1#', '*0*1*17*1#', '*0*1*18*1#', '*0*1*19*1#',
		'*0*1*20*1#', '*0*1*21*1#', '*0*1*22*1#', '*0*1*23*1#', '*0*1*24*1#',
		'*0*1*25*1#', '*0*1*26*1#', '*0*1*27*1#', '*0*1*28*1#', '*0*1*29*1#',
		'*0*1*30*1#', '*0*1*31*1#','*0*1*32*1#','*0*1*33*1#','*0*1*34*1#','*0*1*35*1#',
		-- ورق
		'*0*3*0*1#', '*0*3*1*1#', 
		-- پروفیل MDF
		'*0*4*0*1#', '*0*4*1*1#', '*0*4*2*1#', '*0*4*3*1#', '*0*4*4*1#',
		'*0*4*5*1#', '*0*4*6*1#', '*0*4*7*1#', '*0*4*8*1#', '*0*4*9*1#',
		'*0*4*10*1#', '*0*4*11*1#', '*0*4*12*1#', '*0*4*13*1#', '*0*4*14*1#',
		'*0*4*15*1#', '*0*4*16*1#', '*0*4*17*1#', '*0*4*18*1#', '*0*4*19*1#',
		'*0*4*20*1#', '*0*4*21*1#', '*0*4*22*1#', '*0*4*23*1#',
		'*0*4*11*0*1#', '*0*4*11*1*1#', '*0*4*11*2*1#', '*0*4*11*3*1#', '*0*4*11*4*1#',
		'*0*4*12*0*1#', '*0*4*12*1*1#', '*0*4*12*2*1#', '*0*4*12*3*1#', '*0*4*12*4*1#',
		--'*0*4*13*0*1#', '*0*4*13*1*1#',
		--'*0*4*0*1#', '*0*4*1*1#', '*0*4*2*1#', '*0*4*3*1#', '*0*4*4*1#',
      --'*0*4*5*1#', '*0*4*6*1#', '*0*4*7*1#', '*0*4*8*1#', '*0*4*9*1#',
      --'*0*4*10*1#', '*0*4*11*1#', '*0*4*12*1#', '*0*4*13*1#', '*0*4*14*1#', 
      --'*0*4*15*1#', '*0*4*16*1#', '*0*4*17*1#', '*0*4*18*1#', '*0*4*19*1#',  
      --'*0*4*20*1#', '*0*4*21*1#', '*0*4*22*1#', '*0*4*23*1#', 
      '*0*4*11*0*1#', '*0*4*11*1*1#', '*0*4*11*2*1#', '*0*4*11*3*1#',
      '*0*4*12*0*1#', '*0*4*12*1*1#', '*0*4*12*2*1#', '*0*4*12*3*1#',
      '*0*4*13*0*1#', '*0*4*13*1*1#', '*0*4*13*2*1#', '*0*4*13*3*1#',    
      '*0*4*14*0*1#', '*0*4*14*1*1#',
      '*0*4*15*0*1#', '*0*4*15*1*1#',
      '*0*4*19*0*1#', '*0*4*19*1*1#',
      '*0*4*2*0*1#', '*0*4*2*1*1#',
      '*0*4*20*0*1#', '*0*4*20*1*1#', '*0*4*20*2*1#',
      '*0*4*21*1#',
      -- پروفیل PVC
      '*0*5*0*1#', '*0*5*1*1#', '*0*5*2*1#', '*0*5*3*1#', '*0*5*4*1#',
      '*0*5*5*0*1#', '*0*5*5*1*1#',
      -- چسب
      '*0*6*0*1#', '*0*6*1*1#', '*0*6*2*1#', '*0*6*3*1#',
      -- فوم
      '*0*7*0*1#' , '*0*7*1*1#',
      -- تاپکو
      '*0*8*0*0*1#', '*0*8*0*1*1#', '*0*8*0*2*1#', '*0*8*0*3*1#',
      '*0*8*1*1#', '*0*8*2*1#', '*0*8*3*1#', '*0*8*4*1#', '*0*8*5*1#',
      '*0*8*6*1#', '*0*8*7*1#', '*0*8*8*1#', '*0*8*9*1#', '*0*8*10*1#',
      '*0*8*11*1#', '*0*8*12*1#', '*0*8*13*1#',
      -- صفحه کابینت
      '*0*9*0*1#', '*0*9*1*1#', '*0*9*2*1#'
	  )
	  BEGIN
		IF CHARINDEX('*', @SuprGrop, 0) = 0 
		  BEGIN
			 IF EXISTS(
				SELECT *
				  FROM Holoo1.dbo.ARTICLE a, Holoo1.dbo.UNIT u
				 WHERE SUBSTRING(A_Code, 1, 4) = @SuprGrop
				   AND A_Name LIKE N'%'+ @MenuText + N'%'
				   AND a.VahedCode = u.Unit_Code
			 )
			 BEGIN
				SELECT @ContArtc = SUM(a.Exist)
				  FROM Holoo1.dbo.ARTICLE a, Holoo1.dbo.UNIT u
				 WHERE SUBSTRING(A_Code, 1, 4) = @SuprGrop
				   AND A_Name LIKE N'%'+ @MenuText + N'%'
				   AND a.VahedCode = u.Unit_Code;
	            
				--IF /*@ContArtc < 5 */ @ContArtc < @UserContArtc
				--   SET @Message = N'👈 موجودی کالا محدود می باشد لطفا با دفتر 📞 تماس بگیرید';
				--ELSE
				--   SET @Message = N'👌 کالا موجود میباشد';
				IF @ContArtc = 0
				   SET @Message = N'😕 کالا موجود نمیباشد'
				ELSE IF /*@ContArtc < 5 */ @ContArtc < @UserContArtc
				   SET @Message = N'👈 موجودی کالا محدود می باشد لطفا با دفتر 📞 تماس بگیرید'
				ELSE
				   SET @Message = N'👌 کالا موجود میباشد'
			 END 
			 ELSE
				SET @Message = N'اطلاعات ورودی اشتباه میباشد، دوباره تلاش کنید'
			 /*SELECT @Message = ISNULL(CONVERT(NVARCHAR(max), 
				(
				   SELECT N'👈 کالا : ( ' + a.A_Name + N' ) ' + CHAR(10) + CAST(a.Exist AS NVARCHAR(MAX)) + N' ' + u.Unit_Name
					 FROM Holoo1.dbo.ARTICLE a, Holoo1.dbo.UNIT u
					WHERE SUBSTRING(A_Code, 1, 4) = @SuprGrop
					  AND A_Name LIKE N'%'+ @MenuText + N'%'
					  AND a.VahedCode = u.Unit_Code
					  FOR XML PATH('')
				)), N'');*/
		  END      
		  ELSE
		  BEGIN
			 SET @Message = '' + CHAR(10);
			 SET @ContArtc = 0;
	         
			 DECLARE C$Items CURSOR FOR
				SELECT Item FROM dbo.SplitString(@SuprGrop, '*');
			 SET @Index = 0;
			 OPEN [C$Items];
			 L$FetchC$Item_1:
			 FETCH NEXT FROM [C$Items] INTO @Item;
	         
			 IF @@FETCH_STATUS <> 0
				GOTO L$EndC$Item_1;
	         
			 /*SELECT @Message += ISNULL(CONVERT(NVARCHAR(max), 
				(
				   SELECT N'👈 کالا : ( ' + a.A_Name + N' ) ' + CHAR(10) + CAST(a.Exist AS NVARCHAR(MAX)) + N' ' + u.Unit_Name + CHAR(10) + CHAR(10)
					 FROM Holoo1.dbo.ARTICLE a, Holoo1.dbo.UNIT u
					WHERE SUBSTRING(A_Code, 1, 4) = @Item
					  AND A_Name LIKE N'%'+ @MenuText + N'%'
					  AND a.VahedCode = u.Unit_Code
					  FOR XML PATH(''), TYPE
				)
			 ), N'');*/
	         
			 IF EXISTS(
				SELECT *
				  FROM Holoo1.dbo.ARTICLE a, Holoo1.dbo.UNIT u
				 WHERE SUBSTRING(A_Code, 1, 4) = @Item
				   AND A_Name LIKE N'%'+ @MenuText + N'%'
				   AND a.VahedCode = u.Unit_Code
			 )
			 BEGIN
				SET @Visit = 1;
				SELECT @ContArtc += SUM(a.Exist)
				  FROM Holoo1.dbo.ARTICLE a, Holoo1.dbo.UNIT u
				 WHERE SUBSTRING(A_Code, 1, 4) = @Item
				   AND A_Name LIKE N'%'+ @MenuText + N'%'
				   AND a.VahedCode = u.Unit_Code;
			 END
	         
			 SET @Index += 1;
			 GOTO L$FetchC$Item_1;
			 L$EndC$Item_1:
			 CLOSE [C$Items];
			 DEALLOCATE [C$Items];
	         
			 IF @Visit = 0 
				SET @Message = N'اطلاعات ورودی اشتباه میباشد، دوباره تلاش کنید';
	         
			 --IF @ContArtc < 5   
				--SET @Message = N'👈 موجودی کالا محدود می باشد لطفا با دفتر 📞 تماس بگیرید';
			 --ELSE
				--SET @Message = N'👌 کالا موجود میباشد';
		    IF @ContArtc = 0
		      SET @Message = N'😕 کالا موجود نمیباشد'
		    ELSE IF /*@ContArtc < 5 */ @ContArtc < @UserContArtc
		      SET @Message = N'👈 موجودی کالا محدود می باشد لطفا با دفتر 📞 تماس بگیرید'
		    ELSE
		      SET @Message = N'👌 کالا موجود میباشد'
		  END
      END
      ELSE
      BEGIN
         --IF CHARINDEX('*', @SuprGrop, 0) = 0 
		      SET @Message = (
			      SELECT N'👉 ' + 
				         CONVERT(NVARCHAR(MAX), ROW_NUMBER() OVER (order by a_name) ) + ' :    ' + 
				         CONVERT(NVARCHAR(MAX), A_Name) + 
				         CHAR(10) + 
				         CASE
				            WHEN SUM(Exist) = 0 THEN N'😕 کالا موجود نمیباشد'
				            WHEN SUM(Exist) < 5 THEN N'🔴 موجودی کالا محدود می باشد' + CHAR(10) + N'لطفا با دفتر 📞 تماس بگیرید'
				            ELSE N'✅ کالا موجود میباشد'
				         END +
				         CHAR(10) + 
				         N' ' + 
				         CHAR(10) 
			        FROM Holoo1.dbo.ARTICLE
			       WHERE (SUBSTRING(A_Code, 1, 4) COLLATE SQL_Latin1_General_CP1_CI_AS) IN (SELECT (Item COLLATE SQL_Latin1_General_CP1_CI_AS) FROM dbo.SplitString(@SuprGrop, '*'))
			         AND Exist > 0
			       GROUP BY A_Name
			       FOR XML PATH('')
		      );			      
      END      
    END;
    -- 
    -- نمایش کد تلگرام
    ELSE IF @UssdCode = '*2#' AND @ChildUssdCode = '*2*1#'
    BEGIN
      SET @Message = N'کد تلگرامی شما ' + CONVERT(NVARCHAR(14), @ChatID) + N' می باشد';
    END
    -- ثبت از طریق شماره موبایل از سمت تلگرام
    IF @UssdCode = '*2#' AND @ChildUssdCode = '*2*2#'
    BEGIN
      BEGIN TRY
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
    
    SELECT @Message += CHAR(10) + CHAR(10) + N'⏰ ' + dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5));
    
    L$EndSP:
    SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
    SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END;

GO
