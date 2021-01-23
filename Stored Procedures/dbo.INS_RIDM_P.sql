SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_RIDM_P]
	@X XML
	/*
	<Instagram code="" rbid="">
	   <Direct>
	      <Message>Hi There Fans @{sextype} @{frstname} @{lastname}</Message>
	      <Users>
	         <User pkid="" chatid=""/>
	      </Users>
	   </Direct>
	</Instagram>
	*/
AS
BEGIN
	BEGIN TRY
	   BEGIN TRAN [T$INS_RIDM_P];
	   DECLARE @RinsCode BIGINT,
	           @Rbid BIGINT,
	           @MesgText NVARCHAR(MAX),
	           @TrnsMesgText NVARCHAR(MAX),
	           @Pkid BIGINT,
	           @Chatid BIGINT;
	   
	   -- First Step Get Template Message and another var
	   SELECT @Rbid = @x.query('Instagram').value('(Instagram/@rbid)[1]','BIGINT')
	         ,@RinsCode = @x.query('Instagram').value('(Instagram/@code)[1]','BIGINT')
	         ,@MesgText = @x.query('//Message').value('.','NVARCHAR(MAX)');
	   
	   -- Loop For Pkids
      DECLARE @docHandle INT;	
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;

      DECLARE C$Users CURSOR
      FOR
      SELECT *
        FROM OPENXML(@docHandle, N'//User')
        WITH (        
           Pkid BIGINT '@pkid',
           Chatid BIGINT '@chatid'
        );
	   
	   OPEN [C$Users];
	   L$Loop$Users:
	   FETCH [C$Users] INTO @Pkid, @Chatid;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop$Users;
	   
	   IF @Chatid = 0 SET @Chatid = NULL;
	   
	   -- Translate Template Message To Target Message
	   -- <TemplateToText rbid="" chatid="" pkid="" tmid=""/>
	   DECLARE @XP XML = (
         SELECT @Rbid AS '@rbid'
               ,@Chatid AS '@chatid'
               ,@Pkid AS '@pkid'
               ,@MesgText AS '@text'
            FOR XML PATH('TemplateToText')
      );
      
      SET @XP = dbo.GET_TEXT_F(@XP);
      SELECT @TrnsMesgText = @XP.query('//Result').value('.', 'NVARCHAR(MAX)');
	   
	   -- INSERT RECORD MESSAGE ON ROBOT_INSTAGRAM_DIRECTMESSAGE
	   INSERT INTO dbo.Robot_Instagram_DirectMessage ( RINS_CODE ,CODE ,INST_PKID ,MESG_TYPE ,MESG_TEXT )
	   VALUES (@RinsCode, 0, @Pkid, '001', @TrnsMesgText);
	   
	   GOTO L$Loop$Users;
	   L$EndLoop$Users:
	   CLOSE [C$Users];
	   DEALLOCATE [C$Users];
	   
	   EXEC sp_xml_removedocument @docHandle;  
	   -- EndLoop
	   
	   COMMIT TRAN [T$INS_RIDM_P];
	END TRY
	BEGIN CATCH
      DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1 );
      ROLLBACK TRAN [T$INS_RIDM_P];
	END CATCH
END
GO
