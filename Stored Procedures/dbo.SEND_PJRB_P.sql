SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SEND_PJRB_P]
	@X XML
AS
BEGIN
	DECLARE @Token VARCHAR(100)
	       ,@RoboRbid BIGINT	
	       ,@DfltAces VARCHAR(3)
	       ,@ChatId BIGINT
	       ,@ToChatId BIGINT
	       ,@OrdrType VARCHAR(3)
          ,@OrdrDesc NVARCHAR(MAX)
          ,@ElmnTYpe VARCHAR(3)
          ,@Fileid VARCHAR(MAX)
          ,@UssdCode VARCHAR(250)
          ,@ChildUssdCode VARCHAR(250);
	
	SELECT @Token = @X.query('Robot').value('(Robot/@token)[1]', 'VARCHAR(100)')
	      ,@DfltAces = @X.query('//Order').value('(Order/@dfltaces)[1]', 'VARCHAR(3)')
	      ,@ChatId = @X.query('//Order').value('(Order/@chatid)[1]', 'BIGINT')
	      ,@OrdrType = @X.query('//Order').value('(Order/@type)[1]', 'VARCHAR(3)')
         ,@ElmnTYpe = @X.query('//Order').value('(Order/@elmntype)[1]', 'VARCHAR(3)')
         ,@FileId = @X.query('//Order').value('(Order/@fileid)[1]', 'VARCHAR(250)')
         ,@UssdCode = @X.query('//Order').value('(Order/@ussdcode)[1]', 'VARCHAR(250)')
         ,@ChildUssdCode = @X.query('//Order').value('(Order/@childussdcode)[1]', 'VARCHAR(250)')
         ,@OrdrDesc = @X.query('//Order').value('.', 'NVARCHAR(MAX)');
	
	SELECT @RoboRbid = Rbid FROM dbo.Robot WHERE @Token = TKON_CODE;
	
	IF @DfltAces = '' SET @DfltAces = NULL;
	IF @ChatId = 0 SET @ChatId = NULL;	
	
	DECLARE C$PRBTS CURSOR FOR
	   SELECT CHAT_ID
	     FROM dbo.Personal_Robot
	    WHERE ROBO_RBID = @RoboRbid
	      AND (@DfltAces IS NULL OR DFLT_ACES = @DfltAces)
	      AND (@ChatId IS NULL OR CHAT_ID = @ChatId);
	
	OPEN [C$PRBTS];
	L$LOOP:
	FETCH [C$PRBTS] INTO @ToChatId;
	
	IF @@FETCH_STATUS <> 0
	   GOTO L$ENDLOOP;
	
	DECLARE @XTemp XML;
	SELECT @XTemp = (
	   SELECT @Token AS '@token'
	         ,@ToChatId AS 'Order/@chatid' 
	         ,@OrdrType AS 'Order/@type'
	         ,@ElmnType AS 'Order/@elmntype'
	         ,@Fileid AS 'Order/@fileid'
	         ,@UssdCode AS 'Order/@ussdcode'
	         ,@ChildUssdCode AS 'Order/@childussdcode'
	         ,@OrdrDesc AS 'Order'
	  FOR XML PATH('Robot')
	)
	
	EXEC dbo.Save_Ordr_P @X = @XTemp -- xml	
	   
	GOTO L$LOOP
	L$ENDLOOP:
	CLOSE [C$PRBTS];
	DEALLOCATE [C$PRBTS];		
END
GO
