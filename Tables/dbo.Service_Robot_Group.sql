CREATE TABLE [dbo].[Service_Robot_Group]
(
[SRBT_SERV_FILE_NO] [bigint] NOT NULL,
[SRBT_ROBO_RBID] [bigint] NOT NULL,
[GROP_GPID] [bigint] NOT NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Service_Robot_Group_STAT] DEFAULT ('002'),
[DFLT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[CHAT_ID] [bigint] NULL
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
CREATE TRIGGER [dbo].[CG$AINS_SRGP]
   ON  [dbo].[Service_Robot_Group]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Group T
   USING (SELECT * FROM Inserted ) S
   ON (T.GROP_GPID = S.GROP_GPID  AND
       T.SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO AND
       T.SRBT_ROBO_RBID = S.SRBT_ROBO_RBID
   )
   WHEN MATCHED THEN
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME())
        ,t.CRET_DATE = GETDATE()
        ,t.CHAT_ID = (
           SELECT sr.CHAT_ID
             FROM dbo.Service_Robot sr
            WHERE sr.SERV_FILE_NO = s.SRBT_SERV_FILE_NO
              AND sr.ROBO_RBID = s.SRBT_ROBO_RBID
        );
   
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
CREATE TRIGGER [dbo].[CG$AUPD_SRGP]
   ON  [dbo].[Service_Robot_Group]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Group T
   USING (SELECT * FROM Inserted ) S
   ON (T.GROP_GPID = S.GROP_GPID  AND
       T.SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO AND
       T.SRBT_ROBO_RBID = S.SRBT_ROBO_RBID
   )
   WHEN MATCHED THEN
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,t.MDFY_DATE = GETDATE();
   
END
GO
ALTER TABLE [dbo].[Service_Robot_Group] ADD CONSTRAINT [PK_SRGP] PRIMARY KEY CLUSTERED  ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID], [GROP_GPID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Group] ADD CONSTRAINT [SRGP_GROP_FK] FOREIGN KEY ([GROP_GPID]) REFERENCES [dbo].[Group] ([GPID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Group] ADD CONSTRAINT [SRGP_SRBT_FK] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'دسترسی پیش فرض
این گزینه در حال حاضر برای خرید مشتریان اضافه شده
که بتوانیم برای دسته بنده مشتریان و قیمت های مختلفی که برای انها مشخص کرده ایم را ارائه دهیم
مثلا مشتریان عادی، همکاران فروش، ...', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Group', 'COLUMN', N'DFLT_STAT'
GO
