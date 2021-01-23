CREATE TABLE [dbo].[Personal_Robot_Job_Service_Robot]
(
[PRJB_CODE] [bigint] NULL,
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Personal_Robot_Job_Service_Robot_CODE] DEFAULT ((0)),
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
CREATE TRIGGER [dbo].[CG$AINS_PJSR]
   ON  [dbo].[Personal_Robot_Job_Service_Robot]
   AFTER INSERT
AS 
BEGIN
	MERGE dbo.Personal_Robot_Job_Service_Robot T
	USING (SELECT * FROM Inserted) S
	ON (T.CODE = S.Code)
	WHEN MATCHED THEN
	   UPDATE SET
	      T.CRET_BY = UPPER(SUSER_NAME())
	     ,T.CRET_DATE = GETDATE()
	     ,T.CODE = dbo.GNRT_NVID_U();
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
CREATE TRIGGER [dbo].[CG$AUPD_PJSR]
   ON  [dbo].[Personal_Robot_Job_Service_Robot]
   AFTER UPDATE
AS 
BEGIN
	MERGE dbo.Personal_Robot_Job_Service_Robot T
	USING (SELECT * FROM Inserted) S
	ON (T.CODE = S.Code)
	WHEN MATCHED THEN
	   UPDATE SET
	      T.MDFY_BY = UPPER(SUSER_NAME())
	     ,T.MDFY_DATE = GETDATE();

END
GO
ALTER TABLE [dbo].[Personal_Robot_Job_Service_Robot] ADD CONSTRAINT [PK_PJSR] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Personal_Robot_Job_Service_Robot] ADD CONSTRAINT [FK_PJSR_PRJB] FOREIGN KEY ([PRJB_CODE]) REFERENCES [dbo].[Personal_Robot_Job] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Personal_Robot_Job_Service_Robot] ADD CONSTRAINT [FK_PJSR_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
