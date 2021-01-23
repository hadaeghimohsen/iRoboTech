CREATE TABLE [dbo].[Service_Robot_Seller_Competitor]
(
[SRSP_CODE] [bigint] NULL,
[SRSC_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[SLER_CHAT_ID] [bigint] NULL,
[COMP_CHAT_ID] [bigint] NULL,
[SLER_TARF_CODE_] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COMP_TARF_CODE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SRSC]
   ON  [dbo].[Service_Robot_Seller_Competitor]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Seller_Competitor T
   USING (SELECT * FROM Inserted) S
   ON (t.SRSP_CODE = s.SRSP_CODE AND 
       t.SRSC_CODE = s.SRSC_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.SLER_CHAT_ID = (SELECT srs.CHAT_ID FROM dbo.Service_Robot_Seller srs WHERE s.SRSP_CODE = srs.CODE),
         T.COMP_CHAT_ID = (SELECT srs.CHAT_ID FROM dbo.Service_Robot_Seller srs WHERE s.SRSC_CODE = srs.CODE);
         
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
CREATE TRIGGER [dbo].[CG$AUPD_SRSC]
   ON  [dbo].[Service_Robot_Seller_Competitor]
   AFTER UPDATE   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Seller_Competitor T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Service_Robot_Seller_Competitor] ADD CONSTRAINT [PK_SRSC] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Seller_Competitor] ADD CONSTRAINT [FK_Service_Robot_Seller_Competitor_Service_Robot_Seller_Product] FOREIGN KEY ([SRSP_CODE]) REFERENCES [dbo].[Service_Robot_Seller_Product] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Seller_Competitor] ADD CONSTRAINT [FK_Service_Robot_Seller_Competitor_Service_Robot_Seller_Product1] FOREIGN KEY ([SRSC_CODE]) REFERENCES [dbo].[Service_Robot_Seller_Product] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد کالای رقیب', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Competitor', 'COLUMN', N'COMP_TARF_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد کالای فروشنده', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Competitor', 'COLUMN', N'SLER_TARF_CODE_'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد رقیب', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Competitor', 'COLUMN', N'SRSC_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد فروشنده', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Competitor', 'COLUMN', N'SRSP_CODE'
GO
