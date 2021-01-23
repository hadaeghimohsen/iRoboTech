CREATE TABLE [dbo].[Organ_Category]
(
[ORGN_OGID] [bigint] NOT NULL,
[ISIC_CODE] [bigint] NOT NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Organ_Category_STAT] DEFAULT ('002')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Organ_Category] ADD CONSTRAINT [PK_Organ_Category] PRIMARY KEY CLUSTERED  ([ORGN_OGID], [ISIC_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Organ_Category] ADD CONSTRAINT [FK_Organ_Category_Isic_Category] FOREIGN KEY ([ISIC_CODE]) REFERENCES [dbo].[Isic_Category] ([CODE])
GO
ALTER TABLE [dbo].[Organ_Category] WITH NOCHECK ADD CONSTRAINT [FK_Organ_Category_Organ] FOREIGN KEY ([ORGN_OGID]) REFERENCES [dbo].[Organ] ([OGID])
GO
