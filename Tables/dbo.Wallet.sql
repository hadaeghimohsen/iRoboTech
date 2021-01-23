CREATE TABLE [dbo].[Wallet]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CHAT_ID] [bigint] NULL,
[WLET_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AMNT_DNRM] [bigint] NULL,
[LAST_IN_AMNT_DNRM] [bigint] NULL,
[LAST_IN_DATE_DNRM] [datetime] NULL,
[LAST_OUT_AMNT_DNRM] [bigint] NULL,
[LAST_OUT_DATE_DNRM] [datetime] NULL,
[TEMP_AMNT_USE] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_WLET]
   ON  [dbo].[Wallet]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Wallet T
   USING (SELECT * FROM Inserted) S
   ON (t.SRBT_SERV_FILE_NO = s.SRBT_SERV_FILE_NO AND 
       t.SRBT_ROBO_RBID = s.SRBT_ROBO_RBID AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END,
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
CREATE TRIGGER [dbo].[CG$AUPD_WLET]
   ON  [dbo].[Wallet]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Wallet T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
   
   -- 1399/10/22 * اطلاع رسانی به مشتریان جهت اطلاع رسانی برای برداشت پورسانت
   IF EXISTS(
      SELECT *
        FROM dbo.Robot r, dbo.Wallet w, Inserted i
       WHERE r.RBID = w.SRBT_ROBO_RBID
         AND w.SRBT_SERV_FILE_NO = i.SRBT_SERV_FILE_NO
         AND w.SRBT_ROBO_RBID = i.SRBT_ROBO_RBID
         AND w.CHAT_ID = i.CHAT_ID
         AND r.MIN_WITH_DRAW <= w.AMNT_DNRM
         AND w.WLET_TYPE = '002' -- کیف پول نقدینگی
   )
   BEGIN
      DECLARE @xTemp XML;
      SET @xTemp = (
          SELECT TOP 1
                 r.ROBO_RBID AS '@rbid',
                 w.CHAT_ID AS 'Order/@chatid',
                 '012' AS 'Order/@type',
                 'withdrawcashwlet' AS 'Order/@oprt',
                 w.AMNT_DNRM AS 'Order/@valu'
            FROM dbo.Robot r, dbo.Wallet w, Inserted i
           WHERE r.RBID = w.SRBT_ROBO_RBID
             AND w.SRBT_SERV_FILE_NO = i.SRBT_SERV_FILE_NO
             AND w.SRBT_ROBO_RBID = i.SRBT_ROBO_RBID
             AND w.CHAT_ID = i.CHAT_ID
             AND r.MIN_WITH_DRAW <= w.AMNT_DNRM
             AND w.WLET_TYPE = '002' -- کیف پول نقدینگی   
             FOR XML PATH('Robot')
      );
      EXEC dbo.SEND_MEOJ_P @X = @xTemp, @XRet = @xTemp OUTPUT;
   END 
END
GO
ALTER TABLE [dbo].[Wallet] ADD CONSTRAINT [PK_WLET] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Wallet] ADD CONSTRAINT [FK_WLET_ROBO] FOREIGN KEY ([SRBT_ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
ALTER TABLE [dbo].[Wallet] ADD CONSTRAINT [FK_WLET_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع کیف پول
001 به معنی اعتبار کیف پول میباشد
002 به معنی میزان نقدینگی کیف پول می باشد', 'SCHEMA', N'dbo', 'TABLE', N'Wallet', 'COLUMN', N'WLET_TYPE'
GO
