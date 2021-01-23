CREATE TABLE [dbo].[Robot_Credit]
(
[ROBO_RBID] [bigint] NULL,
[CRID] [bigint] NOT NULL,
[SUB_SYS] [int] NULL,
[CRDT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AMNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ALRM_MIN_CRDT_AMNT] [bigint] NULL,
[CRDT_AMNT_DNRM] [bigint] NULL,
[LAST_DPST_CRDT_AMNT_DNRM] [bigint] NULL,
[LAST_DPST_CRDT_DATE_DNRM] [datetime] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RCRD]
   ON  [dbo].[Robot_Credit]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Credit T
   USING (SELECT * FROM Inserted) S
   ON (T.ROBO_RBID = S.ROBO_RBID AND
       T.CRID = s.CRID)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,T.CRID = CASE s.CRID WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CRID END;
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
CREATE TRIGGER [dbo].[CG$AUPD_RCRD]
   ON  [dbo].[Robot_Credit]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Credit T
   USING (SELECT * FROM Inserted) S
   ON (T.ROBO_RBID = S.ROBO_RBID AND
       T.CRID = s.CRID)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE();
        
END
GO
ALTER TABLE [dbo].[Robot_Credit] ADD CONSTRAINT [PK_RCRD] PRIMARY KEY CLUSTERED  ([CRID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Credit] ADD CONSTRAINT [FK_RCRD_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداقل موجودی شارژ باقیمانده', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Credit', 'COLUMN', N'ALRM_MIN_CRDT_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع واحد مبلغ', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Credit', 'COLUMN', N'AMNT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ شارژ/اعتبار باقیمانده', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Credit', 'COLUMN', N'CRDT_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع اعتباری که می خوایم لحاظ کنیم
اعتبار شارژ تراکنش ها
اعتبار پشتیبانی سالیانه', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Credit', 'COLUMN', N'CRDT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اخرین مبلغ شارژ انجام شده', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Credit', 'COLUMN', N'LAST_DPST_CRDT_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آخرین تاریخ شارژ انجام شده', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Credit', 'COLUMN', N'LAST_DPST_CRDT_DATE_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'این اعتبار برای کدام زیر سیستم لحاظ میشود', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Credit', 'COLUMN', N'SUB_SYS'
GO
