CREATE TABLE [dbo].[Group_Menu_Ussd]
(
[GROP_GPID] [bigint] NOT NULL,
[MNUS_MUID] [bigint] NOT NULL,
[MNUS_ROBO_RBID] [bigint] NOT NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Group_Menu_Ussd_STAT] DEFAULT ('002'),
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
CREATE TRIGGER [dbo].[CG$AINS_GRMU]
   ON  [dbo].[Group_Menu_Ussd]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Group_Menu_Ussd T
   USING (SELECT * FROM Inserted ) S
   ON (T.GROP_GPID = S.GROP_GPID  AND
       T.MNUS_MUID = s.MNUS_MUID AND
       T.MNUS_ROBO_RBID = s.MNUS_ROBO_RBID
   )
   WHEN MATCHED THEN
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME())
        ,t.CRET_DATE = GETDATE();
   
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
CREATE TRIGGER [dbo].[CG$AUPD_GRMU]
   ON  [dbo].[Group_Menu_Ussd]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Group_Menu_Ussd T
   USING (SELECT * FROM Inserted ) S
   ON (T.GROP_GPID = S.GROP_GPID  AND
       T.MNUS_MUID = s.MNUS_MUID AND
       T.MNUS_ROBO_RBID = s.MNUS_ROBO_RBID
   )
   WHEN MATCHED THEN
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,t.MDFY_DATE = GETDATE();
   
END
GO
ALTER TABLE [dbo].[Group_Menu_Ussd] ADD CONSTRAINT [PK_GRMU] PRIMARY KEY CLUSTERED  ([GROP_GPID], [MNUS_MUID], [MNUS_ROBO_RBID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Group_Menu_Ussd] WITH NOCHECK ADD CONSTRAINT [FK_GRMU_MNUS] FOREIGN KEY ([MNUS_ROBO_RBID], [MNUS_MUID]) REFERENCES [dbo].[Menu_Ussd] ([ROBO_RBID], [MUID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Group_Menu_Ussd] ADD CONSTRAINT [GRMU_GROP_FK] FOREIGN KEY ([GROP_GPID]) REFERENCES [dbo].[Group] ([GPID]) ON DELETE CASCADE
GO
