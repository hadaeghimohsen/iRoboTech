CREATE TABLE [dbo].[Service_Robot_Product_Like]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[RBPR_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[TARF_CODE_DNRM] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHAT_ID] [bigint] NULL,
[LIKE_DATE] [datetime] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SRPL]
   ON  [dbo].[Service_Robot_Product_Like]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Product_Like T
   USING (SELECT * FROM Inserted) S
   ON (t.SRBT_SERV_FILE_NO = s.SRBT_SERV_FILE_NO AND
       t.SRBT_ROBO_RBID = s.SRBT_ROBO_RBID AND 
       t.RBPR_CODE = s.RBPR_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.LIKE_DATE = GETDATE(),
         T.STAT = '002',
         T.CHAT_ID = (
            SELECT sr.CHAT_ID
              FROM dbo.Service_Robot sr
             WHERE sr.SERV_FILE_NO = s.SRBT_SERV_FILE_NO
               AND sr.ROBO_RBID = s.SRBT_ROBO_RBID
         ),
         t.TARF_CODE_DNRM = (
            SELECT rp.TARF_CODE
              FROM dbo.Robot_Product rp
             WHERE rp.ROBO_RBID = s.SRBT_ROBO_RBID
               AND rp.CODE = s.RBPR_CODE
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
CREATE TRIGGER [dbo].[CG$AUPD_SRPL]
   ON  [dbo].[Service_Robot_Product_Like]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Product_Like T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
   
   -- 1399/04/21
   UPDATE p
      SET p.LIKE_CONT_DNRM = (SELECT COUNT(lp.CODE) FROM dbo.Service_Robot_Product_Like lp WHERE lp.RBPR_CODE = p.CODE AND lp.STAT = '002')
     FROM dbo.Robot_Product p, Inserted i
    WHERE p.ROBO_RBID = i.SRBT_ROBO_RBID
      AND p.TARF_CODE = i.TARF_CODE_DNRM;
END
GO
ALTER TABLE [dbo].[Service_Robot_Product_Like] ADD CONSTRAINT [PK_Service_Robot_Product_Like] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Product_Like] ADD CONSTRAINT [FK_Service_Robot_Product_Like_Robot_Product] FOREIGN KEY ([RBPR_CODE]) REFERENCES [dbo].[Robot_Product] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Product_Like] ADD CONSTRAINT [FK_Service_Robot_Product_Like_Service_Robot] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
