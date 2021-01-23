CREATE TABLE [dbo].[Menu_Ussd]
(
[ROBO_RBID] [bigint] NOT NULL,
[MUID] [bigint] NOT NULL IDENTITY(1, 1),
[MNUS_MUID] [bigint] NULL,
[ROOT_MENU] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR] [smallint] NULL,
[USSD_CODE] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MENU_TEXT] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MNUS_DESC] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CMND_FIRE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Menu_Ussd_STAT] DEFAULT ('002'),
[STEP_BACK] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STEP_BACK_USSD_CODE] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CMND_PLAC] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ROW] [int] NULL,
[CLMN] [int] NULL,
[CMND_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UPLD_FILE_PATH] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MNUS_USSD_CODE] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXST_NUMB] [float] NULL CONSTRAINT [DF_Menu_Ussd_EXST_NUMB] DEFAULT ((0)),
[MENU_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEST_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PATH_TEXT] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CMND_TEXT] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PARM_TEXT] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[POST_EXEC] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRGR_TEXT] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DATA_TEXT_DNRM] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AINS_MNUS]
   ON  [dbo].[Menu_Ussd]
   AFTER INSERT
AS 
BEGIN
   DECLARE @Muid BIGINT, 
           @RoboRbid BIGINT,
           @Gpid BIGINT,
           @RootMenu VARCHAR(3);
   
	DECLARE C$AINS_MNUS CURSOR FOR
	   SELECT MUID, ROBO_RBID, ROOT_MENU FROM INSERTED;
	
	OPEN C$AINS_MNUS;
	Fetch_C$AINS_MNUS:
	FETCH NEXT FROM C$AINS_MNUS INTO @Muid, @RoboRbid, @RootMenu;
   

	IF @@FETCH_STATUS <> 0
	   GOTO End_C$AINS_MNUS;
	
	IF NOT EXISTS(
	   SELECT * 
	     FROM dbo.[Group]
	    WHERE ROBO_RBID = @RoboRbid
	      AND AUTO_JOIN = '002'
	)
	BEGIN		
	   INSERT INTO dbo.[Group]
	           ( ROBO_RBID ,
	             NAME ,
	             STAT ,
	             AUTO_JOIN ,
	             ADMN_ORGN
	           )
	   VALUES  ( @RoboRbid , -- ROBO_RBID - bigint
	             N'گروه عمومی' , -- NAME - nvarchar(200)
	             '002' , -- STAT - varchar(3)
	             '002' , -- AUTO_JOIN - varchar(3)
	             '001'  -- ADMN_ORGN - varchar(3)
	           );
	END;
	--ELSE
	BEGIN
	   SELECT @Gpid = GPID
	     FROM [Group]
	    WHERE Robo_Rbid = @RoboRbid
		  AND AUTO_JOIN = '002';
	   
	   PRINT @Gpid;
	END
	
	IF NOT EXISTS(
	   SELECT *
	     FROM Group_Menu_Ussd
	    WHERE GROP_GPID = @Gpid
	      AND MNUS_ROBO_RBID = @RoboRbid
	      AND MNUS_MUID = @Muid
	)
	BEGIN
	   INSERT INTO dbo.Group_Menu_Ussd
	           ( GROP_GPID ,
	             MNUS_MUID ,
	             MNUS_ROBO_RBID ,
	             STAT
	           )
	   VALUES  ( @Gpid , -- GROP_GPID - bigint
	             @Muid , -- MNUS_MUID - bigint
	             @RoboRbid , -- MNUS_ROBO_RBID - bigint
	             '002'  -- STAT - varchar(3)
	           );
	END;
	
	IF LEN(@RootMenu) <> 3 OR @RootMenu IS NULL
	   UPDATE dbo.Menu_Ussd SET ROOT_MENU = '001' WHERE MUID = @Muid AND ROBO_RBID = @RoboRbid;
	
	UPDATE dbo.Menu_Ussd
	   SET MNUS_DESC = MENU_TEXT
	      ,STEP_BACK = ISNULL(STEP_BACK, '001')
	      ,CLMN = 2
	      ,STAT = '002'
	      ,CMND_PLAC = ISNULL(CMND_PLAC, '001')
	      ,CMND_FIRE = ISNULL(CMND_FIRE, '001')
	      ,CRET_BY = UPPER(SUSER_NAME())	      
	      ,CRET_DATE = GETDATE()
	      ,CMND_TYPE = ISNULL(CMND_TYPE, '000')
	 WHERE MUID = @Muid;
	
	GOTO Fetch_C$AINS_MNUS;
	
	End_C$AINS_MNUS:
	CLOSE C$AINS_MNUS;
	DEALLOCATE C$AINS_MNUS;

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AUPD_MNUS]
   ON  [dbo].[Menu_Ussd]
   AFTER UPDATE
