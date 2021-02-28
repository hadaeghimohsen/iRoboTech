CREATE TABLE [dbo].[Robot_External_Query]
(
[ROBO_RBID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[REDQ_NAME] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MAP_TABL_NAME] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DATA_SORC_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ROW_PROC_SEND_TO_SRVR] [int] NULL,
[INS_EXEC_WITH] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UPD_EXEC_WITH] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEL_EXEC_WITH] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QURY_STMT] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[ACNT_APP_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CG$AINS_REXQ]
   ON  [dbo].[Robot_External_Query]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   MERGE dbo.Robot_External_Query T
   USING (SELECT * FROM Inserted) S
   ON (T.ROBO_RBID = S.ROBO_RBID AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         t.CODE = CASE ISNULL(s.CODE, 0) WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;

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
CREATE TRIGGER [dbo].[CG$AUPD_REXQ]
   ON  [dbo].[Robot_External_Query]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   MERGE dbo.Robot_External_Query T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Robot_External_Query] ADD CONSTRAINT [PK_Robot_External_Datasource_Query] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_External_Query] ADD CONSTRAINT [FK_REXQ_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'نام نرم افزار حسابداری', 'SCHEMA', N'dbo', 'TABLE', N'Robot_External_Query', 'COLUMN', N'ACNT_APP_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع پول ارتباطی
Connection String Local Server Or Web Server', 'SCHEMA', N'dbo', 'TABLE', N'Robot_External_Query', 'COLUMN', N'DATA_SORC_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Execute With StoreProcedure For Save', 'SCHEMA', N'dbo', 'TABLE', N'Robot_External_Query', 'COLUMN', N'INS_EXEC_WITH'
GO
EXEC sp_addextendedproperty N'MS_Description', N'در نهایت این خروجی بر روی کدام جدول نقش بازی میکند
مثلا جدول کالا ها
Robot_Product', 'SCHEMA', N'dbo', 'TABLE', N'Robot_External_Query', 'COLUMN', N'MAP_TABL_NAME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد ردیف هایی قابل پردازش سمت سرور', 'SCHEMA', N'dbo', 'TABLE', N'Robot_External_Query', 'COLUMN', N'ROW_PROC_SEND_TO_SRVR'
GO
