CREATE TABLE [dbo].[Service_Robot_Product_Feedback]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[RBPR_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CHAT_ID] [bigint] NULL,
[TARF_CODE_DNRM] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NAME_NOT_VLID] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IMAG_NOT_GOOD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INFO_NOT_TRUE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DESC_NOT_TRUE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PROD_NOT_ORGN] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PROD_HAVE_DUPL] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FEED_BACK_TEXT] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FEED_BACK_DATE] [datetime] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SRPF]
   ON  [dbo].[Service_Robot_Product_Feedback]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Product_Feedback T
   USING (SELECT * FROM Inserted) S
   ON (T.SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO AND 
       t.SRBT_ROBO_RBID = s.SRBT_ROBO_RBID AND 
       t.RBPR_CODE = s.RBPR_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE ISNULL(s.CODE, 0) WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
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
CREATE TRIGGER [dbo].[CG$AUPD_SRPF]
   ON  [dbo].[Service_Robot_Product_Feedback]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Service_Robot_Product_Feedback T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Service_Robot_Product_Feedback] ADD CONSTRAINT [PK_SRPF] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Product_Feedback] ADD CONSTRAINT [FK_SRPF_RBPR] FOREIGN KEY ([RBPR_CODE]) REFERENCES [dbo].[Robot_Product] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Product_Feedback] ADD CONSTRAINT [FK_SRPF_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
