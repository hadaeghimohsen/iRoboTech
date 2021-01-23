CREATE TABLE [dbo].[Robot_Import]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[ROBO_RBID] [bigint] NULL CONSTRAINT [DF_Robot_Import_ROBO_RBID] DEFAULT ([dbo].[Gnrt_nvid_u]()),
[TEXT_TYPE] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SNDR] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEXT_TITL] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEXT_ANSR] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHNL_URL] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RBKN]
   ON  [dbo].[Robot_Import]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Robot_Import T
   USING(SELECT * FROM INSERTED) S
   ON (T.ROBO_RBID = S.ROBO_RBID 
   AND T.ID = S.ID)
   WHEN MATCHED THEN
      UPDATE SET
         CRET_BY = UPPER(SUSER_NAME())
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
CREATE TRIGGER [dbo].[CG$AUPD_RBKN]
   ON  [dbo].[Robot_Import]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Robot_Import T
   USING(SELECT * FROM INSERTED) S
   ON (T.ROBO_RBID = S.ROBO_RBID 
   AND T.ID = S.ID)
   WHEN MATCHED THEN
      UPDATE SET
         MDFY_BY = UPPER(SUSER_NAME())
        ,MDFY_DATE = GETDATE();
   
   
END
GO
ALTER TABLE [dbo].[Robot_Import] ADD CONSTRAINT [PK_Robot_Import] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Import] ADD CONSTRAINT [FK_Robot_Import_Robot] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
