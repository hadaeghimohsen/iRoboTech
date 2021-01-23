CREATE TABLE [dbo].[Service_Robot_Public]
(
[SRBT_SERV_FILE_NO] [bigint] NOT NULL,
[SRBT_ROBO_RBID] [bigint] NOT NULL,
[RWNO] [int] NOT NULL,
[CELL_PHON] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CORD_X] [float] NULL,
[CORD_Y] [float] NULL,
[CHAT_ID] [bigint] NULL,
[SERV_ADRS] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NAME] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VALD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL
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
CREATE TRIGGER [dbo].[CG$AINS_SRPB]
   ON  [dbo].[Service_Robot_Public]
   AFTER INSERT
AS 
BEGIN
	MERGE dbo.Service_Robot_Public T
   USING (SELECT * FROM INSERTED I) S
   ON (T.SRBT_SERV_FILE_NO   = S.SRBT_SERV_FILE_NO AND
       T.SRBT_ROBO_RBID      = S.SRBT_ROBO_RBID AND
       T.RWNO                = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET T.CRET_BY = UPPER(SUSER_NAME())
            ,T.CRET_DATE = GETDATE()
            ,T.RWNO = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Service_Robot_Public WHERE SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO AND SRBT_ROBO_RBID = S.SRBT_ROBO_RBID)
            ,T.VALD_TYPE = ISNULL(s.VALD_TYPE, '002');
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
CREATE TRIGGER [dbo].[CG$AUPD_SRPB]
   ON  [dbo].[Service_Robot_Public]
   AFTER UPDATE
AS 
BEGIN
	MERGE dbo.Service_Robot T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(M.RWNO) FROM dbo.Service_Robot_Public M 
                            WHERE M.SRBT_SERV_FILE_NO = I.SRBT_SERV_FILE_NO
                              AND M.SRBT_ROBO_RBID = I.SRBT_ROBO_RBID
                              AND M.CELL_PHON IS NOT NULL 
                              AND M.CORD_X IS NOT NULL
                              AND M.CORD_Y IS NOT NULL
                              AND m.SERV_ADRS IS NOT NULL)) S
   ON (T.SERV_FILE_NO   = S.SRBT_SERV_FILE_NO AND
       T.ROBO_RBID      = S.SRBT_ROBO_RBID)
   WHEN MATCHED THEN
      UPDATE 
         SET T.SRPB_RWNO = S.RWNO
            ,T.CELL_PHON = S.CELL_PHON
            ,T.CORD_X = S.CORD_X
            ,T.CORD_Y = S.CORD_Y
            ,T.NAME = S.NAME
            ,T.SERV_ADRS = S.SERV_ADRS;

END
GO
ALTER TABLE [dbo].[Service_Robot_Public] ADD CONSTRAINT [PK_Service_Robot_Public] PRIMARY KEY CLUSTERED  ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Public] ADD CONSTRAINT [FK_SRPB_ROBO] FOREIGN KEY ([SRBT_ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Public] WITH NOCHECK ADD CONSTRAINT [FK_SRPB_SERV] FOREIGN KEY ([SRBT_SERV_FILE_NO]) REFERENCES [dbo].[Service] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Public] WITH NOCHECK ADD CONSTRAINT [FK_SRPB_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'اعتبار مشخصات عمومی مشتری', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Public', 'COLUMN', N'VALD_TYPE'
GO
