CREATE TABLE [dbo].[Service_Robot_Seller]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CHAT_ID] [bigint] NULL,
[CONF_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONF_DATE] [datetime] NULL,
[TIME_SPLY_DNRM] [real] NULL,
[POST_COMT_DNRM] [real] NULL,
[NO_RTRN_DNRM] [real] NULL,
[PROD_STAS_DNRM] [real] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[SHOP_NAME] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHOP_POST_ADRS] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHOP_CORD_X] [float] NULL,
[SHOP_CORD_Y] [float] NULL,
[SHOP_BOT] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHOP_DESC] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHOW_SERV_INFO] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CG$AINS_SRBS]
   ON  [dbo].[Service_Robot_Seller]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Seller T
   USING (SELECT * FROM Inserted) S
   ON (t.SRBT_SERV_FILE_NO = s.SRBT_SERV_FILE_NO AND 
       t.SRBT_ROBO_RBID = s.SRBT_ROBO_RBID AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.CHAT_ID = (
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
CREATE TRIGGER [dbo].[CG$AUPD_SRBS]
   ON  [dbo].[Service_Robot_Seller]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Seller T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Service_Robot_Seller] ADD CONSTRAINT [PK_SRBS] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Seller] ADD CONSTRAINT [FK_SRBS_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ تایید', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller', 'COLUMN', N'CONF_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت تاییدیه درخواست فروشندگی', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller', 'COLUMN', N'CONF_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'بدون مرجوعی', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller', 'COLUMN', N'NO_RTRN_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان رضایتمندی از کالاهای فروشنده', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller', 'COLUMN', N'PROD_STAS_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'لینک فروشگاه انلاین بله', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller', 'COLUMN', N'SHOP_BOT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تلفن فروشگاه', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller', 'COLUMN', N'SHOP_CORD_X'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره موبایل', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller', 'COLUMN', N'SHOP_CORD_Y'
GO
EXEC sp_addextendedproperty N'MS_Description', N'توضیحات فروشگاه', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller', 'COLUMN', N'SHOP_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نام فروشگاه', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller', 'COLUMN', N'SHOP_NAME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آدرس پستی فروشگاه', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller', 'COLUMN', N'SHOP_POST_ADRS'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نمایش اطلاعات مشتری به تامین کننده', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller', 'COLUMN', N'SHOW_SERV_INFO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تامین به موقع کالا', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Seller', 'COLUMN', N'TIME_SPLY_DNRM'
GO
