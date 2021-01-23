CREATE TABLE [dbo].[Service_Robot_Discount_Card]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[ORDR_CODE] [bigint] NULL,
[DCID] [bigint] NOT NULL,
[DISC_DCID] [bigint] NULL,
[CHAT_ID] [bigint] NULL,
[OFF_PRCT] [real] NULL,
[OFF_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OFF_KIND] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FROM_AMNT] [bigint] NULL,
[DISC_CODE] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MAX_AMNT_OFF] [bigint] NULL,
[EXPR_DATE] [datetime] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SRDC]
   ON [dbo].[Service_Robot_Discount_Card]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Discount_Card T
   USING (SELECT * FROM Inserted) S
   ON (t.SRBT_SERV_FILE_NO = s.SRBT_SERV_FILE_NO AND
       t.SRBT_ROBO_RBID = s.SRBT_ROBO_RBID AND 
       t.ORDR_CODE = s.ORDR_CODE AND 
       t.DCID = s.DCID)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,T.DCID = CASE s.DCID WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.DCID END
        ,T.CHAT_ID = (
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
CREATE TRIGGER [dbo].[CG$AUPD_SRDC]
   ON [dbo].[Service_Robot_Discount_Card]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Discount_Card T
   USING (SELECT * FROM Inserted) S
   ON (t.DCID = s.DCID)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Service_Robot_Discount_Card] ADD CONSTRAINT [PK_Service_Robot_Discount_Card] PRIMARY KEY CLUSTERED  ([DCID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Discount_Card] ADD CONSTRAINT [FK_Service_Robot_Discount_Card_Service_Robot] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Discount_Card] ADD CONSTRAINT [FK_SRDC_ORDR] FOREIGN KEY ([ORDR_CODE]) REFERENCES [dbo].[Order] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'تخفیف های گردونه شانس باید مشخص کند که از چه مبلغی لحاظ میشود', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Discount_Card', 'COLUMN', N'FROM_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ تخفیف برای شانس گردونه
مثال : 
فرض کنید مشتری کد تخفیف را دارد که میگویم اگر سفارش شما از 400 هزار تومن بیشتر شد مبلغ 70 هزار تومن تخفیف به شما داده میشود', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Discount_Card', 'COLUMN', N'MAX_AMNT_OFF'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع تخفیف
تخفیف گردونه فروش :
تخفیف گردونه شرط تاریخ پایان رو داره و مبلغ سفارش که تخفیف بتونه لحاظ بشه
تخفیف خرید های مشتری از فروشگاه :
این نوع تخفیف فقط تاریخ پایان رو داره
همه ی تخفیف ها فقط در یک فاکتور می توانند لحاظ شوند', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Discount_Card', 'COLUMN', N'OFF_KIND'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اعتبار کارت تخفیف 
این گزینه می تواند توسط از دست رفتن زمان باقیمانده باشد
و یا استفاده کردن درون سفارش', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Discount_Card', 'COLUMN', N'VALD_TYPE'
GO
