CREATE TABLE [dbo].[Service_Robot_Seller_Product_Gift]
(
[SRSP_CODE] [bigint] NULL,
[SSPG_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[TARF_CODE_DNRM] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GIFT_TARF_CODE_DNRM] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SRPG]
   ON  [dbo].[Service_Robot_Seller_Product_Gift]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Seller_Product_Gift T
   USING (SELECT * FROM Inserted) S
   ON (T.SRSP_CODE = S.SRSP_CODE AND
       T.SSPG_CODE = S.SSPG_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE ISNULL(s.CODE, 0) WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.STAT = ISNULL(s.STAT, '002'),
         T.TARF_CODE_DNRM = (
            SELECT p.TARF_CODE
              FROM dbo.Service_Robot_Seller_Product p
             WHERE S.SRSP_CODE = p.CODE
         ),
         T.GIFT_TARF_CODE_DNRM = (
            SELECT p.TARF_CODE
              FROM dbo.Service_Robot_Seller_Product p
             WHERE s.SSPG_CODE = p.CODE
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
CREATE TRIGGER [dbo].[CG$AUPD_SRPG]
   ON  [dbo].[Service_Robot_Seller_Product_Gift]
   AFTER UPDATE   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Seller_Product_Gift T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Service_Robot_Seller_Product_Gift] ADD CONSTRAINT [PK_Service_Robot_Seller_Product_Gift] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Seller_Product_Gift] ADD CONSTRAINT [FK_Service_Robot_Seller_Product_Gift_Service_Robot_Seller_Product] FOREIGN KEY ([SSPG_CODE]) REFERENCES [dbo].[Service_Robot_Seller_Product] ([CODE])
GO
ALTER TABLE [dbo].[Service_Robot_Seller_Product_Gift] ADD CONSTRAINT [FK_SSPG_SRSP] FOREIGN KEY ([SRSP_CODE]) REFERENCES [dbo].[Service_Robot_Seller_Product] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'فروشنده کالایی را که به شما می فروشد', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product_Gift', 'COLUMN', N'SRSP_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'فروشنده کالاهایی که به صورت هدیه بابت خرید کالای مورد نظر به شما هدیه میدهد', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product_Gift', 'COLUMN', N'SSPG_CODE'
GO
