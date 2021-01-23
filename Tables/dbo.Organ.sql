CREATE TABLE [dbo].[Organ]
(
[REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OGID] [bigint] NOT NULL IDENTITY(1, 1),
[NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORGN_DESC] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CORD_X] [float] NULL CONSTRAINT [DF_Cord_X] DEFAULT ((0)),
[CORD_Y] [float] NULL CONSTRAINT [DF_Cord_Y] DEFAULT ((0)),
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Organ_STAT] DEFAULT ('002'),
[KEY_WORD] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GOGL_MAP] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
-- Author:  <Author,,Name>  
-- Create date: <Create Date,,>  
-- Description: <Description,,>  
-- =============================================  
create TRIGGER [dbo].[CG$AINS_ORGN]  
   ON  [dbo].[Organ]  
   AFTER insert 
AS   
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for trigger here  
 MERGE dbo.Organ T  
 USING (Select * FROM Inserted )s  
 ON (T.OGID = S.OGID)  
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
-- Author:  <Author,,Name>  
-- Create date: <Create Date,,>  
-- Description: <Description,,>  
-- =============================================  
CREATE TRIGGER [dbo].[CG$AUPD_ORGN]  
   ON  [dbo].[Organ]  
   AFTER UPDATE  
AS   
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for trigger here  
 MERGE dbo.Organ T  
 USING (Select * FROM Inserted )s  
 ON (T.OGID = S.OGID)  
 WHEN MATCHED THEN  
  UPDATE  
   SET Orgn_Desc = ISNULL(S.Orgn_Desc, S.NAME)
      ,T.MDFY_BY = UPPER(SUSER_NAME())
      ,T.MDFY_DATE = GETDATE();  
END
GO
ALTER TABLE [dbo].[Organ] ADD CONSTRAINT [PK__Organ__ADEA759F4D94879B] PRIMARY KEY CLUSTERED  ([OGID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Organ_OGID] ON [dbo].[Organ] ([OGID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Organ] ADD CONSTRAINT [FK_Organ_Region] FOREIGN KEY ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE])
GO
