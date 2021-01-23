CREATE TABLE [dbo].[Robot_Credit_Detial]
(
[RCRD_CRID] [bigint] NULL,
[CDID] [bigint] NOT NULL,
[CHAT_ID] [bigint] NULL,
[ORDR_CODE] [bigint] NULL,
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[AMNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRDT_AMNT] [bigint] NULL,
[CRDT_DATE] [datetime] NULL,
[VALD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RCDT]
   ON  [dbo].[Robot_Credit_Detial]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Credit_Detial T
   USING (SELECT * FROM Inserted) S
   ON (t.RCRD_CRID = s.RCRD_CRID AND 
       t.CDID = s.CDID)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,T.CDID = CASE s.CDID WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CDID END;
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
CREATE TRIGGER [dbo].[CG$AUPD_RCDT]
   ON  [dbo].[Robot_Credit_Detial]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Credit_Detial T
   USING (SELECT * FROM Inserted) S
   ON (t.RCRD_CRID = s.RCRD_CRID AND 
       t.CDID = s.CDID)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE()
        ,T.SRBT_SERV_FILE_NO = (
           SELECT sr.SERV_FILE_NO
             FROM dbo.Service_Robot sr, dbo.Robot_Credit rc
            WHERE sr.CHAT_ID = s.CHAT_ID
              AND rc.CRID = s.RCRD_CRID
              AND sr.ROBO_RBID = rc.ROBO_RBID )
        ,T.SRBT_ROBO_RBID = (
           SELECT sr.ROBO_RBID
             FROM dbo.Service_Robot sr, dbo.Robot_Credit rc
            WHERE sr.CHAT_ID = s.CHAT_ID
              AND rc.CRID = s.RCRD_CRID
              AND sr.ROBO_RBID = rc.ROBO_RBID );
END
GO
ALTER TABLE [dbo].[Robot_Credit_Detial] ADD CONSTRAINT [PK_RCDT] PRIMARY KEY CLUSTERED  ([CDID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Credit_Detial] ADD CONSTRAINT [FK_RCDT_ORDR] FOREIGN KEY ([ORDR_CODE]) REFERENCES [dbo].[Order] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Robot_Credit_Detial] ADD CONSTRAINT [FK_RCDT_RCRD] FOREIGN KEY ([RCRD_CRID]) REFERENCES [dbo].[Robot_Credit] ([CRID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Robot_Credit_Detial] ADD CONSTRAINT [FK_RCDT_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'برای واریز مبلغ های شارژ شرکت هم باید درخواستی در جدول درخواستها ثبت شود', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Credit_Detial', 'COLUMN', N'ORDR_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'معتبر بودن رکورد پرداخت شده', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Credit_Detial', 'COLUMN', N'VALD_TYPE'
GO
