CREATE TABLE [dbo].[Robot_Currency]
(
[RBCS_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [int] NULL,
[CRNC_NAME] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRNT_AMNT_DNRM] [bigint] NULL,
[MAX_AMNT_DNRM] [bigint] NULL,
[MIN_AMNT_DNRM] [bigint] NULL,
[PRCT_CHNG_DNRM] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LAST_UPDT_DNRM] [datetime] NULL,
[UPDT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RBCR]
   ON  [dbo].[Robot_Currency]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Currency T
   USING (SELECT * FROM Inserted) S
   ON (t.RBCS_CODE = s.RBCS_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END,
         T.RWNO = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Robot_Currency x WHERE s.RBCS_CODE = x.RBCS_CODE);
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
CREATE TRIGGER [dbo].[CG$AUPD_RBCR]
   ON  [dbo].[Robot_Currency]
   AFTER UPDATE   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Currency T
   USING (SELECT * FROM Inserted) S
   ON (t.RBCS_CODE = s.RBCS_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Robot_Currency] ADD CONSTRAINT [PK_RBCR] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Currency] ADD CONSTRAINT [FK_RBCR_RBCS] FOREIGN KEY ([RBCS_CODE]) REFERENCES [dbo].[Robot_Currency_Source] ([CODE]) ON DELETE CASCADE
GO
