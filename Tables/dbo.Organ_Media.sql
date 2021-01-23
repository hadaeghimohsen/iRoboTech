CREATE TABLE [dbo].[Organ_Media]
(
[OPID] [bigint] NOT NULL IDENTITY(1, 1),
[ORGN_OGID] [bigint] NULL,
[ROBO_RBID] [bigint] NULL,
[RBCN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_PATH] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_NAME] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IMAG_DESC] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Organ_Picture_STAT] DEFAULT ('002'),
[IMAG_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_ID] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHOW_STRT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR] [int] NULL,
[USSD_CODE] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRDC_CODE] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPN_PRIC] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_OGMD]
   ON  [dbo].[Organ_Media]
   AFTER INSERT
AS 
BEGIN
	MERGE dbo.Organ_Media T
	USING (
	   SELECT * 
	     FROM INSERTED I
	) S
	ON (T.OPID = S.OPID) 
	WHEN MATCHED THEN
	   UPDATE
	      SET ORGN_OGID = (SELECT ORGN_OGID FROM dbo.Robot WHERE RBID = S.ROBO_RBID)
	         ,T.CRET_BY = UPPER(SUSER_NAME())
	         ,T.CRET_DATE = GETDATE();

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
CREATE TRIGGER [dbo].[CG$AUPD_OGMD]
   ON  [dbo].[Organ_Media]
   AFTER UPDATE
AS 
BEGIN
	MERGE dbo.Organ_Media T
	USING (
	   SELECT * 
	     FROM INSERTED I
	) S
	ON (T.OPID = S.OPID) 
	WHEN MATCHED THEN
	   UPDATE
	      SET ORGN_OGID = (SELECT ORGN_OGID FROM dbo.Robot WHERE RBID = S.ROBO_RBID)
	         ,T.MDFY_BY = UPPER(SUSER_NAME())
	         ,T.MDFY_DATE = GETDATE();

END
GO
ALTER TABLE [dbo].[Organ_Media] ADD CONSTRAINT [PK_Organ_Picture] PRIMARY KEY CLUSTERED  ([OPID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Organ_Media] ADD CONSTRAINT [FK_Organ_Media_Robot] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID])
GO
ALTER TABLE [dbo].[Organ_Media] ADD CONSTRAINT [FK_Organ_Picture_Organ] FOREIGN KEY ([ORGN_OGID]) REFERENCES [dbo].[Organ] ([OGID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع مدیا
مثلا فرض کنید میخواهید مشخص کنید که این عکس گزینه ای برای خرید جدید می باشد یا اینکه سبد خرید خالی می باشد یا نحوه ارسال بسته سفارش', 'SCHEMA', N'dbo', 'TABLE', N'Organ_Media', 'COLUMN', N'RBCN_TYPE'
GO
