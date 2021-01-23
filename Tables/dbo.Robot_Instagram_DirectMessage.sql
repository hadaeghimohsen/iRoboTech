CREATE TABLE [dbo].[Robot_Instagram_DirectMessage]
(
[RINS_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[ACTN_DATE] [datetime] NULL,
[INST_PKID] [bigint] NULL,
[MESG_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MESG_TEXT] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LINK] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_PATH] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CORD_X] [float] NULL,
[CORD_Y] [float] NULL,
[CITY_NAME] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SEND_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RIDM]
   ON  [dbo].[Robot_Instagram_DirectMessage]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Instagram_DirectMessage T
   USING (SELECT * FROM Inserted) S
   ON (t.RINS_CODE = S.RINS_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.SEND_STAT = ISNULL(S.SEND_STAT, '005');
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
CREATE TRIGGER [dbo].[CG$AUPD_RIDM]
   ON  [dbo].[Robot_Instagram_DirectMessage]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Instagram_DirectMessage T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Robot_Instagram_DirectMessage] ADD CONSTRAINT [PK_RIDM] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Instagram_DirectMessage] ADD CONSTRAINT [FK_RIDM_RINS] FOREIGN KEY ([RINS_CODE]) REFERENCES [dbo].[Robot_Instagram] ([CODE]) ON DELETE CASCADE
GO
