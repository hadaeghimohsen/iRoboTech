CREATE TABLE [dbo].[Send_Advertising]
(
[ROBO_RBID] [bigint] NULL,
[ORDR_CODE] [bigint] NULL,
[ID] [bigint] NOT NULL,
[PAKT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEXT_MESG] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_ID] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_PATH] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR] [int] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRGT_PROC_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INLN_KEYB_DNRM] [xml] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SNAD]
   ON  [dbo].[Send_Advertising]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Send_Advertising T
   USING (SELECT * FROM Inserted) S
   ON (T.ROBO_RBID = S.ROBO_RBID AND 
       T.ID = S.ID)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,T.ORDR = (SELECT ISNULL(MAX(ORDR), 0) + 1 FROM dbo.Send_Advertising WHERE ROBO_RBID = t.ROBO_RBID)
        ,ID = dbo.GNRT_NVID_U();
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
CREATE TRIGGER [dbo].[CG$AUPD_SNAD]
   ON  [dbo].[Send_Advertising]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Send_Advertising T
   USING (SELECT * FROM Inserted) S
   ON (T.ROBO_RBID = S.ROBO_RBID AND 
       T.ID = S.ID)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Send_Advertising] ADD CONSTRAINT [PK_SDAD] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Send_Advertising] ADD CONSTRAINT [FK_SDAD_ORDR] FOREIGN KEY ([ORDR_CODE]) REFERENCES [dbo].[Order] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Send_Advertising] ADD CONSTRAINT [FK_SDAD_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'نحوه مشخص کردن اطلاعات مربوط به مشتریان', 'SCHEMA', N'dbo', 'TABLE', N'Send_Advertising', 'COLUMN', N'TRGT_PROC_STAT'
GO
