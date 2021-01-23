CREATE TABLE [dbo].[User_RobotListener_Fgac]
(
[FGA_CODE] [bigint] NOT NULL IDENTITY(1, 1),
[USER_NAME] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HOST_NAME] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STRT_DATE] [date] NULL,
[END_DATE] [date] NULL,
[ACES_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_URLF]
   ON  [dbo].[User_RobotListener_Fgac]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.User_RobotListener_Fgac T
   USING (SELECT * FROM inserted )S
   ON (T.FGA_CODE = S.FGA_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET T.CRET_BY = UPPER(SUSER_NAME())
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
CREATE TRIGGER [dbo].[CG$AUPD_URLF]
   ON  [dbo].[User_RobotListener_Fgac]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.User_RobotListener_Fgac T
   USING (SELECT * FROM inserted )S
   ON (T.FGA_CODE = S.FGA_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET T.MDFY_BY = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE();         
END
GO
ALTER TABLE [dbo].[User_RobotListener_Fgac] ADD CONSTRAINT [PK_URLF] PRIMARY KEY CLUSTERED  ([FGA_CODE]) ON [PRIMARY]
GO
