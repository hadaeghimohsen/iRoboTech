CREATE TABLE [dbo].[Group_Header]
(
[GHID] [bigint] NOT NULL IDENTITY(1, 1),
[GRPH_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ROBO_RBID] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_GPHD]
   ON  [dbo].[Group_Header]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    MERGE dbo.Group_Header T
    USING (SELECT * FROM Inserted) S
    ON (t.GHID = s.GHID)
    WHEN MATCHED THEN
		UPDATE SET
			T.CRET_BY = UPPER(SUSER_NAME())
		   ,T.CRET_DATE = GETDATE();
    
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
CREATE TRIGGER [dbo].[CG$AUPD_GPHD]
   ON  [dbo].[Group_Header]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    MERGE dbo.Group_Header T
    USING (SELECT * FROM Inserted) S
    ON (t.GHID = s.GHID)
    WHEN MATCHED THEN
		UPDATE SET
			T.MDFY_BY = UPPER(SUSER_NAME())
		   ,T.MDFY_DATE = GETDATE();
    
END
GO
ALTER TABLE [dbo].[Group_Header] ADD CONSTRAINT [PK_GPHD] PRIMARY KEY CLUSTERED  ([GHID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Group_Header] ADD CONSTRAINT [FK_GPHD_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'گروه های مربوط به ربات', 'SCHEMA', N'dbo', 'TABLE', N'Group_Header', 'COLUMN', N'ROBO_RBID'
GO
