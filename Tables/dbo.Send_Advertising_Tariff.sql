CREATE TABLE [dbo].[Send_Advertising_Tariff]
(
[ROBO_RBID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[PAKT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AMNT] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SATF]
   ON  [dbo].[Send_Advertising_Tariff]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   IF (SELECT COUNT(a.CODE) FROM dbo.Send_Advertising_Tariff a, Inserted b WHERE a.ROBO_RBID = b.ROBO_RBID AND a.PAKT_TYPE = b.PAKT_TYPE) >= 2
   BEGIN
      RAISERROR(N'تعرفه وارد شده تکراری می باشد، لطفا نوع تعرفه خود را اصلاح کنید', 16, 1);
      RETURN;
   END 
   
   -- Insert statements for trigger here
   MERGE dbo.Send_Advertising_Tariff T
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
CREATE TRIGGER [dbo].[CG$AUPD_SATF]
   ON  [dbo].[Send_Advertising_Tariff]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   IF (SELECT COUNT(a.CODE) FROM dbo.Send_Advertising_Tariff a, Inserted b WHERE a.ROBO_RBID = b.ROBO_RBID AND a.PAKT_TYPE = b.PAKT_TYPE) >= 2
   BEGIN
      RAISERROR(N'تعرفه وارد شده تکراری می باشد، لطفا نوع تعرفه خود را اصلاح کنید', 16, 1);
      RETURN;
   END 
   
   -- Insert statements for trigger here
   MERGE dbo.Send_Advertising_Tariff T
   USING (SELECT * FROM Inserted) S
   ON (t.ROBO_RBID = s.ROBO_RBID AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Send_Advertising_Tariff] ADD CONSTRAINT [PK_SATF] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Send_Advertising_Tariff] ADD CONSTRAINT [FK_SATF_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
