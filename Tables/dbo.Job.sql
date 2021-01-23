CREATE TABLE [dbo].[Job]
(
[ROBO_RBID] [bigint] NOT NULL,
[CODE] [bigint] NOT NULL IDENTITY(1, 1),
[ORDR_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[JOB_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IS_FRST_FIRE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_JOB]
   ON  [dbo].[Job]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    MERGE dbo.Job T
    USING (SELECT * FROM Inserted) S
    ON (T.ROBO_RBID = S.ROBO_RBID AND
        T.CODE = S.CODE)
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
CREATE TRIGGER [dbo].[CG$AUPD_JOB]
   ON  [dbo].[Job]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    MERGE dbo.Job T
    USING (SELECT * FROM Inserted) S
    ON (T.ROBO_RBID = S.ROBO_RBID AND
        T.CODE = S.CODE)
    WHEN MATCHED THEN
      UPDATE SET
            T.MDFY_BY = UPPER(SUSER_NAME())
           ,T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Job] ADD CONSTRAINT [PK_Job] PRIMARY KEY CLUSTERED  ([ROBO_RBID], [CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Job] ADD CONSTRAINT [FK_Job_Robot] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
