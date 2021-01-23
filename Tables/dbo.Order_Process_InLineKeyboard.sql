CREATE TABLE [dbo].[Order_Process_InLineKeyboard]
(
[ROBO_RBID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[TRGT_ORDR_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRGT_ORDR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SLAV_ORDR_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SLAV_ORDR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SLAV_PATH] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CMND_TEXT] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_OPIL]
   ON  [dbo].[Order_Process_InLineKeyboard]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Order_Process_InLineKeyboard T
   USING (SELECT * FROM Inserted) S
   ON (t.ROBO_RBID = s.ROBO_RBID AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
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
CREATE TRIGGER [dbo].[CG$AUPD_OPIL]
   ON  [dbo].[Order_Process_InLineKeyboard]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Order_Process_InLineKeyboard T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();

END
GO
ALTER TABLE [dbo].[Order_Process_InLineKeyboard] ADD CONSTRAINT [PK_Order_Process_InLineKeyboard] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Order_Process_InLineKeyboard] ADD CONSTRAINT [FK_Order_Process_InLineKeyboard_Robot] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'اگر گزینه مربوط به درخواست ثانویه ای وجود نداشته باشد می توان از این گزینه استفاده کرد', 'SCHEMA', N'dbo', 'TABLE', N'Order_Process_InLineKeyboard', 'COLUMN', N'SLAV_PATH'
GO
