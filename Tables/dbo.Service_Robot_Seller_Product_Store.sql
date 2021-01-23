CREATE TABLE [dbo].[Service_Robot_Seller_Product_Store]
(
[SRSP_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[TARF_CODE_DNRM] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STOR_DATE] [datetime] NULL,
[NUMB] [real] NULL,
[MAKE_DATE] [datetime] NULL,
[EXPR_DATE] [datetime] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SRSS]
   ON  [dbo].[Service_Robot_Seller_Product_Store]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Seller_Product_Store T
   USING (SELECT * FROM Inserted) S
   ON (T.SRSP_CODE = S.SRSP_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE ISNULL(s.CODE, 0) WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.STOR_DATE = GETDATE(),
         T.TARF_CODE_DNRM = (
            SELECT sp.TARF_CODE
              FROM dbo.Service_Robot_Seller_Product sp
             WHERE sp.CODE = s.SRSP_CODE
         );
   
   -- 1399/05/05
   DECLARE C$NewProdStor CURSOR FOR
      SELECT p.TARF_CODE
        FROM Inserted i, dbo.Service_Robot_Seller_Product p
       WHERE i.SRSP_CODE = p.CODE;
   
   DECLARE @TarfCode VARCHAR(100);
   
   OPEN [C$NewProdStor];
   L$NewProdStor:
   FETCH [C$NewProdStor] INTO @TarfCode;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndNewProdStor;
      
   -- 1399/05/04
   -- اگر محصولی که اضافه میکنیم مشتری داشته باشیم که درخواست کننده این کالا بوده باید به آن اطلاع بدهیم که موجودی کالا اوکی شده و می توانید خرید را انجام دهید
   IF EXISTS(
      SELECT *
        FROM dbo.Service_Robot_Seller_Product sp, Inserted i, dbo.Service_Robot_Product_Signal s
       WHERE sp.CODE = i.SRSP_CODE
         AND s.TARF_CODE_DNRM = sp.TARF_CODE
         AND s.SEND_STAT IN ('002', '005')
         AND s.TARF_CODE_DNRM = @TarfCode
   )
   BEGIN
      -- 1399/04/26
      -- اطلاع رسانی به به مشتریان در لیست انتظار فروشگاه
      DECLARE @xTemp XML;
      SET @xTemp = (
          SELECT TOP 1
                 s.SRBT_ROBO_RBID AS '@rbid',
                 s.CHAT_ID AS 'Order/@chatid',
                 '012' AS 'Order/@type',
                 'addprodtostor' AS 'Order/@oprt',
                 sp.TARF_CODE AS 'Order/@valu'
            FROM dbo.Service_Robot_Seller s, dbo.Service_Robot_Seller_Product sp, Inserted i
           WHERE s.CODE = sp.SRBS_CODE
             AND sp.CODE = i.SRSP_CODE
             AND sp.TARF_CODE = @TarfCode
             FOR XML PATH('Robot')
      );
      EXEC dbo.SEND_MEOJ_P @X = @xTemp, @XRet = @xTemp OUTPUT;
   END
   
   GOTO L$NewProdStor;
   L$EndNewProdStor:
   CLOSE [C$NewProdStor];
   DEALLOCATE [C$NewProdStor];
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
CREATE TRIGGER [dbo].[CG$AUPD_SRSS]
   ON  [dbo].[Service_Robot_Seller_Product_Store]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Seller_Product_Store T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
  
  -- بروزرسانی تعداد کل کالا درون جدول انبار
  UPDATE p
     SET p.WREH_INVR_NUMB = (SELECT ISNULL(SUM(s.NUMB), 0) FROM dbo.Service_Robot_Seller_Product_Store s WHERE s.SRSP_CODE = p.CODE),
         p.CRNT_NUMB_DNRM = (SELECT ISNULL(SUM(s.NUMB), 0) FROM dbo.Service_Robot_Seller_Product_Store s WHERE s.SRSP_CODE = p.CODE) - (p.SALE_NUMB_DNRM + p.SALE_CART_NUMB_DNRM) --ISNULL(p.CRNT_NUMB_DNRM, 0) + i.NUMB
    FROM dbo.Service_Robot_Seller_Product p, Inserted i
   WHERE i.SRSP_CODE = p.CODE;
END
GO
ALTER TABLE [dbo].[Service_Robot_Seller_Product_Store] ADD CONSTRAINT [PK_Service_Robot_Seller_Product_Store] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Seller_Product_Store] ADD CONSTRAINT [FK_Service_Robot_Seller_Product_Store_Service_Robot_Seller_Product] FOREIGN KEY ([SRSP_CODE]) REFERENCES [dbo].[Service_Robot_Seller_Product] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ انقضا', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product_Store', 'COLUMN', N'EXPR_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ تولید', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product_Store', 'COLUMN', N'MAKE_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product_Store', 'COLUMN', N'NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ ورود به انبار', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller_Product_Store', 'COLUMN', N'STOR_DATE'
GO
