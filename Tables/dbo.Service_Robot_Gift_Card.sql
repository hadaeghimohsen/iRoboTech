CREATE TABLE [dbo].[Service_Robot_Gift_Card]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[ORDR_CODE] [bigint] NULL,
[GCID] [bigint] NOT NULL,
[GIFC_GCID] [bigint] NULL,
[CHAT_ID] [bigint] NULL,
[CARD_NUMB] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AMNT] [bigint] NULL,
[BLNC_AMNT_DNRM] [bigint] NULL,
[VALD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_ID] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GIFT_TEXT] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEMP_AMNT_USE] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SRGC]
   ON  [dbo].[Service_Robot_Gift_Card]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Gift_Card T
   USING (SELECT * FROM Inserted) S
   ON (t.SRBT_SERV_FILE_NO = s.SRBT_SERV_FILE_NO AND 
       t.SRBT_ROBO_RBID = S.SRBT_ROBO_RBID AND 
       t.GCID = s.GCID)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.GCID = CASE s.GCID WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.GCID END,
         T.CHAT_ID = (
            SELECT sr.CHAT_ID
              FROM dbo.Service_Robot sr
             WHERE sr.SERV_FILE_NO = s.SRBT_SERV_FILE_NO
               AND sr.ROBO_RBID = s.SRBT_ROBO_RBID
         );
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
CREATE TRIGGER [dbo].[CG$AUPD_SRGC]
   ON  [dbo].[Service_Robot_Gift_Card]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Gift_Card T
   USING (SELECT * FROM Inserted) S
   ON (t.GCID = s.GCID)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Service_Robot_Gift_Card] ADD CONSTRAINT [PK_SRGC] PRIMARY KEY CLUSTERED  ([GCID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Gift_Card] ADD CONSTRAINT [FK_SRGC_ORDR] FOREIGN KEY ([ORDR_CODE]) REFERENCES [dbo].[Order] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Gift_Card] ADD CONSTRAINT [FK_SRGC_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Gift_Card] ADD CONSTRAINT [FK_SRGC_SRGC] FOREIGN KEY ([GIFC_GCID]) REFERENCES [dbo].[Service_Robot_Gift_Card] ([GCID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ کارت هدیه', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Gift_Card', 'COLUMN', N'AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ باقیمانده از کارت هدیه', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Gift_Card', 'COLUMN', N'BLNC_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره کارت هدیه', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Gift_Card', 'COLUMN', N'CARD_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ استفاده شده درون یک سفارش به صورت موقت', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Gift_Card', 'COLUMN', N'TEMP_AMNT_USE'
GO
