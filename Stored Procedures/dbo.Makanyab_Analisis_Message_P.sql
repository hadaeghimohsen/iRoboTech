SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Makanyab_Analisis_Message_P]
	@X XML,
	@XResult XML OUT
AS
BEGIN
   DECLARE @UssdCode VARCHAR(250),
           @ChildUssdCode VARCHAR(250),    
           @MenuText NVARCHAR(250),
           @Message NVARCHAR(MAX),
		     @XMessage XML,
		     @XTemp XML,
           @ChatID BIGINT,
           @CordX  FLOAT,
           @CordY  FLOAT,
           @PhotoFileId VARCHAR(MAX),
           @VideoFileId VARCHAR(MAX),
           @DocumentFileId VARCHAR(MAX),
           @ElmnType VARCHAR(3),
           @Item NVARCHAR(1000),
           @NameService NVARCHAR(100),
           @CellPhon VARCHAR(13),
           @ServAddres NVARCHAR(1000),
           @Index BIGINT = 0;
	
	SELECT @UssdCode = @X.query('//Message').value('(Message/@ussd)[1]', 'VARCHAR(250)'),
	       @ChildUssdCode = @X.query('//Message').value('(Message/@childussd)[1]', 'VARCHAR(250)'),    
	       @ChatID   = @X.query('//Message').value('(Message/@chatid)[1]', 'BIGINT'),	       
	       @ElmnType   = @X.query('//Message').value('(Message/@elmntype)[1]', 'VARCHAR(3)'),	       
	       @MenuText = @X.query('//Text').value('.', 'NVARCHAR(250)'),
	       @CordX    = @X.query('//Location').value('(Location/@latitude)[1]', 'FLOAT'),
	       @CordY    = @X.query('//Location').value('(Location/@longitude)[1]', 'FLOAT'),
	       @PhotoFileId   = @X.query('//Photo').value('(Photo/@fileid)[1]', 'NVARCHAR(MAX)'),
	       @VideoFileId   = @X.query('//Video').value('(Video/@fileid)[1]', 'NVARCHAR(MAX)'),
	       @DocumentFileId   = @X.query('//Document').value('(Document/@fileid)[1]', 'NVARCHAR(MAX)');
	
   --insert into logs (x) values (@x); 

   IF @UssdCode = '*2*1*1#'
   BEGIN
      IF NOT (@CordX = 0 AND @CordY = 0)
      BEGIN
         UPDATE dbo.Service_Robot
            SET CORD_X = @CordX
               ,CORD_Y = @CordY
          WHERE CHAT_ID = @ChatID
            AND ROBO_RBID = 13;
   		
		   SELECT @Message = 
	         (N'اطلاعات موقعیت جغرافیایی شما برای ثبت گردید.');
	   END
   END
   ELSE IF @UssdCode = '*2*1*2#'
   BEGIN
      IF @MenuText IS NOT NULL
		BEGIN
			UPDATE dbo.Service_Robot
            SET RDUS_SRCH = CAST(@MenuText AS BIGINT)
          WHERE CHAT_ID = @ChatID
            AND ROBO_RBID = 13;

		   SELECT @Message = 
			  (N'اطلاعات شعاع جستجوی جغرافیایی شما در سیستم ثبت گردید');
	   END
   END
   ELSE IF @UssdCode = '*2*1*3*1#'
   BEGIN
      IF @ChildUssdCode = '*2*1*3*1*1#'
      BEGIN
         UPDATE dbo.Service_Robot
            SET REGN_PRVN_CNTY_CODE = '001'
               ,REGN_PRVN_CODE = '017'
               ,REGN_CODE = '001'
          WHERE CHAT_ID = @ChatID
            AND ROBO_RBID = 13;
         SELECT @Message = 
			  (N'اطلاعات مکان شهری برای شما در سیستم ثبت گردید');
      END      
   END
   ELSE  IF @UssdCode = '*1*19#'    
 BEGIN    
    SELECT @Message = (    
       SELECT o.NAME + N' ' + r.NAME + CHAR(10)    
         FROM Organ o, Robot r    
        WHERE o.OGID = r.ORGN_OGID    
          AND ( o.NAME LIKE N'%'+ @MenuText +N'%'    
             OR o.ORGN_DESC LIKE N'%'+ @MenuText +N'%'    
             OR r.NAME LIKE N'%'+ @MenuText +N'%'    
             OR o.KEY_WORD LIKE N'%'+ @MenuText +N'%'    
          )    
          AND o.STAT = '002'    
          AND r.STAT = '002'    
        ORDER BY o.OGID, r.RBID    
          FOR XML PATH('')    
    );    
 END    
 ELSE IF @UssdCode = '*1#'     
 BEGIN    
  IF @ChildUssdCode = '*1*1#'    
   SELECT @Message = (    
       SELECT TOP 10 o.Name +  N' ' + r.Name + CHAR(10) + N' 👁  '  + CAST(COUNT(*) AS VARCHAR(32)) +  CHAR(10)
         FROM dbo.Service_Robot_Visit srv, Robot r, organ O
        WHERE srv.srrb_robo_rbid = r.rbid
          AND r.orgn_ogid = o.ogid
          AND r.Stat = '002'
          AND o.Stat = '002'
        GROUP BY r.name, o.name
        ORDER BY count(*) desc  
          FOR XML PATH('')    
    );    
  ELSE IF @ChildUssdCode = '*1*2#'    
  BEGIN
   SELECT @Message = (    
     SELECT DISTINCT o.NAME + N' ' + r.NAME + CHAR(10)    
    FROM Organ o, Organ_Category oc, Robot r    
      WHERE o.OGID = oc.ORGN_OGID    
     AND o.OGID = r.ORGN_OGID    
     AND oc.ISIC_CODE IN (27)    
     AND o.STAT = '002'    
     AND oc.STAT = '002'    
     AND r.STAT = '002'    
      --ORDER BY o.OGID, r.RBID    
     FOR XML PATH('')    
     );      
   SELECT @Message = ISNULL(@Message, ' ') + CHAR(10) + (    
        SELECT DISTINCT N'👈 ' + o.NAME + N'، '  + CHAR(10) + 
         (
            SELECT od.ITEM_DESC + ' ' + od.ITEM_VALU + CHAR(10)
              FROM dbo.Organ_Description od
             WHERE od.ORGN_OGID = o.OGID
             ORDER BY od.ORDR
             FOR XML PATH('')
         ) + CHAR(10)    
          FROM Organ o, Organ_Category oc, dbo.Robot r
         WHERE o.OGID = oc.ORGN_OGID    
           AND o.OGID = r.ORGN_OGID
           AND oc.ISIC_CODE IN (27)    
           AND r.STAT = '001'
           AND o.STAT = '001'    
           AND oc.STAT = '002'    
         FOR XML PATH('')
      );  
  END  
  ELSE IF @ChildUssdCode = '*1*3#'   
  BEGIN
   SELECT @Message = (    
     SELECT DISTINCT o.NAME + N' ' + r.NAME + CHAR(10)    
    FROM Organ o, Organ_Category oc, Robot r    
      WHERE o.OGID = oc.ORGN_OGID    
     AND o.OGID = r.ORGN_OGID    
     AND oc.ISIC_CODE IN (7, 8)    
     AND o.STAT = '002'    
     AND oc.STAT = '002'    
     AND r.STAT = '002'    
      --ORDER BY o.OGID, r.RBID    
     FOR XML PATH('')    
     );      
   SELECT @Message = ISNULL(@Message, ' ') + CHAR(10) + (    
        SELECT DISTINCT N'👈 ' + o.NAME + N'، '  + CHAR(10) + 
         (
            SELECT od.ITEM_DESC + ' ' + od.ITEM_VALU + CHAR(10)
              FROM dbo.Organ_Description od
             WHERE od.ORGN_OGID = o.OGID
             ORDER BY od.ORDR
             FOR XML PATH('')
         ) + CHAR(10)    
          FROM Organ o, Organ_Category oc, dbo.Robot r
         WHERE o.OGID = oc.ORGN_OGID    
           AND o.OGID = r.ORGN_OGID
           AND oc.ISIC_CODE IN (7, 8)    
           AND r.STAT = '001'
           AND o.STAT = '001'    
           AND oc.STAT = '002'    
         FOR XML PATH('')
      );  
  END
  ELSE IF @ChildUssdCode = '*1*4#'    
  BEGIN 
   SELECT @Message = (    
     SELECT DISTINCT o.NAME + N' ' + r.NAME + CHAR(10)    
       FROM Organ o, Organ_Category oc, Robot r    
      WHERE o.OGID = oc.ORGN_OGID    
        AND o.OGID = r.ORGN_OGID    
        AND oc.ISIC_CODE IN (4, 5, 6)    
        AND o.STAT = '002'    
        AND oc.STAT = '002'    
        AND r.STAT = '002'    
      --ORDER BY o.OGID, r.RBID    
      FOR XML PATH('')    
     );
     
   SELECT @Message = ISNULL(@Message, ' ') + CHAR(10) + (    
        SELECT DISTINCT N'👈 ' + o.NAME + N'، ' +  CHAR(10) +
         (
            SELECT od.ITEM_DESC + ' ' + od.ITEM_VALU + CHAR(10)
              FROM dbo.Organ_Description od
             WHERE od.ORGN_OGID = o.OGID
             ORDER BY od.ORDR
             FOR XML PATH('')
         ) + CHAR(10)    
          FROM Organ o, Organ_Category oc, dbo.Robot r
         WHERE o.OGID = oc.ORGN_OGID    
           AND o.OGID = r.ORGN_OGID
           AND oc.ISIC_CODE IN (4, 5, 6)    
           AND r.STAT = '001'
           AND o.STAT = '001'    
           AND oc.STAT = '002'    
         FOR XML PATH('')
      );    
  END
  ELSE IF @ChildUssdCode = '*1*5#'    
  BEGIN
     SELECT @Message = (    
     SELECT DISTINCT o.NAME + N' ' + r.NAME + CHAR(10)    
       FROM Organ o, Organ_Category oc, Robot r    
      WHERE o.OGID = oc.ORGN_OGID    
        AND o.OGID = r.ORGN_OGID    
        AND oc.ISIC_CODE IN (2, 11)    
        AND o.STAT = '002'    
        AND oc.STAT = '002'    
        AND r.STAT = '002'    
      --ORDER BY o.OGID, r.RBID    
      FOR XML PATH('')    
     );     
     SELECT @Message = ISNULL(@Message, ' ') + CHAR(10) + (    
        SELECT DISTINCT N'👈 ' + o.NAME + N'، ' + CHAR(10) +
         (
            SELECT od.ITEM_DESC + ' ' + od.ITEM_VALU + CHAR(10)
              FROM dbo.Organ_Description od
             WHERE od.ORGN_OGID = o.OGID
             ORDER BY od.ORDR
             FOR XML PATH('')
         ) + CHAR(10)    
          FROM Organ o, Organ_Category oc, dbo.Robot r
         WHERE o.OGID = oc.ORGN_OGID    
           AND o.OGID = r.ORGN_OGID
           AND oc.ISIC_CODE IN (2, 11)    
           AND r.STAT = '001'
           AND o.STAT = '001'    
           AND oc.STAT = '002'    
         FOR XML PATH('')
      );          
  END
   
  ELSE IF @ChildUssdCode = '*1*6#'    
  BEGIN
   SELECT @Message = (    
     SELECT DISTINCT o.NAME + N' ' + r.NAME + CHAR(10)    
       FROM Organ o, Organ_Category oc, Robot r    
      WHERE o.OGID = oc.ORGN_OGID    
        AND o.OGID = r.ORGN_OGID    
        AND oc.ISIC_CODE IN (16)    
        AND o.STAT = '002'    
        AND oc.STAT = '002'    
        AND r.STAT = '002'    
      --ORDER BY o.OGID, r.RBID    
      FOR XML PATH('')    
     );     
   SELECT @Message = ISNULL(@Message, ' ') + CHAR(10) + (    
        SELECT DISTINCT N'👈 ' + o.NAME + N'، ' + CHAR(10) +
         (
            SELECT od.ITEM_DESC + ' ' + od.ITEM_VALU + CHAR(10)
              FROM dbo.Organ_Description od
             WHERE od.ORGN_OGID = o.OGID
             ORDER BY od.ORDR
             FOR XML PATH('')
         ) + CHAR(10)    
          FROM Organ o, Organ_Category oc, dbo.Robot r
         WHERE o.OGID = oc.ORGN_OGID    
           AND o.OGID = r.ORGN_OGID
           AND oc.ISIC_CODE IN (16)    
           AND r.STAT = '001'
           AND o.STAT = '001'    
           AND oc.STAT = '002'    
         FOR XML PATH('')
      );
  END
  ELSE IF @ChildUssdCode = '*1*7#' 
  BEGIN   
   SELECT @Message = (    
     SELECT DISTINCT o.NAME + N' ' + r.NAME + CHAR(10)    
    FROM Organ o, Organ_Category oc, Robot r    
      WHERE o.OGID = oc.ORGN_OGID    
     AND o.OGID = r.ORGN_OGID    
     AND oc.ISIC_CODE IN (8, 29)    
     AND o.STAT = '002'    
     AND oc.STAT = '002'    
     AND r.STAT = '002'    
      --ORDER BY o.OGID, r.RBID    
     FOR XML PATH('')    
     );
     
     SELECT @Message = ISNULL(@Message, ' ') + CHAR(10) + (    
        SELECT DISTINCT N'👈 ' + o.NAME + N'، ' + CHAR(10) +
         (
            SELECT od.ITEM_DESC + ' ' + od.ITEM_VALU + CHAR(10)
              FROM dbo.Organ_Description od
             WHERE od.ORGN_OGID = o.OGID
             ORDER BY od.ORDR
             FOR XML PATH('')
         ) + CHAR(10)    
          FROM Organ o, Organ_Category oc, dbo.Robot r
         WHERE o.OGID = oc.ORGN_OGID    
           AND o.OGID = r.ORGN_OGID
           AND oc.ISIC_CODE IN (8, 29)    
           AND r.STAT = '001'
           AND o.STAT = '001'    
           AND oc.STAT = '002'    
         FOR XML PATH('')
      );          
  END    
  ELSE IF @ChildUssdCode = '*1*8#'    
  BEGIN
     SELECT @Message = (    
     SELECT DISTINCT o.NAME + N' ' + r.NAME + CHAR(10)    
       FROM Organ o, Organ_Category oc, Robot r    
      WHERE o.OGID = oc.ORGN_OGID    
        AND o.OGID = r.ORGN_OGID    
        AND oc.ISIC_CODE IN (21)    
        AND o.STAT = '002'    
        AND oc.STAT = '002'    
        AND r.STAT = '002'    
      --ORDER BY o.OGID, r.RBID    
      FOR XML PATH('')    
     );     
     SELECT @Message = ISNULL(@Message, ' ') + CHAR(10) + (    
        SELECT DISTINCT N'👈 ' + o.NAME + N'، ' + CHAR(10) +
         (
            SELECT od.ITEM_DESC + ' ' + od.ITEM_VALU + CHAR(10)
              FROM dbo.Organ_Description od
             WHERE od.ORGN_OGID = o.OGID
             ORDER BY od.ORDR
             FOR XML PATH('')
         ) + CHAR(10)    
          FROM Organ o, Organ_Category oc, dbo.Robot r
         WHERE o.OGID = oc.ORGN_OGID    
           AND o.OGID = r.ORGN_OGID
           AND oc.ISIC_CODE IN (21)    
           AND r.STAT = '001'
           AND o.STAT = '001'    
           AND oc.STAT = '002'    
         FOR XML PATH('')
      );          
  END
  ELSE IF @ChildUssdCode = '*1*9#'   
  BEGIN
   SELECT @Message = (    
     SELECT DISTINCT o.NAME + N' ' + r.NAME + CHAR(10)    
    FROM Organ o, Organ_Category oc, Robot r    
      WHERE o.OGID = oc.ORGN_OGID    
     AND o.OGID = r.ORGN_OGID    
     AND oc.ISIC_CODE IN (23,24,22)    
     AND o.STAT = '002'    
     AND oc.STAT = '002'    
     AND r.STAT = '002'    
      --ORDER BY o.OGID, r.RBID    
     FOR XML PATH('')    
     );      
   SELECT @Message = ISNULL(@Message, ' ') + CHAR(10) + (    
        SELECT DISTINCT N'👈 ' + o.NAME + N'، ' + CHAR(10) +
         (
            SELECT od.ITEM_DESC + ' ' + od.ITEM_VALU + CHAR(10)
              FROM dbo.Organ_Description od
             WHERE od.ORGN_OGID = o.OGID
             ORDER BY od.ORDR
             FOR XML PATH('')
         ) + CHAR(10)    
          FROM Organ o, Organ_Category oc, dbo.Robot r
         WHERE o.OGID = oc.ORGN_OGID    
           AND o.OGID = r.ORGN_OGID
           AND oc.ISIC_CODE IN (23,24,22)   
           AND r.STAT = '001'
           AND o.STAT = '001'    
           AND oc.STAT = '002'    
         FOR XML PATH('')
      );  
  END
 END
	
	L$EndSP:
	SET @XResult = '<Respons actncode="1000"><Message>No Message</Message></Respons>';
	SET @XResult.modify('replace value of (/Respons/Message/text())[1] with sql:variable("@Message")');
END
GO
