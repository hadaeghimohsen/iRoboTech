CREATE TABLE [dbo].[Order_Access]
(
[ORDR_CODE] [bigint] NULL,
[PROB_SERV_FILE_NO] [bigint] NULL,
[PROB_ROBO_RBID] [bigint] NULL,
[CHAT_ID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RECD_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_ORAC]
   ON  [dbo].[Order_Access]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Order_Access T
   USING (SELECT * FROM Inserted) S
   ON (T.ORDR_CODE = S.ORDR_CODE AND
       T.PROB_SERV_FILE_NO = S.PROB_SERV_FILE_NO AND
       T.PROB_ROBO_RBID = S.PROB_ROBO_RBID AND
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,T.CODE = dbo.GNRT_NVID_U()
        ,T.RECD_STAT = '002'
        ,T.CHAT_ID = (SELECT pr.CHAT_ID FROM dbo.Personal_Robot pr WHERE pr.SERV_FILE_NO = s.PROB_SERV_FILE_NO AND pr.ROBO_RBID = s.PROB_ROBO_RBID);
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
CREATE TRIGGER [dbo].[CG$AUPD_ORAC]
   ON  [dbo].[Order_Access]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Order_Access T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE();
        
END
GO
ALTER TABLE [dbo].[Order_Access] ADD CONSTRAINT [PK_Order_Access] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Order_Access] ADD CONSTRAINT [FK_ORAC_ORDR] FOREIGN KEY ([ORDR_CODE]) REFERENCES [dbo].[Order] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Order_Access] ADD CONSTRAINT [FK_ORAC_PRBT] FOREIGN KEY ([PROB_SERV_FILE_NO], [PROB_ROBO_RBID]) REFERENCES [dbo].[Personal_Robot] ([SERV_FILE_NO], [ROBO_RBID])
GO
