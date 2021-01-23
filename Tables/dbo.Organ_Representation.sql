CREATE TABLE [dbo].[Organ_Representation]
(
[OLID] [bigint] NOT NULL IDENTITY(1, 1),
[ORGN_OGID] [bigint] NULL,
[CORD_X] [float] NULL,
[CORD_Y] [float] NULL,
[PLAC_ADRS] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Organ_Representation] ADD CONSTRAINT [PK_Organ_Representation] PRIMARY KEY CLUSTERED  ([OLID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Organ_Representation] WITH NOCHECK ADD CONSTRAINT [FK_Organ_Representation_Organ] FOREIGN KEY ([ORGN_OGID]) REFERENCES [dbo].[Organ] ([OGID])
GO
