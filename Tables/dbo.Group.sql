CREATE TABLE [dbo].[Group]
(
[GPID] [bigint] NOT NULL IDENTITY(1, 1),
[ROBO_RBID] [bigint] NULL,
[NAME] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Group_STAT] DEFAULT ('002'),
[AUTO_JOIN] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADMN_ORGN] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OFF_PRCT] [int] NULL,
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
create TRIGGER [dbo].[CG$AINS_GROP]
   ON  [dbo].[Group]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.[Group] T
   USING (SELECT * FROM Inserted ) S
   ON (T.GPID = S.GPID
   AND T.ROBO_RBID = S.ROBO_RBID
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
create TRIGGER [dbo].[CG$AUPD_GROP]
   ON  [dbo].[Group]
   AFTER UPDATE 
AS  
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.[Group] T
   USING (SELECT * FROM Inserted ) S
   ON (T.GPID = S.GPID
   AND T.ROBO_RBID = S.ROBO_RBID
   )
   WHEN MATCHED THEN
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,t.MDFY_DATE = GETDATE();
   
END
GO
ALTER TABLE [dbo].[Group] ADD CONSTRAINT [PK_GROP] PRIMARY KEY CLUSTERED  ([GPID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Group_GPID] ON [dbo].[Group] ([GPID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Group] ADD CONSTRAINT [FK_GROP_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'درصد تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Group', 'COLUMN', N'OFF_PRCT'
GO
