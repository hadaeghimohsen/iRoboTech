CREATE TABLE [dbo].[Service_Robot_Following]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[FOLW_SRBT_SERV_FILE_NO] [bigint] NULL,
[FOLW_SRBT_ROBO_RBID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CHAT_ID] [bigint] NULL,
[FOLW_CHAT_ID] [bigint] NULL,
[FOLW_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RLAT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Following] ADD CONSTRAINT [PK_Service_Robot_Following] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Following] ADD CONSTRAINT [FK_SRF1_SRBT] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Following] ADD CONSTRAINT [FK_SRF2_SRBT] FOREIGN KEY ([FOLW_SRBT_SERV_FILE_NO], [FOLW_SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع ارتباط افراد به هم', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Following', 'COLUMN', N'RLAT_TYPE'
GO
