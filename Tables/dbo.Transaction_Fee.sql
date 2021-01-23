CREATE TABLE [dbo].[Transaction_Fee]
(
[TFID] [bigint] NOT NULL,
[TXFE_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CALC_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TXFE_PRCT] [real] NULL,
[FROM_AMNT] [bigint] NULL,
[TO_AMNT] [bigint] NULL,
[TXFE_AMNT] [bigint] NULL,
[AMNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TXFE_DESC] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_TXFE]
   ON  [dbo].[Transaction_Fee]   
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Transaction_Fee T
   USING (SELECT * FROM Inserted) S
   ON (t.TFID = s.TFID)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()        
        ,t.TFID = CASE ISNULL(S.TFID, 0) WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.TFID END;
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
CREATE TRIGGER [dbo].[CG$AUPD_TXFE]
   ON  [dbo].[Transaction_Fee]   
   AFTER UPDATE   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Transaction_Fee T
   USING (SELECT * FROM Inserted) S
   ON (t.TFID = s.TFID)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Transaction_Fee] ADD CONSTRAINT [PK_TXFE] PRIMARY KEY CLUSTERED  ([TFID]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'نحوه محاسبه
درصدی
رنج مبلغ', 'SCHEMA', N'dbo', 'TABLE', N'Transaction_Fee', 'COLUMN', N'CALC_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اگر نوع محاسبه رنج مبلغی باشد مقدار مبلغ کارمزد محاسبه میگردد', 'SCHEMA', N'dbo', 'TABLE', N'Transaction_Fee', 'COLUMN', N'TXFE_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اگر نوع محاسبه درصد باشد مقدار درصد محاسبه را اینجا وارد میکنیم', 'SCHEMA', N'dbo', 'TABLE', N'Transaction_Fee', 'COLUMN', N'TXFE_PRCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع کارمزد تراکنش برای کارفرما یا مشتریان', 'SCHEMA', N'dbo', 'TABLE', N'Transaction_Fee', 'COLUMN', N'TXFE_TYPE'
GO
