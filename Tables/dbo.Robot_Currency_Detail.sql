CREATE TABLE [dbo].[Robot_Currency_Detail]
(
[RBCR_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [bigint] NULL,
[CRNT_AMNT] [bigint] NULL,
[MAX_AMNT] [bigint] NULL,
[MIN_AMNT] [bigint] NULL,
[PRCT_CHNG] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LAST_UPDT] [datetime] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RBCD]
   ON  [dbo].[Robot_Currency_Detail]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Currency_Detail T
   USING (SELECT * FROM Inserted) S
   ON (t.RBCR_CODE = s.RBCR_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE S.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END,
         T.LAST_UPDT = GETDATE(),
         T.RWNO = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Robot_Currency_Detail x WHERE s.RBCR_CODE = x.RBCR_CODE);;
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
CREATE TRIGGER [dbo].[CG$AUPD_RBCD]
   ON  [dbo].[Robot_Currency_Detail]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Currency_Detail T
   USING (SELECT * FROM Inserted) S
   ON (t.RBCR_CODE = s.RBCR_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
   
   -- بروزرسانی آخرین قیمت ثبت شده
   MERGE dbo.Robot_Currency T
   USING (
            SELECT a.CRNT_AMNT, a.MAX_AMNT, a.MIN_AMNT, a.PRCT_CHNG, a.LAST_UPDT , a.RBCR_CODE
              FROM dbo.Robot_Currency_Detail a, Inserted i
             WHERE a.RBCR_CODE = i.RBCR_CODE
               AND a.LAST_UPDT = (
                     SELECT MAX(b.LAST_UPDT)
                       FROM dbo.Robot_Currency_Detail b
                      WHERE b.RBCR_CODE = a.RBCR_CODE
                   )
         ) S
   ON (t.CODE = s.RBCR_CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRNT_AMNT_DNRM = s.CRNT_AMNT,
         T.MAX_AMNT_DNRM = s.MAX_AMNT,
         T.MIN_AMNT_DNRM = S.MIN_AMNT,
         T.PRCT_CHNG_DNRM = S.PRCT_CHNG,
         T.LAST_UPDT_DNRM = S.LAST_UPDT;
END
GO
ALTER TABLE [dbo].[Robot_Currency_Detail] ADD CONSTRAINT [PK_RBCD] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Currency_Detail] ADD CONSTRAINT [FK_RBCD_RBCR] FOREIGN KEY ([RBCR_CODE]) REFERENCES [dbo].[Robot_Currency] ([CODE]) ON DELETE CASCADE
GO
