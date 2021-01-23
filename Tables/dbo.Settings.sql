CREATE TABLE [dbo].[Settings]
(
[CODE] [bigint] NOT NULL IDENTITY(1, 1),
[DFLT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Settings_DFLT_STAT] DEFAULT ('001'),
[BACK_UP] [bit] NULL,
[BACK_UP_APP_EXIT] [bit] NULL,
[BACK_UP_IN_TRED] [bit] NULL,
[BACK_UP_OPTN_PATH] [bit] NULL,
[BACK_UP_OPTN_PATH_ADRS] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BACK_UP_ROOT_PATH] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UPLD_FILE] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Settings] ADD CONSTRAINT [PK_Settings] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'مسیر ذخیره سازی فایل ها', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'UPLD_FILE'
GO
