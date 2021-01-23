CREATE TABLE [dbo].[Personal_Robot_Job]
(
[PRBT_SERV_FILE_NO] [bigint] NULL,
[PRBT_ROBO_RBID] [bigint] NULL,
[JOB_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL IDENTITY(1, 1),
[CHAT_ID] [bigint] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SEQ_NUMB] [int] NULL,
[BUSY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_PRJB]
   ON  [dbo].[Personal_Robot_Job]
   AFTER DELETE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- 1399/08/15 * برای آن دسته از پرسنلی که در قسمت فروشگاه انلاین ثبت میشوند و به عنوان حسابدار ثبت شده اند و الان اطلاعات انها حذف شده اطلاعات مربوط به برداشت حسابداری را پاک میکنیم
   DELETE dbo.Service_Robot_Card_Bank
    WHERE CODE IN (
          SELECT c.CODE 
            FROM Deleted d, dbo.Service_Robot_Card_Bank c
           WHERE c.SRBT_SERV_FILE_NO = d.PRBT_SERV_FILE_NO
             AND c.SRBT_ROBO_RBID = d.PRBT_ROBO_RBID

             AND d.JOB_CODE = 32 /* سغل حسابداری */                
             AND c.ACNT_TYPE_DNRM = '002' /* حساب فروشگاه */
             AND c.ACNT_STAT_DNRM = '002' /* حساب فعال */
             AND c.ORDR_TYPE_DNRM = '024' /* حساب پرداختنی بابت واریز پورسانت مشتریان */
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
CREATE TRIGGER [dbo].[CG$AINS_PRJB]
   ON  [dbo].[Personal_Robot_Job]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Personal_Robot_Job T
   USING(SELECT * FROM inserted) S
   ON (T.PRBT_SERV_FILE_NO = S.PRBT_SERV_FILE_NO AND
       T.PRBT_ROBO_RBID = S.PRBT_ROBO_RBID AND
       T.JOB_CODE = S.JOB_CODE AND
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE         
         SET T.CRET_BY = UPPER(SUSER_NAME())
            ,T.CRET_DATE = GETDATE()
            ,T.CHAT_ID = (
               SELECT sr.CHAT_ID
                 FROM dbo.Service_Robot sr
                WHERE sr.ROBO_RBID = s.PRBT_ROBO_RBID
                  AND sr.SERV_FILE_NO = s.PRBT_SERV_FILE_NO
            );
   
   -- 1399/08/15 * برای آن دسته از پرسنلی که در قسمت فروشگاه انلاین ثبت میشوند و به عنوان حسابدار ثبت میشود اطلاعات مربوط به برداشت حسابداری را به انها الحاق میکنیم
   IF EXISTS (
      SELECT * 
        FROM Inserted i, dbo.Personal_Robot_Job pj , dbo.Robot_Card_Bank_Account c
       WHERE pj.PRBT_SERV_FILE_NO = i.PRBT_SERV_FILE_NO 
         AND pj.PRBT_ROBO_RBID = i.PRBT_ROBO_RBID 
         AND i.PRBT_ROBO_RBID =  c.ROBO_RBID
         AND i.JOB_CODE = pj.JOB_CODE
         AND i.JOB_CODE = 32 /* سغل حسابداری */
         AND c.ACNT_TYPE = '002' /* حساب فروشگاه */
         AND c.ACNT_STAT = '002' /* حساب فعال */
         AND c.ORDR_TYPE = '024' /* حساب پرداختنی بابت واریز پورسانت مشتریان */
         AND NOT EXISTS (
             SELECT *
               FROM dbo.Service_Robot_Card_Bank sb
              WHERE sb.SRBT_SERV_FILE_NO = pj.PRBT_SERV_FILE_NO
                AND sb.SRBT_ROBO_RBID = pj.PRBT_ROBO_RBID
                AND sb.ACNT_TYPE_DNRM = '002' /* حساب فروشگاه */
                AND sb.ACNT_STAT_DNRM = '002' /* حساب فعال */
                AND sb.ORDR_TYPE_DNRM = '024' /* حساب پرداختنی بابت واریز پورسانت مشتریان */ )
         )
    BEGIN
      -- ثبت اطلاعات پرسنل به عنوان سمت حسابدار و قابلیت برداشت از حساب به عنوان پرداخت پورسانت مشتریان
      INSERT INTO dbo.Service_Robot_Card_Bank ( SRBT_SERV_FILE_NO ,SRBT_ROBO_RBID ,RCBA_CODE ,CODE )
      SELECT i.PRBT_SERV_FILE_NO, i.PRBT_ROBO_RBID, c.CODE, dbo.GNRT_NVID_U()
        FROM Inserted i, dbo.Personal_Robot_Job pj , dbo.Robot_Card_Bank_Account c
       WHERE pj.PRBT_SERV_FILE_NO = i.PRBT_SERV_FILE_NO 
         AND pj.PRBT_ROBO_RBID = i.PRBT_ROBO_RBID 
         AND i.PRBT_ROBO_RBID =  c.ROBO_RBID
         AND i.JOB_CODE = pj.JOB_CODE
         AND i.JOB_CODE = 32 /* سغل حسابداری */
         AND c.ACNT_TYPE = '002' /* حساب فروشگاه */
         AND c.ACNT_STAT = '002' /* حساب فعال */
         AND c.ORDR_TYPE = '024' /* حساب پرداختنی بابت واریز پورسانت مشتریان */;

    END 
   
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
CREATE TRIGGER [dbo].[CG$AUPD_PRJB]
   ON  [dbo].[Personal_Robot_Job]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Personal_Robot_Job T
   USING(SELECT * FROM inserted) S
   ON (T.PRBT_SERV_FILE_NO = S.PRBT_SERV_FILE_NO AND
       T.PRBT_ROBO_RBID = S.PRBT_ROBO_RBID AND
       T.JOB_CODE = S.JOB_CODE AND
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE         
         SET T.MDFY_BY = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE();
   
END
GO
ALTER TABLE [dbo].[Personal_Robot_Job] ADD CONSTRAINT [PK_PRJB] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Personal_Robot_Job] ADD CONSTRAINT [FK_Personal_Robot_Job_Job] FOREIGN KEY ([PRBT_ROBO_RBID], [JOB_CODE]) REFERENCES [dbo].[Job] ([ROBO_RBID], [CODE])
GO
ALTER TABLE [dbo].[Personal_Robot_Job] ADD CONSTRAINT [FK_PRJB_PRBT] FOREIGN KEY ([PRBT_SERV_FILE_NO], [PRBT_ROBO_RBID]) REFERENCES [dbo].[Personal_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
