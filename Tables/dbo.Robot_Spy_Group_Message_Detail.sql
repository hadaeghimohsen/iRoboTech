CREATE TABLE [dbo].[Robot_Spy_Group_Message_Detail]
(
[RSGM_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CHAT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RSGD]
   ON  [dbo].[Robot_Spy_Group_Message_Detail]
   AFTER INSERT
AS 
BEGIN
	
	MERGE dbo.Robot_Spy_Group_Message_Detail T
	USING (SELECT * FROM Inserted) S
	ON (T.CODE = S.CODE)
	WHEN MATCHED THEN
	   UPDATE SET
	      t.CRET_BY = UPPER(SUSER_NAME())
	     ,t.CRET_DATE = GETDATE();
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
CREATE TRIGGER [dbo].[CG$AUPD_RSGD]
   ON  [dbo].[Robot_Spy_Group_Message_Detail]
   AFTER UPDATE
AS 
BEGIN
	
	MERGE dbo.Robot_Spy_Group_Message_Detail T
	USING (SELECT * FROM Inserted) S
	ON (T.CODE = S.CODE)
	WHEN MATCHED THEN
	   UPDATE SET
	      t.MDFY_BY = UPPER(SUSER_NAME())
	     ,t.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Robot_Spy_Group_Message_Detail] ADD CONSTRAINT [PK_Robot_Spy_Group_Message_Detail] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Spy_Group_Message_Detail] ADD CONSTRAINT [FK_RSGD_RSGM] FOREIGN KEY ([RSGM_CODE]) REFERENCES [dbo].[Robot_Spy_Group_Message] ([CODE])
GO
