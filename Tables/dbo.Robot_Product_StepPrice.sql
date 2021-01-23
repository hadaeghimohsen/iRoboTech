CREATE TABLE [dbo].[Robot_Product_StepPrice]
(
[RBPR_CODE] [bigint] NOT NULL,
[RWNO] [bigint] NOT NULL,
[TARF_CODE_DNRM] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STEP_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TARF_CODE_QNTY] [real] NULL,
[CART_SUM_PRIC] [bigint] NULL,
[EXPN_PRIC] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RPSP]
   ON  [dbo].[Robot_Product_StepPrice]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Product_StepPrice T
   USING (SELECT * FROM Inserted) S
   ON (t.RBPR_CODE = s.RBPR_CODE AND 
       t.RWNO = s.RWNO)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.RWNO = CASE WHEN s.RWNO = 0 THEN (SELECT ISNULL(MAX(rpsp.RWNO), 0) + 1 FROM dbo.Robot_Product_StepPrice rpsp WHERE rpsp.RBPR_CODE = s.RBPR_CODE) ELSE s.RWNO END,
         T.TARF_CODE_DNRM = (
            SELECT rp.TARF_CODE
              FROM dbo.Robot_Product rp
             WHERE rp.CODE = s.RBPR_CODE
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
CREATE TRIGGER [dbo].[CG$AUPD_RPSP]
   ON  [dbo].[Robot_Product_StepPrice]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Product_StepPrice T
   USING (SELECT * FROM Inserted) S
   ON (t.RBPR_CODE = s.RBPR_CODE AND 
       t.RWNO = s.RWNO)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Robot_Product_StepPrice] ADD CONSTRAINT [PK_RPSP] PRIMARY KEY CLUSTERED  ([RBPR_CODE], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Product_StepPrice] ADD CONSTRAINT [FK_RPSP_RBPR] FOREIGN KEY ([RBPR_CODE]) REFERENCES [dbo].[Robot_Product] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'جمع مبلغ فاکتور', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product_StepPrice', 'COLUMN', N'CART_SUM_PRIC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مشخص کننده نوع قیمت پله کانی می باشد
اگر تعداد مطرح باشد 
یا جمع فاکتور', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product_StepPrice', 'COLUMN', N'STEP_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداقل تعداد خرید', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product_StepPrice', 'COLUMN', N'TARF_CODE_QNTY'
GO
