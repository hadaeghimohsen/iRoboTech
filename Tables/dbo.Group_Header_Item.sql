CREATE TABLE [dbo].[Group_Header_Item]
(
[GPHD_GHID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[GHDT_DESC] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRIC] [bigint] NULL,
[TAX_PRCT] [int] NULL,
[AMNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UNIT_APBS_CODE] [bigint] NULL,
[SCND_NUMB] [smallint] NULL,
[MINT_NUMB] [smallint] NULL,
[HORS_NUMB] [smallint] NULL,
[DAYS_NUMB] [smallint] NULL,
[MONT_NUMB] [smallint] NULL,
[YEAR_NUMB] [smallint] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COEF_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GRMU_GROP_GPID] [bigint] NULL,
[GRMU_MNUS_ROBO_RBID] [bigint] NULL,
[GRMU_MNUS_MUID] [bigint] NULL,
[USSD_CODE_DNRM] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_GHIT]
   ON  [dbo].[Group_Header_Item]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Group_Header_Item T
   USING (SELECT * FROM Inserted) S
   ON (T.GPHD_GHID = S.GPHD_GHID AND
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,t.CODE = dbo.GNRT_NVID_U();
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
CREATE TRIGGER [dbo].[CG$AUPD_GHIT]
   ON  [dbo].[Group_Header_Item]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Group_Header_Item T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE()
        ,T.USSD_CODE_DNRM = (SELECT m.USSD_CODE FROM dbo.Menu_Ussd m WHERE m.ROBO_RBID = s.GRMU_MNUS_ROBO_RBID AND m.MUID = s.GRMU_MNUS_MUID);
END
GO
ALTER TABLE [dbo].[Group_Header_Item] ADD CONSTRAINT [PK_GHIT] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Group_Header_Item] ADD CONSTRAINT [FK_GHIT_APBS] FOREIGN KEY ([UNIT_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Group_Header_Item] ADD CONSTRAINT [FK_GHIT_GPHD] FOREIGN KEY ([GPHD_GHID]) REFERENCES [dbo].[Group_Header] ([GHID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Group_Header_Item] ADD CONSTRAINT [FK_GHIT_GRMU] FOREIGN KEY ([GRMU_GROP_GPID], [GRMU_MNUS_MUID], [GRMU_MNUS_ROBO_RBID]) REFERENCES [dbo].[Group_Menu_Ussd] ([GROP_GPID], [MNUS_MUID], [MNUS_ROBO_RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'واحد مالی
ریال 
تومان
بیت کوین
اتریوم
...', 'SCHEMA', N'dbo', 'TABLE', N'Group_Header_Item', 'COLUMN', N'AMNT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مالیات بر ارزش افزوده', 'SCHEMA', N'dbo', 'TABLE', N'Group_Header_Item', 'COLUMN', N'TAX_PRCT'
GO