AS 
BEGIN
   DECLARE @Muid BIGINT, 
           @RoboRbid BIGINT,
           @Gpid BIGINT,
           @RootMenu VARCHAR(3);
           
	DECLARE C$AUPD_MNUS CURSOR FOR
	   SELECT MUID, ROBO_RBID, ROOT_MENU FROM INSERTED;
	
	OPEN C$AUPD_MNUS;
	Fetch_C$AUPD_MNUS:
	FETCH NEXT FROM C$AUPD_MNUS INTO @Muid, @RoboRbid, @RootMenu;
	
	IF @@FETCH_STATUS <> 0
	   GOTO End_C$AUPD_MNUS;
	
	IF NOT EXISTS(
	   SELECT * 
	     FROM dbo.[Group]
	    WHERE ROBO_RBID = @RoboRbid
	      AND AUTO_JOIN = '002'
	)
	BEGIN
	   INSERT INTO dbo.[Group]
	           ( ROBO_RBID ,
	             NAME ,
	             STAT ,
	             AUTO_JOIN ,
	             ADMN_ORGN
	           )
	   VALUES  ( @RoboRbid , -- ROBO_RBID - bigint
	             N'گروه عمومی' , -- NAME - nvarchar(200)
	             '002' , -- STAT - varchar(3)
	             '002' , -- AUTO_JOIN - varchar(3)
	             '001'  -- ADMN_ORGN - varchar(3)
	           );
	END;
	--ELSE
	BEGIN
	   SELECT @Gpid = GPID
	     FROM [Group]
	    WHERE Robo_Rbid = @RoboRbid
		  AND AUTO_JOIN = '002';
	END
	
	IF NOT EXISTS(
	   SELECT *
	     FROM Group_Menu_Ussd
	    WHERE /*GROP_GPID = @Gpid
	      AND*/ MNUS_ROBO_RBID = @RoboRbid
	      AND MNUS_MUID = @Muid
	)
	BEGIN
	   INSERT INTO dbo.Group_Menu_Ussd
	           ( GROP_GPID ,
	             MNUS_MUID ,
	             MNUS_ROBO_RBID ,
	             STAT
	           )
	   VALUES  ( @Gpid , -- GROP_GPID - bigint
	             @Muid , -- MNUS_MUID - bigint
	             @RoboRbid , -- MNUS_ROBO_RBID - bigint
	             '002'  -- STAT - varchar(3)
	           );
	END;
	
	IF LEN(@RootMenu) <> 3 OR @RootMenu IS NULL
      UPDATE dbo.Menu_Ussd SET CMND_TYPE = ISNULL(CMND_TYPE, '000'), ROOT_MENU = '001', MDFY_BY = UPPER(SUSER_NAME()), MDFY_DATE = GETDATE() WHERE MUID = @Muid AND ROBO_RBID = @RoboRbid;
   ELSE
      UPDATE dbo.Menu_Ussd 
         SET CMND_TYPE = ISNULL(CMND_TYPE, '000'), 
             MDFY_BY = UPPER(SUSER_NAME()), 
             MDFY_DATE = GETDATE(),
             DATA_TEXT_DNRM = CASE MENU_TYPE
                                   WHEN '001' /* KeyboardMarkup */ THEN NULL
                                   WHEN '002' /* InlineQuery */ THEN -- CASE DEST_TYPE WHEN '001' THEN N'@' WHEN '002' THEN N'.' END + N'/' + PATH_TEXT + N';' + CMND_TEXT + CASE WHEN PARM_TEXT IS NULL OR LEN(PARM_TEXT) = 0 THEN N'' ELSE N'-' END + ISNULL(PARM_TEXT, N'')                                        
                                          CASE DEST_TYPE WHEN '001' THEN N'@' WHEN '002' THEN N'.' END + N'/' + 
                                          ISNULL(PATH_TEXT, '') + N';' + 
                                          ISNULL(CMND_TEXT, '') + N'-' + 
                                          ISNULL(PARM_TEXT, N'') + N'$' + 
                                          ISNULL(POST_EXEC, '') + N'#' + 
                                          ISNULL(TRGR_TEXT, '')                                        
                              END 
       WHERE MUID = @Muid AND ROBO_RBID = @RoboRbid;

	GOTO Fetch_C$AUPD_MNUS;
	
	End_C$AUPD_MNUS:
	CLOSE C$AUPD_MNUS;
	DEALLOCATE C$AUPD_MNUS;

