CREATE TABLE [dbo].[App_Base_Define]
(
[CODE] [bigint] NOT NULL,
[RWNO] [int] NULL,
[TITL_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ENTY_NAME] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REF_CODE] [bigint] NULL,
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
create TRIGGER [dbo].[CG$AINS_APBS]
   ON  [dbo].[App_Base_Define]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.App_Base_Define T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET T.CRET_BY = UPPER(SUSER_NAME())
            ,T.CRET_DATE = GETDATE()
            ,T.CODE = dbo.GNRT_NVID_U();

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
create TRIGGER [dbo].[CG$UPD_APBS]
   ON  [dbo].[App_Base_Define]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.App_Base_Define T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET T.MDFY_BY = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[App_Base_Define] ADD CONSTRAINT [PK_APBS] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[App_Base_Define] ADD CONSTRAINT [FK_RAPB_APBS] FOREIGN KEY ([REF_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'ترتیب', 'SCHEMA', N'dbo', 'TABLE', N'App_Base_Define', 'COLUMN', N'RWNO'
GO
