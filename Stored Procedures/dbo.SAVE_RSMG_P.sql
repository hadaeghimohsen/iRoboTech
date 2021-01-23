SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SAVE_RSMG_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	/*
	   <Robot_Spy_Message_Group rbid="" gropcode="" chatid="" frstname="" lastname="">
	      <Message type="">	         
	         ...
	      </Message>
	   </Robot_Spy_Message_Group>
	*/
	DECLARE @Rbid BIGINT;
	DECLARE @GropCode BIGINT
	       ,@GropName NVARCHAR(250);
   DECLARE @FrstName NVARCHAR(250)
          ,@LastName NVARCHAR(250)
          ,@ChatId BIGINT
          ,@UserName VARCHAR(100)
          ,@FileNo BIGINT;
   DECLARE @MesgId BIGINT
          ,@MesgType VARCHAR(30)
          ,@MesgText NVARCHAR(MAX)
          ,@MimeType VARCHAR(30)
          ,@Lat FLOAT
          ,@Lon FLOAT 
          ,@FileId VARCHAR(200)
          ,@ContactFrstName NVARCHAR(250)
          ,@ContactLastName NVARCHAR(250)
          ,@PhonNumb VARCHAR(11)
          ,@JoinLeft VARCHAR(4);

   
   SELECT @Rbid = @X.query('Robot_Spy_Message_Group').value('(Robot_Spy_Message_Group/@rbid)[1]', 'BIGINT'),
          @GropCode = @X.query('//Group').value('(Group/@code)[1]', 'BIGINT'),
          @GropName = @X.query('//Group').value('(Group/@titl)[1]', 'NVARCHAR(250)'),
          @FrstName = @X.query('//Service').value('(Service/@frstname)[1]', 'NVARCHAR(250)'),
          @LastName = @X.query('//Service').value('(Service/@lastname)[1]', 'NVARCHAR(250)'),
          @ChatId   = @X.query('//Service').value('(Service/@id)[1]', 'BIGINT'),
          @UserName = @X.query('//Service').value('(Service/@username)[1]', 'VARCHAR(100)'),
          @MesgId   = @X.query('//Message').value('(Message/@id)[1]', 'BIGINT'),
          @MesgType = @X.query('//Message').value('(Message/@type)[1]', 'VARCHAR(30)');
   
   -- ثبت اطلاعات گروه ربات       
   IF NOT EXISTS(
      SELECT * 
        FROM dbo.Robot_Spy_Group
       WHERE ROBO_RBID = @Rbid
         AND GROP_CODE = @GropCode
   )
   BEGIN
      INSERT INTO dbo.Robot_Spy_Group
              ( ROBO_RBID, GROP_CODE, GROP_NAME )
      VALUES  ( @Rbid, -- ROBO_RBID - bigint
                @GropCode, -- GROP_CODE - bigint
                @GropName  -- GROP_NAME - nvarchar(250)
                );
   END
   
   SELECT @FileNo = FILE_NO
     FROM dbo.Service
    WHERE CHAT_ID = @ChatId;
   
   IF @FileNo IS NULL
   BEGIN
      INSERT INTO dbo.Service
              ( FILE_NO ,
                CELL_PHON ,
                FRST_NAME ,
                LAST_NAME ,
                USER_NAME ,
                CHAT_ID ,
                STAT ,
                VRFY_CODE ,
                IMAG_PROF
              )
      VALUES  ( 0 , -- FILE_NO - bigint
                NULL , -- CELL_PHON - varchar(11)
                @FrstName , -- FRST_NAME - nvarchar(100)
                @LastName , -- LAST_NAME - nvarchar(100)
                NULL , -- USER_NAME - varchar(100)
                @ChatId , -- CHAT_ID - bigint
                '002' , -- STAT - varchar(3)
                0 , -- VRFY_CODE - int
                NULL  -- IMAG_PROF - image
              );
      
      SELECT @FileNo = FILE_NO
        FROM dbo.Service
       WHERE CHAT_ID = @ChatId;
      
      INSERT INTO dbo.Service_Robot
              ( SERV_FILE_NO ,
                ROBO_RBID ,
                CHAT_ID,
                JOIN_DATE)
      VALUES  ( @FileNo , -- SERV_FILE_NO - bigint
                @Rbid , -- ROBO_RBID - bigint
                @ChatId ,
                GETDATE()
              );
   END   
   
   IF @MesgType = 'TextMessage'          
   BEGIN
      SELECT @MesgText = @X.query('//TextMessage').value('(TextMessage/@text)[1]', 'NVARCHAR(MAX)')
      INSERT INTO dbo.Robot_Spy_Group_Message
              ( RSPG_ROBO_RBID ,
                RSPG_GROP_CODE ,
                SRBT_SERV_FILE_NO,
                CODE ,
                CHAT_ID ,
                MESG_TEXT ,
                MESG_TYPE ,
                MESG_DATE ,
                MESG_ID
              )
      VALUES  ( @Rbid , -- RSPG_ROBO_RBID - bigint
                @GropCode , -- RSPG_GROP_CODE - bigint
                @FileNo ,
                0 , -- CODE - bigint
                @ChatId , -- CHAT_ID - bigint
                @MesgText , -- MESG_TEXT - nvarchar(max)
                '001',
                GETDATE() , -- MESG_DATE - datetime
                @MesgId  -- MESG_ID - bigint
              );
   END
   ELSE IF @MesgType = 'AudioMessage'
   BEGIN
      SELECT @MimeType = @X.query('//AudioMessage').value('(AudioMessage/@mimetype)[1]', 'VARCHAR(30)')
            ,@FileId = @X.query('//AudioMessage').value('(AudioMessage/@fileid)[1]', 'VARCHAR(200)')
      INSERT INTO dbo.Robot_Spy_Group_Message
              ( RSPG_ROBO_RBID ,
                RSPG_GROP_CODE ,
                SRBT_SERV_FILE_NO,
                CODE ,
                CHAT_ID ,
                FILE_ID,
                MESG_TYPE,
                MIME_TYPE,
                MESG_DATE ,
                MESG_ID
              )
      VALUES  ( @Rbid , -- RSPG_ROBO_RBID - bigint
                @GropCode , -- RSPG_GROP_CODE - bigint
                @FileNo ,
                0 , -- CODE - bigint
                @ChatId , -- CHAT_ID - bigint
                @FileId,
                '006',
                @MimeType,
                GETDATE() , -- MESG_DATE - datetime
                @MesgId  -- MESG_ID - bigint
              );
   END
   ELSE IF @MesgType = 'ContactMessage'
   BEGIN
      SELECT @ContactFrstName = @X.query('//ContactMessage').value('(ContactMessage/@frstname)[1]', 'NVARCHAR(250)')
            ,@ContactLastName = @X.query('//ContactMessage').value('(ContactMessage/@lastname)[1]', 'NVARCHAR(250)')
            ,@PhonNumb = @X.query('//ContactMessage').value('(ContactMessage/@phonnumb)[1]', 'VARCHAR(11)')
      INSERT INTO dbo.Robot_Spy_Group_Message
              ( RSPG_ROBO_RBID ,
                RSPG_GROP_CODE ,
                SRBT_SERV_FILE_NO,
                CODE ,
                CHAT_ID ,
                MESG_TYPE,
                MESG_DATE ,
                MESG_ID ,
                CONT_FRST_NAME,
                CONT_LAST_NAME,
                CONT_PHON_NUMB
              )
      VALUES  ( @Rbid , -- RSPG_ROBO_RBID - bigint
                @GropCode , -- RSPG_GROP_CODE - bigint
                @FileNo ,
                0 , -- CODE - bigint
                @ChatId , -- CHAT_ID - bigint
                '008',
                GETDATE() , -- MESG_DATE - datetime
                @MesgId,  -- MESG_ID - bigint
                @ContactFrstName,
                @ContactLastName,
                @PhonNumb
              );
   END
   ELSE IF @MesgType = 'ServiceMessage'
   BEGIN
      SELECT @ContactFrstName = @X.query('//ServiceMessage').value('(ServiceMessage/@frstname)[1]', 'NVARCHAR(250)')
            ,@ContactLastName = @X.query('//ServiceMessage').value('(ServiceMessage/@lastname)[1]', 'NVARCHAR(250)')
            ,@ChatId = @X.query('//ServiceMessage').value('(ServiceMessage/@id)[1]', 'BIGINT')
            ,@UserName = @X.query('//ServiceMessage').value('(ServiceMessage/@username)[1]', 'VARCHAR(100)')
            ,@JoinLeft = @X.query('//ServiceMessage').value('(ServiceMessage/@joinleft)[1]', 'VARCHAR(4)');
      INSERT INTO dbo.Robot_Spy_Group_Message
              ( RSPG_ROBO_RBID ,
                RSPG_GROP_CODE ,
                SRBT_SERV_FILE_NO,
                CODE ,
                CHAT_ID ,
                MESG_TYPE,
                MESG_DATE ,
                MESG_ID ,
                CONT_FRST_NAME,
                CONT_LAST_NAME,
                CONT_CHAT_ID,
                CONT_USER_NAME,
                JOIN_LEFT
              )
      VALUES  ( @Rbid , -- RSPG_ROBO_RBID - bigint
                @GropCode , -- RSPG_GROP_CODE - bigint
                @FileNo ,
                0 , -- CODE - bigint
                @ChatId , -- CHAT_ID - bigint
                '010',
                GETDATE() , -- MESG_DATE - datetime
                @MesgId,  -- MESG_ID - bigint
                @ContactFrstName,
                @ContactLastName,
                @ChatId,
                @UserName,
                @JoinLeft
              );
   END
   ELSE IF @MesgType = 'DocumentMessage'
   BEGIN
      SELECT @MimeType = @X.query('//DocumentMessage').value('(DocumentMessage/@mimetype)[1]', 'VARCHAR(30)')
            ,@FileId = @X.query('//DocumentMessage').value('(DocumentMessage/@fileid)[1]', 'VARCHAR(200)')   
      INSERT INTO dbo.Robot_Spy_Group_Message
              ( RSPG_ROBO_RBID ,
                RSPG_GROP_CODE ,
                SRBT_SERV_FILE_NO,
                CODE ,
                CHAT_ID ,
                FILE_ID,
                MESG_TYPE,
                MIME_TYPE,
                MESG_DATE ,
                MESG_ID
              )
      VALUES  ( @Rbid , -- RSPG_ROBO_RBID - bigint
                @GropCode , -- RSPG_GROP_CODE - bigint
                @FileNo ,
                0 , -- CODE - bigint
                @ChatId , -- CHAT_ID - bigint
                @FileId,
                '004',
                @MimeType,
                GETDATE() , -- MESG_DATE - datetime
                @MesgId  -- MESG_ID - bigint
              );
   END 
   ELSE IF @MesgType = 'LocationMessage'
   BEGIN
      SELECT @Lat = @X.query('//LocationMessage').value('(LocationMessage/@latitude)[1]', 'FLOAT')
            ,@Lon = @X.query('//LocationMessage').value('(LocationMessage/@longitude)[1]', 'FLOAT')
      INSERT INTO dbo.Robot_Spy_Group_Message
              ( RSPG_ROBO_RBID ,
                RSPG_GROP_CODE ,
                SRBT_SERV_FILE_NO,
                CODE ,
                CHAT_ID ,
                MESG_TYPE,
                MESG_DATE ,
                MESG_ID,
                LAT,
                LON
              )
      VALUES  ( @Rbid , -- RSPG_ROBO_RBID - bigint
                @GropCode , -- RSPG_GROP_CODE - bigint
                @FileNo ,
                0 , -- CODE - bigint
                @ChatId , -- CHAT_ID - bigint
                '005',
                GETDATE() , -- MESG_DATE - datetime
                @MesgId,  -- MESG_ID - bigint
                @Lat,
                @Lon                
              );
   END
   ELSE IF @MesgType = 'PhotoMessage'
   BEGIN
      SELECT @MesgText = @X.query('//PhotoMessage').value('(PhotoMessage/@caption)[1]', 'NVARCHAR(MAX)')
            ,@FileId = @X.query('//PhotoMessage').value('(PhotoMessage/@fileid)[1]', 'VARCHAR(200)')   
      INSERT INTO dbo.Robot_Spy_Group_Message
              ( RSPG_ROBO_RBID ,
                RSPG_GROP_CODE ,
                SRBT_SERV_FILE_NO,
                CODE ,
                CHAT_ID ,
                FILE_ID,
                MESG_TYPE,
                MIME_TYPE,
                MESG_DATE ,
                MESG_ID
              )
      VALUES  ( @Rbid , -- RSPG_ROBO_RBID - bigint
                @GropCode , -- RSPG_GROP_CODE - bigint
                @FileNo ,
                0 , -- CODE - bigint
                @ChatId , -- CHAT_ID - bigint
                @FileId,
                '002',
                @MimeType,
                GETDATE() , -- MESG_DATE - datetime
                @MesgId  -- MESG_ID - bigint
              );      
   END
   ELSE IF @MesgType = 'StickerMessage'
   BEGIN
      SELECT @MesgText = @X.query('//StickerMessage').value('(StickerMessage/@emoji)[1]', 'NVARCHAR(MAX)')
            ,@FileId = @X.query('//StickerMessage').value('(StickerMessage/@fileid)[1]', 'VARCHAR(200)')   
      INSERT INTO dbo.Robot_Spy_Group_Message
              ( RSPG_ROBO_RBID ,
                RSPG_GROP_CODE ,
                SRBT_SERV_FILE_NO,
                CODE ,
                CHAT_ID ,
                FILE_ID,
                MESG_TYPE,
                MESG_TEXT,
                MESG_DATE ,
                MESG_ID
              )
      VALUES  ( @Rbid , -- RSPG_ROBO_RBID - bigint
                @GropCode , -- RSPG_GROP_CODE - bigint
                @FileNo ,
                0 , -- CODE - bigint
                @ChatId , -- CHAT_ID - bigint
                @FileId,
                '002',
                @MesgText,
                GETDATE() , -- MESG_DATE - datetime
                @MesgId  -- MESG_ID - bigint
              );      
   END
   ELSE IF @MesgType = 'VideoMessage'
   BEGIN
      SELECT @MimeType = @X.query('//VideoMessage').value('(VideoMessage/@mimetype)[1]', 'VARCHAR(30)')
            ,@FileId = @X.query('//VideoMessage').value('(VideoMessage/@fileid)[1]', 'VARCHAR(200)')         
      INSERT INTO dbo.Robot_Spy_Group_Message
              ( RSPG_ROBO_RBID ,
                RSPG_GROP_CODE ,
                SRBT_SERV_FILE_NO,
                CODE ,
                CHAT_ID ,
                FILE_ID,
                MESG_TYPE,
                MIME_TYPE,
                MESG_DATE ,
                MESG_ID
              )
      VALUES  ( @Rbid , -- RSPG_ROBO_RBID - bigint
                @GropCode , -- RSPG_GROP_CODE - bigint
                @FileNo ,
                0 , -- CODE - bigint
                @ChatId , -- CHAT_ID - bigint
                @FileId,
                '003',
                @MimeType,
                GETDATE() , -- MESG_DATE - datetime
                @MesgId  -- MESG_ID - bigint
              );            
      
   END
   ELSE IF @MesgType = 'VoiceMessage'
   BEGIN
      SELECT @MimeType = @X.query('//VideoMessage').value('(VideoMessage/@mimetype)[1]', 'VARCHAR(30)')
            ,@FileId = @X.query('//VideoMessage').value('(VideoMessage/@fileid)[1]', 'VARCHAR(200)')            
      
      INSERT INTO dbo.Robot_Spy_Group_Message
              ( RSPG_ROBO_RBID ,
                RSPG_GROP_CODE ,
                SRBT_SERV_FILE_NO,
                CODE ,
                CHAT_ID ,
                FILE_ID,
                MESG_TYPE,
                MIME_TYPE,
                MESG_DATE ,
                MESG_ID
              )
      VALUES  ( @Rbid , -- RSPG_ROBO_RBID - bigint
                @GropCode , -- RSPG_GROP_CODE - bigint
                @FileNo ,
                0 , -- CODE - bigint
                @ChatId , -- CHAT_ID - bigint
                @FileId,
                '009',
                @MimeType,
                GETDATE() , -- MESG_DATE - datetime
                @MesgId  -- MESG_ID - bigint
              );                  
   END
   
	
	RETURN 0;
END
GO
