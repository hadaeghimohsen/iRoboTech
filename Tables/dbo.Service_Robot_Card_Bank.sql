CREATE TABLE [dbo].[Service_Robot_Card_Bank]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[RCBA_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CHAT_ID] [bigint] NULL,
[CARD_NUMB_DNRM] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CARD_NUMB_FRMT_DNRM] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHBA_NUMB_DNRM] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHBA_NUMB_FRMT_DNRM] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BANK_NAME_DNRM] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACNT_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACNT_OWNR_DNRM] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACNT_DESC_DNRM] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACNT_STAT_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[IDPY_ADRS_DNRM] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CG$AINS_SRCB]
   ON  [dbo].[Service_Robot_Card_Bank]
   AFTER INSERT
AS 
BEGIN
   -- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
	MERGE dbo.Service_Robot_Card_Bank T
	USING (SELECT * FROM Inserted) S
	ON (T.SRBT_SERV_FILE_NO = s.SRBT_SERV_FILE_NO AND 
	    t.SRBT_ROBO_RBID = s.SRBT_ROBO_RBID AND 
	    t.RCBA_CODE = s.RCBA_CODE AND 
	    t.CODE = s.CODE)
	WHEN MATCHED THEN
	   UPDATE SET 
	      t.CRET_BY = UPPER(SUSER_NAME()),
	      T.CRET_DATE = GETDATE(),
	      T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
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
CREATE TRIGGER [dbo].[CG$AUPD_SRCB]
   ON  [dbo].[Service_Robot_Card_Bank]
   AFTER UPDATE 
AS 
BEGIN

	MERGE dbo.Service_Robot_Card_Bank T
	USING (SELECT i.CODE, a.CARD_NUMB, a.CARD_NUMB_DNRM, a.BANK_NAME, a.ACNT_TYPE, a.SHBA_NUMB, a.SHBA_NUMB_DNRM, a.ACNT_OWNR, a.ACNT_DESC, a.ORDR_TYPE, a.ACNT_STAT, a.IDPY_ADRS FROM Inserted i, dbo.Robot_Card_Bank_Account a WHERE i.RCBA_CODE = a.CODE) S
	ON (t.CODE = s.CODE)
	WHEN MATCHED THEN
	   UPDATE SET 
	      t.MDFY_BY = UPPER(SUSER_NAME()),
	      T.MDFY_DATE = GETDATE(),
	      T.CARD_NUMB_DNRM = s.CARD_NUMB,
	      T.CARD_NUMB_FRMT_DNRM = s.CARD_NUMB_DNRM,
	      T.SHBA_NUMB_DNRM = s.SHBA_NUMB,
	      T.SHBA_NUMB_FRMT_DNRM = s.SHBA_NUMB_DNRM,
	      T.BANK_NAME_DNRM = s.BANK_NAME,
	      T.ACNT_TYPE_DNRM = s.ACNT_TYPE,
	      T.ACNT_OWNR_DNRM = s.ACNT_OWNR,
	      T.ACNT_DESC_DNRM = s.ACNT_DESC,
	      T.ORDR_TYPE_DNRM = s.ORDR_TYPE,
	      T.ACNT_STAT_DNRM = s.ACNT_STAT,
	      t.IDPY_ADRS_DNRM = s.IDPY_ADRS;
END
GO
ALTER TABLE [dbo].[Service_Robot_Card_Bank] ADD CONSTRAINT [PK_SRCB] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Card_Bank] ADD CONSTRAINT [FK_SRBC_ROBO] FOREIGN KEY ([SRBT_ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
ALTER TABLE [dbo].[Service_Robot_Card_Bank] ADD CONSTRAINT [FK_SRCB_RCBA] FOREIGN KEY ([RCBA_CODE]) REFERENCES [dbo].[Robot_Card_Bank_Account] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Card_Bank] ADD CONSTRAINT [FK_SRCB_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'شناسه درگاه آی دی پی', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Card_Bank', 'COLUMN', N'IDPY_ADRS_DNRM'
GO
