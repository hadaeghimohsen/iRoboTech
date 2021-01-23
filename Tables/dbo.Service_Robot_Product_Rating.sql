CREATE TABLE [dbo].[Service_Robot_Product_Rating]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[RBPR_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CHAT_ID] [bigint] NULL,
[TARF_CODE_DNRM] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RATE_NUMB] [real] NULL,
[TITL_TEXT] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RATE_TEXT] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SRPR]
   ON  [dbo].[Service_Robot_Product_Rating]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Product_Rating T
   USING (SELECT * FROM Inserted) S
   ON (t.SRBT_SERV_FILE_NO = s.SRBT_SERV_FILE_NO AND 
       t.SRBT_ROBO_RBID = s.SRBT_ROBO_RBID AND 
       t.RBPR_CODE = s.RBPR_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE ISNULL(s.CODE, 0) WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END,
         T.CHAT_ID = (
            SELECT sr.CHAT_ID
              FROM dbo.Service_Robot sr
             WHERE sr.SERV_FILE_NO = s.SRBT_SERV_FILE_NO
               AND sr.ROBO_RBID = s.SRBT_ROBO_RBID              
         ),
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
CREATE TRIGGER [dbo].[CG$AUPD_SRPR]
   ON  [dbo].[Service_Robot_Product_Rating]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Product_Rating T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
   
   
   -- ثبت آمار نظرسنجی برای کالا یا خدمات
   UPDATE rp
      SET rp.RTNG_NUMB_DNRM = (SELECT AVG(r.RATE_NUMB) FROM dbo.Service_Robot_Product_Rating r WHERE r.SRBT_ROBO_RBID = rp.ROBO_RBID AND r.RBPR_CODE = rp.CODE),
          rp.RTNG_CONT_DNRM = (SELECT COUNT(r.CODE) FROM dbo.Service_Robot_Product_Rating r WHERE r.SRBT_ROBO_RBID = rp.ROBO_RBID AND r.RBPR_CODE = rp.CODE)
     FROM dbo.Robot_Product rp, Inserted i
    WHERE rp.CODE = i.RBPR_CODE;
END
GO
ALTER TABLE [dbo].[Service_Robot_Product_Rating] ADD CONSTRAINT [PK_Service_Robot_Product_Rating] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Product_Rating] ADD CONSTRAINT [FK_Service_Robot_Product_Rating_Robot_Product] FOREIGN KEY ([RBPR_CODE]) REFERENCES [dbo].[Robot_Product] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Product_Rating] ADD CONSTRAINT [FK_Service_Robot_Product_Rating_Service_Robot] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