END
GO
ALTER TABLE [dbo].[Menu_Ussd] ADD CONSTRAINT [PK_Menu_Ussd] PRIMARY KEY CLUSTERED  ([ROBO_RBID], [MUID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Menu_Ussd] ADD CONSTRAINT [FK_MNUS_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
ALTER TABLE [dbo].[Menu_Ussd] ADD CONSTRAINT [FK_SMNU_RMNU] FOREIGN KEY ([ROBO_RBID], [MNUS_MUID]) REFERENCES [dbo].[Menu_Ussd] ([ROBO_RBID], [MUID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع اجرای دستور', 'SCHEMA', N'dbo', 'TABLE', N'Menu_Ussd', 'COLUMN', N'CMND_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'[ "@" | "." ] "/" PATH ; Command - Param
==> [ "@" | "." ] (Destination)
', 'SCHEMA', N'dbo', 'TABLE', N'Menu_Ussd', 'COLUMN', N'DEST_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'موجودی کالا', 'SCHEMA', N'dbo', 'TABLE', N'Menu_Ussd', 'COLUMN', N'EXST_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مشخص میکنیم که نوع منو به چه صورت میباشد.
KeyboardMarkup
InLineQuery', 'SCHEMA', N'dbo', 'TABLE', N'Menu_Ussd', 'COLUMN', N'MENU_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'منو ارجاعی برای نمایش فایل های ارسالی', 'SCHEMA', N'dbo', 'TABLE', N'Menu_Ussd', 'COLUMN', N'MNUS_USSD_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'این گزینه برای این میباشد که زمانی که دکمه ای را فشار میدهیم ایا همان لحظه باید اتفاق خاصی انجام شود یا خیر مثلا حذف پیام فعلی
./*0#;addcart-1$del', 'SCHEMA', N'dbo', 'TABLE', N'Menu_Ussd', 'COLUMN', N'POST_EXEC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'این گزینه برای این میباشد که بعد از اجرا دستور اصلی ما باید دستورات دیگری را آیا اجرا کنیم  یا خیر
مثلا
1 ) ./*0#;addcart-1#>>infoprod,showcart
2 ) ./*0#;addcart-1#<<infoprod,showcart
گزینه 1 به این معنا می باشد که بعد از اجرا و نمایش خروجی بعد از آن دو تابع نام برده شده را اجرا میکند که به صورت زیر میباشد.
./*0#;infoprod-1
./*0#;showcart-1
گزینه 2 به این معنا می باشد که بعد از اجرا دوتابع نام برده شده اجرا میشوند و نمایش خروجی تابع اصلی در نهایت نمایش داده میشود.', 'SCHEMA', N'dbo', 'TABLE', N'Menu_Ussd', 'COLUMN', N'TRGR_TEXT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مسیر ذخیره شدن اطلاعات ارسالی', 'SCHEMA', N'dbo', 'TABLE', N'Menu_Ussd', 'COLUMN', N'UPLD_FILE_PATH'
GO
